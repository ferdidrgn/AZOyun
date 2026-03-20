// ═══════════════════════════════════════════════════════════════════
// MİNİ GOLF  —  Production-ready multiplayer
// ═══════════════════════════════════════════════════════════════════
//
// Firebase schema  golf_rooms/<roomId>
//   code           : String
//   status         : 'waiting' | 'playing' | 'finished'
//   holeCount      : int   (default 5)
//   currentHole    : int   1..holeCount
//   holeSeed       : int   RNG seed → every player builds same layout
//   players/<key>  : { name, totalShots, holeShots/{h:n}, done, isHost }
//
// Sync model (local physics, shared progress)
//   • Each device runs its OWN physics loop (ball is local).
//   • When a player holes out  →  writes done=true + shots to Firebase.
//   • HOST watches Firebase.  When ALL players are done  →
//       host writes currentHole++ (or status=finished), new holeSeed.
//   • Non-host devices detect currentHole change → reset layout.
//   This avoids syncing 60fps ball positions while keeping multiplayer.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

// ─── colours ────────────────────────────────────────────────────────────────

const _green = Color(0xFF1B5E20);
const _greenMd = Color(0xFF2E7D32);
const _greenLt = Color(0xFF4CAF50);
const _grass1 = Color(0xFF388E3C);
const _grass2 = Color(0xFF2E7D32);

// ════════════════════════════════════════════════════════════════════════════
// LOBBY
// ════════════════════════════════════════════════════════════════════════════

class GolfLobbyScreen extends StatefulWidget {
  const GolfLobbyScreen({super.key});

  @override
  State<GolfLobbyScreen> createState() => _GolfLobbyState();
}

