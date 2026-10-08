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
  late List<_Egg> _eggs = _lay();
  int _round = 1;
  int _score = 0;
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
                  child: CustomPaint(
                    painter: _SmashPainter(eggs: _eggs, line: _line),
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
  _SmashPainter({required this.eggs, required this.line});

  final List<_Egg> eggs;
  final List<Offset> line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF16343A));
    for (final egg in eggs) {
      final center = Offset(egg.at.dx * size.width, egg.at.dy * size.height);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 36, height: 48),
        Paint()..color = egg.good ? FeltColors.brass : (egg.hit ? AZColors.redDk : AZColors.red),
      );
    }
    if (line.length > 1) {
      final path = Path()..moveTo(line.first.dx * size.width, line.first.dy * size.height);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = FeltColors.ivory
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SmashPainter oldDelegate) => true;
}
