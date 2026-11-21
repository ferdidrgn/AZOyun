import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'tic_tac_toe_rules.dart';

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

  Future<void> _play(int index) async {
    if (_busy || _board[index] != null || _winningLine != null) return;
    setState(() {
      _board[index] = _mark(_turn);
    });
    await _afterMove();
  }

  Future<void> _afterMove() async {
    final outcome = ticTacToeOutcome(_board);
    final win = outcome.winningLine;
    if (win != null) {
      setState(() => _winningLine = win);
      await _finish(winnerIndex: _turn);
      return;
    }
    if (outcome.draw) {
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

  int _minimax(
      List<String?> board, int depth, bool maximizing, String me, String opp) {
    final win = ticTacToeOutcome(board).winningLine;
    if (win != null) {
      final winner = board[win[0]];
      if (winner == me) return 10 - depth;
      return depth - 10;
    }
    if (ticTacToeOutcome(board).draw) return 0;

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
              _winningLine != null || ticTacToeOutcome(_board).draw
                  ? 'Oyun bitti'
                  : '${_current.name} sırası (${_mark(_turn)})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(-0.07),
                  child: Container(
                    padding: const EdgeInsets.all(10),
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFD9AD75), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xAA000000),
                          blurRadius: 24,
                          offset: Offset(0, 14),
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
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0x88351F11), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 9,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemBuilder: (_, i) {
                                    final mark = _board[i];
                                    final isWinCell =
                                        _winningLine?.contains(i) ?? false;
                                    return GestureDetector(
                                      onTap: () => _play(i),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        decoration: BoxDecoration(
                                          gradient: isWinCell
                                              ? const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFFFFFFFF),
                                                    Color(0xFFE7DDFB),
                                                    Color(0xFFCFC0EA),
                                                  ],
                                                )
                                              : const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0x463D314B),
                                                    Color(0x26302739),
                                                  ],
                                                ),
                                          borderRadius: BorderRadius.circular(
                                              AZRadius.md),
                                          border: Border.all(
                                            color: isWinCell
                                                ? const Color(0xFFDCCBFF)
                                                : const Color(0x558B79A8),
                                            width: isWinCell ? 1.5 : .8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isWinCell
                                                  ? const Color(0xAA9C79E7)
                                                  : const Color(0x44000000),
                                              blurRadius: isWinCell ? 14 : 5,
                                              offset: const Offset(0, 4),
                                            ),
                                            if (!isWinCell)
                                              const BoxShadow(
                                                color: Color(0x33FFFFFF),
                                                blurRadius: 2,
                                                offset: Offset(-1, -1),
                                              ),
                                          ],
                                        ),
                                        child: Center(
                                          child: mark == null
                                              ? null
                                              : _TicTacToeMark(
                                                  mark: mark,
                                                  winning: isWinCell,
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (_winningLine != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _WinningLinePainter(_winningLine!),
                                  ),
                                ),
                              ),
                          ],
                        ),
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

class _TicTacToeMark extends StatelessWidget {
  const _TicTacToeMark({required this.mark, required this.winning});

  final String mark;
  final bool winning;

  @override
  Widget build(BuildContext context) => Text(
        mark,
        style: TextStyle(
          fontSize: 52,
          height: 1,
          fontWeight: FontWeight.w900,
          color: winning
              ? AZColors.purple
              : mark == 'X'
                  ? Colors.white
                  : AZColors.accentGoldSoft,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(180),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
            Shadow(
              color: mark == 'X'
                  ? const Color(0x889D8CE0)
                  : const Color(0x88FFC857),
              blurRadius: winning ? 18 : 7,
              offset: const Offset(-1, -1),
            ),
            Shadow(
              color: Colors.white.withAlpha(winning ? 150 : 70),
              blurRadius: 2,
              offset: const Offset(-1, -2),
            ),
          ],
        ),
      );
}

class _WinningLinePainter extends CustomPainter {
  const _WinningLinePainter(this.line);

  final List<int> line;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    const gap = 8.0;
    final boardSize = size.width - inset * 2;
    final cellSize = (boardSize - gap * 2) / 3;
    Offset centerOf(int index) {
      final row = index ~/ 3;
      final column = index % 3;
      return Offset(
        inset + cellSize / 2 + column * (cellSize + gap),
        inset + cellSize / 2 + row * (cellSize + gap),
      );
    }

    final first = centerOf(line.first);
    final last = centerOf(line.last);
    final shadow = Paint()
      ..color = const Color(0xBB17131F)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawLine(first.translate(0, 3), last.translate(0, 3), shadow);

    final glow = Paint()
      ..color = const Color(0xCC80E6B0)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawLine(first, last, glow);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF2B2), Color(0xFF76E7A7), Color(0xFFF3D88A)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(first, last, linePaint);

    canvas.drawLine(
      first,
      last,
      Paint()
        ..color = Colors.white.withAlpha(210)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WinningLinePainter oldDelegate) =>
      oldDelegate.line != line;
}
