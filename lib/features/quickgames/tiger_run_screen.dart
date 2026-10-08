import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

class TigerRunLobbyScreen extends StatelessWidget {
  const TigerRunLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Kaplan Koşusu',
        emoji: '🐯',
        gradient: AZColors.gradOrange,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Kaplan koşar. Zıpla ile engeli aş, altınları topla.',
      );
}

class TigerRunGameScreen extends StatelessWidget {
  const TigerRunGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'tigerrun',
        gradient: AZColors.gradOrange,
        title: 'Kaplan Koşusu',
        emoji: '🐯',
        formatScore: (score) => '$score altın',
        sessionBuilder: (context, player, onFinished) =>
            _TigerSession(player: player, onFinished: onFinished),
      );
}

class _Gate {
  _Gate({required this.x, required this.coin});
  double x;
  final bool coin;
  bool taken = false;
}

class _TigerSession extends StatefulWidget {
  const _TigerSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_TigerSession> createState() => _TigerSessionState();
}

class _TigerSessionState extends State<_TigerSession> {
  static const _ground = 0.72;
  static const _tigerX = 0.22;

  final _rng = Random();
  final _gates = <_Gate>[];
  Timer? _timer;
  double _y = _ground;
  double _vy = 0;
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

  void _jump() {
    if (!_started) {
      _start();
    }
    if (_over || _y < _ground - 0.02) {
      return;
    }
    setState(() => _vy = -0.034);
  }

  void _tick() {
    if (_over) {
      return;
    }
    _vy += 0.0022;
    _y += _vy;
    if (_y > _ground) {
      _y = _ground;
      _vy = 0;
    }
    _spawn += 0.012;
    if (_spawn >= 0.46) {
      _spawn = 0;
      _gates.add(_Gate(x: 1.15, coin: _rng.nextBool()));
    }
    for (final gate in _gates) {
      gate.x -= 0.012;
      final near = (gate.x - _tigerX).abs() < 0.05;
      if (!near) {
        continue;
      }
      if (gate.coin && !gate.taken && _y < _ground - 0.08) {
        gate.taken = true;
        _score++;
      }
      if (!gate.coin && _y > _ground - 0.12) {
        _end();
        return;
      }
    }
    _gates.removeWhere((gate) => gate.x < -0.2);
    setState(() {});
  }

  void _end() {
    _over = true;
    _timer?.cancel();
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onFinished(_score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Altın $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AZRadius.lg),
            child: CustomPaint(
              painter: _TigerPainter(y: _y, gates: _gates),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _over ? null : _jump,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AZColors.orangeDk,
            ),
            child: Text(_started ? 'Zıpla' : 'Koşmaya başla'),
          ),
        ),
      ],
    );
  }
}

class _TigerPainter extends CustomPainter {
  _TigerPainter({required this.y, required this.gates});

  final double y;
  final List<_Gate> gates;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF245C4A),
    );
    final ground = size.height * 0.78;
    canvas.drawRect(
      Rect.fromLTWH(0, ground, size.width, size.height - ground),
      Paint()..color = FeltColors.feltDeep,
    );
    for (final gate in gates) {
      if (gate.coin) {
        if (!gate.taken) {
          canvas.drawCircle(
            Offset(gate.x * size.width, ground - 70),
            10,
            Paint()..color = FeltColors.brass,
          );
        }
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(gate.x * size.width, ground - 46, 28, 46),
            const Radius.circular(4),
          ),
          Paint()..color = FeltColors.clay,
        );
      }
    }
    final tiger = Offset(size.width * 0.22, y / 0.72 * ground - 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: tiger, width: 46, height: 28),
        const Radius.circular(10),
      ),
      Paint()..color = AZColors.orange,
    );
    canvas.drawCircle(tiger.translate(16, -8), 10, Paint()..color = AZColors.orangeDk);
  }

  @override
  bool shouldRepaint(covariant _TigerPainter oldDelegate) => true;
}
