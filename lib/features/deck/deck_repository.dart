import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import '../../core/services/room_service.dart';
import 'deck_engine.dart';

class DeckSeat {
  const DeckSeat({required this.key, required this.name, required this.role, required this.isHost});

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
    if (found.data['status'] != 'waiting') {
      throw DeckRoomException('Oyun başlamış');
    }
    final players = Map<String, dynamic>.from((found.data['players'] as Map?) ?? {});
    if (asTable) {
      final existing = found.data['tableKey']?.toString() ?? '';
      if (existing.isNotEmpty && players.containsKey(existing)) {
        throw DeckRoomException('Bu odada zaten bir masa ekranı var');
      }
      await _rooms.updateRoom(
        gamePath: GamePaths.deck,
        roomId: found.id,
        updates: {
          'tableKey': 'table',
          'players/table': {
            'name': name,
            'role': 'table',
            'isHost': false,
          },
        },
      );
      return (roomId: found.id, myKey: 'table');
    }
    final seated = players.entries.where((entry) {
      final value = entry.value;
      if (value is! Map) {
        return false;
      }
      return value['role'] != 'table';
    }).length;
    if (seated >= 4) {
      throw DeckRoomException('Masa dolu');
    }
    var myKey = '';
    for (var n = 1; n <= 4; n++) {
      if (!players.containsKey('p$n')) {
        myKey = 'p$n';
        break;
      }
    }
    if (myKey.isEmpty) {
      throw DeckRoomException('Masa dolu');
    }
    await _rooms.addPlayer(
      gamePath: GamePaths.deck,
      roomId: found.id,
      playerKey: myKey,
      playerData: {
        'name': name,
        'role': 'player',
        'isHost': false,
      },
    );
    return (roomId: found.id, myKey: myKey);
  }

  Future<String?> start(String roomId, Map<String, dynamic> room) async {
    final seats = playerSeats(room);
    if (seats.length < 2) {
      return 'En az iki oyuncu gerekli';
    }
    final game = PistiGame.deal(seats, Random());
    try {
      await _rooms.updateRoom(
        gamePath: GamePaths.deck,
        roomId: roomId,
        updates: {
          'status': 'playing',
          'game': game.toMap(),
        },
      );
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
    await _rooms.removePlayer(
      gamePath: GamePaths.deck,
      roomId: roomId,
      playerKey: playerKey,
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