class _GolfLobbyState extends State<GolfLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _rooms = RoomService.instance;
  final _store = StorageService.instance;
  final _ctrl = TextEditingController();
  String? _name;
  bool _busy = false;

  // bouncing ball
  late final AnimationController _bounce;
  late final Animation<double> _bounceY;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _bounceY = Tween(begin: 0.0, end: -16.0)
        .animate(CurvedAnimation(parent: _bounce, curve: Curves.easeInOut));
    _init();
  }

  @override
  void dispose() {
    _bounce.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final n = await _store.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty)
      setState(() => _name = n);
    else
      _askName();
  }

  Future<void> _askName() async {
    final c = TextEditingController(text: _name);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('👤 Adınız'),
        content: TextField(
            controller: c,
            autofocus: true,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _saveName(c.text)),
        actions: [
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _greenMd),
              onPressed: () => _saveName(c.text),
              child: const Text('Tamam'))
        ],
      ),
    );
  }

  Future<void> _saveName(String raw) async {
    final n = raw.trim();
    if (n.isEmpty) return;
    await _store.setPlayerName(n);
    setState(() => _name = n);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _create() async {
    if (_name == null) {
      await _askName();
      if (_name == null) return;
    }
    setState(() => _busy = true);
    try {
      final code = _rooms.generateCode();
      final seed = Random().nextInt(1 << 30);
      final id = await _rooms.createRoom(path: GamePaths.golf, data: {
        'code': code,
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'holeCount': 5,
        'currentHole': 1,
        'holeSeed': seed,
        'players': {
          'p1': {
            'name': _name,
            'totalShots': 0,
            'holeShots': {},
            'done': false,
            'isHost': true
          }
        },
      });
      if (!mounted) return;
      _go(GolfRoomScreen(roomId: id, myKey: 'p1', myName: _name!));
    } catch (_) {
      _snack('Oda oluşturulamadı');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (_name == null) {
      await _askName();
      if (_name == null) return;
    }
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6) {
      _snack('6 haneli kod girin');
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _rooms.findByCode(path: GamePaths.golf, code: code);
      if (r == null) {
        _snack('Oda bulunamadı');
        return;
      }
      if (r.data['status'] != 'waiting') {
        _snack('Oyun başlamış');
        return;
      }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 4) {
        _snack('Oda dolu (max 4)');
        return;
      }
      final myKey = 'p${players.length + 1}';
      await _rooms.update(GamePaths.golf, r.id, {
        'players/$myKey': {
          'name': _name,
          'totalShots': 0,
          'holeShots': {},
          'done': false,
          'isHost': false
        },
      });
      if (!mounted) return;
      _go(GolfRoomScreen(roomId: r.id, myKey: myKey, myName: _name!));
    } catch (_) {
      _snack('Katılınamadı');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      gradient: AZColors.gradGreen,
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context))),
            const SizedBox(height: 4),
            AnimatedBuilder(
                animation: _bounceY,
                builder: (_, __) => Transform.translate(
                    offset: Offset(0, _bounceY.value),
                    child: const Text('⛳', style: TextStyle(fontSize: 72)))),
            const SizedBox(height: 8),
            const Text('MİNİ GOLF',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 4),
            const Text('2-4 Oyuncu · 5 Delik · En az vuruş kazanır',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 32),
            GestureDetector(
                onTap: _askName,
                child: FrostCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.person_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(_name ?? 'Ad seç',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, color: Colors.white60, size: 14),
                    ]))),
            const SizedBox(height: 40),
            BigButton(
                label: 'YENİ ODA OLUŞTUR',
                icon: Icons.add_circle_outline,
                onPressed: _create,
                color: _greenMd,
                loading: _busy),
            const SizedBox(height: 28),
            const Text('— veya —', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 28),
            FrostCard(
                child: Column(children: [
              TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]'))
                  ],
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.white),
                  decoration: InputDecoration(
                      counterText: '',
                      hintText: 'ODA KODU',
                      hintStyle:
                          const TextStyle(color: Colors.white38, fontSize: 16),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              JoinButton(onPressed: _join, loading: _busy),
            ])),
            const SizedBox(height: 32),
            FrostCard(
                opacity: 0.08,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Nasıl oynanır?',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      SizedBox(height: 8),
                      Text(
                          '• Parmağını topa sürükle → gücü ayarla → bırak\n'
                          '• Engelleri ve duvarları kullanarak deliğe sok\n'
                          '• Her delik rastgele engel ve konum üretir\n'
                          '• 5 delik sonunda toplam vuruş karşılaştırılır',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.65)),
                    ])),
            const SizedBox(height: 24),
          ])),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROOM
// ════════════════════════════════════════════════════════════════════════════

class GolfRoomScreen extends StatefulWidget {
  const GolfRoomScreen(
      {super.key,
      required this.roomId,
      required this.myKey,
      required this.myName});

  final String roomId, myKey, myName;

  @override
  State<GolfRoomScreen> createState() => _GolfRoomState();
}

