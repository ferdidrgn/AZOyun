import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The only room data allowed across the phone/watch boundary.
/// Never add player identity, hidden role, hand, target, or private game state.
enum WearRoomEventType {
  roomCreated,
  playerJoined,
  roomStarted,
  turnChanged,
  roomFinished,
  roomUpdated,
}

class WearRoomSummary {
  const WearRoomSummary({
    required this.game,
    required this.code,
    required this.status,
    required this.players,
    required this.eventId,
    required this.eventType,
    required this._turn,
  });

  final String game;
  final String code;
  final String status;
  final int players;
  final String eventId;
  final WearRoomEventType eventType;
  final String _turn;

  Map<String, Object> toPlatformMap() => {
        'game': game,
        'code': code,
        'status': status,
        'players': players,
        'eventId': eventId,
        'eventType': eventType.name,
        'sentAt': DateTime.now().millisecondsSinceEpoch,
      };

  static WearRoomSummary? fromRoom({
    required String gamePath,
    required String roomId,
    required Map<String, dynamic>? room,
    required WearRoomSummary? previous,
  }) {
    if (room == null) return null;
    final players = room['players'];
    final count = players is Map ? players.length : 0;
    final rawStatus =
        (room['status'] ?? room['state'] ?? 'waiting').toString().toLowerCase();
    const allowedStatuses = {
      'waiting',
      'waiting_for_players',
      'waitingforplayers',
      'full',
      'started',
      'playing',
      'active',
      'finished',
      'complete',
      'completed',
      'ended',
      'closed',
      'results',
    };
    final status = allowedStatuses.contains(rawStatus) ? rawStatus : 'active';
    // Only export a numeric turn counter internally. A current-turn field often
    // contains a player key, so string identifiers are never forwarded.
    final rawTurn = room['turnIndex'];
    final turn = rawTurn is num ? rawTurn.toInt().toString() : '';
    final WearRoomEventType eventType;
    if (previous == null) {
      eventType = WearRoomEventType.roomCreated;
    } else if (status != previous.status &&
        const {'started', 'playing', 'active'}.contains(status)) {
      eventType = WearRoomEventType.roomStarted;
    } else if (status != previous.status &&
        const {'finished', 'complete', 'completed', 'ended'}.contains(status)) {
      eventType = WearRoomEventType.roomFinished;
    } else if (count > previous.players) {
      eventType = WearRoomEventType.playerJoined;
    } else if (turn.isNotEmpty && turn != previous._turn) {
      eventType = WearRoomEventType.turnChanged;
    } else {
      eventType = WearRoomEventType.roomUpdated;
    }

    final normalizedCode = (room['code'] ?? room['roomCode'] ?? '')
        .toString()
        .replaceAll(RegExp('[^A-Za-z0-9]'), '');
    final code = normalizedCode.length > 8 ? normalizedCode.substring(0, 8) : normalizedCode;
    // Event IDs encode only coarse room state, never player or hidden game data.
    final eventId = '$gamePath:$code:${eventType.name}:$status:$count:$turn';
    return WearRoomSummary(
      game: _gameName(gamePath),
      code: code,
      status: status,
      players: count,
      eventId: eventId,
      eventType: eventType,
      _turn: turn,
    );
  }

  static String _gameName(String path) => const {
        'hangman_rooms': 'Adam Asmaca',
        'golf_rooms': 'Mini Golf',
        'soccer_rooms': 'Serbest Vuruş',
        'city_puzzle_rooms': 'Şehir Bulmaca',
        'word_puzzle_rooms': 'Kelime Bulmaca',
        'vampire_rooms': 'Vampir Köylü',
        'liar_cafe_rooms': 'Yalancılar Kahvesi',
        'okey_rooms': 'Okey',
        'fighter_rooms': 'Dövüşçüler',
        'racing_rooms': 'Araba Yarışı',
        'dama_rooms': 'Dama',
        'impostor_rooms': 'Hain Kim?',
        'deck_rooms': 'Pişti',
      }[path] ?? 'AZOyun';
}

class WearRoomBridge {
  WearRoomBridge._();
  static const _channel = MethodChannel('azoyun/wear');

  static Future<bool> isWearAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('wearAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> publish(WearRoomSummary? room) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>(
        'publishRoom',
        room?.toPlatformMap() ?? {
          'game': '',
          'code': '',
          'status': 'closed',
          'players': 0,
          'eventId': 'closed',
          'eventType': 'roomFinished',
          'sentAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } on PlatformException {
      // Wear OS is optional; phone room play must continue without it.
    } on MissingPluginException {
      // A watch companion may not be installed on this phone build.
    }
  }
}
