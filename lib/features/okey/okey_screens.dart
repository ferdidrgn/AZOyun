import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

// ═══════════════════════════════════════════════════════════════════
// TILE MODEL
// ═══════════════════════════════════════════════════════════════════

enum TColor { sari, mavi, kirmizi, siyah }

class OTile {
  final int num;
  final TColor color;
  final bool joker;
  final String id;
  const OTile({required this.num, required this.color, required this.joker, required this.id});

  factory OTile.fromMap(Map m) => OTile(
    num: m['n'] as int, color: TColor.values[m['c'] as int],
    joker: m['j'] as bool? ?? false, id: m['id'] as String,
  );
  Map<String, dynamic> toMap() => {'n': num, 'c': color.index, 'j': joker, 'id': id};

  static Color uiColor(TColor c) => [
    const Color(0xFFCBA135), AZColors.blueDk,
    AZColors.redDk, const Color(0xFF212121),
  ][c.index];

  String get display => joker ? '★' : '$num';
}

// ═══════════════════════════════════════════════════════════════════
// EL GEÇERLİLİĞİ — "AÇTIM" kontrolü
//
// Elindeki taşların TAMAMI, standart okey kurallarına uygun 3+ taşlık
// gruplara ayrılabiliyor mu? İki grup tipi var:
//  - PER: aynı sayı, farklı renk (3 ya da 4 taş — her renkten en fazla 1)
//  - SERİ: aynı renk, ardışık sayılar (min 3, max 13, 13'ten sonra 1'e
//    dönmez)
// Jokerler (gerçek joker taşları + gösterge ile eşleşen "okey" taşı)
// eksik taşın yerine geçebilir. Backtracking ile çözülür: her adımda
// henüz kullanılmamış ilk taşı içeren olası grupları dener.
bool isValidOkeyHand(List<OTile> tiles, {required bool Function(OTile) isOkeyPiece}) {
  final normals = <OTile>[];
  var jokerCount = 0;
  for (final t in tiles) {
    if (isOkeyPiece(t)) {
      jokerCount++;
    } else {
      normals.add(t);
    }
  }
  return _OkeyHandSolver(normals).solve(jokerCount);
}

class _OkeyHandSolver {
  _OkeyHandSolver(this.normals);
  final List<OTile> normals;

  int _steps = 0;
  static const _maxSteps = 300000; // combinatorial patlamaya karşı güvenlik sınırı

  bool solve(int jokerCount) => _solve(List.filled(normals.length, false), jokerCount);

  bool _solve(List<bool> used, int jokersLeft) {
    if (++_steps > _maxSteps) return false;
    final firstIdx = used.indexOf(false);
    if (firstIdx == -1) return true; // tüm taşlar bir gruba dahil edildi
    final first = normals[firstIdx];

    // PER dene: first.color'ı içeren 3'lü ve 4'lü renk kombinasyonları
    for (final size in [4, 3]) {
      for (final colors in _colorSubsetsContaining(first.color, size)) {
        final newUsed = List<bool>.from(used)..[firstIdx] = true;
        var need = 0;
        for (final c in colors) {
          if (c == first.color) continue;
          final idx = _findUnused(newUsed, (t) => t.num == first.num && t.color == c);
          if (idx != -1) {
            newUsed[idx] = true;
          } else {
            need++;
          }
        }
        if (need <= jokersLeft && _solve(newUsed, jokersLeft - need)) return true;
      }
    }

    // SERİ dene: first.color renginde, first.num'u içeren her uzunluk/konum
    for (var length = 3; length <= 13; length++) {
      for (var offset = 0; offset < length; offset++) {
        final start = first.num - offset;
        final end = start + length - 1;
        if (start < 1 || end > 13) continue;
        final newUsed = List<bool>.from(used)..[firstIdx] = true;
        var need = 0;
        for (var n = start; n <= end; n++) {
          if (n == first.num) continue;
          final idx = _findUnused(newUsed, (t) => t.num == n && t.color == first.color);
          if (idx != -1) {
            newUsed[idx] = true;
          } else {
            need++;
          }
        }
        if (need <= jokersLeft && _solve(newUsed, jokersLeft - need)) return true;
      }
    }

    return false;
  }