class _GolfRoomState extends State<GolfRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(GamePaths.golf, widget.roomId).listen(_onData);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => GolfGameScreen(
                  roomId: widget.roomId,
                  myKey: widget.myKey,
                  myName: widget.myName)));
    }
  }

  Map get _players => (_room['players'] as Map?) ?? {};

  String get _code => _room['code'] ?? '------';

  bool get _amHost => widget.myKey == 'p1';

  bool get _canStart => _players.length >= 2;

  Future<void> _start() async {
    if (!_canStart) {
      _snack('En az 2 oyuncu gerekli');
      return;
    }
    await _rooms.update(GamePaths.golf, widget.roomId, {
      'status': 'playing',
      'currentHole': 1,
    });
  }

  Future<void> _leave() async {
    if (_amHost) await _rooms.delete(GamePaths.golf, widget.roomId);
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _leave(),
      child: GradientScaffold(
        gradient: AZColors.gradGreen,
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _leave),
                const Expanded(
                    child: Text('MİNİ GOLF',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ]),
              const SizedBox(height: 20),
              AZCard(
                  child: Column(children: [
                const Text('ODA KODU',
                    style: TextStyle(
                        fontSize: 11, letterSpacing: 2, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_code,
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                          color: _greenMd)),
                  IconButton(
                      icon: const Icon(Icons.copy, color: _greenMd),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _code));
                        _snack('Kopyalandı!');
                      }),
                ]),
                const Text('Arkadaşına gönder',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ])),
              const SizedBox(height: 20),
              FrostCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Oyuncular (${_players.length}/4)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 14),
                    ...['p1', 'p2', 'p3', 'p4'].map((k) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _GolfRoomTile(
                            pKey: k, data: _players[k], myKey: widget.myKey))),
                    if (!_canStart)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(children: const [
                            SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white38)),
                            SizedBox(width: 8),
                            Text('Rakip bekleniyor...',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                          ])),
                  ])),
              const Spacer(),
              if (_amHost)
                BigButton(
                    label: 'OYUNU BAŞLAT',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _canStart ? _start : null,
                    color: _greenMd,
                    width: double.infinity)
              else
                FrostCard(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                      CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                      SizedBox(width: 14),
                      Text('Host başlatacak...',
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                    ])),
            ])),
      ),
    );
  }
}

class _GolfRoomTile extends StatelessWidget {
  const _GolfRoomTile(
      {required this.pKey, required this.data, required this.myKey});

  final String pKey, myKey;
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final present = data != null;
    final isMe = pKey == myKey;
    return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: isMe ? Border.all(color: Colors.white, width: 1.5) : null),
        child: Row(children: [
          Text(present ? '🏌️' : '○', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(present ? (data['name'] ?? pKey) : 'Bekleniyor...',
                  style: TextStyle(
                      color: present ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w600,
                      fontSize: 15))),
          if (data?['isHost'] == true)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('HOST',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown))),
          if (isMe)
            const Text('  SEN',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
        ]));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GAME SCREEN  —  Local physics + Firebase sync on completion
// ════════════════════════════════════════════════════════════════════════════

class GolfGameScreen extends StatefulWidget {
  const GolfGameScreen(
      {super.key,
      required this.roomId,
      required this.myKey,
      required this.myName});

  final String roomId, myKey, myName;

  @override
  State<GolfGameScreen> createState() => _GolfGameState();
}

