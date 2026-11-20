import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class DicePartyLobbyScreen extends StatelessWidget {
  const DicePartyLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Parti Zarı',
        emoji: '🎲',
        gradient: AZColors.gradGreen,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            '5 zar, 3 atış hakkın var. İstediğin zarları tutup diğerlerini '
            'tekrar at. Aynı sayılardan oluşan setler bonus puan kazandırır. '
            'En yüksek puan kazanır!',
      );
}

int _diceScore(List<int> dice) {
  final counts = <int, int>{};
  for (final d in dice) {
    counts[d] = (counts[d] ?? 0) + 1;
  }
  final maxCount = counts.values.reduce(max);
  final sum = dice.reduce((a, b) => a + b);
  final bonus = switch (maxCount) {
    5 => 40,
    4 => 20,
    3 => 10,
    _ => 0,
  };
  return sum + bonus;
}

class DicePartyGameScreen extends StatelessWidget {
  const DicePartyGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'diceparty',
        gradient: AZColors.gradGreen,
        title: 'Parti Zarı',
        emoji: '🎲',
        formatScore: (s) => '$s puan',
        sessionBuilder: (context, player, onFinished) =>
            _DiceSession(player: player, onFinished: onFinished),
      );
}

class _DiceSession extends StatefulWidget {
  const _DiceSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_DiceSession> createState() => _DiceSessionState();
}

class _DiceSessionState extends State<_DiceSession> {
  final _rng = Random();
  final List<int> _dice = List.filled(5, 1);
  final List<bool> _held = List.filled(5, false);
  int _rollsLeft = 3;
  bool _rolledOnce = false;
  bool _finished = false;
  int _rollVersion = 0;

  void _roll() {
    if (_rollsLeft <= 0 || _finished) return;
    setState(() {
      for (var i = 0; i < 5; i++) {
        if (!_held[i]) _dice[i] = 1 + _rng.nextInt(6);
      }
      _rollsLeft--;
      _rolledOnce = true;
      _rollVersion++;
    });
    if (_rollsLeft <= 0) _finish();
  }

  void _toggleHold(int i) {
    if (!_rolledOnce || _rollsLeft <= 0 || _finished) return;
    setState(() => _held[i] = !_held[i]);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onFinished(_diceScore(_dice));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.player.name} · Atış hakkı: $_rollsLeft',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 8),
      const Text('Tutmak istediğin zarlara dokun', style: TextStyle(color: Colors.white60, fontSize: 12)),
      const Spacer(),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 5; i++)
            GestureDetector(
              onTap: () => _toggleHold(i),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('$_rollVersion-$i'),
                tween: Tween(begin: 0, end: pi * 4),
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeOutCubic,
                builder: (context, angle, child) => Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(sin(angle) * 0.12)
                    ..rotateY(cos(angle) * 0.12)
                    ..rotateZ(angle),
                  child: child,
                ),
                child: _DiceFace(value: _dice[i], held: _held[i]),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(_rolledOnce ? 'Tahmini puan: ${_diceScore(_dice)}' : ' ',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
      const Spacer(),
      AZButton(
        label: _rollsLeft > 0 ? 'ZAR AT ($_rollsLeft kaldı)' : 'PUANLANIYOR...',
        icon: Icons.casino_rounded,
        color: AZColors.greenDk,
        onPressed: _rollsLeft > 0 ? _roll : null,
      ),
      const SizedBox(height: 12),
      if (_rolledOnce && _rollsLeft > 0)
        TextButton(
          onPressed: _finish,
          child: const Text('BİTİR VE PUANLA', style: TextStyle(color: Colors.white70)),
        ),
      const SizedBox(height: 12),
    ]);
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value, required this.held});

  final int value;
  final bool held;

  static const _pipLayouts = <int, Set<int>>{
    1: {4},
    2: {0, 8},
    3: {0, 4, 8},
    4: {0, 2, 6, 8},
    5: {0, 2, 4, 6, 8},
    6: {0, 2, 3, 5, 6, 8},
  };

  @override
  Widget build(BuildContext context) => Container(
        width: 54,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: held
                ? const [Color(0xFFFFD078), Color(0xFFE58A23), Color(0xFFAC4B13)]
                : const [Color(0xFFFFFFFF), Color(0xFFF4F7F2), Color(0xFFCFD8CF)],
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: held ? const Color(0xFFFFE5A8) : const Color(0xFFFFFFFF),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 9,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: held ? const Color(0x77FFD06A) : const Color(0x88FFFFFF),
              blurRadius: 9,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: held ? const Color(0x22803A0B) : const Color(0x11728D76),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: held ? const Color(0x44FFF2C7) : const Color(0x55FFFFFF),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) => Center(
                child: (_pipLayouts[value] ?? _pipLayouts[1]!).contains(index)
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: held ? const Color(0xFF74320E) : AZColors.greenDk,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: held
                                  ? const Color(0x88FFE7B0)
                                  : const Color(0x66708070),
                              blurRadius: 2,
                              offset: const Offset(-1, -1),
                            ),
                            BoxShadow(
                              color: Colors.black.withAlpha(70),
                              blurRadius: 2,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
}
