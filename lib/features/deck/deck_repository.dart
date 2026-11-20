import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import '../../core/services/room_service.dart';
import 'deck_engine.dart';

class DeckSeat {
  const DeckSeat(
      {required this.key,
      required this.name,
      required this.role,
      required this.isHost});

  final String key;
  final String name;
  final String role;
  final bool isHost;

  bool get isTable => role == 'table';
}

class DeckRepository {
  DeckRepository._();

  static final DeckRepository instance = DeckRepository._();

  final RoomService _rooms = RoomService.instance;

  Future<({String roomId, String myKey})> create({
    required String name,
    required bool asTable,
  }) async {
    final code = _rooms.generateCode();
    final myKey = asTable ? 'table' : 'p1';
    final roomId = await _rooms.createRoom(
      gamePath: GamePaths.deck,
      data: {
        'code': code,
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'hostKey': myKey,
        'tableKey': asTable ? myKey : '',
        'players': {
          myKey: {
            'name': name,
            'role': asTable ? 'table' : 'player',
            'isHost': true,
          },
        },
      },
    );
    return (roomId: roomId, myKey: myKey);
  }

  Future<({String roomId, String myKey})> join({
    required String code,
    required String name,
    required bool asTable,
  }) async {
    final found = await _rooms.findByCode(gamePath: GamePaths.deck, code: code);
    if (found == null) {
      throw DeckRoomException('Oda bulunamadı');
    }
    String? seat;
    var rejection = 'Oda dolu veya kapanmış';
    final result = await _rooms.transactRoom(
      gamePath: GamePaths.deck,
      roomId: found.id,
      update: (current) {
        seat = null;
        if (current['status'] != 'waiting') {
          rejection = 'Oyun başlamış';
          return null;
        }
        final players =
            Map<String, dynamic>.from((current['players'] as Map?) ?? {});
        if (asTable) {
          final existing = current['tableKey'];
          if (players.containsKey('table') || players.containsKey(existing)) {
            rejection = 'Bu odada zaten bir masa ekranı var';
            return null;
          }
          seat = 'table';
        } else {
          for (var number = 1; number <= 4; number++) {
            final candidate = 'p$number';
            if (!players.containsKey(candidate)) {
              seat = candidate;
              break;
            }
          }
          if (seat == null || playerSeats(current).length >= 4) {
            rejection = 'Masa dolu';
            return null;
          }
        }
        return {
          ...current,
          if (asTable) 'tableKey': 'table',
          'players': {
            ...players,
            seat!: {
              'name': name,
              'role': asTable ? 'table' : 'player',
              'isHost': false
            },
          },
        };
      },
    );
    final joinedSeat = seat;
    if (!result.committed || !result.snapshot.exists || joinedSeat == null) {
      throw DeckRoomException(rejection);
    }
    return (roomId: found.id, myKey: joinedSeat);
  }

  Future<String?> start(
      String roomId, String hostKey, Object? previousDeal) async {
    final seed = Random.secure().nextInt(1 << 30);
    try {
      final result = await _rooms.transactRoom(
        gamePath: GamePaths.deck,
        roomId: roomId,
        update: (current) {
          if (!seatsOf(current)
                  .any((seat) => seat.key == hostKey && seat.isHost) ||
              current['dealStartedAt'] != previousDeal) return null;
          final oldGame = current['game'];
          final canDeal = current['status'] == 'waiting' ||
              (oldGame is Map && oldGame['phase'] == 'scored');
          final seats = playerSeats(current);
          if (!canDeal || seats.length < 2) return null;
          return {
            ...current,
            'status': 'playing',
            'dealStartedAt': ServerValue.timestamp,
            'game': PistiGame.deal(seats, Random(seed)).toMap(),
          };
        },
      );
      if (!result.committed || !result.snapshot.exists) {
        return 'Masa değişti. İki oyuncu hazır olduğunda tekrar dene.';
      }
    } on Object {
      return 'El dağıtılamadı. Bağlantını kontrol edip tekrar dene.';
    }
    return null;
  }

  Future<String?> play({
    required String roomId,
    required String playerKey,
    required String card,
  }) async {
    final ref = FirebaseDatabase.instance.ref('${GamePaths.deck}/$roomId/game');
    try {
      final result = await ref.runTransaction((current) {
        if (current is! Map) {
          return Transaction.abort();
        }
        final game = PistiGame.fromMap(current);
        final error = game.play(playerKey, card);
        if (error != null) {
          return Transaction.abort();
        }
        return Transaction.success(game.toMap());
      });
      if (!result.committed) {
        return 'Kart oynanamadı';
      }
    } on Object {
      return 'Bağlantı koptu. Tekrar dene.';
    }
    return null;
  }

  Future<void> leave({
    required String roomId,
    required String playerKey,
    required bool isHost,
    required bool isTable,
  }) async {
    if (isHost) {
      await _rooms.deleteRoom(gamePath: GamePaths.deck, roomId: roomId);
      return;
    }
    if (isTable) {
      await _rooms.updateRoom(
        gamePath: GamePaths.deck,
        roomId: roomId,
        updates: {
          'tableKey': '',
          'players/$playerKey': null,
        },
      );
      return;
    }
    await _rooms.unregisterPresence(
        gamePath: GamePaths.deck, roomId: roomId, playerKey: playerKey);
    await _rooms.transactRoom(
      gamePath: GamePaths.deck,
      roomId: roomId,
      update: (current) {
        final players =
            Map<String, dynamic>.from((current['players'] as Map?) ?? {});
        if (players.remove(playerKey) == null) return null;
        final game = current['game'];
        final interrupted = game is Map && game['phase'] == 'play';
        return {
          ...current,
          'players': players,
          if (interrupted) ...{
            'status': 'waiting',
            'game': null,
            'dealStartedAt': null
          },
        };
      },
    );
  }

  Stream<Map<String, dynamic>?> watch(String roomId) =>
      _rooms.watchRoom(gamePath: GamePaths.deck, roomId: roomId);

  Future<void> presence({
    required String roomId,
    required String playerKey,
    required bool isHost,
  }) =>
      _rooms.registerPresence(
        gamePath: GamePaths.deck,
        roomId: roomId,
        playerKey: playerKey,
        isHost: isHost,
      );

  static List<DeckSeat> seatsOf(Map<String, dynamic> room) {
    final players = room['players'];
    if (players is! Map) {
      return const [];
    }
    final host = room['hostKey']?.toString() ?? '';
    final seats = <DeckSeat>[];
    players.forEach((key, value) {
      if (value is! Map) {
        return;
      }
      final id = key.toString();
      seats.add(DeckSeat(
        key: id,
        name: value['name']?.toString() ?? 'Oyuncu',
        role: value['role']?.toString() ?? 'player',
        isHost: id == host || value['isHost'] == true,
      ));
    });
    seats.sort((a, b) => a.key.compareTo(b.key));
    return seats;
  }

  static List<String> playerSeats(Map<String, dynamic> room) => [
        for (final seat in seatsOf(room))
          if (!seat.isTable) seat.key,
      ];
}

class DeckRoomException implements Exception {
  DeckRoomException(this.message);
  final String message;

  @override
  String toString() => message;
}