class _GolfGameState extends State<GolfGameScreen>
    with TickerProviderStateMixin {
  // ── Firebase ───────────────────────────────────────────────────────────────
  final _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;

  // ── hole layout (deterministic from seed) ─────────────────────────────────
  int _lastSeed = -1;
  int _lastHoleNo = 0;
  Offset _ballStart = const Offset(0.5, 0.82);
  Offset _hole = const Offset(0.5, 0.12);
  List<_Obs> _obs = [];
  List<_Wall> _walls = [];

  // ── ball physics (local) ──────────────────────────────────────────────────
  Offset _ball = const Offset(0.5, 0.82);
  Offset _vel = Offset.zero;
  bool _moving = false;
  bool _myDone = false;
  int _myShots = 0;

  // ── drag ──────────────────────────────────────────────────────────────────
  Offset? _ds, _dn; // drag start / drag now (normalised 0..1)

  // ── animation ─────────────────────────────────────────────────────────────
  late AnimationController _physCtrl;
  late AnimationController _celebCtrl;
  late Animation<double> _celebScale;
  bool _celebrating = false;

  static const double _ballR = 0.026; // normalised radius
  static const double _dt = 0.018; // physics time step per tick

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.golf}/${widget.roomId}');

    // 60-fps physics ticker
    _physCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_tick);

    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _celebScale = Tween(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut));

    _sub = _ref.onValue.listen(_onFirebase);
  }

  @override
  void dispose() {
    _physCtrl.dispose();
    _celebCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // ── firebase listener ─────────────────────────────────────────────────────

  void _onFirebase(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() => _room = d);

    final hole = (d['currentHole'] as int?) ?? 1;
    final seed = (d['holeSeed'] as int?) ?? 0;
    if (hole != _lastHoleNo || seed != _lastSeed) _initHole(hole, seed);

    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      Future.delayed(const Duration(milliseconds: 600), _showFinal);
    }
  }

  // ── deterministic hole builder ────────────────────────────────────────────

  void _initHole(int holeNo, int seed) {
    _lastHoleNo = holeNo;
    _lastSeed = seed;
    final rng = Random(seed);

    // Reset physics
    _ball =
        Offset(0.25 + rng.nextDouble() * 0.5, 0.72 + rng.nextDouble() * 0.12);
    _ballStart = _ball;
    _vel = Offset.zero;
    _moving = false;
    _myDone = false;
    _myShots = 0;
    _ds = null;
    _dn = null;

    // Hole position (upper third, away from ball)
    Offset h;
    do {
      h = Offset(
          0.12 + rng.nextDouble() * 0.76, 0.07 + rng.nextDouble() * 0.18);
    } while ((h - _ball).distance < 0.35);
    _hole = h;

    // Obstacles (more as holes advance)
    final obsCount = (holeNo + 1).clamp(2, 6);
    _obs = [];
    for (int i = 0; i < obsCount; i++) {
      Offset c;
      int tries = 0;
      do {
        c = Offset(
            0.07 + rng.nextDouble() * 0.86, 0.28 + rng.nextDouble() * 0.42);
        tries++;
      } while (tries < 30 &&
          ((c - _hole).distance < 0.13 || (c - _ball).distance < 0.13));
      final w = 0.06 + rng.nextDouble() * 0.07;
      final h2 = 0.03 + rng.nextDouble() * 0.035;
      _obs.add(_Obs(c: c, w: w, h: h2));
    }

    // Walls (appear from hole 2 onward)
    final wCount = (holeNo - 1).clamp(0, 3);
    _walls = [];
    for (int i = 0; i < wCount; i++) {
      final horiz = rng.nextBool();
      final cx = 0.15 + rng.nextDouble() * 0.70;
      final cy = 0.30 + rng.nextDouble() * 0.38;
      final len = 0.14 + rng.nextDouble() * 0.10;
      _walls.add(_Wall(
          a: Offset(cx - (horiz ? len : 0.01), cy - (horiz ? 0.01 : len)),
          b: Offset(cx + (horiz ? len : 0.01), cy + (horiz ? 0.01 : len))));
    }

    setState(() {});
  }

  // ── physics tick ──────────────────────────────────────────────────────────

  void _tick() {
    if (!_moving) return;
    setState(() {
      // integrate
      _ball += _vel * _dt;
      _vel *= 0.974; // rolling friction

      // boundary walls  (bounce with energy loss)
      if (_ball.dx < _ballR) {
        _ball = Offset(_ballR, _ball.dy);
        _vel = Offset(-_vel.dx * 0.60, _vel.dy);
      }
      if (_ball.dx > 1 - _ballR) {
        _ball = Offset(1 - _ballR, _ball.dy);
        _vel = Offset(-_vel.dx * 0.60, _vel.dy);
      }
      if (_ball.dy < _ballR) {
        _ball = Offset(_ball.dx, _ballR);
        _vel = Offset(_vel.dx, -_vel.dy * 0.60);
      }
      if (_ball.dy > 1 - _ballR) {
        _ball = Offset(_ball.dx, 1 - _ballR);
        _vel = Offset(_vel.dx, -_vel.dy * 0.60);
      }

      // obstacle AABB collisions
      for (final o in _obs) {
        final hw = o.w / 2 + _ballR;
        final hh = o.h / 2 + _ballR;
        final dx = _ball.dx - o.c.dx;
        final dy = _ball.dy - o.c.dy;
        if (dx.abs() < hw && dy.abs() < hh) {
          // push out along shallowest axis, reflect velocity
          if (dx.abs() / hw < dy.abs() / hh) {
            // top/bottom face
            final sign = dy > 0 ? 1.0 : -1.0;
            _ball = Offset(_ball.dx, o.c.dy + sign * hh);
            _vel = Offset(_vel.dx * 0.85, -_vel.dy * 0.55);
          } else {
            // left/right face
            final sign = dx > 0 ? 1.0 : -1.0;
            _ball = Offset(o.c.dx + sign * hw, _ball.dy);
            _vel = Offset(-_vel.dx * 0.55, _vel.dy * 0.85);
          }
        }
      }

      // thin wall (line segment) collisions
      for (final w in _walls) {
        final wx = (w.a.dx + w.b.dx) / 2;
        final wy = (w.a.dy + w.b.dy) / 2;
        final ww = (w.b.dx - w.a.dx).abs().clamp(0.02, 1.0);
        final wh = (w.b.dy - w.a.dy).abs().clamp(0.02, 1.0);
        final hw2 = ww / 2 + _ballR;
        final hh2 = wh / 2 + _ballR;
        final dx = _ball.dx - wx;
        final dy = _ball.dy - wy;
        if (dx.abs() < hw2 && dy.abs() < hh2) {
          if (ww > wh) {
            // horizontal wall
            _ball = Offset(_ball.dx, wy + (dy > 0 ? hh2 : -hh2));
            _vel = Offset(_vel.dx * 0.9, -_vel.dy * 0.55);
          } else {
            // vertical wall
            _ball = Offset(wx + (dx > 0 ? hw2 : -hw2), _ball.dy);
            _vel = Offset(-_vel.dx * 0.55, _vel.dy * 0.9);
          }
        }
      }

      // stop when velocity negligible
      if (_vel.distance < 0.007) {
        _vel = Offset.zero;
        _moving = false;
        _physCtrl.stop();
        _checkHole();
      }
    });
  }

  void _checkHole() {
    if ((_ball - _hole).distance < 0.048) _onGoal();
  }

  // ── goal ──────────────────────────────────────────────────────────────────

  Future<void> _onGoal() async {
    if (_myDone) return;
    _myDone = true;

    // celebration
    setState(() => _celebrating = true);
    _celebCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _celebrating = false);

    // write to Firebase
    final hole = (_room['currentHole'] as int?) ?? 1;
    final prevTot =
        (_room['players']?[widget.myKey]?['totalShots'] as int?) ?? 0;
    await _ref.update({
      'players/${widget.myKey}/done': true,
      'players/${widget.myKey}/holeShots/$hole': _myShots,
      'players/${widget.myKey}/totalShots': prevTot + _myShots,
    });

    // host checks if everyone finished
    if (widget.myKey == 'p1') await _hostCheckAdvance();
  }

  // HOST: check all done → advance hole or finish game
  Future<void> _hostCheckAdvance() async {
    final snap = await _ref.child('players').get();
    if (!snap.exists) return;
    final players = Map<String, dynamic>.from(snap.value as Map);
    final allDone = players.values.every((p) => p['done'] == true);
    if (!allDone) return;

    final hole = (_room['currentHole'] as int?) ?? 1;
    final total = (_room['holeCount'] as int?) ?? 5;

    if (hole >= total) {
      await _ref.update({'status': 'finished'});
    } else {
      final newSeed = Random().nextInt(1 << 30);
      final updates = <String, dynamic>{
        'currentHole': hole + 1,
        'holeSeed': newSeed,
      };
      for (final k in players.keys) updates['players/$k/done'] = false;
      await _ref.update(updates);
    }
  }

  // non-host also needs to trigger advance check when they finish
  // → watch: when currentHole changes AND _myDone was true → reset
  // (handled in _onFirebase via _initHole resetting _myDone=false)

  // ── drag handlers ─────────────────────────────────────────────────────────

  Offset _norm(Offset p, Size s) => Offset(p.dx / s.width, p.dy / s.height);

  void _onPanStart(DragStartDetails d, Size s) {
    if (_moving || _myDone) return;
    // tap must be near ball (within 0.12 normalised)
    final tap = _norm(d.localPosition, s);
    if ((tap - _ball).distance > 0.15) return;
    _ds = tap;
    _dn = tap;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d, Size s) {
    if (_ds == null) return;
    setState(() => _dn = _norm(d.localPosition, s));
  }

  void _onPanEnd(DragEndDetails _, Size s) {
    if (_ds == null || _dn == null || _moving || _myDone) return;
    final delta = _ds! - _dn!;
    if (delta.distance < 0.015) {
      _ds = null;
      _dn = null;
      setState(() {});
      return;
    }

    final power = (delta.distance * 7.5).clamp(0.4, 6.0);
    final dir = delta / delta.distance;

    setState(() {
      _vel = dir * power;
      _moving = true;
      _myShots++;
      _ds = null;
      _dn = null;
    });
    _physCtrl.repeat();
    HapticFeedback.selectionClick();

    // Sync shot count for scoreboard
    _ref.child('players/${widget.myKey}/shots').set(_myShots);

    // Non-host: also check advance after holing out
    // (done via _onGoal → writes done=true, then we watch for p1 to advance)
  }

  // ── final result dialog ───────────────────────────────────────────────────

  void _showFinal() {
    if (!mounted) return;
    final players = (_room['players'] as Map?) ?? {};
    final sorted = players.entries.toList()
      ..sort((a, b) => ((a.value['totalShots'] as int?) ?? 99)
          .compareTo((b.value['totalShots'] as int?) ?? 99));

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              title: const Text('🏆 Oyun Bitti!', textAlign: TextAlign.center),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: sorted.asMap().entries.map((e) {
                    final medals = ['🥇', '🥈', '🥉', '4.'];
                    final m = e.key < medals.length ? medals[e.key] : '?';
                    final isMe = e.value.key == widget.myKey;
                    final sc = (e.value.value['totalShots'] as int?) ?? 0;
                    return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: isMe ? Colors.green.shade50 : null,
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          Text(m, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(e.value.value['name'] ?? e.value.key,
                                  style: TextStyle(
                                      fontWeight: isMe
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 16))),
                          Text('$sc vuruş',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ]));
                  }).toList()),
              actions: [
                FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _greenMd),
                    onPressed: () async {
                      await _db
                          .child('${GamePaths.golf}/${widget.roomId}')
                          .remove();
                      if (mounted)
                        Navigator.popUntil(context, (r) => r.isFirst);
                    },
                    child: const Text('Ana Menü'))
              ],
            ));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(
          backgroundColor: _grass2,
          body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    final hole = (_room['currentHole'] as int?) ?? 1;
    final maxH = (_room['holeCount'] as int?) ?? 5;
    final players = (_room['players'] as Map?) ?? {};

    return Scaffold(
      backgroundColor: _grass2,
      body: SafeArea(
          child: Column(children: [
        // ── score bar ─────────────────────────────────────────────────────
        _ScoreBar(
            players: players, myKey: widget.myKey, hole: hole, maxHole: maxH),

        // ── status strip ─────────────────────────────────────────────────
        AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _myDone
                ? const Color(0xFF1B5E20)
                : _moving
                    ? const Color(0xFFF57F17)
                    : const Color(0xFF33691E),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Center(
                child: Text(
                    _myDone
                        ? '✅ Deliğe soktu! Diğerleri bekleniyor...'
                        : _moving
                            ? '🎱 Top gidiyor...'
                            : '🏌️ Topa dokun, çek ve bırak!  ($_myShots vuruş)',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)))),

        // ── game canvas ───────────────────────────────────────────────────
        Expanded(child: LayoutBuilder(builder: (_, cons) {
          final size = cons.biggest;
          return GestureDetector(
            onPanStart: (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: (d) => _onPanEnd(d, size),
            child: Stack(children: [
              // field
              CustomPaint(
                  size: size,
                  painter: _FieldPainter(
                      ball: _ball,
                      hole: _hole,
                      obs: _obs,
                      walls: _walls,
                      ds: _myDone ? null : _ds,
                      dn: _dn,
                      moving: _moving)),

              // celebration overlay
              if (_celebrating)
                AnimatedBuilder(
                  animation: _celebScale,
                  builder: (_, __) => Positioned.fill(
                      child: IgnorePointer(
                          child: Container(
                              color: Colors.white
                                  .withOpacity(0.18 * (1 - _celebCtrl.value)),
                              child: Center(
                                  child: Transform.scale(
                                      scale: _celebScale.value,
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('⛳',
                                                style: TextStyle(fontSize: 80)),
                                            const SizedBox(height: 8),
                                            Text('$_myShots vuruşla girdi!',
                                                style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                          blurRadius: 16,
                                                          color: Colors.black54)
                                                    ])),
                                          ])))))),

                  // shot counter badge
                  child: Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('🏌️ $_myShots vuruş',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)))),
                )
            ]),
          );
        })),
      ])),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SCORE BAR
