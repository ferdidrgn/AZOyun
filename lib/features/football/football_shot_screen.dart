import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ShotMode {
  freeKick('Frikik Ustası'),
  penalty('Penaltı Antrenmanı');

  const ShotMode(this.title);
  final String title;
}

class FootballShotScreen extends StatefulWidget {
  const FootballShotScreen({super.key, required this.mode});
  final ShotMode mode;

  @override
  State<FootballShotScreen> createState() => _FootballShotScreenState();
}

const _startBall = Offset(.5, .80);
const _goalLeft = .16;
const _goalRight = .84;
const _goalTop = .10;
const _goalBottom = .30;

class _FootballShotScreenState extends State<FootballShotScreen>
    with SingleTickerProviderStateMixin {
  late final _flight = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 820))
    ..addStatusListener(_onStatus);

  Offset? _origin;
  Offset? _drag;
  _Shot? _shot;
  String? _result;
  int _attempt = 0;
  int _goals = 0;
  int _points = 0;
  double _curve = 0;
  bool get _freeKick => widget.mode == ShotMode.freeKick;
  bool get _done => _attempt == 6 && !_flight.isAnimating;

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  double get _wallCenter => .36 + (_attempt % 3) * .13;
  double get _keeperStart => .33 + (_attempt % 4) * .11;

  _Shot _aim(Size size) {
    final drag = _drag ?? Offset.zero;
    final power = (-drag.dy / (size.height * .47)).clamp(0.0, 1.12);
    return _Shot(
      Offset(.5 + drag.dx / size.width * 1.3, .43 - power * .34),
      _freeKick ? _curve * .24 : 0,
      power,
    );
  }

  void _launch(Size size) {
    final shot = _aim(size);
    setState(() {
      _origin = null;
      _drag = null;
      if (shot.power < .23) return;
      _shot = shot;
      _result = null;
      _attempt++;
      _flight.forward(from: 0);
    });
  }

  double _keeper(double time) {
    final phase = (_attempt - 1) * 1.9 + time * 2.7;
    return (_keeperStart + math.sin(phase) * .16).clamp(.23, .77);
  }

  double _stopAt(_Shot shot) {
    final wall = shot.position(.55);
    final wallCenter = .36 + ((_attempt - 1) % 3) * .13;
    if (_freeKick && (wall.dx - wallCenter).abs() < .13 && shot.power < .80)
      return .55;
    return 1;
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final shot = _shot!;
    final target = shot.target;
    final stopped = _stopAt(shot) < 1;
    final onFrame = target.dx > _goalLeft &&
        target.dx < _goalRight &&
        target.dy > _goalTop &&
        target.dy < _goalBottom;
    final saved = (target.dx - _keeper(1)).abs() < .105 && target.dy > .145;
    final goal = !stopped && onFrame && !saved;
    final corner = (target.dx - .5).abs() > .22 || target.dy < .15;
    setState(() {
      _result = stopped
          ? 'Barajda kaldı'
          : !onFrame
              ? 'Aut'
              : saved
                  ? 'Kaleci kurtardı'
                  : corner
                      ? 'Köşeye gol · +3'
                      : 'Gol · +2';
      if (goal) {
        _goals++;
        _points += corner ? 3 : 2;
      }
    });
  }

  void _reset() {
    _flight.reset();
    setState(() {
      _attempt = 0;
      _goals = 0;
      _points = 0;
      _shot = null;
      _result = null;
      _curve = 0;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.mode.title)),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                  'Vuruş $_attempt/6   ·   Gol $_goals   ·   $_points puan',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              final size = constraints.biggest;
              final enabled = !_done && !_flight.isAnimating;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: !enabled
                    ? null
                    : (event) {
                        final ball = Offset(size.width * .5, size.height * .8);
                        if ((event.localPosition - ball).distance < 64) {
                          setState(() {
                            _origin = event.localPosition;
                            _drag = Offset.zero;
                          });
                        }
                      },
                onPanUpdate: !enabled
                    ? null
                    : (event) {
                        if (_origin != null)
                          setState(
                              () => _drag = event.localPosition - _origin!);
                      },
                onPanEnd: !enabled
                    ? null
                    : (_) {
                        if (_origin != null) _launch(size);
                      },
                onPanCancel: () => setState(() {
                  _origin = null;
                  _drag = null;
                }),
                child: AnimatedBuilder(
                    animation: _flight,
                    builder: (context, _) {
                      final shot = _shot;
                      final time = _flight.value;
                      final ball = shot == null || !_flight.isAnimating
                          ? _startBall
                          : shot.position(math.min(time, _stopAt(shot)));
                      return CustomPaint(
                          painter: _PitchPainter(
                            ball: ball,
                            keeper: shot != null && _flight.isAnimating
                                ? _keeper(time)
                                : _keeperStart,
                            wall: !_freeKick
                                ? null
                                : _flight.isAnimating
                                    ? .36 + ((_attempt - 1) % 3) * .13
                                    : _wallCenter,
                            aim: _drag != null ? _aim(size).target : null,
                          ),
                          child: const SizedBox.expand());
                    }),
              );
            })),
            if (_freeKick)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Text('Falso'),
                  Expanded(
                      child: Slider(
                    value: _curve,
                    min: -1,
                    max: 1,
                    divisions: 10,
                    label: _curve < 0
                        ? 'Sola'
                        : _curve > 0
                            ? 'Sağa'
                            : 'Düz',
                    onChanged: _flight.isAnimating || _done
                        ? null
                        : (value) => setState(() => _curve = value),
                  )),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _done
                  ? FilledButton(
                      onPressed: _reset,
                      child: Text('$_goals gol · Tekrar oyna'))
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_result != null)
                        Text(_result!,
                            style: Theme.of(context).textTheme.titleMedium),
                      const Text(
                          'Topun başladığı noktadan yukarı sürükle. Uzun sürükleme topu yükseltir.',
                          textAlign: TextAlign.center),
                    ]),
            ),
          ]),
        ))),
      );
}