  int _findUnused(List<bool> used, bool Function(OTile) test) {
    for (var i = 0; i < normals.length; i++) {
      if (!used[i] && test(normals[i])) return i;
    }
    return -1;
  }

  List<List<TColor>> _colorSubsetsContaining(TColor must, int size) {
    final others = TColor.values.where((c) => c != must).toList();
    final result = <List<TColor>>[];
    void combo(List<TColor> chosen, int start) {
      if (chosen.length == size - 1) {
        result.add([must, ...chosen]);
        return;
      }
      for (var i = start; i < others.length; i++) {
        combo([...chosen, others[i]], i + 1);
      }
    }
    combo([], 0);
    return result;
  }
}

List<Map<String, dynamic>> buildDeck(int seed) {
  final rng = Random(seed);
  final tiles = <Map<String, dynamic>>[];
  int id = 0;
  for (var copy = 0; copy < 2; copy++) {
    for (var c = 0; c < 4; c++) {
      for (var n = 1; n <= 13; n++) {
        tiles.add(OTile(num: n, color: TColor.values[c], joker: false, id: 't${id++}').toMap());
      }
    }
  }
  tiles.add(OTile(num: 0, color: TColor.sari, joker: true, id: 'j0').toMap());
  tiles.add(OTile(num: 0, color: TColor.siyah, joker: true, id: 'j1').toMap());
  tiles.shuffle(rng);
  return tiles;
}

// ═══════════════════════════════════════════════════════════════════
// LOBBY
// ═══════════════════════════════════════════════════════════════════

class OkeyLobbyScreen extends StatefulWidget {
  const OkeyLobbyScreen({super.key, this.mode = 'okey'});
  final String mode;
  @override State<OkeyLobbyScreen> createState() => _OLobbyState();
}

class _OLobbyState extends State<OkeyLobbyScreen> {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _name; bool _loading = false;
  late String _mode;

  @override void initState() { super.initState(); _mode = widget.mode; _load(); }
  @override void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Color get _accent => _mode == '101' ? AZColors.orangeDk : AZColors.greenDk;
  Gradient get _grad => _mode == '101' ? AZColors.gradOrange : AZColors.gradGreen;

  Future<void> _load() async {
    final n = await _storage.getPlayerName(); if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _name = n); else _ask();
  }
  Future<void> _ask() async {
    final n = await showNameDialog(context, current: _name, accentColor: _accent);
    if (n == null || !mounted) return;
    await _storage.setPlayerName(n); setState(() => _name = n);
  }

  Future<void> _create() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final seed = Random().nextInt(999999);
      final id = await _rooms.createRoom(gamePath: GamePaths.okey, data: {
        'code': code, 'status': 'waiting', 'mode': _mode,
        'createdAt': ServerValue.timestamp, 'seed': seed,
        'players': {'p1': {'name': _name, 'isHost': true, 'score': 0, 'hand': []}},
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          OkeyRoomScreen(roomId: id, myKey: 'p1', myName: _name!, mode: _mode)));
    } catch (e) { context.snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _join() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { context.snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.okey, code: code);
      if (r == null) { context.snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { context.snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 4) { context.snack('Oda dolu'); return; }
      final myKey = 'p${players.length + 1}';
      final roomMode = r.data['mode'] as String? ?? 'okey';
      await _rooms.updateRoom(gamePath: GamePaths.okey, roomId: r.id,
          updates: {'players/$myKey': {'name': _name, 'isHost': false, 'score': 0, 'hand': []}});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          OkeyRoomScreen(roomId: r.id, myKey: myKey, myName: _name!, mode: roomMode)));
    } catch (e) { context.snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
    gradient: _grad,
    child: Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context))),
          const Text('🀄', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          // Mod seçici
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _ModeBtn(label: 'Okey', sel: _mode == 'okey', onTap: () => setState(() => _mode = 'okey')),
            const SizedBox(width: 12),
            _ModeBtn(label: '101', sel: _mode == '101', onTap: () => setState(() => _mode = '101')),
          ]),
          const SizedBox(height: 8),
          Text(_mode == '101'
              ? '2-4 Oyuncu · Küçük el (7 taş) · Hızlı tur, el aç kazan!'
              : '2-4 Oyuncu · El aç, kazan!',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(onTap: _ask, child: AZFrostCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(_name ?? 'Ad seç', style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 20),
          AZButton(label: 'ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
              onPressed: _create, color: _accent, loading: _loading, width: 280),
          const SizedBox(height: 20),
          const Text('— veya —', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          AZFrostCard(child: Column(children: [
            AZCodeField(controller: _codeCtrl),
            const SizedBox(height: 14),
            AZJoinButton(onPressed: _join, loading: _loading),
          ])),
          const SizedBox(height: 20),
          AZFrostCard(opacity: 0.1, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_mode == '101' ? '🃏 101 Nasıl?' : '🀄 Okey Nasıl?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_mode == '101'
                  ? '• Her oyuncuya 7 taş dağıtılır (hızlı tur)\n'
                    '• Sırayla demetten çek, at\n'
                    '• Elin tam seri/per gruplarına ayrılınca AÇTIM de\n'
                    '• Yanlış açarsan ceza puanı kaybedersin'
                  : '• 21 taş dağıtılır\n'
                    '• Sırayla çek veya atıktan al\n'
                    '• Elin tam seri/per gruplarına ayrılınca AÇTIM de\n'
                    '• Yanlış açarsan ceza puanı kaybedersin',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
            ],
          )),
          const SizedBox(height: 16),
        ]),
      )),
      const AdaptiveBannerAdWidget(),
    ]),
  );
}