// ════════════════════════════════════════════════════════════════════════════

class _ScoreBar extends StatelessWidget {
  const _ScoreBar(
      {required this.players,
      required this.myKey,
      required this.hole,
      required this.maxHole});

  final Map players;
  final String myKey;
  final int hole, maxHole;

  @override
  Widget build(BuildContext context) => Container(
      color: _green,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Text('Delik $hole/$maxHole',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        Expanded(
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: players.entries.map((e) {
                      final isMe = e.key == myKey;
                      final sc = (e.value['totalShots'] as int?) ?? 0;
                      final done = e.value['done'] == true;
                      return Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: done
                                  ? Colors.green.shade600
                                  : isMe
                                      ? Colors.white
                                      : Colors.white24,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                              '${done ? "✓ " : ""}${e.value['name']}: $sc',
                              style: TextStyle(
                                  color: isMe ? _greenMd : Colors.white,
                                  fontWeight: isMe
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12)));
                    }).toList()))),
      ]));
}

// ════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ════════════════════════════════════════════════════════════════════════════

class _Obs {
  const _Obs({required this.c, required this.w, required this.h});

  final Offset c;
  final double w, h;
}

class _Wall {
  const _Wall({required this.a, required this.b});

  final Offset a, b;
}

// ════════════════════════════════════════════════════════════════════════════
// FIELD PAINTER — deterministic, no allocations inside paint()
// ════════════════════════════════════════════════════════════════════════════

