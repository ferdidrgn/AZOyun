import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GAME PATHS — tüm oyunlar
// ═══════════════════════════════════════════════════════════════════════════

abstract class GamePaths {
  static const hangman = 'hangman_rooms';
  static const golf = 'golf_rooms';
  static const soccer = 'soccer_rooms';
  static const cityPuzzle = 'city_puzzle_rooms';
  static const wordPuzzle = 'word_puzzle_rooms';
  static const vampire = 'vampire_rooms';
  static const liarCafe = 'liar_cafe_rooms';
  // YENİ
  static const okey = 'okey_rooms';
  static const fighter = 'fighter_rooms';
  static const racing = 'racing_rooms';
  static const dama = 'dama_rooms';
  static const impostor = 'impostor_rooms';
  static const deck = 'deck_rooms';
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
  final _presence = <String, _RoomPresence>{};

  String _presenceKey(String path, String roomId, String playerKey) =>
      '$path/$roomId/$playerKey';

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
  }) async {
    await unregisterPresence(
        gamePath: gamePath, roomId: roomId, playerKey: playerKey);
    await _ref(gamePath, roomId).child('players/$playerKey').remove();
  }

  Future<void> setStatus({
    required String gamePath,
    required String roomId,
    required String status,
  }) =>
      _ref(gamePath, roomId).child('status').set(status);

  Future<void> deleteRoom({
    required String gamePath,
    required String roomId,
  }) async {
    final prefix = '$gamePath/$roomId/';
    final keys = _presence.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keys) {
      final registration = _presence.remove(key);
      if (registration != null) await registration.close();
    }
    await _ref(gamePath, roomId).remove();
  }

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
      gamePath: gamePath,
      roomId: roomId,
      playerKey: playerKey,
      isHost: remaining.isEmpty || isHost,
    );
  }

  /// Her bağlantının kendi kaydı vardır. Geçici bağlantı kaybı oyuncu
  /// koltuğunu silmez ve aynı odada yeniden bağlanmaya izin verir.
  Future<void> registerPresence({
    required String gamePath,
    required String roomId,
    required String playerKey,
    required bool isHost,
  }) async {
    final key = _presenceKey(gamePath, roomId, playerKey);
    if (_presence.containsKey(key)) return;
    final registration = _RoomPresence(_ref(gamePath, roomId), playerKey);
    _presence[key] = registration;
    registration.start(FirebaseDatabase.instance.ref('.info/connected'),
        onSeatRemoved: () {
      if (_presence[key] == registration) _presence.remove(key);
      unawaited(registration.close());
    });
  }

  Future<void> unregisterPresence({
    required String gamePath,
    required String roomId,
    required String playerKey,
  }) async {
    final registration =
        _presence.remove(_presenceKey(gamePath, roomId, playerKey));
    if (registration != null) await registration.close();
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

class _RoomPresence {
  _RoomPresence(this.room, this.playerKey);

  final DatabaseReference room;
  final String playerKey;
  StreamSubscription<DatabaseEvent>? _connectionListener;
  StreamSubscription<DatabaseEvent>? _seatListener;
  DatabaseReference? _session;
  Future<void> _pending = Future.value();
  bool _closed = false;
  bool _online = false;
  int _generation = 0;

  void start(DatabaseReference connected,
      {required void Function() onSeatRemoved}) {
    _seatListener = room.child('players/$playerKey').onValue.listen((event) {
      if (!event.snapshot.exists) onSeatRemoved();
    }, onError: (Object _) {});
    _connectionListener = connected.onValue.listen((event) {
      final online = event.snapshot.value == true;
      if (_closed || _online == online) return;
      _online = online;
      final generation = ++_generation;
      if (online) _pending = _pending.then((_) => _register(generation));
    }, onError: (Object _) {});
  }

  Future<void> _register(int generation) async {
    if (_closed || generation != _generation) return;
    final session = room.child('_lifecycle/connections').push();
    try {
      await session.onDisconnect().remove();
      if (_closed || generation != _generation) return;
      final result = await room.runTransaction((value) {
        if (_closed || generation != _generation) {
          return Transaction.abort();
        }
        // A transaction may first see an empty local cache and retry with
        // the remote room. A null write also leaves deleted rooms absent.
        if (value == null) return Transaction.success(null);
        if (value is! Map) return Transaction.abort();
        final roomData = Map<String, dynamic>.from(value);
        final players = roomData['players'];
        if (players is! Map || !players.containsKey(playerKey)) {
          return Transaction.abort();
        }
        final lifecycle = Map<String, dynamic>.from(
          (roomData['_lifecycle'] as Map?) ?? {},
        );
        final tracked = Map<String, dynamic>.from(
          (lifecycle['tracked'] as Map?) ?? {},
        )..[playerKey] = true;
        final connections = Map<String, dynamic>.from(
          (lifecycle['connections'] as Map?) ?? {},
        )..[session.key!] = playerKey;
        roomData['_lifecycle'] = lifecycle
          ..['tracked'] = tracked
          ..['connections'] = connections
          ..remove('emptySince');
        return Transaction.success(roomData);
      }, applyLocally: false);
      if (result.committed &&
          result.snapshot
              .child('_lifecycle/connections/${session.key}')
              .exists) {
        _session = session;
      } else {
        await session.onDisconnect().cancel();
      }
    } catch (_) {
      // Bir sonraki bağlantıda Firebase kayıt işlemini yeniden dener.
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _connectionListener?.cancel();
    await _seatListener?.cancel();
    await _pending;
    final session = _session;
    if (session == null) return;
    try {
      await session.remove();
    } catch (_) {
      // Bağlantı yoksa önceden kaydedilen onDisconnect kaydı temizler.
    }
  }
}
