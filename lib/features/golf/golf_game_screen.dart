import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import 'golf_match.dart';

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
  bool _advancing = false;
  bool _savingScore = false;
  bool _scoreNeedsRetry = false;

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

  late final Ticker _physicsTicker;
  Duration _previousFrame = Duration.zero;
  double _physicsTime = 0;
  late AnimationController _celebrateCtrl;
  late Animation<double>   _celebrateScale;
  bool _celebrating = false;

  static const double _ballRadius = 0.026;
  static const double _dt = 1 / 120;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.golf}/${widget.roomId}');
    _physicsTicker = createTicker(_physicsFrame);
    _celebrateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _celebrateScale = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _celebrateCtrl, curve: Curves.elasticOut));
    _sub = _ref.onValue.listen(_onFirebase);
  }

  @override
  void dispose() {
    _physicsTicker.dispose(); _celebrateCtrl.dispose(); _sub?.cancel();
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
    if (data['players']?[widget.myKey]?['done'] == true) {
      _myDone = true;
      _scoreNeedsRetry = false;
    }
    if (data['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 500), _showFinalDialog);
    }
    // A departure can leave only players who have already scored.
    if (advanceGolfRoom(data, holeNo) != null) {
      unawaited(_advanceAfterDeparture(holeNo));
    }
  }

  void _initHole(int holeNo, int seed) {
    _physicsTicker.stop();
    _celebrating = false;
    _scoreNeedsRetry = false;
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

  void _physicsFrame(Duration elapsed) {
    final seconds = (elapsed - _previousFrame).inMicroseconds / 1000000;
    _previousFrame = elapsed;
    _physicsTime += seconds.clamp(0, 0.05);
    setState(() {
      while (_moving && _physicsTime >= _dt) {
        _physicsTime -= _dt;
        _physicsStep();
      }
    });
  }

  void _physicsStep() {
    _ball += _vel * _dt;
    _vel *= 0.987;

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

    final inCup = (_ball - _holePos).distance < 0.036 &&
        _vel.distance < 0.95;
    if (inCup || _vel.distance < 0.006) {
      _vel = Offset.zero; _moving = false;
      _physicsTicker.stop();
      if (inCup) {
        _ball = _holePos;
        _myDone = true;
        _celebrating = true;
        _celebrateCtrl.forward(from: 0).whenComplete(() {
          if (mounted) setState(() => _celebrating = false);
        });
        HapticFeedback.heavyImpact();
        unawaited(_saveScore());
      }
    }
  }

  Future<void> _saveScore() async {
    if (_savingScore) return;
    final hole = _lastHole;
    final shots = _myShots;
    setState(() {
      _savingScore = true;
      _scoreNeedsRetry = false;
    });
    try {
      await _rooms.transactRoom(
        gamePath: GamePaths.golf,
        roomId: widget.roomId,
        update: (room) => scoreGolfHole(
            room, seat: widget.myKey, hole: hole, shots: shots),
      ).timeout(const Duration(seconds: 10));
    } catch (error) {
      debugPrint('Mini Golf skor kaydı: $error');
      if (mounted && _lastHole == hole &&
          _room['players']?[widget.myKey]?['done'] != true) {
        setState(() => _scoreNeedsRetry = true);
      }
    } finally {
      if (mounted) setState(() => _savingScore = false);
    }
  }

  Future<void> _advanceAfterDeparture(int hole) async {
    if (_advancing) return;
    _advancing = true;
    try {
      await _rooms.transactRoom(
        gamePath: GamePaths.golf,
        roomId: widget.roomId,
        update: (room) => advanceGolfRoom(room, hole),
      );
    } catch (error) {
      debugPrint('Mini Golf sıradaki delik: $error');
    } finally {
      _advancing = false;
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
    _physicsTime = 0;
    _previousFrame = Duration.zero;
    _physicsTicker.start();
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
        .reportGameResult(gameId: 'golf', resultId: widget.roomId, won: iWon)
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
            await _rooms.unregisterPresence(
                gamePath: GamePaths.golf, roomId: widget.roomId,
                playerKey: widget.myKey);
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
    }
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmLeave() async {
    final ok = await confirmLeaveGame(
      context,
      title:   'Oyundan çık?',
      message: 'Aktif bir oyunun ortasındasın. Çıkarsan bu geri alınamaz.',
    );
    if (ok) await _leaveGame();
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(backgroundColor: AZColors.greenDk,
          body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    final holeNo  = (_room['currentHole'] as int?) ?? 1;
    final maxHole = (_room['holeCount']   as int?) ?? 5;
    final players = (_room['players'] as Map?) ?? {};

    return AZLeaveGuard(
      onLeave: _confirmLeave,
      child: Scaffold(
      backgroundColor: AZColors.greenDk,
      body: SafeArea(child: Column(children: [
        _ScoreBar(players: players, myKey: widget.myKey,
            holeNo: holeNo, maxHole: maxHole, onLeave: _confirmLeave),
        if (_scoreNeedsRetry)
          FilledButton.tonal(
            onPressed: _saveScore,
            child: const Text('Skoru yeniden gönder'),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: _myDone ? AZColors.greenDk
                : _moving  ? AZColors.orange
                : AZColors.green,
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
          ),
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Center(child: Text(
            _savingScore ? 'Skor gönderiliyor…'
                : _myDone ? 'Deliğe girdi. Diğer oyuncular bekleniyor…'
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
            onPanCancel: () => setState(() {
              _dragStart = null;
              _dragCurrent = null;
            }),
            child: Stack(children: [
              CustomPaint(size: size, painter: _GolfFieldPainter(
                  ball: _ball, holePos: _holePos,
                  ballVelocity: _vel,
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
        colors: [AZColors.green, AZColors.greenDk],
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
    required this.ballVelocity,
    required this.obstacles, required this.walls,
    this.dragStart, this.dragCurrent, required this.moving,
  });
  final Offset ball, holePos, ballVelocity;
  final List<_Obstacle> obstacles;
  final List<_Wall> walls;
  final Offset? dragStart, dragCurrent;
  final bool moving;
  static const _ballR = 0.026;

  double _depth(double y) => 0.66 + y.clamp(0.0, 1.0).toDouble() * 0.50;

  Offset _project(Offset point, Size size) {
    final y = point.dy.clamp(0.0, 1.0).toDouble();
    final perspectiveX = _depth(y);
    final perspectiveY = 0.055 +
        0.91 * (1 - pow(1 - y, 1.12).toDouble());
    return Offset(size.width * (0.5 + (point.dx - 0.5) * perspectiveX),
        size.height * perspectiveY);
  }

  Path _fieldBand(Size size, double y0, double y1) {
    final left0 = _project(Offset(0, y0), size);
    final right0 = _project(Offset(1, y0), size);
    final left1 = _project(Offset(0, y1), size);
    final right1 = _project(Offset(1, y1), size);
    return Path()
      ..moveTo(left0.dx, left0.dy)
      ..lineTo(right0.dx, right0.dy)
      ..lineTo(right1.dx, right1.dy)
      ..lineTo(left1.dx, left1.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size s) {
    final width = s.width;
    final height = s.height;
    canvas.drawRect(Offset.zero & s, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF397A59), Color(0xFF174C38)],
      ).createShader(Offset.zero & s));
    final field = Path()
      ..moveTo(width * .27, height * .055)
      ..lineTo(width * .73, height * .055)
      ..lineTo(width * .96, height * .965)
      ..lineTo(width * .04, height * .965)
      ..close();
    canvas.drawPath(field, Paint()..color = const Color(0xFF26734F));
    canvas.save();
    canvas.clipPath(field);
    for (var i = 0; i < 12; i++) {
      if (i.isOdd) {
        canvas.drawPath(_fieldBand(s, i / 12, (i + 1) / 12), Paint()
          ..color = const Color(0x12203B2B));
      }
    }
    final center = _project(const Offset(.5, .5), s);
    final leftCenter = _project(const Offset(0, .5), s);
    final rightCenter = _project(const Offset(1, .5), s);
    final fieldLine = Paint()
      ..color = Colors.white.withAlpha(76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(leftCenter, rightCenter, fieldLine);
    canvas.drawOval(Rect.fromCenter(center: center,
        width: width * .20, height: height * .10), fieldLine);
    canvas.drawCircle(center, width * .005,
        Paint()..color = Colors.white.withAlpha(90));
    canvas.restore();

    final rail = Paint()
      ..color = const Color(0xFFB99A69)
      ..strokeWidth = width * .025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(width * .27, height * .055),
        Offset(width * .04, height * .965), rail);
    canvas.drawLine(Offset(width * .73, height * .055),
        Offset(width * .96, height * .965), rail);

    final wallPaint = Paint()
      ..strokeWidth = width * .018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final w in walls) {
      final a = _project(w.a, s);
      final b = _project(w.b, s);
      canvas.drawLine(a.translate(0, width * .010), b.translate(0, width * .010),
          Paint()..color = Colors.black.withAlpha(80)
            ..strokeWidth = width * .025 ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      wallPaint.color = const Color(0xFF654B35);
      canvas.drawLine(a, b, wallPaint);
      canvas.drawLine(a.translate(0, -width * .007), b.translate(0, -width * .007),
          Paint()..color = const Color(0xFFD2B78A)
            ..strokeWidth = width * .006 ..strokeCap = StrokeCap.round);
    }
    for (final o in obstacles) {
      final center = _project(o.center, s);
      final depth = _depth(o.center.dy);
      final rect = Rect.fromCenter(
          center: center,
          width: o.w * width * depth,
          height: o.h * height * depth);
      final rr = RRect.fromRectAndRadius(
          rect, Radius.circular(width * .012 * depth));
      final extrusion = Offset(width * .008 * depth, height * .012 * depth);
      canvas.drawRRect(rr.shift(extrusion), Paint()
        ..color = Colors.black.withAlpha(90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      final side = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right + extrusion.dx, rect.bottom + extrusion.dy)
        ..lineTo(rect.left + extrusion.dx, rect.bottom + extrusion.dy)
        ..close();
      canvas.drawPath(side, Paint()..color = const Color(0xFF4F493F));
      canvas.drawRRect(rr, Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC7AF8A), Color(0xFF806B55)],
        ).createShader(rect));
      canvas.drawRRect(rr, Paint()
        ..color = const Color(0x70FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * .003);
    }
    final hole = _project(holePos, s);
    final holeDepth = _depth(holePos.dy);
    final hr = width * .027 * holeDepth;
    canvas.drawOval(Rect.fromCenter(
        center: hole.translate(width * .004, hr * .35),
        width: hr * 2.7, height: hr * 1.15), Paint()
      ..color = Colors.black.withAlpha(90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawOval(Rect.fromCenter(center: hole,
        width: hr * 2.6, height: hr * 1.35),
        Paint()..color = const Color(0xFFB39B71));
    canvas.drawOval(Rect.fromCenter(center: hole.translate(0, hr * .12),
        width: hr * 1.72, height: hr * .94),
        Paint()..color = const Color(0xFF090D0B));
    final poleHeight = height * .075 * holeDepth;
    canvas.drawLine(hole, hole.translate(0, -poleHeight),
        Paint()..color = const Color(0xFFE9E2D0)
          ..strokeWidth = width * .0045 * holeDepth
          ..strokeCap = StrokeCap.round);
    final flag = Path()
      ..moveTo(hole.dx, hole.dy - poleHeight)
      ..lineTo(hole.dx + width * .048 * holeDepth,
          hole.dy - poleHeight + height * .018 * holeDepth)
      ..lineTo(hole.dx, hole.dy - poleHeight + height * .037 * holeDepth)
      ..close();
    canvas.drawPath(flag, Paint()..color = AZColors.red);

    if (dragStart != null && dragCurrent != null && !moving) {
      final ballPoint = _project(ball, s);
      final dx = dragStart!.dx - dragCurrent!.dx;
      final dy = dragStart!.dy - dragCurrent!.dy;
      final dist  = sqrt(dx * dx + dy * dy);
      final power = (dist / (width * 0.25)).clamp(0.0, 1.0).toDouble();
      final target = _project(Offset(
          (ball.dx + dx / width * 1.4).clamp(0.0, 1.0).toDouble(),
          (ball.dy + dy / height * 1.4).clamp(0.0, 1.0).toDouble()), s);
      canvas.drawLine(ballPoint, target,
          Paint()
            ..color = Color.lerp(Colors.white.withAlpha(217),
                AZColors.red.withAlpha(217), power)!
            ..strokeWidth = width * .008
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      for (var i = 1; i <= 5; i++) {
        final point = Offset.lerp(ballPoint, target, i / 6)!;
        canvas.drawCircle(
            point, width * .006 * (1 - i / 6 * .35),
            Paint()..color = AZColors.orange
                .withAlpha(power > i / 5.0 ? 230 : 51));
      }
      canvas.drawCircle(ballPoint, width * 0.034 * _depth(ball.dy),
          Paint()
            ..color = Color.lerp(Colors.white38,
                AZColors.red.withAlpha(153), power)!
            ..style = PaintingStyle.stroke ..strokeWidth = width * .005);
    }

    final ballPoint = _project(ball, s);
    final ballDepth = _depth(ball.dy);
    final br = width * _ballR * ballDepth;
    final speed = ballVelocity.distance;
    if (moving && speed > .015) {
      final direction = ballVelocity / speed;
      for (var i = 4; i >= 1; i--) {
        final tail = Offset(
          (ball.dx - direction.dx * i * .018).clamp(0.0, 1.0).toDouble(),
          (ball.dy - direction.dy * i * .018).clamp(0.0, 1.0).toDouble(),
        );
        final point = _project(tail, s);
        final fade = (70 * (1 - i / 5) * (speed / .35).clamp(0.0, 1.0))
            .round().clamp(0, 70).toInt();
        canvas.drawCircle(point,
            br * (1.65 - i * .16), Paint()
              ..color = const Color(0xFFE8F8ED).withAlpha(fade)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
    }
    canvas.drawOval(Rect.fromCenter(
        center: ballPoint.translate(br * .25, br * .62),
        width: br * 2.3, height: br * .80), Paint()
      ..color = Colors.black.withAlpha(90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(ballPoint.translate(0, -br * .12), br * 1.08, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.45),
        colors: [Colors.white, const Color(0xFFE2E5E2), const Color(0xFF9CA8A0)],
      ).createShader(Rect.fromCircle(center: ballPoint, radius: br * 1.08)));
    final dimple = Paint()..color = const Color(0x26000000);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      canvas.drawCircle(
          Offset(ballPoint.dx + cos(a) * br * 0.52,
              ballPoint.dy - br * .12 + sin(a) * br * 0.52),
          br * 0.17, dimple);
    }
    canvas.drawCircle(ballPoint.translate(0, -br * .12), br * .2, dimple);
    canvas.drawCircle(ballPoint.translate(-br * .36, -br * .48), br * .30,
        Paint()..color = const Color(0xAAFFFFFF));
  }

  @override bool shouldRepaint(_) => true;
}