class _FieldPainter extends CustomPainter {
  const _FieldPainter({
    required this.ball,
    required this.hole,
    required this.obs,
    required this.walls,
    this.ds,
    this.dn,
    required this.moving,
  });

  final Offset ball, hole;
  final List<_Obs> obs;
  final List<_Wall> walls;
  final Offset? ds, dn;
  final bool moving;

  static final _grassP = Paint()..color = _grass1;
  static final _stripeP = Paint()..color = const Color(0x08000000);
  static final _wallP = Paint()
    ..color = const Color(0xFF6D4C41)
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final _holeShadow = Paint()
    ..color = Colors.black26
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final _holeFill = Paint()..color = Colors.black87;
  static final _ballShadow = Paint()
    ..color = Colors.black38
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
  static final _ballFill = Paint()..color = Colors.white;
  static final _dimpleP = Paint()..color = const Color(0x18000000);
  static final _highlight = Paint()..color = const Color(0xAAFFFFFF);

  @override
  void paint(Canvas canvas, Size s) {
    // ── grass ──
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _grassP);
    // subtle stripe pattern
    for (int i = 0; i < 10; i++) {
      if (i.isOdd)
        canvas.drawRect(
            Rect.fromLTWH(0, s.height * i / 10, s.width, s.height / 10),
            _stripeP);
    }

