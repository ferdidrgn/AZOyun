import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class NimLobbyScreen extends StatelessWidget {
  const NimLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Taş Alma',
        emoji: '🪨',
        gradient: AZColors.gradDark,
        minPlayers: 2,
        maxPlayers: 2,
        allowAI: true,
        instructions:
            'Sırayla bir yığından istediğin kadar taş al (en az 1). '
            'Son taşı alan oyunu kazanır. Dikkat, basit ama kafa karıştırıcı!',
      );
}

class NimGameScreen extends StatefulWidget {
  const NimGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<NimGameScreen> createState() => _NimGameScreenState();
}

class _NimGameScreenState extends State<NimGameScreen> {
  static const _initialPiles = [3, 5, 7, 9];
  final _rng = Random();

  late List<int> _piles;
  int _turn = 0;
  bool _busy = false;
  bool _gameOver = false;

  QPPlayer get _current => widget.players[_turn];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _piles = List.of(_initialPiles);
      _turn = 0;
      _busy = false;
      _gameOver = false;
    });
    _maybeLetAIPlay();
  }

  void _takeFrom(int pileIndex, int newSize) {
    if (_busy || _gameOver || _current.isAI) return;
    if (newSize >= _piles[pileIndex]) return;
    setState(() => _piles[pileIndex] = newSize);
    _afterMove();
  }

  Future<void> _afterMove() async {
    if (_piles.every((p) => p == 0)) {
      await _finish(winnerIndex: _turn);
      return;
    }
    setState(() => _turn = 1 - _turn);
    _maybeLetAIPlay();
  }

  void _maybeLetAIPlay() {
    if (_gameOver || !_current.isAI) return;
    setState(() => _busy = true);
    Future.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final move = _pickAiMove(_piles);
      setState(() {
        _piles[move[0]] = move[1];
        _busy = false;
      });
      await _afterMove();
    });
  }

  List<int> _pickAiMove(List<int> piles) {
    if (_rng.nextDouble() < 0.8) {
      final nimSum = piles.reduce((a, b) => a ^ b);
      if (nimSum != 0) {
        for (var i = 0; i < piles.length; i++) {
          final target = piles[i] ^ nimSum;
          if (target < piles[i]) return [i, target];
        }
      }
    }
    final nonEmpty = [for (var i = 0; i < piles.length; i++) if (piles[i] > 0) i];
    final i = nonEmpty[_rng.nextInt(nonEmpty.length)];
    final newSize = _rng.nextInt(piles[i]);
    return [i, newSize];
  }

  Future<void> _finish({required int winnerIndex}) async {
    setState(() {
      _gameOver = true;
      _busy = true;
    });
    final winner = widget.players[winnerIndex];
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'nim',
      resultTitle: '${winner.name} kazandı! 🎉',
      resultMessage: 'Son taşı alan kazanır — ${winner.name} son taşı aldı!',
      humanWon: !winner.isAI,
      onRematch: _reset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'Taş Alma (Nim)'),
          const SizedBox(height: 12),
          AZFrostCard(
            child: Text(
              _gameOver ? 'Oyun bitti' : '${_current.name} sırası — bir yığından taş al',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _piles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, pi) {
                final size = _piles[pi];
                return AZFrostCard(
                  opacity: 0.08,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Yığın ${pi + 1}  ($size taş)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var j = 0; j < size; j++)
                          GestureDetector(
                            onTap: () => _takeFrom(pi, j),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFBCAAA4), shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
