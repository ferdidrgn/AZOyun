import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

class LaneRaceLobbyScreen extends StatelessWidget {
  const LaneRaceLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Şerit Yarışı',
        emoji: '🏎️',
        gradient: AZColors.gradRed,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Araba üç şeritte gider. Sol ve sağ ile şerit değiştir, engelden kaç.',
      );
}

class LaneRaceGameScreen extends StatelessWidget {
  const LaneRaceGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'lanerace',
        gradient: AZColors.gradRed,
        title: 'Şerit Yarışı',
        emoji: '🏎️',
        formatScore: (score) => '$score metre',
        sessionBuilder: (context, player, onFinished) =>
            _LaneSession(player: player, onFinished: onFinished),
      );
}

class _Block {
  _Block({required this.lane, required this.y});
  final int lane;
  double y;
}

class _LaneSession extends StatefulWidget {
  const _LaneSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_LaneSession> createState() => _LaneSessionState();
}

class _LaneSessionState extends State<_LaneSession> {
  final _rng = Random();
  final _blocks = <_Block>[];
  Timer? _timer;
  int _lane = 1;
  double _spawn = 0;
  int _score = 0;
  bool _started = false;
  bool _over = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) {
      return;
    }
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
  }

  void _move(int delta) {
    if (!_started || _over) {
      return;
    }
    setState(() => _lane = (_lane + delta).clamp(0, 2));
  }

  void _tick() {
    if (_over) {
      return;
    }
    _score++;
    _spawn += 0.03;
    final speed = min(0.02, 0.01 + _score * 0.00002);
    if (_spawn >= 0.7) {
      _spawn = 0;
      _blocks.add(_Block(lane: _rng.nextInt(3), y: -0.15));
    }
    for (final block in _blocks) {
      block.y += speed;
      if (block.lane == _lane && block.y > 0.72 && block.y < 0.9) {
        _end();
        return;
      }
    }
    _blocks.removeWhere((block) => block.y > 1.2);
    setState(() {});
  }

  void _end() {
    _over = true;
    _timer?.cancel();
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onFinished(_score ~/ 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  ${_score ~/ 4} m',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AZRadius.lg),
            child: CustomPaint(
              painter: _LanePainter(lane: _lane, blocks: _blocks),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        if (!_started)
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AZColors.redDk,
              ),
              child: const Text('Yarışa başla'),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _move(-1),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AZColors.redDk,
                    ),
                    child: const Text('Sol'),
                  ),
                ),
              ),
              const SizedBox(width: AZSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _move(1),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AZColors.redDk,
                    ),
                    child: const Text('Sağ'),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _LanePainter extends CustomPainter {
  _LanePainter({required this.lane, required this.blocks});

  final int lane;
  final List<_Block> blocks;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF2A3038));
    final laneWidth = size.width / 3;
    final paint = Paint()
      ..color = FeltColors.ivory.withAlpha(80)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(laneWidth, 0), Offset(laneWidth, size.height), paint);
    canvas.drawLine(Offset(laneWidth * 2, 0), Offset(laneWidth * 2, size.height), paint);
    for (final block in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(laneWidth * (block.lane + 0.5), block.y * size.height),
            width: laneWidth * 0.55,
            height: 36,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = AZColors.red,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(laneWidth * (lane + 0.5), size.height * 0.82),
          width: laneWidth * 0.5,
          height: 48,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = FeltColors.brass,
    );
  }

  @override
  bool shouldRepaint(covariant _LanePainter oldDelegate) => true;
}
