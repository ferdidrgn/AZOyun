import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/room_service.dart';
import '../../core/theme/az_theme.dart';

class SoccerGameScreen extends StatefulWidget {
  const SoccerGameScreen({
    super.key,
    required this.roomId,
    required this.myKey,
    required this.myName,
  });

  final String roomId, myKey, myName;

  @override
  State<SoccerGameScreen> createState() => _SoccerGameScreenState();
}

class _SoccerGameScreenState extends State<SoccerGameScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;

  Map<String, dynamic> _room        = {};
  bool   _finalShown   = false;
  bool   _isMyTurn     = false;
  int    _myScore      = 0;
  int    _currentRound = 1;
  int    _totalRounds  = 5;

  Offset? _dragStart;
  Offset? _dragCurrent;
  bool    _shooting = false;

  Offset _ball         = const Offset(0.5, 0.75);
  Offset _ballVelocity = Offset.zero;
  bool   _ballMoving   = false;

  double _gkX       = 0.5;
  double _gkTargetX = 0.5;

  late AnimationController _physCtrl;
  late AnimationController _goalCtrl;
  late Animation<double>   _goalScale;
  bool _celebrating = false;
  bool _missed      = false;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.soccer}/${widget.roomId}');

    _physCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 16))
      ..addListener(_physicsTick);

    _goalCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800));
    _goalScale = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
            parent: _goalCtrl, curve: Curves.elasticOut));

    _sub = _ref.onValue.listen(_onFirebase);
  }

  @override
  void dispose() {
    _physCtrl.dispose();
    _goalCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _onFirebase(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final d =
        Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() {
      _room         = d;
      _currentRound = (d['currentRound'] as int?) ?? 1;
      _totalRounds  = (d['totalRounds']  as int?) ?? 5;
      _isMyTurn     = d['currentPlayer'] == widget.myKey;
      _myScore =
          (d['players']?[widget.myKey]?['score'] as int?) ?? 0;
    });

    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      Future.delayed(
          const Duration(milliseconds: 400), _showFinalDialog);
    }
  }

  void _physicsTick() {
    if (!_ballMoving) return;
    setState(() {
      _ball         += _ballVelocity * 0.016;
      _ballVelocity *= 0.97;

      final diff = _gkTargetX - _gkX;
      _gkX += diff * 0.08;

      if (_ballVelocity.distance < 0.004) {
        _ballVelocity = Offset.zero;
        _ballMoving   = false;
        _physCtrl.stop();
        _checkResult();
      }
    });
  }

  void _onPanStart(DragStartDetails d, Size size) {
    if (!_isMyTurn || _shooting) return;
    final norm = Offset(d.localPosition.dx / size.width,
        d.localPosition.dy / size.height);
    if ((norm - _ball).distance > 0.15) return;
    setState(() {
      _dragStart   = norm;
      _dragCurrent = norm;
    });
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = Offset(
        d.localPosition.dx / size.width,
        d.localPosition.dy / size.height));
  }

  void _onPanEnd(DragEndDetails _, Size size) {
    if (_dragStart   == null ||
        _dragCurrent == null ||
        !_isMyTurn ||
        _shooting) return;
    final delta = _dragStart! - _dragCurrent!;
    if (delta.distance < 0.02) {
      setState(() {
        _dragStart   = null;
        _dragCurrent = null;
      });
      return;
    }
    final power = (delta.distance * 6.0).clamp(0.5, 4.0);
    final dir   = delta / delta.distance;
    setState(() {
      _shooting     = true;
      _ballVelocity = dir * power;
      _ballMoving   = true;
      _dragStart    = null;
      _dragCurrent  = null;
      _gkTargetX    = _rng.nextDouble() * 0.6 + 0.2;
    });
    _physCtrl.repeat();
    HapticFeedback.mediumImpact();
  }

  Future<void> _checkResult() async {
    final inGoalX  = _ball.dx > 0.28 && _ball.dx < 0.72;
    final inGoalY  = _ball.dy < 0.22;
    final gkBlocked =
        (_ball.dx - _gkX).abs() < 0.08 && _ball.dy < 0.25;
    final isGoal = inGoalX && inGoalY && !gkBlocked;

    if (isGoal) {
      await _onGoal();
    } else {
      setState(() {
        _missed      = true;
        _celebrating = false;
      });
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _missed = false);
      _resetBall();
      await _advanceTurn();
    }
  }

  Future<void> _onGoal() async {
    setState(() {
      _celebrating = true;
      _missed      = false;
    });
    _goalCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();

    final newScore = _myScore + 1;
    await _ref
        .update({'players/${widget.myKey}/score': newScore});

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _celebrating = false);
    _resetBall();
    await _advanceTurn();
  }

  void _resetBall() {
    setState(() {
      _ball         = const Offset(0.5, 0.75);
      _ballVelocity = Offset.zero;
      _ballMoving   = false;
      _shooting     = false;
      _gkX          = 0.5;
      _gkTargetX    = 0.5;
    });
  }

  Future<void> _advanceTurn() async {
    if (!_isMyTurn) return;
    final players =
        (_room['players'] as Map?)?.keys.toList() ??
            ['p1', 'p2'];
    final idx     = players.indexOf(widget.myKey);
    final nextKey = players[(idx + 1) % players.length];

    if (_currentRound >= _totalRounds &&
        nextKey == players.first) {
      await _ref.update({'status': 'finished'});
    } else {
      final newRound = nextKey == players.first
          ? _currentRound + 1
          : _currentRound;
      await _ref.update({
        'currentPlayer': nextKey,
        'currentRound':  newRound,
      });
    }
  }

  void _showFinalDialog() {
    if (!mounted) return;
    final players = (_room['players'] as Map?) ?? {};
    final sorted  = players.entries.toList()
      ..sort((a, b) =>
          ((b.value['score'] as int?) ?? 0)
              .compareTo((a.value['score'] as int?) ?? 0));
    const medals = ['🥇', '🥈'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Maç Bitti!',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sorted.asMap().entries.map((e) {
            final isMe  = e.value.key == widget.myKey;
            final score =
                (e.value.value['score'] as int?) ?? 0;
            return Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isMe ? Colors.orange.shade50 : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Text(
                    e.key < medals.length
                        ? medals[e.key]
                        : '?',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                  e.value.value['name'] as String? ??
                      e.value.key,
                  style: TextStyle(
                      fontWeight: isMe
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16),
                )),
                Text('$score gol',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
              ]),
            );
          }).toList(),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AZColors.orange),
            onPressed: () async {
              await _db
                  .child(
                      '${GamePaths.soccer}/${widget.roomId}')
                  .remove();
              if (mounted) {
                Navigator.popUntil(
                    context, (r) => r.isFirst);
              }
            },
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(
          backgroundColor: Color(0xFF1B5E20),
          body: Center(
              child: CircularProgressIndicator(
                  color: Colors.white)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: SafeArea(child: Column(children: [
        _SoccerScoreBar(
          players:  (_room['players'] as Map?) ?? {},
          myKey:    widget.myKey,
          round:    _currentRound,
          maxRound: _totalRounds,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          color: _isMyTurn
              ? const Color(0xFF33691E)
              : const Color(0xFF1B5E20),
          padding:
              const EdgeInsets.symmetric(vertical: 7),
          child: Center(
              child: Text(
            _isMyTurn
                ? '⚽ Senin sıran — vur!'
                : '⏳ Rakip vuruyor...',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          )),
        ),
        Expanded(child: LayoutBuilder(builder: (_, c) {
          final size = c.biggest;
          return GestureDetector(
            onPanStart:  (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd:    (d) => _onPanEnd(d, size),
            child: Stack(children: [
              CustomPaint(
                size: size,
                painter: _SoccerFieldPainter(
                  ball:        _ball,
                  gkX:         _gkX,
                  dragStart:   _isMyTurn
                      ? _dragStart
                      : null,
                  dragCurrent: _dragCurrent,
                ),
              ),
              if (_celebrating)
                AnimatedBuilder(
                  animation: _goalScale,
                  builder: (_, __) => Positioned.fill(
                    child: IgnorePointer(
                        child: Container(
                      color: Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.15 *
                              (1 -
                                  _goalCtrl.value)),
                      child: Center(
                          child: Transform.scale(
                        scale: _goalScale.value,
                        child: const Text(
                            '⚽\nGOL!',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                                fontSize: 56,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      blurRadius: 20,
                                      color: Colors
                                          .black54)
                                ])),
                      )),
                    )),
                  ),
                  child: const SizedBox.shrink(),
                ),
              if (_missed)
                Positioned.fill(
                    child: IgnorePointer(
                        child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0x8C000000),
                        borderRadius:
                            BorderRadius.circular(12)),
                    child: const Text('❌ Iskaladın!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold)),
                  ),
                ))),
            ]),
          );
        })),
      ])),
    );
  }
}

