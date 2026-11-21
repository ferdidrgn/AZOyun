import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Publishes a deliberately small, public-only room summary to a reachable
/// companion Wear OS app. Private hands, roles, targets and player identifiers
/// are never included in this channel.
class WearRoomSnapshot {
  const WearRoomSnapshot({
    required this.roomKey,
    required this.gameName,
    required this.roomCode,
    required this.status,
    required this.playerCount,
    required this.maxPlayers,
    required this.revision,
    required this.eventType,
  });

  final String roomKey;
  final String gameName;
  final String roomCode;
  final String status;
  final int playerCount;
  final int maxPlayers;
  final int revision;
  final String eventType;

  String get eventId => '$roomKey:$revision:$eventType';

  Map<String, Object> toMap() => {
        'roomKey': roomKey,
        'gameName': gameName,
        'roomCode': roomCode,
        'status': status,
        'playerCount': playerCount,
        'maxPlayers': maxPlayers,
        'revision': revision,
        'eventType': eventType,
        'eventId': eventId,
      };

  static const _gameNames = <String, String>{
    'hangman_rooms': 'Adam Asmaca',
    'golf_rooms': 'Mini Golf',
    'soccer_rooms': 'Futbol',
    'city_puzzle_rooms': 'Şehir Bulmaca',
    'word_puzzle_rooms': 'Kelime Bulmaca',
    'vampire_rooms': 'Vampir Köylü',
    'liar_cafe_rooms': 'Yalancılar Kahvesi',
    'okey_rooms': 'Okey',
    'fighter_rooms': 'Dövüşçüler',
    'racing_rooms': 'Araba Yarışı',
    'dama_rooms': 'Dama',
    'impostor_rooms': 'Hain Kim?',
    'deck_rooms': 'Kart Oyunu',
    'family_rooms': 'Aile Masası',
  };

  static WearRoomSnapshot project({
    required String gamePath,
    required String roomId,
    required Map<String, dynamic> room,
    required Map<String, dynamic>? previous,
    required int revision,
  }) {
    final players = room['players'];
    final previousPlayers = previous?['players'];
    final playerCount = players is Map ? players.length : 0;
    final previousCount = previousPlayers is Map ? previousPlayers.length : 0;
    final status = _safeStatus(room['status']);
    final previousStatus = _safeStatus(previous?['status']);
    final eventType = previous == null
        ? 'roomSnapshot'
        : previousStatus != 'playing' && status == 'playing'
            ? 'roomStarted'
            : previousStatus == 'playing' && status == 'finished'
                ? 'roomFinished'
                : playerCount > previousCount
                    ? 'playerJoined'
                    : 'roomUpdated';
    final rawCode = room['code'] ?? room['roomCode'];
    final normalizedCode = rawCode is String ? rawCode.trim().toUpperCase() : '';

    return WearRoomSnapshot(
      roomKey: '$gamePath/$roomId',
      gameName: _gameNames[gamePath] ?? 'Oyun Odası',
      roomCode: normalizedCode.substring(0, normalizedCode.length.clamp(0, 12)),
      status: status,
      playerCount: playerCount,
      maxPlayers: _safeCount(room['maxPlayers'] ?? room['playerLimit']),
      revision: revision,
      eventType: eventType,
    );
  }

  static String _safeStatus(Object? value) {
    switch (value) {
      case 'waiting':
      case 'lobby':
        return 'waiting';
      case 'playing':
      case 'active':
        return 'playing';
      case 'finished':
      case 'complete':
      case 'completed':
        return 'finished';
      default:
        return 'unknown';
    }
  }

  static int _safeCount(Object? value) {
    final count = value is int ? value : int.tryParse('$value') ?? 0;
    return count.clamp(0, 64);
  }

  String get dedupeKey =>
      '$roomKey|$gameName|$roomCode|$status|$playerCount|$maxPlayers';
}

class WearRoomBridge {
  WearRoomBridge._();

  static const _channel = MethodChannel('azoyun/wear');
  static final Map<String, String> _lastPublished = <String, String>{};

  static Future<void> publish(WearRoomSnapshot snapshot) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_lastPublished[snapshot.roomKey] == snapshot.dedupeKey) return;
    _lastPublished[snapshot.roomKey] = snapshot.dedupeKey;
    try {
      await _channel.invokeMethod<bool>(
        'publishRoomSummary',
        snapshot.toMap(),
      );
    } on PlatformException {
      // Room sync must continue if Play services or a reachable watch is absent.
    } on MissingPluginException {
      // Alternate/test Flutter engines may not register the Android channel.
    }
  }
}
