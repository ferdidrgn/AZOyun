import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'nim_rules.dart';

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
        instructions: 'Sırayla bir yığından istediğin kadar taş al (en az 1). '
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
    final move = nimApplyMove(
      _piles,
      pileIndex: pileIndex,
      removeCount: _piles[pileIndex] - newSize,
    );
    setState(() => _piles = move.piles);
    _afterMove();
  }

  Future<void> _afterMove() async {
    if (nimIsFinished(_piles)) {
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
      final result = nimApplyMove(
        _piles,
        pileIndex: move[0],
        removeCount: _piles[move[0]] - move[1],
      );
      setState(() {
        _piles = result.piles;
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
    final nonEmpty = [
      for (var i = 0; i < piles.length; i++)
        if (piles[i] > 0) i
    ];
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
              _gameOver
                  ? 'Oyun bitti'
                  : '${_current.name} sırası — bir yığından taş al',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
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
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yığın ${pi + 1}  ($size taş)',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF473324), Color(0xFF281D18)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0x886B523A), width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x77000000),
                                blurRadius: 9,
                                offset: Offset(0, 5),
                              ),
                              BoxShadow(
                                color: Color(0x22FFE0B5),
                                blurRadius: 3,
                                offset: Offset(-1, -1),
                              ),
                            ],
                          ),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var j = 0; j < size; j++)
                                GestureDetector(
                                  onTap: () => _takeFrom(pi, j),
                                  child: const _NimStone(),
                                ),
                            ],
                          ),
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

class _NimStone extends StatelessWidget {
  const _NimStone();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-.38, -.42),
                  radius: .95,
                  colors: [
                    Color(0xFFF7ECE7),
                    Color(0xFFC9B4AD),
                    Color(0xFF8C7773),
                  ],
                  stops: [0, .58, 1],
                ),
                border: Border.all(color: const Color(0xFFE8D9D3), width: .9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Color(0x66FFFFFF),
                    blurRadius: 2,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 7,
              top: 5,
              child: Container(
                width: 8,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(175),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.white38, blurRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