    // ── walls ──
    for (final w in walls) {
      canvas.drawLine(Offset(w.a.dx * s.width, w.a.dy * s.height),
          Offset(w.b.dx * s.width, w.b.dy * s.height), _wallP);
    }

    // ── obstacles ──
    for (final o in obs) {
      final rect = Rect.fromCenter(
          center: Offset(o.c.dx * s.width, o.c.dy * s.height),
          width: o.w * s.width,
          height: o.h * s.height);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(
          rr.shift(const Offset(2, 3)),
          Paint()
            ..color = Colors.black26
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawRRect(rr, Paint()..color = const Color(0xFF795548));
      canvas.drawRRect(
          rr,
          Paint()
            ..color = Colors.white.withOpacity(0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }

    // ── hole ──
    final hx = hole.dx * s.width, hy = hole.dy * s.height;
    final hr = s.width * 0.024;
    canvas.drawCircle(Offset(hx + 2, hy + 2), hr, _holeShadow);
    canvas.drawCircle(Offset(hx, hy), hr, _holeFill);
    // flag pole
    canvas.drawLine(
        Offset(hx, hy),
        Offset(hx, hy - s.height * 0.075),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    // flag
    final fp = Path()
      ..moveTo(hx, hy - s.height * 0.075)
      ..lineTo(hx + s.width * 0.05, hy - s.height * 0.057)
      ..lineTo(hx, hy - s.height * 0.038)
      ..close();
    canvas.drawPath(fp, Paint()..color = Colors.red);

    // ── power indicator ──
    if (ds != null && dn != null && !moving) {
      final bx = ball.dx * s.width, by = ball.dy * s.height;
      final dx = (ds!.dx - dn!.dx) * s.width;
      final dy = (ds!.dy - dn!.dy) * s.height;
      final dist = sqrt(dx * dx + dy * dy);
      final power = (dist / (s.width * 0.25)).clamp(0.0, 1.0);
      final tx = bx + dx * 1.4, ty = by + dy * 1.4;

      // direction line
      canvas.drawLine(
          Offset(bx, by),
          Offset(tx, ty),
          Paint()
            ..color = Color.lerp(Colors.white.withOpacity(0.9),
                Colors.red.withOpacity(0.9), power)!
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round);

      // distance dots
      for (int i = 1; i <= 5; i++) {
        final t = i / 6;
        canvas.drawCircle(
            Offset(bx + dx * 1.4 * t, by + dy * 1.4 * t),
            5,
            Paint()
              ..color =
                  Colors.yellow.withOpacity(power > i / 5.0 ? 0.9 : 0.18));
      }
      // power ring on ball
      canvas.drawCircle(
          Offset(bx, by),
          s.width * 0.034,
          Paint()
            ..color =
                Color.lerp(Colors.white38, Colors.red.withOpacity(0.55), power)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }

    // ── ball ──
    final bx = ball.dx * s.width, by = ball.dy * s.height;
    final br = s.width * _FieldPainter._ballR2;
    canvas.drawCircle(Offset(bx + 2, by + 3), br * 0.88, _ballShadow);
    canvas.drawCircle(Offset(bx, by), br, _ballFill);
    // dimples (5 in a pattern)
    for (int i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      canvas.drawCircle(
          Offset(bx + cos(a) * br * 0.52, by + sin(a) * br * 0.52),
          br * 0.18,
          _dimpleP);
    }
    canvas.drawCircle(Offset(bx, by), br * 0.2, _dimpleP);
    // highlight
    canvas.drawCircle(
        Offset(bx - br * 0.36, by - br * 0.36), br * 0.30, _highlight);
  }

  static const double _ballR2 = 0.026;

  @override
  bool shouldRepaint(_) => true;
}
