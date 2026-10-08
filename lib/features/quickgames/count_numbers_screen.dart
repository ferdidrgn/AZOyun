import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class CountNumbersLobbyScreen extends StatelessWidget {
  const CountNumbersLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Sayı Say',
        emoji: '1️⃣',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Yıldızları say ve doğru sayıyı seç. Sekiz tur.',
      );
}

class CountNumbersGameScreen extends StatelessWidget {
  const CountNumbersGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'count123',
        gradient: AZColors.gradCyan,
        title: 'Sayı Say',
        emoji: '1️⃣',
        sessionBuilder: (context, player, onFinished) =>
            _CountSession(player: player, onFinished: onFinished),
      );
}

class _CountSession extends StatefulWidget {
  const _CountSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_CountSession> createState() => _CountSessionState();
}

class _Round {
  _Round(this.count, this.options);
  final int count;
  final List<int> options;
}

class _CountSessionState extends State<_CountSession> {
  final _rng = Random();
  late final List<_Round> _rounds = List.generate(8, (_) => _make());
  int _index = 0;
  int _score = 0;

  _Round _make() {
    final count = _rng.nextInt(8) + 1;
    final options = <int>{count};
    while (options.length < 4) {
      final next = _rng.nextInt(9) + 1;
      options.add(next);
    }
    return _Round(count, options.toList()..shuffle(_rng));
  }

  void _pick(int value) {
    if (value == _rounds[_index].count) {
      _score += 10;
    }
    if (_index == _rounds.length - 1) {
      widget.onFinished(_score);
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  ${_index + 1}/8  $_score puan',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AZSpacing.sm,
          runSpacing: AZSpacing.sm,
          children: [
            for (var i = 0; i < round.count; i++)
              const Text('⭐', style: TextStyle(fontSize: 32)),
          ],
        ),
        const SizedBox(height: AZSpacing.lg),
        for (final option in round.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AZSpacing.sm),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => _pick(option),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AZColors.textPrimary,
                ),
                child: Text('$option', style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
      ],
    );
  }
}
