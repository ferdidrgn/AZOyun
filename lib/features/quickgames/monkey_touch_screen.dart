import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'monkey_rules.dart';

class MonkeyTouchLobbyScreen extends StatelessWidget {
  const MonkeyTouchLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Maymun Dokunuşu',
        emoji: '🐵',
        gradient: AZColors.gradOrange,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Maymun belirince o kareye dokun. Yirmi saniye. Boş kare puan götürmez.',
      );
}

class MonkeyTouchGameScreen extends StatelessWidget {
  const MonkeyTouchGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'monkeytap',
        gradient: AZColors.gradOrange,
        title: 'Maymun Dokunuşu',
        emoji: '🐵',
        formatScore: (score) => '$score dokunuş',
        sessionBuilder: (context, player, onFinished) =>
            _MonkeySession(player: player, onFinished: onFinished),
      );
}

class _MonkeySession extends StatefulWidget {
  const _MonkeySession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_MonkeySession> createState() => _MonkeySessionState();
}

class _MonkeySessionState extends State<_MonkeySession> {
  final _rng = Random();
  Timer? _move;
  Timer? _clock;
  int _cell = 4;
  int _score = 0;
  int _left = monkeySessionSeconds;
  bool _started = false;

  @override
  void dispose() {
    _move?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) {
      return;
    }
    setState(() => _started = true);
    _move = Timer.periodic(Duration(milliseconds: monkeyMoveIntervalMs), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _cell = _rng.nextInt(9));
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final tick = tickMonkeySession(_left);
      _left = tick.secondsLeft;
      if (!tick.running) {
        _move?.cancel();
        _clock?.cancel();
        widget.onFinished(_score);
        return;
      }
      setState(() {});
    });
  }

  void _tap(int index) {
    final result = tapMonkey(
      score: _score,
      targetIndex: _cell,
      tappedIndex: index,
      running: _started,
    );
    if (result.hit) {
      setState(() {
        _score = result.score;
        _cell = _rng.nextInt(9);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  $_score    ${_started ? '$_left sn' : 'Hazır'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _MonkeyForestPainter()),
              GridView.count(
            padding: const EdgeInsets.all(AZSpacing.sm),
            crossAxisCount: 3,
            mainAxisSpacing: AZSpacing.sm,
            crossAxisSpacing: AZSpacing.sm,
            childAspectRatio: 1.2,
            children: [
              for (var i = 0; i < 9; i++)
                AnimatedScale(
                  scale: i == _cell && _started ? 1.08 : 1,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutBack,
                  child: FilledButton(
                  onPressed: () => _tap(i),
                  style: FilledButton.styleFrom(
                    backgroundColor: i == _cell && _started
                        ? const Color(0xFFFF9B32)
                        : const Color(0xCC286346),
                    foregroundColor: Colors.white,
                    elevation: 7,
                    shadowColor: Colors.black.withOpacity(.55),
                    side: BorderSide(
                      color: i == _cell && _started
                          ? const Color(0xFFFFE1A4)
                          : const Color(0x7792C98A),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(i == _cell && _started ? '🐵' : '', style: const TextStyle(fontSize: 32)),
                ),
                ),
            ],
          ),
            ],
          ),
        ),
        if (!_started)
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AZColors.orangeDk,
              ),
              child: const Text('Başla'),
            ),
          ),
      ],
    );
  }
}

class _MonkeyForestPainter extends CustomPainter {
  const _MonkeyForestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF123C38), Color(0xFF1F6549), Color(0xFF164633)],
    ).createShader(rect));

    for (var i = 0; i < 8; i++) {
      final x = size.width * i / 7;
      final height = size.height * (.27 + (i % 3) * .055);
      final width = size.width * .035;
      final trunk = Rect.fromLTWH(x - width / 2, 0, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(trunk, Radius.circular(width)),
        Paint()..shader = LinearGradient(
          colors: [const Color(0xFF12362B), const Color(0xFF34704B).withOpacity(.45)],
        ).createShader(trunk),
      );
      for (var leaf = 0; leaf < 3; leaf++) {
        final center = Offset(x + (leaf - 1) * size.width * .075, height * .22);
        canvas.drawOval(
          Rect.fromCenter(center: center, width: size.width * .22, height: height * .28),
          Paint()..color = const Color(0xFF73AA57).withOpacity(.2),
        );
      }
    }

    final platform = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .035, size.height * .04, size.width * .93, size.height * .91),
      const Radius.circular(26),
    );
    canvas.drawRRect(
      platform.shift(const Offset(0, 10)),
      Paint()
        ..color = Colors.black.withOpacity(.46)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      platform,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF87A85C), Color(0xFF426E42), Color(0xFF244F3A)],
      ).createShader(platform.outerRect),
    );
    canvas.drawRRect(
      platform.deflate(3),
      Paint()
        ..color = const Color(0x99D7E59A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final glint = Path()
      ..moveTo(size.width * .12, size.height * .12)
      ..quadraticBezierTo(size.width * .36, size.height * .055,
          size.width * .61, size.height * .09);
    canvas.drawPath(glint, Paint()
      ..color = Colors.white.withOpacity(.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _MonkeyForestPainter oldDelegate) => false;
}