class _Shot {
  const _Shot(this.target, this.curve, this.power);
  final Offset target;
  final double curve;
  final double power;

  Offset position(double time) =>
      Offset.lerp(_startBall, target, time)! +
      Offset(curve * math.sin(math.pi * time), 0);
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter(
      {required this.ball, required this.keeper, this.wall, this.aim});
  final Offset ball;
  final double keeper;
  final double? wall;
  final Offset? aim;

  @override
  void paint(Canvas canvas, Size size) {
    Offset point(double x, double y) => Offset(x * size.width, y * size.height);
    final paint = Paint();
    for (var row = 0; row < 8; row++) {
      paint.color =
          row.isEven ? const Color(0xFF1D6349) : const Color(0xFF205A46);
      canvas.drawRect(
          Rect.fromPoints(point(0, row / 8), point(1, (row + 1) / 8)), paint);
    }
    final goal = Rect.fromPoints(
        point(_goalLeft, _goalTop), point(_goalRight, _goalBottom));
    canvas.drawRect(goal, paint..color = const Color(0xFF18352F));
    paint
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1;
    for (var n = 1; n < 10; n++) {
      final x = goal.left + goal.width * n / 10;
      canvas.drawLine(Offset(x, goal.top), Offset(x, goal.bottom), paint);
    }
    for (var n = 1; n < 5; n++) {
      final y = goal.top + goal.height * n / 5;
      canvas.drawLine(Offset(goal.left, y), Offset(goal.right, y), paint);
    }
    canvas.drawRect(
        goal,
        paint
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: point(keeper, .245),
                width: size.width * .14,
                height: 15),
            const Radius.circular(7)),
        paint..color = const Color(0xFFF7B955));
    final wallX = wall;
    if (wallX != null) {
      for (final offset in [-.08, 0.0, .08]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: point(wallX + offset, .50),
                    width: size.width * .07,
                    height: 23),
                const Radius.circular(7)),
            paint..color = const Color(0xFFF47967));
      }
    }
    final target = aim;
    if (target != null) {
      canvas.drawLine(point(.5, .8), point(target.dx, target.dy),
          paint..color = Colors.white54);
      canvas.drawCircle(point(target.dx, target.dy), 8,
          paint..color = const Color(0xFFF7D28A));
    }
    canvas.drawCircle(point(.5, .8), 3, paint..color = Colors.white54);
    canvas.drawCircle(point(ball.dx, ball.dy),
        math.max(8, size.shortestSide * .027), paint..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) =>
      ball != oldDelegate.ball ||
      keeper != oldDelegate.keeper ||
      wall != oldDelegate.wall ||
      aim != oldDelegate.aim;
}
