import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GAME PATHS
// ═══════════════════════════════════════════════════════════════════════════

abstract class GamePaths {
  static const hangman = 'hangman_rooms';
  static const golf = 'golf_rooms';
  static const soccer = 'soccer_rooms';
  static const cityPuzzle = 'city_puzzle_rooms';
  static const wordPuzzle = 'word_puzzle_rooms';
  static const vampire = 'vampire_rooms';
  static const liarCafe = 'liar_cafe_rooms';
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOM RESULT
// ═══════════════════════════════════════════════════════════════════════════

class RoomResult {
  final String id;
  final Map<String, dynamic> data;

  const RoomResult({required this.id, required this.data});
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOM SERVICE — Singleton
// ═══════════════════════════════════════════════════════════════════════════

class RoomService {
  RoomService._();

  static final RoomService instance = RoomService._();

  final _db = FirebaseDatabase.instance.ref();

  // ── Helpers ──────────────────────────────────────────────────────────────

  String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (final _) => chars[rng.nextInt(chars.length)])
        .join();
  }

  DatabaseReference _nodeRef(final String gamePath, final String roomId) =>
      _db.child('$gamePath/$roomId');

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<String> createRoom({
    required final String gamePath,
    required final Map<String, dynamic> data,
  }) async {
    final ref = _db.child(gamePath).push();
    await ref.set(data);
    return ref.key!;
  }

  /// Searches by 'code' first, then falls back to 'roomCode' for legacy rooms
  Future<RoomResult?> findByCode({
    required final String gamePath,
    required final String code,
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
        final id = map.keys.first as String;
        return RoomResult(
          id: id,
          data: Map<String, dynamic>.from(map[id] as Map),
        );
      }
    }
    return null;
  }

  Future<void> updateRoom({
    required final String gamePath,
    required final String roomId,
    required final Map<String, dynamic> updates,
  }) =>
      _nodeRef(gamePath, roomId).update(updates);

  Future<void> addPlayer({
    required final String gamePath,
    required final String roomId,
    required final String playerKey,
    required final Map<String, dynamic> playerData,
  }) =>
      _nodeRef(gamePath, roomId).child('players/$playerKey').set(playerData);

  Future<void> removePlayer({
    required final String gamePath,
    required final String roomId,
    required final String playerKey,
  }) =>
      _nodeRef(gamePath, roomId).child('players/$playerKey').remove();

  Future<void> setStatus({
    required final String gamePath,
    required final String roomId,
    required final String status,
  }) =>
      _nodeRef(gamePath, roomId).child('status').set(status);

  Future<void> deleteRoom({
    required final String gamePath,
    required final String roomId,
  }) =>
      _nodeRef(gamePath, roomId).remove();

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> watchRoom({
    required final String gamePath,
    required final String roomId,
  }) =>
      _nodeRef(gamePath, roomId).onValue.map((final e) {
        if (e.snapshot.value == null) return null;
        return Map<String, dynamic>.from(e.snapshot.value as Map);
      });
}
