import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class MiniBowlingLobbyScreen extends StatelessWidget {
  const MiniBowlingLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Mini Bovling',
        emoji: '🎳',
        gradient: AZColors.gradBlue,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Önce nişan al, sonra gücü ayarla — hareketli çubuk istediğin '
            'noktadayken dokunup durdur. 2 atış hakkın var, en çok pin '
            'deviren kazanır!',
      );
}

enum _Phase { aiming, power, thrown }

class MiniBowlingGameScreen extends StatelessWidget {
  const MiniBowlingGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'minibowling',
        gradient: AZColors.gradBlue,
        title: 'Mini Bovling',
        emoji: '🎳',
        formatScore: (s) => '$s pin',
        sessionBuilder: (context, player, onFinished) =>
            _BowlingSession(player: player, onFinished: onFinished),
      );
}

class _BowlingSession extends StatefulWidget {
  const _BowlingSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_BowlingSession> createState() => _BowlingSessionState();
}

class _BowlingSessionState extends State<_BowlingSession> {
  static const _pinX = [0.0, -0.13, 0.13, -0.26, 0.0, 0.26, -0.39, -0.13, 0.13, 0.39];
  static const _pinY = [0.31, 0.24, 0.24, 0.17, 0.17, 0.17, 0.10, 0.10, 0.10, 0.10];

  Timer? _timer;
  double _t = 0;
  double? _aim;
  final List<bool> _pinsDown = List.filled(10, false);
  int _throwsLeft = 2;
  bool _started = false;
  _Phase _phase = _Phase.aiming;
  double _ballX = 0;
  double _ballY = 0.88;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _startOsc();
  }

  void _startOsc() {
    _timer?.cancel();
    _t = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (mounted) setState(() => _t += 0.09);
    });
  }

  double get _osc => (sin(_t) + 1) / 2;

  void _tapBar() {
    if (_phase == _Phase.aiming) {
      setState(() {
        _aim = _osc * 2 - 1;
        _phase = _Phase.power;
        _t = 0;
      });
    } else if (_phase == _Phase.power) {
      _throwBall();
    }
  }

  void _throwBall() {
    final aim = _aim!;
    final power = _osc;
    _timer?.cancel();
    final landing = (aim * (0.55 + power * 0.5)).clamp(-1.0, 1.0);
    setState(() {
      _phase = _Phase.thrown;
      _ballX = landing;
      _ballY = 0.20;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _resolveThrow(landing, power);
    });
  }

  void _resolveThrow(double landing, double power) {
    final radius = 0.15 + power * 0.09;
    setState(() {
      for (var i = 0; i < 10; i++) {
        if (_pinsDown[i]) continue;
        if ((_pinX[i] - landing).abs() < radius) _pinsDown[i] = true;
      }
      _throwsLeft--;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_throwsLeft <= 0 || _pinsDown.every((d) => d)) {
        widget.onFinished(_pinsDown.where((d) => d).length);
      } else {
        setState(() {
          _phase = _Phase.aiming;
          _aim = null;
          _ballX = 0;
          _ballY = 0.88;
        });
        _startOsc();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎳', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('${widget.player.name}, hazır mısın?',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AZButton(label: 'BAŞLA', icon: Icons.play_arrow_rounded, color: AZColors.blueDk, onPressed: _start),
        ]),
      );
    }
    final knocked = _pinsDown.where((d) => d).length;
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.player.name} · Atış ${2 - _throwsLeft}/2 · Devrilen: $knocked/10',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(0.35),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E241D), Color(0xFF7A6552)],
                ),
                borderRadius: BorderRadius.circular(AZRadius.md),
              ),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _LanePainter())),
                for (var i = 0; i < 10; i++)
                  Builder(builder: (context) {
                    final scale = 0.82 + _pinY[i] * 0.55;
                    final pinWidth = 28 * scale;
                    final pinHeight = 40 * scale;
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      left: (0.5 + _pinX[i] * 0.5) * w - pinWidth / 2,
                      top: _pinY[i] * h - pinHeight / 2,
                      child: SizedBox(
                        width: pinWidth,
                        height: pinHeight,
                        child: Stack(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _pinsDown[i] ? 0.62 : 1,
                              child: Transform.rotate(
                                angle: _pinsDown[i] ? 1.12 : 0,
                                child: CustomPaint(
                                  size: Size(pinWidth, pinHeight),
                                  painter: _PinPainter(),
                                ),
                              ),
                            ),
                            if (_pinsDown[i])
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey('pin-hit-$i'),
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 420),
                                    builder: (context, progress, child) => CustomPaint(
                                      painter: _PinHitPainter(progress),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOut,
                  left: (0.5 + _ballX * 0.5) * w - (18 + (1 - _ballY) * 9) / 2,
                  top: _ballY * h - (18 + (1 - _ballY) * 9) / 2,
                  child: CustomPaint(
                    size: Size.square(18 + (1 - _ballY) * 9),
                    painter: _BowlingBallPainter(),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
      const SizedBox(height: 16),
      if (_phase != _Phase.thrown) _buildBar(),
      const SizedBox(height: 12),
    ]);
  }

  Widget _buildBar() {
    final label =
        _phase == _Phase.aiming ? 'NİŞAN AL — durdurmak için dokun' : 'GÜÇ — durdurmak için dokun';
    return GestureDetector(
      onTap: _tapBar,
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(14)),
          child: LayoutBuilder(builder: (context, constraints) {
            final barW = constraints.maxWidth;
            return Stack(children: [
              Positioned(
                left: _osc * (barW - 18),
                top: 4,
                child: Container(
                  width: 18,
                  height: 20,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]);
          }),
        ),
      ]),
    );
  }
}

class _LanePainter extends CustomPainter {
  const _LanePainter();

