import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GAME PATHS — tüm oyunlar
// ═══════════════════════════════════════════════════════════════════════════

abstract class GamePaths {
  static const hangman    = 'hangman_rooms';
  static const golf       = 'golf_rooms';
  static const soccer     = 'soccer_rooms';
  static const cityPuzzle = 'city_puzzle_rooms';
  static const wordPuzzle = 'word_puzzle_rooms';
  static const vampire    = 'vampire_rooms';
  static const liarCafe   = 'liar_cafe_rooms';
  // YENİ
  static const okey       = 'okey_rooms';
  static const fighter    = 'fighter_rooms';
  static const racing     = 'racing_rooms';
  static const dama       = 'dama_rooms';
  static const impostor   = 'impostor_rooms';
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

  String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  DatabaseReference _ref(String gamePath, String roomId) =>
      _db.child('$gamePath/$roomId');

  Future<String> createRoom({
    required String gamePath,
    required Map<String, dynamic> data,
  }) async {
    final ref = _db.child(gamePath).push();
    await ref.set(data);
    return ref.key!;
  }

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
  }) => _ref(gamePath, roomId).update(updates);

  Future<void> addPlayer({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required Map<String, dynamic> playerData,
  }) => _ref(gamePath, roomId).child('players/$playerKey').set(playerData);

  Future<void> removePlayer({
    required String gamePath,
    required String roomId,
    required String playerKey,
  }) => _ref(gamePath, roomId).child('players/$playerKey').remove();

  Future<void> setStatus({
    required String gamePath,
    required String roomId,
    required String status,
  }) => _ref(gamePath, roomId).child('status').set(status);

  Future<void> deleteRoom({
    required String gamePath,
    required String roomId,
  }) => _ref(gamePath, roomId).remove();

  // ─────────────────────────────────────────────────────────────────────────
  // ODADAN ÇIKIŞ — oda/lobi ekranlarının "çık" akışındaki Firebase kısmı.
  //
  // Bu blok, 12 oyun ekranında ayrı ayrı elle yazılmış olan aynı iki-dallı
  // kararın ortak hali. Kasıtlı olarak TEK bir metot değil, İKİ metot:
  // oyunların bugünkü davranışı gerçekten iki farklı kural kullanıyor ve
  // bu refactor hiçbir oyunun davranışını değiştirmiyor.
  // ─────────────────────────────────────────────────────────────────────────

  /// Kural 1 — **host odayı kapatır**.
  ///
  /// Host ayrılırsa oda tamamen silinir; host değilse sadece o oyuncunun
  /// koltuğu boşaltılır ve oda ayakta kalır.
  ///
  /// Kullananlar: Mini Golf, Serbest Vuruş, Adam Asmaca oda ekranları ve
  /// Şehir Bulmaca / Kelime Bulmaca / Yalancılar Kahvesi lobileri.
  Future<void> leaveRoom({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required bool isHost,
  }) async {
    if (isHost) {
      await deleteRoom(gamePath: gamePath, roomId: roomId);
    } else {
      await removePlayer(
          gamePath: gamePath, roomId: roomId, playerKey: playerKey);
    }
  }

  /// Kural 2 — **host ya da geriye kimse kalmıyorsa oda kapanır**.
  ///
  /// [leaveRoom]'dan tek farkı: host olmayan bir oyuncu ayrılırken odada
  /// başka hiç kimse kalmıyorsa oda boş bırakılmaz, silinir. [players]
  /// çağıranın elindeki güncel `players` haritasıdır (ayrılan oyuncu dahil);
  /// "son oyuncu muyum" kararı buradan türetilir.
  ///
  /// Kullananlar: Araba Yarışı, Dövüşçüler, Hain Kim?, Okey, Dama ve
  /// Vampir Köylü lobileri.
  Future<void> leaveRoomClosingIfLast({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required bool isHost,
    required Map<dynamic, dynamic> players,
  }) {
    final remaining = Map<dynamic, dynamic>.from(players)..remove(playerKey);
    return leaveRoom(
      gamePath:  gamePath,
      roomId:    roomId,
      playerKey: playerKey,
      isHost:    remaining.isEmpty || isHost,
    );
  }

  /// Bağlantı **kontrolsüz** koparsa (uygulama çöker, ağ kesilir, telefon
  /// kapanır) Firebase sunucusunun kendisinin yapacağı temizliği kaydeder.
  /// Düzgün "odadan çık" akışı zaten her oyunda ayrı ayrı çalışıyor — bu,
  /// sadece o akışın hiç çalışamadığı durumu kapatır. Host için tüm odayı,
  /// diğer oyuncular için sadece kendi koltuklarını siler; bu, mevcut
  /// manuel "çık" davranışıyla birebir aynı kural.
  Future<void> registerPresence({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required bool isHost,
  }) async {
    final target = isHost
        ? _ref(gamePath, roomId)
        : _ref(gamePath, roomId).child('players/$playerKey');
    try {
      await target.onDisconnect().remove();
    } catch (_) {
      // onDisconnect kaydı başarısız olsa bile düzgün "çık" akışı çalışmaya
      // devam eder; bu sadece ekstra bir güvenlik ağı.
    }
  }

  Stream<Map<String, dynamic>?> watchRoom({
    required String gamePath,
    required String roomId,
  }) =>
      _ref(gamePath, roomId).onValue.map((e) {
        if (e.snapshot.value == null) return null;
        return Map<String, dynamic>.from(e.snapshot.value as Map);
      });
}
