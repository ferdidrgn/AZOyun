import 'package:firebase_database/firebase_database.dart';

/// 🔥 Firebase servis yöneticisi
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Hangman odaları referansı
  DatabaseReference get hangmanRooms => _database.child('hangman_rooms');

  /// Golf odaları referansı (gelecekte)
  DatabaseReference get golfRooms => _database.child('golf_rooms');

  /// Free kick odaları referansı (gelecekte)
  DatabaseReference get freeKickRooms => _database.child('freekick_rooms');

  /// Racing odaları referansı (gelecekte)
  DatabaseReference get racingRooms => _database.child('racing_rooms');

  /// Kullanıcı istatistikleri
  DatabaseReference get userStats => _database.child('user_stats');

  /// Oda oluştur
  Future<String> createRoom(
    String gamePath,
    Map<String, dynamic> roomData,
  ) async {
    final roomRef = _database.child(gamePath).push();
    await roomRef.set(roomData);
    return roomRef.key!;
  }

  /// Oda güncelle
  Future<void> updateRoom(
    String gamePath,
    String roomId,
    Map<String, dynamic> updates,
  ) async {
    await _database.child('$gamePath/$roomId').update(updates);
  }

  /// Oda sil
  Future<void> deleteRoom(String gamePath, String roomId) async {
    await _database.child('$gamePath/$roomId').remove();
  }

  /// Oda dinle
  Stream<DatabaseEvent> listenToRoom(String gamePath, String roomId) {
    return _database.child('$gamePath/$roomId').onValue;
  }

  /// Tüm odaları dinle
  Stream<DatabaseEvent> listenToRooms(String gamePath) {
    return _database.child(gamePath).onValue;
  }

  /// Oda koduna göre oda bul
  Future<Map<String, dynamic>?> findRoomByCode(
    String gamePath,
    String roomCode,
  ) async {
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

  /// Bekleyen odaları getir
  Future<List<Map<String, dynamic>>> getWaitingRooms(String gamePath) async {
    final snapshot = await _database
        .child(gamePath)
        .orderByChild('status')
        .equalTo('waiting')
        .once();

    final List<Map<String, dynamic>> rooms = [];
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final room = Map<String, dynamic>.from(value as Map);
        room['id'] = key;
        rooms.add(room);
      });
    }
    return rooms;
  }

  /// Kullanıcı istatistiklerini güncelle
  Future<void> updateUserStats(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    await userStats.child(userId).update(stats);
  }

  /// Kullanıcı istatistiklerini getir
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    final snapshot = await userStats.child(userId).once();
    if (snapshot.snapshot.value != null) {
      return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
    }
    return null;
  }

  /// Bağlantı durumunu kontrol et
  Stream<bool> get connectionState {
    return _database.child('.info/connected').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Sunucu zamanını al
  Future<int> getServerTimestamp() async {
    final snapshot = await _database.child('.info/serverTimeOffset').once();
    final offset = snapshot.snapshot.value as int? ?? 0;
    return DateTime.now().millisecondsSinceEpoch + offset;
  }
}
