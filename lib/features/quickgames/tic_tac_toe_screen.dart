import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class TicTacToeLobbyScreen extends StatelessWidget {
  const TicTacToeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'XOX',
        emoji: '❌⭕',
        gradient: AZColors.gradPurple,
        minPlayers: 2,
        maxPlayers: 2,
        allowAI: true,
        instructions:
            'Sırayla kutucuklara işaretini koy. Yatay, dikey ya da çapraz '
            '3 tane yan yana dizen kazanır!',
      );
}

class TicTacToeGameScreen extends StatefulWidget {
  const TicTacToeGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<TicTacToeGameScreen> createState() => _TicTacToeGameScreenState();
}

class _TicTacToeGameScreenState extends State<TicTacToeGameScreen> {
  static const _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  late List<String?> _board;
  late int _turn; // 0 or 1
  bool _busy = false;
  List<int>? _winningLine;

  QPPlayer get _current => widget.players[_turn];
  String _mark(int playerIndex) => playerIndex == 0 ? 'X' : 'O';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List<String?>.filled(9, null);
    _turn = 0;
    _winningLine = null;
    _busy = false;
    if (mounted) setState(() {});
    _maybeLetAIPlay();
  }

  List<int>? _findWinningLine(List<String?> board) {
    for (final line in _lines) {
      final a = board[line[0]], b = board[line[1]], c = board[line[2]];
      if (a != null && a == b && b == c) return line;
    }
    return null;
  }

  bool _isFull(List<String?> board) => board.every((c) => c != null);

  Future<void> _play(int index) async {
    if (_busy || _board[index] != null || _winningLine != null) return;
    setState(() {
      _board[index] = _mark(_turn);
    });
    await _afterMove();
  }

  Future<void> _afterMove() async {
    final win = _findWinningLine(_board);
    if (win != null) {
      setState(() => _winningLine = win);
      await _finish(winnerIndex: _turn);
      return;
    }
    if (_isFull(_board)) {
      await _finish(winnerIndex: null);
      return;
    }
    setState(() => _turn = 1 - _turn);
    _maybeLetAIPlay();
  }

  void _maybeLetAIPlay() {
    if (!_current.isAI || _winningLine != null) return;
    setState(() => _busy = true);
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final move = _bestAiMove(_board, _mark(_turn), _mark(1 - _turn));
      setState(() {
        _board[move] = _mark(_turn);
        _busy = false;
      });
      await _afterMove();
    });
  }

  int _bestAiMove(List<String?> board, String me, String opp) {
    int bestScore = -999;
    int bestMove = board.indexWhere((c) => c == null);
    for (var i = 0; i < 9; i++) {
      if (board[i] != null) continue;
      final copy = List<String?>.from(board)..[i] = me;
      final score = _minimax(copy, 0, false, me, opp);
      if (score > bestScore) {
        bestScore = score;
        bestMove = i;
      }
    }
    return bestMove;
  }

  int _minimax(List<String?> board, int depth, bool maximizing, String me, String opp) {
    final win = _findWinningLine(board);
    if (win != null) {
      final winner = board[win[0]];
      if (winner == me) return 10 - depth;
      return depth - 10;
    }
    if (_isFull(board)) return 0;

    if (maximizing) {
      var best = -999;
      for (var i = 0; i < 9; i++) {
        if (board[i] != null) continue;
        final copy = List<String?>.from(board)..[i] = me;
        best = max(best, _minimax(copy, depth + 1, false, me, opp));
      }
      return best;
    } else {
      var best = 999;
      for (var i = 0; i < 9; i++) {
        if (board[i] != null) continue;
        final copy = List<String?>.from(board)..[i] = opp;
        best = min(best, _minimax(copy, depth + 1, true, me, opp));
      }
      return best;
    }
  }

  Future<void> _finish({int? winnerIndex}) async {
    _busy = true;
    final draw = winnerIndex == null;
    final winner = draw ? null : widget.players[winnerIndex];
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'tictactoe',
      resultTitle: draw ? 'Berabere! 🤝' : '${winner!.name} kazandı! 🎉',
      resultMessage: draw
          ? 'Tahta doldu, kazanan yok.'
          : '${winner!.name} 3 tane dizmeyi başardı.',
      humanWon: !draw && !winner!.isAI,
      onRematch: _reset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradPurple,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'XOX'),
          const SizedBox(height: 16),
          AZFrostCard(
            child: Text(
              _winningLine != null || _isFull(_board)
                  ? 'Oyun bitti'
                  : '${_current.name} sırası (${_mark(_turn)})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemBuilder: (_, i) {
                final mark = _board[i];
                final isWinCell = _winningLine?.contains(i) ?? false;
                return GestureDetector(
                  onTap: () => _play(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isWinCell
                          ? Colors.white
                          : const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(AZRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        mark ?? '',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: isWinCell
                              ? AZColors.purple
                              : (mark == 'X' ? Colors.white : AZColors.accentGoldSoft),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
