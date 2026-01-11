import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

/// 🎮 Generic Room Service - Tüm oyunlar için
class RoomService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Oda kodu oluştur (6 karakter)
  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Oda ID oluştur
  String generateRoomId() {
    return 'room_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Oda oluştur
  Future<String> createRoom({
    required final String gamePath,
    required final Map<String, dynamic> roomData,
  }) async {
    final roomId = generateRoomId();
    await _database.child('$gamePath/$roomId').set(roomData);
    return roomId;
  }

  /// Oda koduna göre oda bul
  Future<Map<String, dynamic>?> findRoomByCode({
    required final String gamePath,
    required final String roomCode,
  }) async {
    final snapshot = await _database
        .child(gamePath)
        .orderByChild('roomCode')
        .equalTo(roomCode)
        .once();

    if (snapshot.snapshot.value != null) {
      final rooms = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final roomId = rooms.keys.first;
      final room = Map<String, dynamic>.from(rooms[roomId] as Map);
      room['id'] = roomId;
      return room;
    }
    return null;
  }

  /// Bekleyen odaları dinle
  Stream<List<Map<String, dynamic>>> listenToWaitingRooms(
    final String gamePath,
  ) {
    return _database.child(gamePath).onValue.map((final event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];

      final rooms = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> roomList = [];

      rooms.forEach((final key, final value) {
        final room = Map<String, dynamic>.from(value as Map);
        room['id'] = key;
        if (room['status'] == 'waiting') {
          roomList.add(room);
        }
      });

      return roomList;
    });
  }

  /// Oda dinle
  Stream<Map<String, dynamic>?> listenToRoom({
    required final String gamePath,
    required final String roomId,
  }) {
    return _database.child('$gamePath/$roomId').onValue.map((final event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Oda güncelle
  Future<void> updateRoom({
    required final String gamePath,
    required final String roomId,
    required final Map<String, dynamic> updates,
  }) async {
    await _database.child('$gamePath/$roomId').update(updates);
  }

  /// Oyuncu ekle
  Future<void> addPlayer({
    required final String gamePath,
    required final String roomId,
    required final String playerKey,
    required final Map<String, dynamic> playerData,
  }) async {
    await _database
        .child('$gamePath/$roomId/players/$playerKey')
        .set(playerData);
  }

  /// Oyuncu güncelle
  Future<void> updatePlayer({
    required final String gamePath,
    required final String roomId,
    required final String playerKey,
    required final Map<String, dynamic> updates,
  }) async {
    await _database
        .child('$gamePath/$roomId/players/$playerKey')
        .update(updates);
  }

  /// Oyun durumunu değiştir
  Future<void> setGameStatus({
    required final String gamePath,
    required final String roomId,
    required final String status,
  }) async {
    await _database.child('$gamePath/$roomId/status').set(status);
  }

  /// Oda sil
  Future<void> deleteRoom({
    required final String gamePath,
    required final String roomId,
  }) async {
    await _database.child('$gamePath/$roomId').remove();
  }

  /// Eski odaları temizle (1 saatten eski)
  Future<void> cleanOldRooms(final String gamePath) async {
    final snapshot = await _database.child(gamePath).get();
    if (!snapshot.exists) return;

    final rooms = Map<String, dynamic>.from(snapshot.value as Map);
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneHourAgo = now - (60 * 60 * 1000);

    for (var entry in rooms.entries) {
      final roomId = entry.key;
      final room = Map<String, dynamic>.from(entry.value as Map);
      final createdAt = room['createdAt'] ?? 0;

      if (createdAt < oneHourAgo) {
        await deleteRoom(gamePath: gamePath, roomId: roomId);
      }
    }
  }
}

/// 🎯 Oyun Yolları
class GamePaths {
  static const String hangman = 'hangman_rooms';
  static const String golf = 'golf_rooms';
  static const String soccer = 'soccer_rooms';
  static const String math = 'math_rooms';
  static const String cityPuzzle = 'city_puzzle_rooms';
  static const String wordPuzzle = 'word_puzzle_rooms';
  static const String vampire = 'vampire_rooms';
  static const String liarCafe = 'liar_cafe_rooms';
}
