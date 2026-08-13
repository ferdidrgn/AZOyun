import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class JumpDashLobbyScreen extends StatelessWidget {
  const JumpDashLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Zıpla Geç',
        emoji: '🐤',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Cihazı sırayla birbirinize verin. Ekrana dokunarak zıpla, '
            'borulara çarpmadan olabildiğince ileri git. En çok boru geçen kazanır!',
      );
}

class _Pipe {
  _Pipe({required this.x, required this.gapCenter});
  double x;
  final double gapCenter;
  bool passed = false;
}

class JumpDashGameScreen extends StatelessWidget {
  const JumpDashGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'jumpdash',
        gradient: AZColors.gradCyan,
        title: 'Zıpla Geç',
        emoji: '🐤',
        formatScore: (s) => '$s boru',
        sessionBuilder: (context, player, onFinished) =>
            _JumpDashSession(player: player, onFinished: onFinished),
      );
}

class _JumpDashSession extends StatefulWidget {
  const _JumpDashSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_JumpDashSession> createState() => _JumpDashSessionState();
}

class _JumpDashSessionState extends State<_JumpDashSession> {
  static const _gravity = 0.0018;
  static const _jumpImpulse = -0.034;
  static const _pipeSpeed = 0.011;
  static const _pipeWidth = 0.14;
  static const _gapHalf = 0.16;
  static const _birdX = 0.22;
  static const _birdR = 0.035;

  final _rng = Random();
  Timer? _timer;
  double _birdY = 0.5;
  double _velocity = 0;
  double _spawnTimer = 0;
  final List<_Pipe> _pipes = [];
  int _score = 0;
  bool _over = false;
  bool _started = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
  }

  void _onTap() {
    if (!_started) {
      _start();
      return;
    }
    if (_over) return;
    setState(() => _velocity = _jumpImpulse);
  }

  void _tick() {
    if (_over) return;
    setState(() {
      _velocity += _gravity;
      _birdY += _velocity;
      _spawnTimer += _pipeSpeed;
      if (_spawnTimer >= 0.42) {
        _spawnTimer = 0;
        _pipes.add(_Pipe(x: 1.15, gapCenter: 0.22 + _rng.nextDouble() * 0.56));
      }
      for (final p in _pipes) {
        p.x -= _pipeSpeed;
        if (!p.passed && p.x + _pipeWidth < _birdX) {
          p.passed = true;
          _score++;
        }
      }
      _pipes.removeWhere((p) => p.x < -0.2);

      if (_birdY - _birdR < 0 || _birdY + _birdR > 1) {
        _end();
        return;
      }
      for (final p in _pipes) {
        final overlapX = (_birdX + _birdR > p.x) && (_birdX - _birdR < p.x + _pipeWidth);
        if (overlapX) {
          final inGap = (_birdY - _birdR > p.gapCenter - _gapHalf) &&
              (_birdY + _birdR < p.gapCenter + _gapHalf);
          if (!inGap) {
            _end();
            return;
          }
        }
      }
    });
  }

  void _end() {
    _over = true;
    _timer?.cancel();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onFinished(_score);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.player.name} · Skor: $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: GestureDetector(
          onTap: _onTap,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return ClipRRect(
              borderRadius: BorderRadius.circular(AZRadius.md),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0x1FFFFFFF),
                child: Stack(children: [
                  Positioned(
                    left: _birdX * w - 16,
                    top: _birdY * h - 16,
                    child: const Text('🐤', style: TextStyle(fontSize: 32)),
                  ),
                  for (final p in _pipes) ...[
                    Positioned(
                      left: p.x * w,
                      top: 0,
                      width: _pipeWidth * w,
                      height: (p.gapCenter - _gapHalf) * h,
                      child: Container(color: AZColors.green),
                    ),
                    Positioned(
                      left: p.x * w,
                      top: (p.gapCenter + _gapHalf) * h,
                      width: _pipeWidth * w,
                      height: h - (p.gapCenter + _gapHalf) * h,
                      child: Container(color: AZColors.green),
                    ),
                  ],
                  if (!_started)
                    Center(
                      child: AZFrostCard(
                        child: Column(mainAxisSize: MainAxisSize.min, children: const [
                          Text('Başlamak için dokun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  if (_over)
                    Center(
                      child: AZFrostCard(
                        child: Text('Çarptın! 💥  Skor: $_score',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 8),
      const Text('Ekrana dokun, zıpla!', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}
