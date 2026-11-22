import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'reversi_rules.dart';

class ReversiLobbyScreen extends StatelessWidget {
  const ReversiLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Reversi',
        emoji: '⚫⚪',
        gradient: AZColors.gradGreen,
        minPlayers: 2,
        maxPlayers: 2,
        allowAI: true,
        instructions:
            'Taşını rakip taşların arasına koyarak onları kendi rengine çevir. '
            'Tahtada en çok taşı olan kazanır!',
      );
}

const _kWeights = [
  [100, -20, 10, 5, 5, 10, -20, 100],
  [-20, -50, -2, -2, -2, -2, -50, -20],
  [10, -2, -1, -1, -1, -1, -2, 10],
  [5, -2, -1, -1, -1, -1, -2, 5],
  [5, -2, -1, -1, -1, -1, -2, 5],
  [10, -2, -1, -1, -1, -1, -2, 10],
  [-20, -50, -2, -2, -2, -2, -50, -20],
  [100, -20, 10, 5, 5, 10, -20, 100],
];

class ReversiGameScreen extends StatefulWidget {
  const ReversiGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<ReversiGameScreen> createState() => _ReversiGameScreenState();
}

class _ReversiGameScreenState extends State<ReversiGameScreen> {
  static const _n = reversiBoardSize;
  late List<int> _board;
  int _turn = 0;
  bool _busy = false;
  bool _gameOver = false;
  final _rng = Random();

  QPPlayer get _current => widget.players[_turn];
  int _mark(int idx) => idx == 0 ? reversiBlack : reversiWhite;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = reversiInitialBoard();
    _turn = 0;
    _busy = false;
    _gameOver = false;
    if (mounted) setState(() {});
    _maybeLetAIPlay();
  }

  Future<void> _tap(int r, int c) async {
    if (_busy || _gameOver || _current.isAI) return;
    final me = _mark(_turn);
    final next = reversiApplyMove(_board, r * _n + c, me);
    if (next == null) return;
    setState(() => _board = next);
    await _afterMove();
  }

  Future<void> _afterMove() async {
    final nextIdx = 1 - _turn;
    final next = reversiNextSide(_board, _mark(_turn));
    if (next == _mark(nextIdx)) {
      setState(() => _turn = nextIdx);
      _maybeLetAIPlay();
      return;
    }
    if (next == _mark(_turn)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${widget.players[nextIdx].name} hamle yapamıyor, sıra atlandı'),
          duration: const Duration(seconds: 2),
        ));
      }
      _maybeLetAIPlay();
      return;
    }
    await _finish();
  }

  void _maybeLetAIPlay() {
    if (_gameOver || !_current.isAI) return;
    setState(() => _busy = true);
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final me = _mark(_turn);
      final moves =
          reversiLegalMoves(_board, me).map((i) => [i ~/ _n, i % _n]).toList();
      if (moves.isEmpty) {
        setState(() => _busy = false);
        await _afterMove();
        return;
      }
      var bestScore = -100000;
      var candidates = <List<int>>[];
      for (final m in moves) {
        final flips = reversiFlips(_board, m[0] * _n + m[1], me);
        final score = _kWeights[m[0]][m[1]] + flips.length * 2;
        if (score > bestScore) {
          bestScore = score;
          candidates = [m];
        } else if (score == bestScore) {
          candidates.add(m);
        }
      }
      final chosen = candidates[_rng.nextInt(candidates.length)];
      setState(() {
        _board = reversiApplyMove(_board, chosen[0] * _n + chosen[1], me)!;
        _busy = false;
      });
      await _afterMove();
    });
  }

  Future<void> _finish() async {
    setState(() {
      _gameOver = true;
      _busy = true;
    });
    final outcome = reversiOutcome(_board)!;
    final blackCount = outcome['black']!;
    final whiteCount = outcome['white']!;
    final draw = outcome['winner'] == reversiEmpty;
    final winnerIdx = draw ? null : (outcome['winner'] == reversiBlack ? 0 : 1);
    final winner = draw ? null : widget.players[winnerIdx!];
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'reversi',
      resultTitle: draw ? 'Berabere! 🤝' : '${winner!.name} kazandı! 🎉',
      resultMessage: '⚫ $blackCount  —  $whiteCount ⚪',
      humanWon: !draw && !winner!.isAI,
      onRematch: _reset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final validForCurrent =
        _current.isAI ? const <int>[] : reversiLegalMoves(_board, _mark(_turn));
    final blackCount = _board.where((cell) => cell == reversiBlack).length;
    final whiteCount = _board.where((cell) => cell == reversiWhite).length;

    return AZGradientScaffold(
      gradient: AZColors.gradGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'Reversi'),
          const SizedBox(height: 12),
          AZFrostCard(
            child: Column(children: [
              Text(
                _gameOver ? 'Oyun bitti' : '${_current.name} sırası',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text('⚫ $blackCount   ⚪ $whiteCount',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFB9844B),
                        Color(0xFF704322),
                        Color(0xFF3D2619),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: const Color(0xFFD9AD75), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x99000000),
                        blurRadius: 20,
                        offset: Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Color(0x44FFE0AF),
                        blurRadius: 8,
                        offset: Offset(-3, -3),
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF242019),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color(0x88351F11), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _n * _n,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _n,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemBuilder: (_, i) {
                          final r = i ~/ _n;
                          final c = i % _n;
                          final v = _board[i];
                          final isHint = validForCurrent.contains(i);
                          return GestureDetector(
                            onTap: () => _tap(r, c),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF36765B),
                                    Color(0xFF1D4F3C)
                                  ],
                                ),
                                border: Border.all(
                                    color: Colors.black.withAlpha(38),
                                    width: .6),
                              ),
                              child: Center(
                                child: v != reversiEmpty
                                    ? _ReversiDisk(black: v == reversiBlack)
                                    : (isHint
                                        ? Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFFD5F5E0)
                                                  .withAlpha(180),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x77000000),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          )
                                        : null),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReversiDisk extends StatelessWidget {
  const _ReversiDisk({required this.black});

  final bool black;

  @override
  Widget build(BuildContext context) {
    final edge = black ? const Color(0xFF050A0B) : const Color(0xFF9FA7A2);
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.35, -.4),
          radius: .92,
          colors: black
              ? const [Color(0xFF626F71), Color(0xFF242D2F), Color(0xFF080D0E)]
              : const [Color(0xFFFFFFFF), Color(0xFFE4E7E0), Color(0xFFB7BEB8)],
        ),
        border: Border.all(color: edge, width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x44FFFFFF),
            blurRadius: 2,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                (black ? Colors.white : const Color(0xFF596460)).withAlpha(60),
            width: .8,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(black ? 44 : 100),
              Colors.transparent,
              Colors.black.withAlpha(black ? 80 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
