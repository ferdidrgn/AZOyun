import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

/// Paths for every game type inside Firebase.
class GamePaths {
  static const hangman = 'hangman_rooms';
  static const golf    = 'golf_rooms';
}

/// Generic CRUD layer for multiplayer rooms.
class RoomService {
  RoomService._();
  static final RoomService instance = RoomService._();

  final _db = FirebaseDatabase.instance.ref();

  // ── helpers ──────────────────────────────────────────────────────────────

  String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  DatabaseReference roomRef(String path, String id) => _db.child('$path/$id');

  // ── create ───────────────────────────────────────────────────────────────

  Future<String> createRoom({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final ref = _db.child(path).push();
    await ref.set(data);
    return ref.key!;
  }

  // ── find by code ─────────────────────────────────────────────────────────

  Future<({String id, Map<String, dynamic> data})?> findByCode({
    required String path,
    required String code,
  }) async {
    final snap = await _db
        .child(path)
        .orderByChild('code')
        .equalTo(code)
        .once();
    if (snap.snapshot.value == null) return null;
    final map = snap.snapshot.value as Map;
    final id  = map.keys.first as String;
    return (id: id, data: Map<String, dynamic>.from(map[id] as Map));
  }

  // ── update / delete ──────────────────────────────────────────────────────

  Future<void> update(String path, String id, Map<String, dynamic> updates) =>
      roomRef(path, id).update(updates);

  Future<void> delete(String path, String id) =>
      roomRef(path, id).remove();

  // ── listen ────────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> watchRoom(String path, String id) =>
      roomRef(path, id).onValue.map((e) {
        if (e.snapshot.value == null) return null;
        return Map<String, dynamic>.from(e.snapshot.value as Map);
      });
}
