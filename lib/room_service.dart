import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

/// 🎮 Generic Room Service - Tüm oyunlar için
class RoomService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Oda kodu oluştur
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

  /// Oda oluştur (generic)
  Future<String> createRoom({
    required String gamePath,
    required Map<String, dynamic> roomData,
  }) async {
    final roomId = generateRoomId();
    await _database.child('$gamePath/$roomId').set(roomData);
    return roomId;
  }

  /// Oda koduna göre oda bul
  Future<Map<String, dynamic>?> findRoomByCode({
    required String gamePath,
    required String roomCode,
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
  Stream<List<Map<String, dynamic>>> listenToWaitingRooms(String gamePath) {
    return _database.child(gamePath).onValue.map((event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];

      final rooms = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> roomList = [];

      rooms.forEach((key, value) {
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
    required String gamePath,
    required String roomId,
  }) {
    return _database.child('$gamePath/$roomId').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Oda güncelle
  Future<void> updateRoom({
    required String gamePath,
    required String roomId,
    required Map<String, dynamic> updates,
  }) async {
    await _database.child('$gamePath/$roomId').update(updates);
  }

  /// Oyuncu ekle
  Future<void> addPlayer({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required Map<String, dynamic> playerData,
  }) async {
    await _database
        .child('$gamePath/$roomId/players/$playerKey')
        .set(playerData);
  }

  /// Oyuncu güncelle
  Future<void> updatePlayer({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required Map<String, dynamic> updates,
  }) async {
    await _database
        .child('$gamePath/$roomId/players/$playerKey')
        .update(updates);
  }

  /// Oyun durumunu değiştir
  Future<void> setGameStatus({
    required String gamePath,
    required String roomId,
    required String status,
  }) async {
    await _database.child('$gamePath/$roomId/status').set(status);
  }

  /// Oda sil
  Future<void> deleteRoom({
    required String gamePath,
    required String roomId,
  }) async {
    await _database.child('$gamePath/$roomId').remove();
  }
}

/// 🎯 Oyun yolları
class GamePaths {
  static const String hangman = 'hangman_rooms';
  static const String golf = 'golf_rooms';
  static const String freeKick = 'freekick_rooms';
  static const String racing = 'racing_rooms';
}
