import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GAME PATHS
// ═══════════════════════════════════════════════════════════════════════════

abstract class GamePaths {
  static const hangman    = 'hangman_rooms';
  static const golf       = 'golf_rooms';
  static const soccer     = 'soccer_rooms';
  static const cityPuzzle = 'city_puzzle_rooms';
  static const wordPuzzle = 'word_puzzle_rooms';
  static const vampire    = 'vampire_rooms';
  static const liarCafe   = 'liar_cafe_rooms';
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT
// ═══════════════════════════════════════════════════════════════════════════

class RoomResult {
  final String id;
  final Map<String, dynamic> data;
  const RoomResult({required this.id, required this.data});
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOM SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class RoomService {
  RoomService._();
  static final RoomService instance = RoomService._();

  final _db = FirebaseDatabase.instance.ref();

  // ── Helpers ──────────────────────────────────────────────────────────────

  String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  DatabaseReference _ref(String gamePath, String roomId) =>
      _db.child('$gamePath/$roomId');

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<String> createRoom({
    required String gamePath,
    required Map<String, dynamic> data,
  }) async {
    final ref = _db.child(gamePath).push();
    await ref.set(data);
    return ref.key!;
  }

  /// Searches 'code' then 'roomCode' for legacy compatibility.
  Future<RoomResult?> findByCode({
    required String gamePath,
    required String code,
  }) async {
    for (final field in ['code', 'roomCode']) {
      final snap = await _db
          .child(gamePath)
          .orderByChild(field)
          .equalTo(code)
          .limitToFirst(1)
          .once();
      if (snap.snapshot.value != null) {
        final map = snap.snapshot.value as Map;
        final id  = map.keys.first as String;
        return RoomResult(
          id:   id,
          data: Map<String, dynamic>.from(map[id] as Map),
        );
      }
    }
    return null;
  }

  Future<void> updateRoom({
    required String gamePath,
    required String roomId,
    required Map<String, dynamic> updates,
  }) =>
      _ref(gamePath, roomId).update(updates);

  Future<void> addPlayer({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required Map<String, dynamic> playerData,
  }) =>
      _ref(gamePath, roomId).child('players/$playerKey').set(playerData);

  Future<void> removePlayer({
    required String gamePath,
    required String roomId,
    required String playerKey,
  }) =>
      _ref(gamePath, roomId).child('players/$playerKey').remove();

  Future<void> setStatus({
    required String gamePath,
    required String roomId,
    required String status,
  }) =>
      _ref(gamePath, roomId).child('status').set(status);

  Future<void> deleteRoom({
    required String gamePath,
    required String roomId,
  }) =>
      _ref(gamePath, roomId).remove();

  // ── Stream ───────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> watchRoom({
    required String gamePath,
    required String roomId,
  }) =>
      _ref(gamePath, roomId).onValue.map((e) {
        if (e.snapshot.value == null) return null;
        return Map<String, dynamic>.from(e.snapshot.value as Map);
      });
}
