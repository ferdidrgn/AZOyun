import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class MathPuzzleLobbyScreen extends StatelessWidget {
  const MathPuzzleLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Matematik Bulmaca',
        emoji: '➗',
        gradient: AZColors.gradBlue,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'İşlemin sonucunu seç. Sekiz soru, her doğru 10 puan.',
      );
}

class _Sum {
  const _Sum(this.text, this.options, this.answer);
  final String text;
  final List<int> options;
  final int answer;
}

_Sum _make(Random rng) {
  final op = rng.nextInt(4);
  late int a;
  late int b;
  late int value;
  late String sign;
  switch (op) {
    case 0:
      a = rng.nextInt(40) + 1;
      b = rng.nextInt(40) + 1;
      value = a + b;
      sign = '+';
    case 1:
      a = rng.nextInt(40) + 10;
      b = rng.nextInt(a);
      value = a - b;
      sign = '−';
    case 2:
      a = rng.nextInt(11) + 2;
      b = rng.nextInt(11) + 2;
      value = a * b;
      sign = '×';
    default:
      b = rng.nextInt(9) + 2;
      value = rng.nextInt(10) + 2;
      a = b * value;
      sign = '÷';
  }
  final options = <int>{value};
  while (options.length < 4) {
    options.add(value + rng.nextInt(11) - 5);
  }
  final list = options.toList()..shuffle(rng);
  return _Sum('$a $sign $b', list, value);
}

class MathPuzzleGameScreen extends StatelessWidget {
  const MathPuzzleGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'mathpuzzle',
        gradient: AZColors.gradBlue,
        title: 'Matematik Bulmaca',
        emoji: '➗',
        sessionBuilder: (context, player, onFinished) =>
            _MathSession(player: player, onFinished: onFinished),
      );
}

class _MathSession extends StatefulWidget {
  const _MathSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_MathSession> createState() => _MathSessionState();
}

class _MathSessionState extends State<_MathSession> {
  final List<_Sum> _items = List.generate(8, (_) => _make(Random()));
  int _index = 0;
  int _score = 0;

  void _pick(int value) {
    if (value == _items[_index].answer) {
      _score += 10;
    }
    if (_index == _items.length - 1) {
      widget.onFinished(_score);
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  ${_index + 1}/8  $_score puan',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.lg),
        Text(
          item.text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AZSpacing.lg),
        for (final option in item.options)
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
                child: Text('$option', style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
      ],
    );
  }
}
