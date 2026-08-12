import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class ConnectFourLobbyScreen extends StatelessWidget {
  const ConnectFourLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: "4'lü Bağlantı",
        emoji: '🔴🟡',
        gradient: AZColors.gradBlue,
        minPlayers: 2,
        maxPlayers: 2,
        allowAI: true,
        instructions:
            'Sırayla bir sütuna disk bırak. Yatay, dikey ya da çapraz '
            '4 diski yan yana dizen kazanır!',
      );
}

class ConnectFourGameScreen extends StatefulWidget {
  const ConnectFourGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<ConnectFourGameScreen> createState() => _ConnectFourGameScreenState();
}

class _ConnectFourGameScreenState extends State<ConnectFourGameScreen> {
  static const _rows = 6;
  static const _cols = 7;
  static const _colWeights = [3, 4, 5, 7, 5, 4, 3];

  late List<List<String?>> _board;
  int _turn = 0;
  bool _busy = false;
  String? _winnerMark;
  final _rng = Random();

  QPPlayer get _current => widget.players[_turn];
  String _mark(int idx) => idx == 0 ? 'R' : 'Y';
  Color _color(String mark) => mark == 'R' ? const Color(0xFFE53935) : const Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(_rows, (_) => List<String?>.filled(_cols, null));
    _turn = 0;
    _winnerMark = null;
    _busy = false;
    if (mounted) setState(() {});
    _maybeLetAIPlay();
  }

  int? _dropRow(List<List<String?>> b, int col) {
    for (var r = _rows - 1; r >= 0; r--) {
      if (b[r][col] == null) return r;
    }
    return null;
  }

  String? _checkWinner(List<List<String?>> b) {
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final v = b[r][c];
        if (v == null) continue;
        if (c + 3 < _cols && v == b[r][c + 1] && v == b[r][c + 2] && v == b[r][c + 3]) return v;
        if (r + 3 < _rows && v == b[r + 1][c] && v == b[r + 2][c] && v == b[r + 3][c]) return v;
        if (r + 3 < _rows && c + 3 < _cols && v == b[r + 1][c + 1] && v == b[r + 2][c + 2] && v == b[r + 3][c + 3]) return v;
        if (r + 3 < _rows && c - 3 >= 0 && v == b[r + 1][c - 1] && v == b[r + 2][c - 2] && v == b[r + 3][c - 3]) return v;
      }
    }
    return null;
  }

  bool _isFull(List<List<String?>> b) => b[0].every((c) => c != null);

  Future<void> _drop(int col) async {
    if (_busy || _winnerMark != null) return;
    final row = _dropRow(_board, col);
    if (row == null) return;
    setState(() => _board[row][col] = _mark(_turn));
    await _afterMove();
  }

  Future<void> _afterMove() async {
    final winner = _checkWinner(_board);
    if (winner != null) {
      setState(() => _winnerMark = winner);
      await _finish(winnerMark: winner);
      return;
    }
    if (_isFull(_board)) {
      await _finish(winnerMark: null);
      return;
    }
    setState(() => _turn = 1 - _turn);
    _maybeLetAIPlay();
  }

  void _maybeLetAIPlay() {
    if (!_current.isAI || _winnerMark != null) return;
    setState(() => _busy = true);
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final col = _pickAiColumn();
      final row = _dropRow(_board, col);
      setState(() {
        if (row != null) _board[row][col] = _mark(_turn);
        _busy = false;
      });
      await _afterMove();
    });
  }

  List<int> _validColumns(List<List<String?>> b) =>
      [for (var c = 0; c < _cols; c++) if (b[0][c] == null) c];

  int _pickAiColumn() {
    final me = _mark(_turn);
    final opp = _mark(1 - _turn);
    final valid = _validColumns(_board);

    // 1) Kazanma hamlesi var mı?
    for (final c in valid) {
      final copy = _cloneBoard();
      final r = _dropRow(copy, c)!;
      copy[r][c] = me;
      if (_checkWinner(copy) == me) return c;
    }
    // 2) Rakibin kazanma hamlesini engelle.
    for (final c in valid) {
      final copy = _cloneBoard();
      final r = _dropRow(copy, c)!;
      copy[r][c] = opp;
      if (_checkWinner(copy) == opp) return c;
    }
    // 3) Rakibe kazandırmayan sütunlar arasından merkeze yakın olanı seç.
    final safe = <int>[];
    for (final c in valid) {
      final copy = _cloneBoard();
      final r = _dropRow(copy, c)!;
      copy[r][c] = me;
      final oppValid = _validColumns(copy);
      var givesOppWin = false;
      for (final oc in oppValid) {
        final copy2 = List.generate(_rows, (i) => List<String?>.from(copy[i]));
        final or = _dropRow(copy2, oc)!;
        copy2[or][oc] = opp;
        if (_checkWinner(copy2) == opp) {
          givesOppWin = true;
          break;
        }
      }
      if (!givesOppWin) safe.add(c);
    }
    final pool = safe.isNotEmpty ? safe : valid;
    pool.sort((a, b) => _colWeights[b].compareTo(_colWeights[a]));
    final topWeight = _colWeights[pool.first];
    final best = pool.where((c) => _colWeights[c] == topWeight).toList();
    return best[_rng.nextInt(best.length)];
  }

  List<List<String?>> _cloneBoard() =>
      List.generate(_rows, (i) => List<String?>.from(_board[i]));

  Future<void> _finish({String? winnerMark}) async {
    _busy = true;
    final draw = winnerMark == null;
    final winnerIndex = draw ? null : (winnerMark == 'R' ? 0 : 1);
    final winner = draw ? null : widget.players[winnerIndex!];
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'connect4',
      resultTitle: draw ? 'Berabere! 🤝' : '${winner!.name} kazandı! 🎉',
      resultMessage: draw ? 'Tahta doldu, kazanan yok.' : '${winner!.name} 4\'lü yaptı!',
      humanWon: !draw && !winner!.isAI,
      onRematch: _reset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradBlue,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: "4'lü Bağlantı"),
          const SizedBox(height: 12),
          AZFrostCard(
            child: Text(
              _winnerMark != null || _isFull(_board)
                  ? 'Oyun bitti'
                  : '${_current.name} sırası',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var c = 0; c < _cols; c++)
                Expanded(
                  child: IconButton(
                    onPressed: (_busy || _winnerMark != null || _board[0][c] != null)
                        ? null
                        : () => _drop(c),
                    icon: const Icon(Icons.arrow_downward_rounded),
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(AZRadius.md),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rows * _cols,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols, crossAxisSpacing: 4, mainAxisSpacing: 4),
                itemBuilder: (_, i) {
                  final r = i ~/ _cols;
                  final c = i % _cols;
                  final v = _board[r][c];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: v == null
                        ? null
                        : Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: _color(v), shape: BoxShape.circle),
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
