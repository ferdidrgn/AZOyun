import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

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
  int _left = 20;
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
    _move = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _cell = _rng.nextInt(9));
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      _left--;
      if (_left <= 0) {
        _move?.cancel();
        _clock?.cancel();
        widget.onFinished(_score);
        return;
      }
      setState(() {});
    });
  }

  void _tap(int index) {
    if (!_started) {
      return;
    }
    if (index == _cell) {
      setState(() {
        _score++;
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
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: AZSpacing.sm,
            crossAxisSpacing: AZSpacing.sm,
            childAspectRatio: 1.2,
            children: [
              for (var i = 0; i < 9; i++)
                FilledButton(
                  onPressed: () => _tap(i),
                  style: FilledButton.styleFrom(
                    backgroundColor: i == _cell && _started ? AZColors.orange : Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(i == _cell && _started ? '🐵' : '', style: const TextStyle(fontSize: 32)),
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
