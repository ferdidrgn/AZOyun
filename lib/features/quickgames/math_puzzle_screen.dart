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
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A78B8), Color(0xFF294E82), Color(0xFF1C355E)],
            ),
            borderRadius: BorderRadius.circular(AZRadius.lg),
            border: Border.all(color: Colors.white.withAlpha(100), width: 1.3),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 6)),
              BoxShadow(color: Color(0x334A9EFF), blurRadius: 10, offset: Offset(0, 1)),
            ],
          ),
          child: Text(
            '${widget.player.name}  ${_index + 1}/8  $_score puan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
        ),
        const SizedBox(height: AZSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween<double>(begin: .94, end: 1).animate(animation), child: child),
          ),
          child: Container(
            key: ValueKey(_index),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF477FBA), Color(0xFF24527F), Color(0xFF12344F)],
              ),
              borderRadius: BorderRadius.circular(AZRadius.lg),
              border: Border.all(color: Colors.white.withAlpha(130), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x77000000), blurRadius: 18, offset: Offset(0, 9)),
                BoxShadow(color: Color(0x443AABFF), blurRadius: 18, offset: Offset(0, 1)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 2,
                  right: 2,
                  top: -22,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withAlpha(34), Colors.transparent],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    item.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 7, offset: Offset(0, 3))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AZSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey('options-$_index'),
            children: [
              for (final option in item.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: AZSpacing.sm),
                  child: SizedBox(
                    height: 58,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF183759),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 9, offset: Offset(0, 5)),
                          BoxShadow(color: Color(0x443C9BE8), blurRadius: 8, offset: Offset(0, 1)),
                        ],
                      ),
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SizedBox.expand(
                        child: FilledButton(
                          onPressed: () => _pick(option),
                          style: FilledButton.styleFrom(
                            elevation: 3,
                            shadowColor: Colors.black54,
                            backgroundColor: const Color(0xFFF7FBFF),
                            foregroundColor: AZColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFB8DDF7), width: 1.2),
                            ),
                          ),
                          child: Text(
                            '$option',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