class _ModeBtn extends StatelessWidget {
  const _ModeBtn({required this.label, required this.sel, required this.onTap});
  final String label; final bool sel; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: sel ? 2 : 1),
      ),
      child: Text(label, style: TextStyle(
          color: sel ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// ROOM
// ═══════════════════════════════════════════════════════════════════

class OkeyRoomScreen extends StatefulWidget {
  const OkeyRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName, required this.mode});
  final String roomId, myKey, myName, mode;
  @override State<OkeyRoomScreen> createState() => _ORoomState();
}

class _ORoomState extends State<OkeyRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.okey, roomId: widget.roomId).listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.okey, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    final players = (d['players'] as Map?) ?? {};
    if (players.isEmpty) {
      _rooms.deleteRoom(gamePath: GamePaths.okey, roomId: widget.roomId);
      if (mounted) Navigator.pop(context);
      return;
    }
    if (d['status'] == 'playing' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          OkeyGameScreen(roomId: widget.roomId, myKey: widget.myKey,
              myName: widget.myName, mode: widget.mode)));
    }
  }

  Map get _players => (_room['players'] as Map?) ?? {};
  String get _code => _room['code'] ?? '------';
  bool get _isHost => widget.myKey == 'p1';
  bool get _canStart => _players.length >= 2;
  String get _mode => _room['mode'] ?? widget.mode;
  Color get _accent => _mode == '101' ? AZColors.orangeDk : AZColors.greenDk;
  Gradient get _grad => _mode == '101' ? AZColors.gradOrange : AZColors.gradGreen;

  Future<void> _start() async {
    if (!_canStart) { context.snack('En az 2 oyuncu'); return; }
    final seed = (_room['seed'] as int?) ?? Random().nextInt(999999);
    final deck = buildDeck(seed);
    final keys = _players.keys.toList();
    // Gerçek Okey kuralı: her oyuncuya 14 taş, başlayan oyuncuya (turu açan)
    // ekstra 1 taş (15) verilir — böylece ilk hamlesinde çekmeden doğrudan
    // taş atar. Bu kural hem klasik Okey hem 101 Okey'de aynıdır.
    const baseSz = 14;
    final updates = <String, dynamic>{
      'status': 'playing', 'turn': keys.first,
      'round': 1,
    };
    var cursor = 0;
    for (var i = 0; i < keys.length; i++) {
      final sz = i == 0 ? baseSz + 1 : baseSz;
      updates['players/${keys[i]}/hand'] = deck.sublist(cursor, cursor + sz);
      cursor += sz;
    }
    final remaining = deck.sublist(cursor);
    // Okey göstergesi
    if (remaining.isNotEmpty) {
      final ind = remaining.first;
      final okN = ((ind['n'] as int) % 13) + 1;
      updates['indicator'] = ind;
      updates['okeyN'] = okN;
      updates['okeyC'] = ind['c'];
    }
    updates['deck'] = remaining.length > 1 ? remaining.sublist(1) : [];
    updates['discard'] = [];
    await _rooms.updateRoom(gamePath: GamePaths.okey, roomId: widget.roomId, updates: updates);
  }

  Future<void> _leave() async {
    await _rooms.leaveRoomClosingIfLast(
        gamePath:  GamePaths.okey,
        roomId:    widget.roomId,
        playerKey: widget.myKey,
        isHost:    _isHost,
        players:   _players);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AZLeaveGuard(onLeave: _leave,
    child: AZGradientScaffold(gradient: _grad,
      child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        AZRoomHeader(title: _mode == '101' ? 'OKEY 101' : 'OKEY', onClose: _leave),
        const SizedBox(height: 20),
        AZRoomCode(code: _code, accentColor: _accent),
        const SizedBox(height: 20),
        AZFrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Oyuncular (${_players.length}/4)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          for (final e in _players.entries)
            AZPlayerTile(name: e.value['name'] as String? ?? e.key,
                isMe: e.key == widget.myKey, isHost: e.value['isHost'] == true,
                emoji: '🀄', present: true),
          if (!_canStart) const Text('En az 2 oyuncu gerekli',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
        ])),
        const Spacer(),
        if (_isHost) AZButton(label: 'DAĞIT!', icon: Icons.shuffle_rounded,
            onPressed: _canStart ? _start : null, color: _accent, width: double.infinity)
        else const AZWaitingCard(message: 'Host dağıtacak...'),
      ])),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// GAME