class _SoccerScoreBar extends StatelessWidget {
  const _SoccerScoreBar({
    required this.players,
    required this.myKey,
    required this.round,
    required this.maxRound,
  });

  final Map    players;
  final String myKey;
  final int    round, maxRound;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF1B5E20),
    padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 10),
    child: Row(children: [
      Text('Round $round/$maxRound',
          style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      Expanded(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: players.entries.map((e) {
                final isMe  = e.key == myKey;
                final score =
                    (e.value['score'] as int?) ?? 0;
                return Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white
                          : Colors.white24,
                      borderRadius:
                          BorderRadius.circular(12)),
                  child: Text(
                    '${e.value['name']}: $score ⚽',
                    style: TextStyle(
                        color: isMe
                            ? AZColors.green
                            : Colors.white,
                        fontWeight: isMe
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12),
                  ),
                );
              }).toList())),
    ]),
  );
}

class _SoccerFieldPainter extends CustomPainter {
  const _SoccerFieldPainter({
    required this.ball,
    required this.gkX,
    this.dragStart,
    this.dragCurrent,
  });

  final Offset  ball;
  final double  gkX;
  final Offset? dragStart, dragCurrent;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()..color = const Color(0xFF388E3C));
    final stripe = Paint()..color = const Color(0x0A000000);
    for (var i = 0; i < 8; i++) {
      if (i.isOdd) {
        canvas.drawRect(
            Rect.fromLTWH(
                0, s.height * i / 8, s.width, s.height / 8),
            stripe);
      }
    }

    final line = Paint()
      ..color       = Colors.white30
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, s.height * .5),
        Offset(s.width, s.height * .5), line);
    canvas.drawCircle(Offset(s.width * .5, s.height * .5),
        40, line..style = PaintingStyle.stroke);

    final goalW = s.width * 0.44;
    final goalH = s.height * 0.14;
    final goalX = (s.width - goalW) / 2;
    canvas.drawRect(
        Rect.fromLTWH(goalX, 0, goalW, goalH),
        Paint()
          ..color       = Colors.white
          ..strokeWidth = 4
          ..style       = PaintingStyle.stroke);

    final netPaint = Paint()
      ..color       = Colors.white24
      ..strokeWidth = 1;
    for (var x = goalX; x < goalX + goalW; x += 18) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, goalH), netPaint);
    }
    for (var y = 0.0; y < goalH; y += 14) {
      canvas.drawLine(Offset(goalX, y),
          Offset(goalX + goalW, y), netPaint);
    }

    final gkCX = gkX * s.width;
    final gkCY = goalH + 10;
    canvas.drawCircle(
        Offset(gkCX + 2, gkCY + 3),
        20,
        Paint()
          ..color      = Colors.black26
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(gkCX, gkCY), 20,
        Paint()..color = Colors.yellow);
    canvas.drawCircle(Offset(gkCX, gkCY), 14,
        Paint()..color = const Color(0xFFFFD54F));
    final eye = Paint()..color = Colors.black;
    canvas.drawCircle(
        Offset(gkCX - 5, gkCY - 4), 3, eye);
    canvas.drawCircle(
        Offset(gkCX + 5, gkCY - 4), 3, eye);
    canvas.drawCircle(
        Offset(gkCX - 22, gkCY), 8,
        Paint()..color = Colors.yellow.shade800);
    canvas.drawCircle(
        Offset(gkCX + 22, gkCY), 8,
        Paint()..color = Colors.yellow.shade800);

    if (dragStart != null && dragCurrent != null) {
      final bx    = ball.dx * s.width;
      final by    = ball.dy * s.height;
      final dx    =
          (dragStart!.dx - dragCurrent!.dx) * s.width;
      final dy    =
          (dragStart!.dy - dragCurrent!.dy) * s.height;
      final power =
          (sqrt(dx * dx + dy * dy) / (s.width * 0.3))
              .clamp(0.0, 1.0);
      canvas.drawLine(
          Offset(bx, by),
          Offset(bx + dx * 1.3, by + dy * 1.3),
          Paint()
            ..color = Color.lerp(
                    Colors.white.withAlpha(204),
                    Colors.redAccent.withAlpha(204),
                    power)!
            ..strokeWidth = 3.5
            ..strokeCap   = StrokeCap.round);
      for (var i = 1; i <= 5; i++) {
        canvas.drawCircle(
            Offset(bx + dx * 1.3 * i / 6,
                by + dy * 1.3 * i / 6),
            5,
            Paint()
              ..color = Colors.yellowAccent
                  .withAlpha(power > i / 5.0 ? 230 : 51));
      }
    }

    final bx = ball.dx * s.width;
    final by = ball.dy * s.height;
    canvas.drawCircle(
        Offset(bx + 2, by + 3),
        16,
        Paint()
          ..color      = Colors.black38
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(
        Offset(bx, by), 15, Paint()..color = Colors.white);
    final pent = Paint()..color = Colors.black87;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      canvas.drawCircle(
          Offset(bx + cos(a) * 9, by + sin(a) * 9),
          4,
          pent);
    }
    canvas.drawCircle(Offset(bx, by), 4, pent);
    canvas.drawCircle(
        Offset(bx - 5, by - 5),
        5,
        Paint()..color = Colors.white.withAlpha(179));
  }

  @override
  bool shouldRepaint(_) => true;
}
