import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class DotsBoxesLobbyScreen extends StatelessWidget {
  const DotsBoxesLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Çizgi Doldurma',
        emoji: '📦',
        gradient: AZColors.gradCyan,
        minPlayers: 2,
        maxPlayers: 4,
        instructions:
            'Sırayla iki nokta arasına çizgi çek. Bir kutunun 4 kenarını da '
            'tamamlayan o kutuyu kazanır ve tekrar oynar. En çok kutusu olan kazanır!',
      );
}

class DotsBoxesGameScreen extends StatefulWidget {
  const DotsBoxesGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<DotsBoxesGameScreen> createState() => _DotsBoxesGameScreenState();
}

class _DotsBoxesGameScreenState extends State<DotsBoxesGameScreen> {
  static const _rows = 4; // kutu satırı
  static const _cols = 4; // kutu sütunu
  static const _dot = 12.0;
  static const _box = 58.0;
  static const _edgeThickness = 12.0;

  // h[r][c]: r 0.._rows, c 0.._cols-1
  late List<List<bool>> _h;
  // v[r][c]: r 0.._rows-1, c 0.._cols
  late List<List<bool>> _v;
  late List<List<int?>> _owner;
  late List<int> _scores;
  int _turn = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _h = List.generate(_rows + 1, (_) => List<bool>.filled(_cols, false));
      _v = List.generate(_rows, (_) => List<bool>.filled(_cols + 1, false));
      _owner = List.generate(_rows, (_) => List<int?>.filled(_cols, null));
      _scores = List.filled(widget.players.length, 0);
      _turn = 0;
    });
  }

  bool _boxComplete(int r, int c) =>
      _h[r][c] && _h[r + 1][c] && _v[r][c] && _v[r][c + 1];

  void _checkBoxesAround({required bool horizontal, required int r, required int c}) {
    var completedAny = false;
    final candidates = <List<int>>[];
    if (horizontal) {
      if (r < _rows) candidates.add([r, c]); // alttaki kutu
      if (r > 0) candidates.add([r - 1, c]); // üstteki kutu
    } else {
      if (c < _cols) candidates.add([r, c]); // sağdaki kutu
      if (c > 0) candidates.add([r, c - 1]); // soldaki kutu
    }
    for (final box in candidates) {
      final br = box[0], bc = box[1];
      if (_owner[br][bc] == null && _boxComplete(br, bc)) {
        _owner[br][bc] = _turn;
        _scores[_turn]++;
        completedAny = true;
      }
    }
    if (_owner.expand((row) => row).every((o) => o != null)) {
      _finish();
      return;
    }
    if (!completedAny) {
      _turn = (_turn + 1) % widget.players.length;
    }
  }

  void _tapH(int r, int c) {
    if (_h[r][c]) return;
    setState(() {
      _h[r][c] = true;
      _checkBoxesAround(horizontal: true, r: r, c: c);
    });
  }

  void _tapV(int r, int c) {
    if (_v[r][c]) return;
    setState(() {
      _v[r][c] = true;
      _checkBoxesAround(horizontal: false, r: r, c: c);
    });
  }

  Future<void> _finish() async {
    final maxScore = _scores.reduce(max);
    final winnerIdxs = [
      for (var i = 0; i < _scores.length; i++)
        if (_scores[i] == maxScore) i
    ];
    final draw = winnerIdxs.length != 1;
    final winner = draw ? null : widget.players[winnerIdxs.first];
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'dotsboxes',
      resultTitle: draw ? 'Berabere! 🤝' : '${winner!.name} kazandı! 🎉',
      resultMessage: draw ? 'Kutular eşit paylaşıldı.' : '${winner!.name} $maxScore kutu kazandı!',
      humanWon: !draw,
      onRematch: _reset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradCyan,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'Çizgi Doldurma'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < widget.players.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == _turn
                        ? Colors.white
                        : kPlayerColors[i % kPlayerColors.length].withAlpha(80),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${widget.players[i].name}: ${_scores[i]}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: i == _turn ? AZColors.blueDk : Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: Center(child: _buildGrid())),
        ]),
      ),
    );
  }

  Widget _buildGrid() {
    final rowsWidgets = <Widget>[];
    for (var r = 0; r <= _rows; r++) {
      // nokta satırı + yatay kenarlar
      final dotRow = <Widget>[];
      for (var c = 0; c < _cols; c++) {
        dotRow.add(_dotWidget());
        dotRow.add(GestureDetector(
          onTap: () => _tapH(r, c),
          child: Container(
            width: _box,
            height: _edgeThickness,
            color: _h[r][c] ? Colors.white : const Color(0x33FFFFFF),
          ),
        ));
      }
      dotRow.add(_dotWidget());
      rowsWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: dotRow));

      if (r < _rows) {
        final edgeRow = <Widget>[];
        for (var c = 0; c <= _cols; c++) {
          edgeRow.add(GestureDetector(
            onTap: () => _tapV(r, c),
            child: Container(
              width: _edgeThickness,
              height: _box,
              color: _v[r][c] ? Colors.white : const Color(0x33FFFFFF),
            ),
          ));
          if (c < _cols) {
            final owner = _owner[r][c];
            edgeRow.add(Container(
              width: _box,
              height: _box,
              alignment: Alignment.center,
              color: owner == null
                  ? Colors.transparent
                  : kPlayerColors[owner % kPlayerColors.length].withAlpha(140),
              child: owner == null
                  ? null
                  : Text(widget.players[owner].name.substring(0, 1),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ));
          }
        }
        rowsWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: edgeRow));
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rowsWidgets);
  }

  Widget _dotWidget() => Container(
        width: _dot,
        height: _dot,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
}
