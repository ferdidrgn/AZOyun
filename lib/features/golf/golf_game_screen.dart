import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/banner_ad_widget.dart';

class _Obstacle {
  const _Obstacle({required this.center, required this.w, required this.h});
  final Offset center; final double w, h;
}

class _Wall {
  const _Wall({required this.a, required this.b});
  final Offset a, b;
}

class GolfGameScreen extends StatefulWidget {
  const GolfGameScreen({super.key,
      required this.roomId, required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override
  State<GolfGameScreen> createState() => _GolfGameScreenState();
}

class _GolfGameScreenState extends State<GolfGameScreen>
    with TickerProviderStateMixin {
  final _db  = FirebaseDatabase.instance.ref();
  final _rooms = RoomService.instance;
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  bool _roomGone = false;

  int    _lastSeed = -1;
  int    _lastHole = 0;
  Offset _holePos  = const Offset(0.5, 0.12);
  List<_Obstacle> _obstacles = [];
  List<_Wall>     _walls     = [];

  Offset _ball    = const Offset(0.5, 0.80);
  Offset _vel     = Offset.zero;
  bool   _moving  = false;
  bool   _myDone  = false;
  int    _myShots = 0;

  Offset? _dragStart;
  Offset? _dragCurrent;

  late AnimationController _physicsCtrl;
  late AnimationController _celebrateCtrl;
  late Animation<double>   _celebrateScale;
  bool _celebrating = false;

  static const double _ballRadius = 0.026;
  static const double _dt         = 0.018;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.golf}/${widget.roomId}');
    _physicsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_physicsTick);
    _celebrateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _celebrateScale = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _celebrateCtrl, curve: Curves.elasticOut));
    _sub = _ref.onValue.listen(_onFirebase);
  }

  @override
  void dispose() {
    _physicsCtrl.dispose(); _celebrateCtrl.dispose(); _sub?.cancel();
    super.dispose();
  }

  void _onFirebase(DatabaseEvent event) {
    if (!mounted) return;
    if (event.snapshot.value == null) {
      // Oda silindi (host ayrıldı ya da bağlantısı koptu) — eskiden burada
      // sessizce return edilirdi ve diğer oyuncuların ekranı sonsuza dek
      // donuk kalırdı. Artık herkesi ana menüye döndürüyoruz.
      if (!_roomGone) {
        _roomGone = true;
        Navigator.popUntil(context, (r) => r.isFirst);
      }
      return;
    }
    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    setState(() => _room = data);
    final holeNo = (data['currentHole'] as int?) ?? 1;
    final seed   = (data['holeSeed']   as int?) ?? 0;
    if (holeNo != _lastHole || seed != _lastSeed) _initHole(holeNo, seed);
    if (data['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 500), _showFinalDialog);
    }
    // Bir oyuncu kendi topunu diğerlerinden ÖNCE bitirmiş olabilir — o an
    // _onGoal() içindeki _hostAdvance() çağrısı "herkes bitirmedi" deyip
    // dönmüş olur. Son oyuncu bitirdiğinde bunu yeniden kontrol eden başka
    // bir tetikleyici yoktu; bu da oyunun "Diğerleri bekleniyor..."
    // ekranında sonsuza kadar takılı kalmasına yol açıyordu. Eskiden bu
    // kontrol SADECE 'p1' (host) tarafından yapılıyordu — host ayrılır ya
    // da bağlantısı koparsa hiç kimse ilerlemeyi tetiklemiyordu.
    // _hostAdvance() canlı veriyi tekrar okuyup kendi kendini koruduğu için
    // (hepsi bitmemişse hiçbir şey yapmaz) artık HERKESİN tetiklemesi güvenli.
    if (data['status'] != 'finished') {
      final players = Map<String, dynamic>.from((data['players'] as Map?) ?? {});
      if (players.isNotEmpty && players.values.every((p) => p['done'] == true)) {
        _hostAdvance();
      }
    }
  }

  void _initHole(int holeNo, int seed) {
    _lastHole = holeNo; _lastSeed = seed;
    final rng = Random(seed);
    _ball = Offset(0.2 + rng.nextDouble() * 0.6, 0.70 + rng.nextDouble() * 0.14);
    _vel = Offset.zero; _moving = false; _myDone = false;
    _myShots = 0; _dragStart = null; _dragCurrent = null;
    Offset h;
    do { h = Offset(0.12 + rng.nextDouble() * 0.76, 0.06 + rng.nextDouble() * 0.20);
    } while ((h - _ball).distance < 0.35);
    _holePos = h;
    final obsCount = (holeNo + 1).clamp(2, 7);
    _obstacles = [];
    for (var i = 0; i < obsCount; i++) {
      Offset c; var tries = 0;
      do {
        c = Offset(0.07 + rng.nextDouble() * 0.86, 0.26 + rng.nextDouble() * 0.44);
        tries++;
      } while (tries < 40 &&
          ((c - _holePos).distance < 0.12 || (c - _ball).distance < 0.12));
      _obstacles.add(_Obstacle(center: c,
          w: 0.055 + rng.nextDouble() * 0.07, h: 0.030 + rng.nextDouble() * 0.035));
    }
    final wallCount = (holeNo - 1).clamp(0, 4);
    _walls = [];
    for (var i = 0; i < wallCount; i++) {
      final horiz = rng.nextBool();
      final cx = 0.15 + rng.nextDouble() * 0.70;
      final cy = 0.28 + rng.nextDouble() * 0.40;
      final len = 0.13 + rng.nextDouble() * 0.12;
      _walls.add(_Wall(
          a: Offset(cx - (horiz ? len : 0.01), cy - (horiz ? 0.01 : len)),
          b: Offset(cx + (horiz ? len : 0.01), cy + (horiz ? 0.01 : len))));
    }
    setState(() {});
  }

  void _physicsTick() {
    if (!_moving) return;
    setState(() {
      _ball += _vel * _dt;
      _vel  *= 0.975;

      void bounceX(double x) {
        _ball = Offset(x, _ball.dy);
        _vel  = Offset(-_vel.dx * 0.58, _vel.dy);
      }
      void bounceY(double y) {
        _ball = Offset(_ball.dx, y);
        _vel  = Offset(_vel.dx, -_vel.dy * 0.58);
      }

      if (_ball.dx < _ballRadius) bounceX(_ballRadius);
      if (_ball.dx > 1 - _ballRadius) bounceX(1 - _ballRadius);
      if (_ball.dy < _ballRadius) bounceY(_ballRadius);
      if (_ball.dy > 1 - _ballRadius) bounceY(1 - _ballRadius);

      for (final o in _obstacles) {
        final hw = o.w / 2 + _ballRadius;
        final hh = o.h / 2 + _ballRadius;
        final dx = _ball.dx - o.center.dx;
        final dy = _ball.dy - o.center.dy;
        if (dx.abs() < hw && dy.abs() < hh) {
          if (dx.abs() / hw < dy.abs() / hh) {
            _ball = Offset(_ball.dx, o.center.dy + (dy > 0 ? hh : -hh));
            _vel  = Offset(_vel.dx * 0.85, -_vel.dy * 0.55);
          } else {
            _ball = Offset(o.center.dx + (dx > 0 ? hw : -hw), _ball.dy);
            _vel  = Offset(-_vel.dx * 0.55, _vel.dy * 0.85);
          }
        }
      }

      for (final wall in _walls) {
        final wx  = (wall.a.dx + wall.b.dx) / 2;
        final wy  = (wall.a.dy + wall.b.dy) / 2;
        final ww  = (wall.b.dx - wall.a.dx).abs().clamp(0.02, 1.0);
        final wh  = (wall.b.dy - wall.a.dy).abs().clamp(0.02, 1.0);
        final hw2 = ww / 2 + _ballRadius;
        final hh2 = wh / 2 + _ballRadius;
        final dx  = _ball.dx - wx;
        final dy  = _ball.dy - wy;
        if (dx.abs() < hw2 && dy.abs() < hh2) {
          if (ww > wh) {
            _ball = Offset(_ball.dx, wy + (dy > 0 ? hh2 : -hh2));
            _vel  = Offset(_vel.dx * 0.90, -_vel.dy * 0.55);
          } else {
            _ball = Offset(wx + (dx > 0 ? hw2 : -hw2), _ball.dy);
            _vel  = Offset(-_vel.dx * 0.55, _vel.dy * 0.90);
          }
        }
      }

      if (_vel.distance < 0.006) {
        _vel = Offset.zero; _moving = false;
        _physicsCtrl.stop(); _checkHoleIn();
      }
    });
  }

  void _checkHoleIn() {
    if ((_ball - _holePos).distance < 0.05) _onGoal();
  }

  Future<void> _onGoal() async {
    if (_myDone) return;
    _myDone = true;
    setState(() => _celebrating = true);
    _celebrateCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _celebrating = false);
    final holeNo  = (_room['currentHole'] as int?) ?? 1;
    final prevTot = (_room['players']?[widget.myKey]?['totalShots'] as int?) ?? 0;
    await _ref.update({
      'players/${widget.myKey}/done':              true,
      'players/${widget.myKey}/holeShots/$holeNo': _myShots,
      'players/${widget.myKey}/totalShots':        prevTot + _myShots,
    });
    await _hostAdvance();
  }

  // Artık "host" değil, "kendi kendini koruyan ilerletici" — canlı players
  // verisini tazeden okur ve hepsi bitmemişse hiçbir şey yapmaz, bu yüzden
  // herhangi bir oyuncunun (sadece p1'in değil) çağırması güvenlidir.
  Future<void> _hostAdvance() async {
    final snap = await _ref.child('players').get();
    if (!snap.exists) return;
    final players = Map<String, dynamic>.from(snap.value as Map);
    if (!players.values.every((p) => p['done'] == true)) return;
    final hole  = (_room['currentHole'] as int?) ?? 1;
    final total = (_room['holeCount']   as int?) ?? 5;
    if (hole >= total) {
      await _ref.update({'status': 'finished'});
    } else {
      final newSeed = DateTime.now().millisecondsSinceEpoch;
      final updates = <String, dynamic>{'currentHole': hole + 1, 'holeSeed': newSeed};
      for (final k in players.keys) updates['players/$k/done'] = false;
      await _ref.update(updates);
    }
  }

  Offset _normalize(Offset local, Size size) =>
      Offset(local.dx / size.width, local.dy / size.height);

  void _onPanStart(DragStartDetails d, Size size) {
    if (_moving || _myDone) return;
    final tap = _normalize(d.localPosition, size);
    if ((tap - _ball).distance > 0.14) return;
    setState(() { _dragStart = tap; _dragCurrent = tap; });
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = _normalize(d.localPosition, size));
  }

  void _onPanEnd(DragEndDetails _, Size size) {
    if (_dragStart == null || _dragCurrent == null || _moving || _myDone) return;
    final delta = _dragStart! - _dragCurrent!;
    if (delta.distance < 0.012) {
      setState(() { _dragStart = null; _dragCurrent = null; }); return;
    }
    final power = (delta.distance * 7.5).clamp(0.4, 6.0);
    final dir   = delta / delta.distance;
    setState(() {
      _vel = dir * power; _moving = true; _myShots++;
      _dragStart = null; _dragCurrent = null;
    });
    _physicsCtrl.repeat();
    HapticFeedback.selectionClick();
  }

  void _showFinalDialog() {
    if (!mounted) return;
    final players = (_room['players'] as Map?) ?? {};
    final sorted  = players.entries.toList()
      ..sort((a, b) => ((a.value['totalShots'] as int?) ?? 99)
          .compareTo((b.value['totalShots'] as int?) ?? 99));
    final iWon = sorted.isNotEmpty && sorted.first.key == widget.myKey;
    ProfileService.instance
        .reportGameResult(gameId: 'golf', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());
    const medals = ['🥇', '🥈', '🥉', '4.'];
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Oyun Bitti!', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: sorted.asMap().entries.map((e) {
            final isMe = e.value.key == widget.myKey;
            final sc   = (e.value.value['totalShots'] as int?) ?? 0;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.green.shade50 : null,
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text(e.key < medals.length ? medals[e.key] : '?',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    e.value.value['name'] as String? ?? e.value.key,
                    style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16))),
                Text('$sc vuruş',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            );
          }).toList(),
        ),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AZColors.green),
          onPressed: () async {
            await _db.child('${GamePaths.golf}/${widget.roomId}').remove();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  /// Aktif oyunda önceden HİÇBİR çıkış yolu yoktu. Kendini players'tan
  /// tamamen kaldırıyoruz — bu, "herkes bitirsin" sayımını anında düzeltir.
  Future<void> _leaveGame() async {
    final players = Map<String, dynamic>.from((_room['players'] as Map?) ?? {});
    final remaining = Map<String, dynamic>.from(players)..remove(widget.myKey);
    if (remaining.isEmpty) {
      await _rooms.deleteRoom(gamePath: GamePaths.golf, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(
          gamePath: GamePaths.golf, roomId: widget.roomId, playerKey: widget.myKey);
      await _hostAdvance();
    }
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Oyundan çık?'),
        content: const Text('Aktif bir oyunun ortasındasın. Çıkarsan bu geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Çık')),
        ],
      ),
    );
    if (ok == true) await _leaveGame();
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(backgroundColor: Color(0xFF2E7D32),
          body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    final holeNo  = (_room['currentHole'] as int?) ?? 1;
    final maxHole = (_room['holeCount']   as int?) ?? 5;
    final players = (_room['players'] as Map?) ?? {};

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _confirmLeave(),
      child: Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: SafeArea(child: Column(children: [
        _ScoreBar(players: players, myKey: widget.myKey,
            holeNo: holeNo, maxHole: maxHole, onLeave: _confirmLeave),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: _myDone ? const Color(0xFF1B5E20)
                : _moving  ? const Color(0xFFF57F17)
                : const Color(0xFF33691E),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
          ),
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Center(child: Text(
            _myDone   ? '✅ Deliğe girdi! Diğerleri bekleniyor...'
                : _moving ? '🎱 Top gidiyor...'
                : '🏌️  Topa dokun, çek, bırak!  (vuruş: $_myShots)',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 13),
          )),
        ),
        Expanded(child: LayoutBuilder(builder: (_, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            onPanStart:  (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd:    (d) => _onPanEnd(d, size),
            child: Stack(children: [
              CustomPaint(size: size, painter: _GolfFieldPainter(
                  ball: _ball, holePos: _holePos,
                  obstacles: _obstacles, walls: _walls,
                  dragStart: _myDone ? null : _dragStart,
                  dragCurrent: _dragCurrent, moving: _moving)),
              if (!_myDone)
                Positioned(bottom: 14, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0x8C000000),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('🏌️  $_myShots vuruş',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  )),
              if (_celebrating)
                AnimatedBuilder(
                  animation: _celebrateScale,
                  builder: (_, __) => Positioned.fill(
                    child: IgnorePointer(child: Container(
                      color: Color.fromRGBO(255, 255, 255,
                          0.15 * (1 - _celebrateCtrl.value)),
                      child: Center(child: Transform.scale(
                        scale: _celebrateScale.value,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('⛳', style: TextStyle(fontSize: 80)),
                          const SizedBox(height: 8),
                          Text('$_myShots vuruşla girdi!',
                              style: const TextStyle(fontSize: 26,
                                  fontWeight: FontWeight.bold, color: Colors.white,
                                  shadows: [Shadow(blurRadius: 16,
                                      color: Colors.black54)])),
                        ]),
                      )),
                    )),
                  ),
                  child: const SizedBox.shrink(),
                ),
            ]),
          );
        })),
        // Banner reklam
        const BannerAdWidget(),
      ])),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.players, required this.myKey,
      required this.holeNo, required this.maxHole, required this.onLeave});
  final Map players; final String myKey; final int holeNo, maxHole;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF226B2C), Color(0xFF1B5E20)],
      ),
      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(children: [
      IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onLeave),
      const SizedBox(width: 4),
      Text('Delik $holeNo/$maxHole',
          style: const TextStyle(color: Color(0xB3FFFFFF),
              fontSize: 12, fontWeight: FontWeight.w600)),
      Expanded(child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisAlignment: MainAxisAlignment.end,
          children: players.entries.map((e) {
            final isMe  = e.key == myKey;
            final shots = (e.value['totalShots'] as int?) ?? 0;
            final done  = e.value['done'] == true;
            return Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: done ? Colors.green.shade600
                    : isMe ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${done ? "✓ " : ""}${e.value['name']}: $shots',
                style: TextStyle(
                    color: isMe ? AZColors.green : Colors.white,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12)),
            );
          }).toList(),
        ),
      )),
    ]),
  );
}

