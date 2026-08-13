import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

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

const _kDirs = [
  [-1, -1], [-1, 0], [-1, 1],
  [0, -1], [0, 1],
  [1, -1], [1, 0], [1, 1],
];

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
  static const _n = 8;
  late List<List<String?>> _board;
  int _turn = 0;
  bool _busy = false;
  bool _gameOver = false;
  final _rng = Random();

  QPPlayer get _current => widget.players[_turn];
  String _mark(int idx) => idx == 0 ? 'B' : 'W';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(_n, (_) => List<String?>.filled(_n, null));
    _board[3][3] = 'W';
    _board[3][4] = 'B';
    _board[4][3] = 'B';
    _board[4][4] = 'W';
    _turn = 0;
    _busy = false;
    _gameOver = false;
    if (mounted) setState(() {});
    _maybeLetAIPlay();
  }

  List<List<int>> _flipsFor(List<List<String?>> b, int r, int c, String me, String opp) {
    if (b[r][c] != null) return const [];
    final flips = <List<int>>[];
    for (final d in _kDirs) {
      final dr = d[0], dc = d[1];
      var rr = r + dr, cc = c + dc;
      final line = <List<int>>[];
      while (rr >= 0 && rr < _n && cc >= 0 && cc < _n && b[rr][cc] == opp) {
        line.add([rr, cc]);
        rr += dr;
        cc += dc;
      }
      if (line.isNotEmpty && rr >= 0 && rr < _n && cc >= 0 && cc < _n && b[rr][cc] == me) {
        flips.addAll(line);
      }
    }
    return flips;
  }

  List<List<int>> _validMoves(List<List<String?>> b, String me) {
    final opp = me == 'B' ? 'W' : 'B';
    final moves = <List<int>>[];
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (b[r][c] != null) continue;
        if (_flipsFor(b, r, c, me, opp).isNotEmpty) moves.add([r, c]);
      }
    }
    return moves;
  }

  void _applyMove(List<List<String?>> b, int r, int c, String me, String opp) {
    final flips = _flipsFor(b, r, c, me, opp);
    b[r][c] = me;
    for (final f in flips) {
      b[f[0]][f[1]] = me;
    }
  }

  Future<void> _tap(int r, int c) async {
    if (_busy || _gameOver || _current.isAI) return;
    final me = _mark(_turn);
    final opp = _mark(1 - _turn);
    if (_flipsFor(_board, r, c, me, opp).isEmpty) return;
    setState(() => _applyMove(_board, r, c, me, opp));
    await _afterMove();
  }

  Future<void> _afterMove() async {
    final nextIdx = 1 - _turn;
    final nextMark = _mark(nextIdx);
    final myMark = _mark(_turn);

    if (_validMoves(_board, nextMark).isNotEmpty) {
      setState(() => _turn = nextIdx);
      _maybeLetAIPlay();
      return;
    }
    if (_validMoves(_board, myMark).isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.players[nextIdx].name} hamle yapamıyor, sıra atlandı'),
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
      final opp = _mark(1 - _turn);
      final moves = _validMoves(_board, me);
      if (moves.isEmpty) {
        setState(() => _busy = false);
        await _afterMove();
        return;
      }
      var bestScore = -100000;
      var candidates = <List<int>>[];
      for (final m in moves) {
        final flips = _flipsFor(_board, m[0], m[1], me, opp);
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
        _applyMove(_board, chosen[0], chosen[1], me, opp);
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
    var blackCount = 0, whiteCount = 0;
    for (final row in _board) {
      for (final cell in row) {
        if (cell == 'B') blackCount++;
        if (cell == 'W') whiteCount++;
      }
    }
    final draw = blackCount == whiteCount;
    final winnerIdx = draw ? null : (blackCount > whiteCount ? 0 : 1);
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
    final validForCurrent = _current.isAI ? const [] : _validMoves(_board, _mark(_turn));
    var blackCount = 0, whiteCount = 0;
    for (final row in _board) {
      for (final cell in row) {
        if (cell == 'B') blackCount++;
        if (cell == 'W') whiteCount++;
      }
    }

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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text('⚫ $blackCount   ⚪ $whiteCount',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _n * _n,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _n, crossAxisSpacing: 2, mainAxisSpacing: 2),
                itemBuilder: (_, i) {
                  final r = i ~/ _n;
                  final c = i % _n;
                  final v = _board[r][c];
                  final isHint = validForCurrent.any((m) => m[0] == r && m[1] == c);
                  return GestureDetector(
                    onTap: () => _tap(r, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        border: Border.all(color: Colors.black26, width: 0.5),
                      ),
                      child: Center(
                        child: v != null
                            ? Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: v == 'B' ? Colors.black : Colors.white,
                                ),
                              )
                            : (isHint
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withAlpha(120),
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
        ]),
      ),
    );
  }
}
