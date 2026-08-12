import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

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
  static const _sessionSeconds = 20;
  static const _balloonLifeMs = 1100;

  final _rng = Random();
  Timer? _countdown;
  Timer? _balloonTimer;
  int _secondsLeft = _sessionSeconds;
  int _score = 0;
  Offset _pos = const Offset(0.5, 0.5);
  bool _visible = false;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _end();
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
    if (!_visible || !_running) return;
    _balloonTimer?.cancel();
    setState(() {
      _score++;
      _visible = false;
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
                    child: const Text('🎈', style: TextStyle(fontSize: 56)),
                  ),
                ),
            ]),
          );
        }),
      ),
    ]);
  }
}
