import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'balloon_rules.dart';

class BalloonPopLobbyScreen extends StatelessWidget {
  const BalloonPopLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Balon Patlatma',
        emoji: '🎈',
        gradient: AZColors.gradPink,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            '20 saniyen var! Ekranda beliren balonlara kaybolmadan hızlıca '
            'dokun. En çok balon patlatan kazanır!',
      );
}

class BalloonPopGameScreen extends StatelessWidget {
  const BalloonPopGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'balloonpop',
        gradient: AZColors.gradPink,
        title: 'Balon Patlatma',
        emoji: '🎈',
        formatScore: (s) => '$s balon',
        sessionBuilder: (context, player, onFinished) =>
            _BalloonSession(player: player, onFinished: onFinished),
      );
}

class _BalloonSession extends StatefulWidget {
  const _BalloonSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_BalloonSession> createState() => _BalloonSessionState();
}

class _BalloonSessionState extends State<_BalloonSession> {
  static const _sessionSeconds = balloonSessionSeconds;
  static const _balloonLifeMs = balloonLifetimeMs;

  final _rng = Random();
  Timer? _countdown;
  Timer? _balloonTimer;
  int _secondsLeft = _sessionSeconds;
  int _score = 0;
  Offset _pos = const Offset(0.5, 0.5);
  Offset _burstPos = const Offset(0.5, 0.5);
  bool _visible = false;
  bool _burstVisible = false;
  int _burstSerial = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final tick = tickBalloonSession(_secondsLeft);
      setState(() => _secondsLeft = tick.secondsLeft);
      if (!tick.running) _end();
    });
    _spawnBalloon();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _balloonTimer?.cancel();
    super.dispose();
  }

  void _spawnBalloon() {
    if (!_running) return;
    setState(() {
      _pos = Offset(0.05 + _rng.nextDouble() * 0.85, 0.05 + _rng.nextDouble() * 0.8);
      _visible = true;
    });
    _balloonTimer?.cancel();
    _balloonTimer = Timer(const Duration(milliseconds: _balloonLifeMs), () {
      if (!mounted || !_running) return;
      setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || !_running) return;
        _spawnBalloon();
      });
    });
  }

  void _pop() {
    final result = popBalloon(
      score: _score,
      visible: _visible,
      running: _running,
    );
    if (!result.popped) return;
    _balloonTimer?.cancel();
    setState(() {
      _score = result.score;
      _visible = false;
      _burstPos = _pos;
      _burstVisible = true;
      _burstSerial++;
    });
    final burstSerial = _burstSerial;
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted || burstSerial != _burstSerial) return;
      setState(() => _burstVisible = false);
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_running) return;
      _spawnBalloon();
    });
  }

  void _end() {
    if (!_running) return;
    _running = false;
    _countdown?.cancel();
    _balloonTimer?.cancel();
    widget.onFinished(_score);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.player.name} · Süre: $_secondsLeft sn · Skor: $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(AZRadius.md)),
            child: Stack(children: [
              if (_visible)
                Positioned(
                  left: _pos.dx * (constraints.maxWidth - 56),
                  top: _pos.dy * (constraints.maxHeight - 56),
                  child: GestureDetector(
                    onTap: _pop,
                    child: const SizedBox(
                      width: 56,
                      height: 68,
                      child: CustomPaint(painter: _BalloonPainter()),
                    ),
                  ),
                ),
              if (_burstVisible)
                Positioned(
                  left: _burstPos.dx * (constraints.maxWidth - 56) - 13,
                  top: _burstPos.dy * (constraints.maxHeight - 56) - 8,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_burstSerial),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 380),
                      builder: (context, progress, child) => CustomPaint(
                        size: const Size(82, 82),
                        painter: _BurstPainter(progress),
                      ),
                    ),
                  ),
                ),
            ]),
          );
        }),
      ),
    ]);
  }
}

class _BalloonPainter extends CustomPainter {
  const _BalloonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.89)
      ..cubicTo(size.width * 0.33, size.height * 0.78, size.width * 0.06,
          size.height * 0.56, size.width * 0.08, size.height * 0.34)
      ..cubicTo(size.width * 0.09, size.height * 0.09, size.width * 0.3,
          size.height * 0.03, size.width * 0.5, size.height * 0.03)
      ..cubicTo(size.width * 0.72, size.height * 0.03, size.width * 0.92,
          size.height * 0.12, size.width * 0.92, size.height * 0.36)
      ..cubicTo(size.width * 0.93, size.height * 0.57, size.width * 0.68,
          size.height * 0.79, size.width * 0.5, size.height * 0.89)
      ..close();

    canvas.drawPath(
      body.shift(const Offset(1, 4)),
      Paint()
        ..color = const Color(0x660A1530)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.38, -0.55),
          radius: 1.15,
          colors: [
            Color(0xFFFFF1FA),
            Color(0xFFFF8FC9),
            Color(0xFFE83D9B),
            Color(0xFF9C176F),
          ],
          stops: [0, 0.24, 0.68, 1],
        ).createShader(Offset.zero & size),
    );

    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.21, size.height * 0.15, size.width * 0.16,
          size.height * 0.32),
      Paint()..color = const Color(0xD9FFFFFF),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.39, size.height * 0.1, size.width * 0.08,
          size.height * 0.1),
      Paint()..color = const Color(0x99FFFFFF),
    );
    final knot = Path()
      ..moveTo(size.width * 0.43, size.height * 0.86)
      ..lineTo(size.width * 0.57, size.height * 0.86)
      ..lineTo(size.width * 0.5, size.height * 0.96)
      ..close();
    canvas.drawPath(knot, Paint()..color = const Color(0xFFB6227D));
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter oldDelegate) => false;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.progress);

  final double progress;

  static const _colors = [
    Color(0xFFFFE36E),
    Color(0xFFFF78B7),
    Color(0xFF72E5FF),
    Color(0xFFFFA95E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < 12; i++) {
      final angle = (i * pi / 6) - pi / 2;
      final distance = 8 + 27 * progress;
      final direction = Offset(cos(angle), sin(angle));
      final point = center + direction * distance;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withOpacity(fade)
        ..strokeWidth = i.isEven ? 3 : 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center + direction * (distance - 7), point, paint);
      canvas.drawCircle(
        point,
        (i.isEven ? 3.2 : 2.2) * fade,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