// ═══════════════════════════════════════════════════════════════════

class OkeyGameScreen extends StatefulWidget {
  const OkeyGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName, required this.mode});
  final String roomId, myKey, myName, mode;
  @override State<OkeyGameScreen> createState() => _OGameState();
}

class _OGameState extends State<OkeyGameScreen> with SingleTickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false, _processing = false;
  bool _roomGone = false;
  int? _selIdx;
  bool _wonDialog = false;

  // İstakadaki (elimdeki) taşların kullanıcının kendi sürükleyerek/sıralayarak
  // ayarladığı görüntü sırası — sadece bu cihazda tutulur; sunucudaki 'hand'
  // listesi taş kimliklerini (id) taşımaya devam eder, biz sadece görüntü
  // sırasını yönetiyoruz. Bir taş atıldığında bu sıra sunucuya da yazılır ki
  // yeniden bağlanınca düzen korunsun.
  final List<String> _order = [];

  late AnimationController _winCtrl;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.okey}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFB);
    _winCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }
  @override void dispose() { _winCtrl.dispose(); _sub?.cancel(); super.dispose(); }

  void _onFB(DatabaseEvent e) {
    if (!mounted) return;
    if (e.snapshot.value == null) {
      // Oda silindi (host ayrıldı ya da bağlantısı koptu) — eskiden burada
      // sessizce return edilirdi ve diğer oyuncuların ekranı sonsuza dek
      // donuk kalırdı. Artık herkesi ana menüye döndürüyoruz.
      if (!_roomGone) {
        _roomGone = true;
        Navigator.popUntil(context, (r) => r.isFirst);
      }
      return;
    }
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() {
      _room = d;
      _syncOrder(_hand);
    });
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true; AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 400), _showFinal);
    }
  }

  void _syncOrder(List<OTile> hand) {
    final ids = hand.map((t) => t.id).toSet();
    _order.removeWhere((id) => !ids.contains(id));
    final placed = _order.toSet();
    for (final t in hand) {
      if (!placed.contains(t.id)) _order.add(t.id);
    }
  }

  List<OTile> get _orderedHand {
    final byId = {for (final t in _hand) t.id: t};
    return _order.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  void _sortHand({required bool byColor}) {
    setState(() {
      final ordered = List<OTile>.from(_orderedHand);
      ordered.sort((a, b) {
        if (a.joker != b.joker) return a.joker ? 1 : -1;
        if (byColor) {
          if (a.color != b.color) return a.color.index.compareTo(b.color.index);
          return a.num.compareTo(b.num);
        } else {
          if (a.num != b.num) return a.num.compareTo(b.num);
          return a.color.index.compareTo(b.color.index);
        }
      });
      _order
        ..clear()
        ..addAll(ordered.map((t) => t.id));
      _selIdx = null;
    });
    HapticFeedback.selectionClick();
  }

  Map get _players => (_room['players'] as Map?) ?? {};
  String get _turn => (_room['turn'] as String?) ?? '';
  bool get _isMyTurn => _turn == widget.myKey;
  List get _deck => (_room['deck'] as List?) ?? [];
  List get _discard => (_room['discard'] as List?) ?? [];
  Map? get _indicator => _room['indicator'] as Map?;
  int? get _okeyN => _room['okeyN'] as int?;
  int? get _okeyC => _room['okeyC'] as int?;
  String get _mode => _room['mode'] ?? widget.mode;

  List<OTile> get _hand {
    final raw = (_players[widget.myKey]?['hand'] as List?) ?? [];
    return raw.map((t) => OTile.fromMap(Map<String, dynamic>.from(t as Map))).toList();
  }

  // Gerçek Okey kuralı: elde 15 taş varsa (tur açan oyuncunun ilk turu ya da
  // demetten/atıktan az önce çekildiyse) taş ATMAK zorunludur; 14 taş varsa
  // ÇEKMEK zorunludur. Bu, sunucudan gelen el uzunluğundan türetilir — ayrı
  // bir yerel bayrak tutmaya gerek yok, bu yüzden yeniden bağlanma/tazeleme
  // durumunda asla yanlış senkronize olmaz.
  bool get _mustDiscard => _isMyTurn && _hand.length.isOdd;

  bool _isOkey(OTile t) {
    if (t.joker) return true;
    if (_okeyN == null || _okeyC == null) return false;
    return t.num == _okeyN && t.color.index == _okeyC;
  }

  Future<void> _drawDeck() async {
    if (!_isMyTurn || _mustDiscard || _processing || _deck.isEmpty) return;
    setState(() => _processing = true);
    try {
      final newDeck = List.from(_deck);
      final drawn = Map<String, dynamic>.from(newDeck.removeLast() as Map);
      final hand = _hand;
      await _ref.update({
        'deck': newDeck,
        'players/${widget.myKey}/hand': [...hand.map((t) => t.toMap()), drawn],
      });
      HapticFeedback.selectionClick();
    } finally { setState(() => _processing = false); }
  }

  Future<void> _drawDiscard() async {
    if (!_isMyTurn || _mustDiscard || _processing || _discard.isEmpty) return;
    setState(() => _processing = true);
    try {
      final newDiscard = List.from(_discard);
      final drawn = Map<String, dynamic>.from(newDiscard.removeLast() as Map);
      final hand = _hand;
      await _ref.update({
        'discard': newDiscard,
        'players/${widget.myKey}/hand': [...hand.map((t) => t.toMap()), drawn],
      });
      HapticFeedback.selectionClick();
    } finally { setState(() => _processing = false); }
  }

  Future<void> _discardTile(int idx) async {
    if (!_isMyTurn || !_mustDiscard || _processing) return;
    setState(() => _processing = true);
    try {
      // İstakadaki (kullanıcının düzenlediği) sırayı temel al, atılan taşı
      // çıkar ve kalan sırayı da sunucuya yaz — böylece düzen korunur.
      final ordered = List<OTile>.from(_orderedHand);
      final tile = ordered.removeAt(idx);
      _order.remove(tile.id);
      final newHand = ordered.map((t) => t.toMap()).toList();
      final newDiscard = [..._discard, tile.toMap()];
      // Sıradaki oyuncu
      final keys = _players.keys.toList();
      final next = keys[(keys.indexOf(widget.myKey) + 1) % keys.length];
      await _ref.update({
        'players/${widget.myKey}/hand': newHand,
        'discard': newDiscard,
        'turn': next,
      });
      setState(() { _selIdx = null; });
      HapticFeedback.lightImpact();
    } finally { setState(() => _processing = false); }
  }

  Future<void> _declareWin() async {
    if (!_isMyTurn || _processing || _wonDialog) return;

    // Gerçek el geçerliliği kontrolü: eldeki TÜM taşlar (jokerler dahil)
    // 3+ taşlık per/seri gruplarına tam olarak ayrılabiliyor mu?
    final valid = isValidOkeyHand(_orderedHand, isOkeyPiece: _isOkey);

    if (!valid) {
      setState(() => _wonDialog = true);
      final tryIt = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: const Text('❌ Bu El Açılmıyor'),
        content: const Text('Elindeki taşlar tam seri/per gruplarına '
            'ayrılamıyor. Yine de denersen ceza puanı kaybedersin!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yine de Aç (Ceza Al)')),
        ],
      ));
      setState(() => _wonDialog = false);
      if (tryIt != true) return;

      setState(() => _processing = true);
      try {
        final penalty = _mode == '101' ? 20 : 30;
        await _ref.update({
          'players/${widget.myKey}/score':
              ((_players[widget.myKey]?['score'] as int?) ?? 0) - penalty,
        });
        context.snack('❌ Yanlış açtın! -$penalty puan.');
      } finally { setState(() => _processing = false); }
      return;
    }

    setState(() => _wonDialog = true);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('🎉 AÇTIM!'),
      content: const Text('Elindeki tüm taşlar geçerli seri/per '
          'gruplarına ayrılıyor. Açmak istiyor musun?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal')),
        FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, aç!')),
      ],
    ));
    if (ok != true) { setState(() => _wonDialog = false); return; }

    setState(() => _processing = true);
    try {
      final bonus = _mode == '101' ? 50 : 100;
      await _ref.update({
        'status': 'finished', 'winner': widget.myKey,
        'players/${widget.myKey}/score':
            ((_players[widget.myKey]?['score'] as int?) ?? 0) + bonus,
      });
    } finally { setState(() => _processing = false); }
  }

  void _showFinal() {
    if (!mounted) return;
    final winner = _room['winner'] as String? ?? '';
    final sorted = _players.entries.toList()
      ..sort((a, b) => ((b.value['score'] as int?) ?? 0).compareTo((a.value['score'] as int?) ?? 0));
    ProfileService.instance
        .reportGameResult(gameId: 'okey', won: winner == widget.myKey)
        .then((_) => AchievementService.instance.checkAndUnlock());
    const medals = ['🥇', '🥈', '🥉', '4.'];
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      title: Text(_mode == '101' ? '🃏 Oyun Bitti!' : '🀄 Oyun Bitti!',
          textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min,
        children: sorted.asMap().entries.map((e) {
          final isMe = e.value.key == widget.myKey;
          final score = (e.value.value['score'] as int?) ?? 0;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: isMe ? Colors.green.shade50 : null,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Text(e.key < medals.length ? medals[e.key] : '?',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value.value['name'] as String? ?? e.value.key,
                  style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 16))),
              if (e.value.key == winner) const Text('👑 ', style: TextStyle(fontSize: 16)),
              Text('$score', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList(),
      ),
      actions: [FilledButton(
        style: FilledButton.styleFrom(backgroundColor: AZColors.greenDk),
        onPressed: () async {
          await _db.child('${GamePaths.okey}/${widget.roomId}').remove();
          if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
        },
        child: const Text('Ana Menü'),
      )],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final hand = _orderedHand;
    final topDiscard = _discard.isNotEmpty
        ? OTile.fromMap(Map<String, dynamic>.from(_discard.last as Map)) : null;

    return Scaffold(
      backgroundColor: const Color(0xFF232C21),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [Color(0xFF4A5C42), Color(0xFF33402E), Color(0xFF232C21)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(child: Column(children: [
        // Score bar
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF3A4A34), Color(0xFF232C21)],
            ),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Text(_mode == '101' ? 'OKEY 101' : 'OKEY',
                style: const TextStyle(color: Colors.white70, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
            const Spacer(),
            ..._players.entries.map((e) {
              final isMe = e.key == widget.myKey;
              final score = (e.value['score'] as int?) ?? 0;
              final isTurn = e.key == _turn;
              return Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: isMe ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                    border: isTurn ? Border.all(color: Colors.yellow, width: 2) : null),
                child: Text('${e.value['name']}: $score',
                    style: TextStyle(color: isMe ? AZColors.greenDk : Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 12)),
              );
            }),
          ]),
        ),

        // Okey göstergesi + Demet + Atık
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // Gösterge
            if (_indicator != null) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GÖSTERGE', style: TextStyle(color: Colors.white54, fontSize: 9,
                  fontWeight: FontWeight.w700)),
              _TileW(tile: OTile.fromMap(Map<String, dynamic>.from(_indicator as Map)),
                  isOkey: false, selected: false, mustDiscard: false, size: 42),
              if (_okeyN != null && _okeyC != null) ...[
                const Text('OKEY', style: TextStyle(color: Colors.yellow, fontSize: 9,
                    fontWeight: FontWeight.w700)),
                _TileW(tile: OTile(num: _okeyN!, color: TColor.values[_okeyC!],
                    joker: false, id: 'ok'), isOkey: true, selected: false,
                    mustDiscard: false, size: 42),
              ],
            ]),
            const Spacer(),
            // Demet
            GestureDetector(
              onTap: _isMyTurn && !_mustDiscard ? _drawDeck : null,
              child: Stack(clipBehavior: Clip.none, children: [
                for (var i = 2; i >= 0; i--)
                  Positioned(left: i * 1.5, top: i * -1.5,
                    child: Container(width: 50, height: 75,
                      decoration: BoxDecoration(
                          color: const Color(0xFF37474F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24)))),
                Container(
                  width: 50, height: 75,
                  decoration: BoxDecoration(
                    color: _isMyTurn && !_mustDiscard
                        ? const Color(0xFF546E7A) : const Color(0xFF263238),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _isMyTurn && !_mustDiscard ? Colors.white60 : Colors.white24,
                        width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 4))]),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.style_rounded, color: Colors.white60, size: 18),
                    const SizedBox(height: 4),
                    Text('${_deck.length}', style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            // Atık
            GestureDetector(
              onTap: _isMyTurn && !_mustDiscard && topDiscard != null ? _drawDiscard : null,
              child: topDiscard != null
                  ? _TileW(tile: topDiscard, isOkey: _isOkey(topDiscard),
                      selected: false, mustDiscard: false, size: 56,
                      highlighted: _isMyTurn && !_mustDiscard)
                  : Container(width: 50, height: 75,
                      decoration: BoxDecoration(
                          color: Colors.white12, borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24)),
                      child: const Center(child: Icon(Icons.block_rounded,
                          color: Colors.white30, size: 18))),
            ),
          ]),
        ),

        // Durum
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: _isMyTurn ? AZColors.green : Colors.black26,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isMyTurn
                  ? [BoxShadow(color: AZColors.green.withAlpha(120), blurRadius: 10, offset: const Offset(0, 3))]
                  : const []),
          child: Text(
            _isMyTurn
                ? (_mustDiscard ? '🗑️ Bir taş at!' : '👆 Demetden veya atıktan çek')
                : '⏳ ${_players[_turn]?['name'] ?? _turn} oynuyor...',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),

        // El — ahşap istaka
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(children: [
              const Text('İSTAKAM', style: TextStyle(color: Colors.white54, fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 1)),
              const Spacer(),
              _SortBtn(icon: Icons.palette_rounded, label: 'Renk',
                  onTap: () => _sortHand(byColor: true)),
              const SizedBox(width: 6),
              _SortBtn(icon: Icons.filter_9_plus_rounded, label: 'Sayı',
                  onTap: () => _sortHand(byColor: false)),
            ])),
            Expanded(child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF8C7863), Color(0xFF5C4A3D), Color(0xFF3A2E22)],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E241D), width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))],
              ),
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
              child: Stack(children: [
                // İstaka oyuğu (taşların üstüne oturduğu ince ışık çizgisi)
                Positioned(left: 10, right: 10, top: 10,
                    child: Container(height: 3, decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(color: Colors.white.withAlpha(30),
                            offset: const Offset(0, 1))]))),
                hand.isEmpty
                    ? const SizedBox()
                    : ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        proxyDecorator: (child, index, animation) => Material(
                            color: Colors.transparent, elevation: 6, child: child),
                        itemCount: hand.length,
                        itemBuilder: (context, i) {
                          final tile = hand[i];
                          final sel = _selIdx == i;
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(tile.id),
                            index: i,
                            child: GestureDetector(
                              onTap: () {
                                if (_isMyTurn && _mustDiscard) {
                                  _discardTile(i);
                                } else {
                                  setState(() => _selIdx = sel ? null : i);
                                }
                              },
                              child: _TileW(tile: tile, isOkey: _isOkey(tile),
                                  selected: sel, mustDiscard: _isMyTurn && _mustDiscard),
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) newIndex -= 1;
                            final id = _order.removeAt(oldIndex);
                            _order.insert(newIndex, id);
                            _selIdx = null;
                          });
                        },
                      ),
              ]),
            )),
          ]),
        )),

        // Buton
        if (_isMyTurn && _mustDiscard)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: FilledButton.icon(
              onPressed: _declareWin,
              icon: const Icon(Icons.celebration_rounded),
              label: const Text('AÇTIM! 🎉',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),

        const BannerAdWidget(),
      ])),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SIRALA BUTONU