  Path _lane(Size size) => Path()
    ..moveTo(size.width * 0.27, 0)
    ..lineTo(size.width * 0.73, 0)
    ..lineTo(size.width * 0.89, size.height)
    ..lineTo(size.width * 0.11, size.height)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final lane = _lane(size);
    canvas.drawPath(
      lane,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8C88C), Color(0xFFD3A56A), Color(0xFFA97545)],
        ).createShader(Offset.zero & size),
    );

    final leftGutter = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.27, 0)
      ..lineTo(size.width * 0.11, size.height)
      ..lineTo(0, size.height)
      ..close();
    final rightGutter = Path()
      ..moveTo(size.width * 0.73, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.89, size.height)
      ..close();
    final gutterPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF573B2B), Color(0xFF1D2428)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(leftGutter, gutterPaint);
    canvas.drawPath(rightGutter, gutterPaint);

    for (var i = 1; i < 8; i++) {
      final fraction = i / 8;
      final topX = size.width * (0.27 + 0.46 * fraction);
      final bottomX = size.width * (0.11 + 0.78 * fraction);
      canvas.drawLine(
        Offset(topX, size.height * 0.015),
        Offset(bottomX, size.height * 0.99),
        Paint()
          ..color = const Color(0x33733E22)
          ..strokeWidth = i.isEven ? 1.1 : 0.65,
      );
    }
    for (var i = 1; i <= 5; i++) {
      final y = size.height * (0.16 + i * 0.14);
      final halfWidth = size.width * (0.23 + i * 0.043);
      canvas.drawLine(
        Offset(size.width / 2 - halfWidth, y),
        Offset(size.width / 2 + halfWidth, y),
        Paint()..color = const Color(0x1EFFF3D5)..strokeWidth = 1,
      );
    }

    final laneEdge = Paint()
      ..color = const Color(0xAAFFE4AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(lane, laneEdge);

    final arrowsY = size.height * 0.58;
    for (final x in [0.39, 0.445, 0.5, 0.555, 0.61]) {
      final arrow = Path()
        ..moveTo(size.width * x, arrowsY - 7)
        ..lineTo(size.width * x - 4, arrowsY + 2)
        ..lineTo(size.width * x + 4, arrowsY + 2)
        ..close();
      canvas.drawPath(arrow, Paint()..color = const Color(0x77FFF6DB));
    }

    final light = Rect.fromLTWH(
      size.width * 0.2,
      0,
      size.width * 0.6,
      size.height,
    );
    canvas.drawRect(
      light,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.transparent, Color(0x16FFFFFF), Colors.transparent],
        ).createShader(light),
    );
  }

  @override
  bool shouldRepaint(covariant _LanePainter oldDelegate) => false;
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.08)
      ..cubicTo(size.width * 0.3, size.height * 0.08, size.width * 0.29,
          size.height * 0.28, size.width * 0.4, size.height * 0.4)
      ..cubicTo(size.width * 0.28, size.height * 0.57, size.width * 0.2,
          size.height * 0.7, size.width * 0.22, size.height * 0.82)
      ..cubicTo(size.width * 0.24, size.height * 0.98, size.width * 0.76,
          size.height * 0.98, size.width * 0.78, size.height * 0.82)
      ..cubicTo(size.width * 0.8, size.height * 0.7, size.width * 0.72,
          size.height * 0.57, size.width * 0.6, size.height * 0.4)
      ..cubicTo(size.width * 0.71, size.height * 0.28, size.width * 0.7,
          size.height * 0.08, size.width * 0.5, size.height * 0.08)
      ..close();
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.92),
        width: size.width * 0.92,
        height: size.height * 0.16,
      ),
      Paint()
        ..color = const Color(0x880D171A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      body.shift(const Offset(0, 1.5)),
      Paint()..color = const Color(0xFF9AA3A8),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF9AA6AC), Color(0xFFFFFFFF), Color(0xFFEAF0F2), Color(0xFF8C999F)],
          stops: [0, 0.28, 0.7, 1],
        ).createShader(Offset.zero & size),
    );
    final stripe = Path()
      ..moveTo(size.width * 0.32, size.height * 0.36)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.43,
          size.width * 0.68, size.height * 0.36);
    canvas.drawPath(
      stripe,
      Paint()
        ..color = const Color(0xFFE23E4F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.39, size.height * 0.22),
        width: size.width * 0.1,
        height: size.height * 0.18,
      ),
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => false;
}

class _BowlingBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawCircle(
      Offset(size.width * 0.53, size.height * 0.58),
      size.width * 0.48,
      Paint()
        ..color = const Color(0x77081425)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      size.width * 0.46,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.55),
          radius: 1.1,
          colors: [Color(0xFFB8F6FF), Color(0xFF2694D2), Color(0xFF123B83)],
          stops: [0, 0.42, 1],
        ).createShader(bounds),
    );
    final holes = Paint()..color = const Color(0xAA092653);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.4), size.width * 0.055, holes);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.37), size.width * 0.055, holes);
    canvas.drawCircle(Offset(size.width * 0.49, size.height * 0.51), size.width * 0.055, holes);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.28),
        width: size.width * 0.18,
        height: size.height * 0.09,
      ),
      Paint()..color = const Color(0xAAFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _BowlingBallPainter oldDelegate) => false;
}

class _PinHitPainter extends CustomPainter {
  const _PinHitPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final direction = Offset(cos(angle), sin(angle));
      final start = center + direction * (5 + progress * 4);
      final end = center + direction * (12 + progress * 14);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFFE17D).withOpacity(fade)
          ..strokeWidth = i.isEven ? 2.5 : 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        end,
        (i.isEven ? 2.5 : 1.5) * fade,
        Paint()..color = const Color(0xFFFFF1B3).withOpacity(fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PinHitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
