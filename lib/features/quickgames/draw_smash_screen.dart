import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

class DrawSmashLobbyScreen extends StatelessWidget {
  const DrawSmashLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Çiz Kazan',
        emoji: '✏️',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Kırmızı yumurtaların üzerinden çizgi çek. '
            'Altın yumurtaya değme. Üç tur.',
      );
}

class DrawSmashGameScreen extends StatelessWidget {
  const DrawSmashGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'drawsmash',
        gradient: AZColors.gradCyan,
        title: 'Çiz Kazan',
        emoji: '✏️',
        formatScore: (score) => '$score yumurta',
        sessionBuilder: (context, player, onFinished) =>
            _DrawSession(player: player, onFinished: onFinished),
      );
}

class _Egg {
  _Egg({required this.at, required this.good});
  final Offset at;
  final bool good;
  bool hit = false;
}

class _DrawSession extends StatefulWidget {
  const _DrawSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_DrawSession> createState() => _DrawSessionState();
}

class _DrawSessionState extends State<_DrawSession> {
  final _rng = Random();
  final _line = <Offset>[];
  final _impactPositions = <Offset>[];
  late List<_Egg> _eggs = _lay();
  int _round = 1;
  int _score = 0;
  int _impactSerial = 0;
  bool _drawing = false;

  List<_Egg> _lay() {
    final eggs = <_Egg>[];
    while (eggs.length < 6) {
      final at = Offset(0.15 + _rng.nextDouble() * 0.7, 0.15 + _rng.nextDouble() * 0.7);
      if (eggs.every((egg) => (egg.at - at).distance > 0.16)) {
        eggs.add(_Egg(at: at, good: eggs.isEmpty));
      }
    }
    return eggs;
  }

  void _startDraw(Offset local, Size size) {
    _drawing = true;
    _line
      ..clear()
      ..add(Offset(local.dx / size.width, local.dy / size.height));
    setState(() {});
  }

  void _extend(Offset local, Size size) {
    if (!_drawing) {
      return;
    }
    final point = Offset(
      (local.dx / size.width).clamp(0, 1),
      (local.dy / size.height).clamp(0, 1),
    );
    _line.add(point);
    for (final egg in _eggs) {
      if (!egg.hit && (egg.at - point).distance < 0.07) {
        egg.hit = true;
        _impactPositions.add(egg.at);
        _impactSerial++;
      }
    }
    setState(() {});
  }

  void _endDraw() {
    if (!_drawing) {
      return;
    }
    _drawing = false;
    final spoiled = _eggs.any((egg) => egg.good && egg.hit);
    if (!spoiled) {
      _score += _eggs.where((egg) => !egg.good && egg.hit).length;
    }
    if (_round == 3) {
      widget.onFinished(_score);
      return;
    }
    setState(() {
      _round++;
      _eggs = _lay();
      _line.clear();
      _impactPositions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Tur $_round/3  $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (details) => _startDraw(details.localPosition, size),
                onPanUpdate: (details) => _extend(details.localPosition, size),
                onPanEnd: (_) => _endDraw(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AZRadius.lg),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_impactSerial),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 480),
                    builder: (context, progress, child) => CustomPaint(
                      painter: _SmashPainter(
                        eggs: _eggs,
                        line: _line,
                        impacts: _impactPositions,
                        impactProgress: progress,
                      ),
                      child: child,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        const Text(
          'Kırmızıların üzerinden geç. Altına değme.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _SmashPainter extends CustomPainter {
  _SmashPainter({
    required this.eggs,
    required this.line,
    required this.impacts,
    required this.impactProgress,
  });

  final List<_Egg> eggs;
  final List<Offset> line;
  final List<Offset> impacts;
  final double impactProgress;

  Path _eggPath(Offset center) => Path()
    ..moveTo(center.dx, center.dy + 23)
    ..cubicTo(center.dx - 16, center.dy + 12, center.dx - 19, center.dy - 5,
        center.dx - 15, center.dy - 16)
    ..cubicTo(center.dx - 11, center.dy - 29, center.dx + 11, center.dy - 29,
        center.dx + 15, center.dy - 16)
    ..cubicTo(center.dx + 19, center.dy - 5, center.dx + 16, center.dy + 12,
        center.dx, center.dy + 23)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF265C62), Color(0xFF15363D), Color(0xFF0E282F)],
        ).createShader(bounds),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.65, -0.75),
          radius: 1.25,
          colors: [const Color(0x337EE5D8), Colors.transparent],
        ).createShader(bounds),
    );

    for (final egg in eggs) {
      final center = Offset(egg.at.dx * size.width, egg.at.dy * size.height);
      final body = _eggPath(center);
      final base = egg.good ? FeltColors.brass : AZColors.red;
      final dark = egg.good ? const Color(0xFF8A5D16) : AZColors.redDk;

      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(2, 8),
          width: 36,
          height: 14,
        ),
        Paint()
          ..color = const Color(0x77081620)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        body.shift(const Offset(0, 3)),
        Paint()..color = dark,
      );
      canvas.drawPath(
        body,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.48, -0.6),
            radius: 1.15,
            colors: egg.hit
                ? [dark, dark, const Color(0xFF31151B)]
                : [Colors.white, base.withOpacity(0.96), base, dark],
            stops: egg.hit ? const [0, 0.25, 1] : const [0, 0.12, 0.7, 1],
          ).createShader(Rect.fromCenter(center: center, width: 42, height: 56)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(-6, -11),
          width: 5,
          height: 12,
        ),
        Paint()..color = const Color(0xAAFFFFFF),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 28),
          width: 9,
          height: 3,
        ),
        Paint()..color = dark,
      );

      if (egg.hit) {
        final crack = Path()
          ..moveTo(center.dx - 8, center.dy - 6)
          ..lineTo(center.dx - 1, center.dy + 1)
          ..lineTo(center.dx - 5, center.dy + 6)
          ..lineTo(center.dx + 3, center.dy + 11)
          ..moveTo(center.dx + 2, center.dy - 1)
          ..lineTo(center.dx + 8, center.dy - 7)
          ..lineTo(center.dx + 5, center.dy + 1);
        canvas.drawPath(
          crack,
          Paint()
            ..color = const Color(0xFFFFE4BE)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    for (final impact in impacts) {
      _paintImpact(canvas, Offset(impact.dx * size.width, impact.dy * size.height));
    }

    if (line.length > 1) {
      final path = Path()..moveTo(line.first.dx * size.width, line.first.dy * size.height);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xAA061A20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = FeltColors.ivory
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xBFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintImpact(Canvas canvas, Offset center) {
    final progress = impactProgress.clamp(0.0, 1.0).toDouble();
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final radius = 8 + 24 * progress;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFD568).withOpacity(0.25 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * fade),
    );
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final direction = Offset(cos(angle), sin(angle));
      final start = center + direction * (7 + 4 * progress);
      final end = center + direction * (radius + 9 * progress);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = (i.isEven ? const Color(0xFFFFE685) : Colors.white)
              .withOpacity(fade)
          ..strokeWidth = i.isEven ? 2.4 : 1.6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        end,
        (i.isEven ? 2.6 : 1.8) * fade,
        Paint()..color = const Color(0xFFFFE685).withOpacity(fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SmashPainter oldDelegate) => true;
}