// ═══════════════════════════════════════════════════════════════════

class _SortBtn extends StatelessWidget {
  const _SortBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// TILE WIDGET
// ═══════════════════════════════════════════════════════════════════

class _TileW extends StatelessWidget {
  const _TileW({required this.tile, required this.isOkey,
      required this.selected, required this.mustDiscard,
      this.highlighted = false, this.size = 52});
  final OTile tile; final bool isOkey, selected, mustDiscard, highlighted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final numColor = tile.joker ? AZColors.purpleDk : OTile.uiColor(tile.color);
    final topShade = isOkey ? const Color(0xFFF0E0B8) : const Color(0xFFFFFDF7);
    final botShade = isOkey ? AZColors.accentGoldSoft : const Color(0xFFEAE3D2);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: 3, vertical: selected ? 0 : 8),
      transform: selected
          ? (Matrix4.identity()..translate(0.0, -6.0))
          : Matrix4.identity(),
      width: size * 0.85, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [topShade, botShade]),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: isOkey ? AZColors.orangeDk
                : selected ? AZColors.orange
                : highlighted ? AZColors.green
                : mustDiscard ? AZColors.red.withAlpha(130)
                : Colors.grey.shade500,
            width: selected || isOkey ? 2.5 : 1.3),
        boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(selected ? 110 : 55),
            blurRadius: selected ? 10 : 4,
            offset: Offset(0, selected ? 4 : 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // Cilalı yüzey hissi — üst kenarda ince parlaklık şeridi
        Positioned(top: 2, left: 4, right: 4,
            child: Container(height: size * 0.16,
                decoration: BoxDecoration(color: Colors.white.withAlpha(110),
                    borderRadius: BorderRadius.circular(6)))),
        // Taban oyuğu — gerçek okey taşının alt kenarındaki iz
        Positioned(left: 0, right: 0, bottom: size * 0.14,
            child: Container(height: 1.4, color: Colors.black.withAlpha(45))),
        Center(child: Padding(
          padding: EdgeInsets.only(bottom: size * 0.08),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tile.display,
                style: TextStyle(fontSize: size * 0.38,
                    fontWeight: FontWeight.w800, color: numColor,
                    shadows: const [Shadow(color: Colors.black26,
                        offset: Offset(0, 1), blurRadius: 1)])),
            if (isOkey && !tile.joker)
              Text('OK', style: TextStyle(fontSize: size * 0.13,
                  color: AZColors.orangeDk, fontWeight: FontWeight.bold)),
            if (tile.joker)
              Text('JKR', style: TextStyle(fontSize: size * 0.13,
                  color: AZColors.purpleDk, fontWeight: FontWeight.bold)),
          ]),
        )),
      ]),
    );
  }
}