class _GolfFieldPainter extends CustomPainter {
  const _GolfFieldPainter({
    required this.ball, required this.holePos,
    required this.obstacles, required this.walls,
    this.dragStart, this.dragCurrent, required this.moving,
  });
  final Offset ball, holePos;
  final List<_Obstacle> obstacles;
  final List<_Wall> walls;
  final Offset? dragStart, dragCurrent;
  final bool moving;
  static const _ballR = 0.026;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()..color = const Color(0xFF388E3C));
    final stripe = Paint()..color = const Color(0x0A000000);
    for (var i = 0; i < 10; i++) {
      if (i.isOdd) canvas.drawRect(
          Rect.fromLTWH(0, s.height * i / 10, s.width, s.height / 10), stripe);
    }
    final wallPaint = Paint()
      ..color = const Color(0xFF6D4C41) ..strokeWidth = 8
      ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
    for (final w in walls) {
      canvas.drawLine(Offset(w.a.dx * s.width, w.a.dy * s.height),
          Offset(w.b.dx * s.width, w.b.dy * s.height), wallPaint);
    }
    for (final o in obstacles) {
      final rect = Rect.fromCenter(
          center: Offset(o.center.dx * s.width, o.center.dy * s.height),
          width: o.w * s.width, height: o.h * s.height);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rr.shift(const Offset(2, 3)),
          Paint()..color = Colors.black26
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawRRect(rr, Paint()..color = const Color(0xFF795548));
      canvas.drawRRect(rr, Paint()
          ..color = const Color(0x24FFFFFF) ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    }
    final hx = holePos.dx * s.width; final hy = holePos.dy * s.height;
    final hr = s.width * 0.024;
    canvas.drawCircle(Offset(hx + 2, hy + 2), hr,
        Paint()..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(hx, hy), hr, Paint()..color = Colors.black87);
    canvas.drawLine(Offset(hx, hy), Offset(hx, hy - s.height * 0.075),
        Paint()..color = Colors.white ..strokeWidth = 2.5 ..strokeCap = StrokeCap.round);
    final flag = Path()
      ..moveTo(hx, hy - s.height * 0.075)
      ..lineTo(hx + s.width * 0.048, hy - s.height * 0.056)
      ..lineTo(hx, hy - s.height * 0.037) ..close();
    canvas.drawPath(flag, Paint()..color = Colors.redAccent);

    if (dragStart != null && dragCurrent != null && !moving) {
      final bx    = ball.dx * s.width; final by = ball.dy * s.height;
      final dx    = (dragStart!.dx - dragCurrent!.dx) * s.width;
      final dy    = (dragStart!.dy - dragCurrent!.dy) * s.height;
      final dist  = sqrt(dx * dx + dy * dy);
      final power = (dist / (s.width * 0.25)).clamp(0.0, 1.0);
      final tx    = bx + dx * 1.4; final ty = by + dy * 1.4;
      canvas.drawLine(Offset(bx, by), Offset(tx, ty),
          Paint()
            ..color = Color.lerp(Colors.white.withAlpha(217),
                Colors.red.withAlpha(217), power)!
            ..strokeWidth = 3.5 ..strokeCap = StrokeCap.round);
      for (var i = 1; i <= 5; i++) {
        canvas.drawCircle(
            Offset(bx + dx * 1.4 * i / 6, by + dy * 1.4 * i / 6), 5,
            Paint()..color = Colors.yellowAccent
                .withAlpha(power > i / 5.0 ? 230 : 51));
      }
      canvas.drawCircle(Offset(bx, by), s.width * 0.034,
          Paint()
            ..color = Color.lerp(Colors.white38,
                Colors.redAccent.withAlpha(153), power)!
            ..style = PaintingStyle.stroke ..strokeWidth = 2.5);
    }

    final bx = ball.dx * s.width; final by = ball.dy * s.height;
    final br = s.width * _ballR;
    canvas.drawCircle(Offset(bx + 2, by + 3), br * 0.88,
        Paint()..color = Colors.black38
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(Offset(bx, by), br, Paint()..color = Colors.white);
    final dimple = Paint()..color = const Color(0x1A000000);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      canvas.drawCircle(
          Offset(bx + cos(a) * br * 0.52, by + sin(a) * br * 0.52),
          br * 0.18, dimple);
    }
    canvas.drawCircle(Offset(bx, by), br * 0.2, dimple);
    canvas.drawCircle(Offset(bx - br * 0.36, by - br * 0.36), br * 0.30,
        Paint()..color = const Color(0xAAFFFFFF));
  }

  @override bool shouldRepaint(_) => true;
}
