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

  void _roll() {
    if (_rollsLeft <= 0 || _finished) return;
    setState(() {
      for (var i = 0; i < 5; i++) {
        if (!_held[i]) _dice[i] = 1 + _rng.nextInt(6);
      }
      _rollsLeft--;
      _rolledOnce = true;
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
              child: Container(
                width: 54,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: _held[i] ? AZColors.orange : Colors.white,
                  borderRadius: BorderRadius.circular(AZRadius.md),
                  border: _held[i] ? Border.all(color: Colors.white, width: 2) : null,
                ),
                alignment: Alignment.center,
                child: Text('${_dice[i]}',
                    style: TextStyle(
                        color: _held[i] ? Colors.white : AZColors.greenDk,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
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
