import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class SlidingPuzzleLobbyScreen extends StatelessWidget {
  const SlidingPuzzleLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Kayan Yapboz',
        emoji: '🧩',
        gradient: AZColors.gradBlue,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Boş kareye komşu bir taşa dokunarak kaydır. Sayıları 1\'den '
            '15\'e sırala! En az hamlede bitiren kazanır.',
      );
}

List<int> _neighborsOf(int pos) {
  final r = pos ~/ 4, c = pos % 4;
  final result = <int>[];
  if (r > 0) result.add(pos - 4);
  if (r < 3) result.add(pos + 4);
  if (c > 0) result.add(pos - 1);
  if (c < 3) result.add(pos + 1);
  return result;
}

List<int> _shuffledBoard(Random rng) {
  final board = List<int>.generate(16, (i) => (i + 1) % 16); // 1..15, 0
  var blank = 15;
  for (var i = 0; i < 150; i++) {
    final neighbors = _neighborsOf(blank);
    final swapWith = neighbors[rng.nextInt(neighbors.length)];
    final tmp = board[blank];
    board[blank] = board[swapWith];
    board[swapWith] = tmp;
    blank = swapWith;
  }
  return board;
}

class SlidingPuzzleGameScreen extends StatelessWidget {
  const SlidingPuzzleGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'slidingpuzzle',
        gradient: AZColors.gradBlue,
        title: 'Kayan Yapboz',
        emoji: '🧩',
        higherIsBetter: false,
        formatScore: (s) => '$s hamle',
        sessionBuilder: (context, player, onFinished) =>
            _PuzzleSession(player: player, onFinished: onFinished),
      );
}

class _PuzzleSession extends StatefulWidget {
  const _PuzzleSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_PuzzleSession> createState() => _PuzzleSessionState();
}

class _PuzzleSessionState extends State<_PuzzleSession> {
  final _rng = Random();
  late List<int> _board = _shuffledBoard(_rng);
  int _moves = 0;
  bool _finished = false;

  bool get _solved {
    for (var i = 0; i < 15; i++) {
      if (_board[i] != i + 1) return false;
    }
    return _board[15] == 0;
  }

  void _tap(int pos) {
    if (_finished) return;
    final blank = _board.indexOf(0);
    if (!_neighborsOf(blank).contains(pos)) return;
    setState(() {
      _board[blank] = _board[pos];
      _board[pos] = 0;
      _moves++;
    });
    if (_solved) {
      _finished = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onFinished(_moves);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.player.name} · Hamle: $_moves',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 20),
      Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(AZRadius.md)),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemBuilder: (_, i) {
                final v = _board[i];
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: v == 0 ? Colors.transparent : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: v == 0
                        ? null
                        : Text('$v',
                            style: const TextStyle(
                                color: AZColors.blueDk, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      if (_finished) ...[
        const SizedBox(height: 16),
        const Text('🎉 Çözüldü!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
      const SizedBox(height: 16),
    ]);
  }
}
