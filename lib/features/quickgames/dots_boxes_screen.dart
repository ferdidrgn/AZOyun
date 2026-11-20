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
          QPTurnBadgeRow(
            players: widget.players,
            scores: _scores,
            turn: _turn,
            activeTextColor: AZColors.blueDk,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: _box,
            height: _edgeThickness,
            decoration: _edgeDecoration(_h[r][c]),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: _edgeThickness,
              height: _box,
              decoration: _edgeDecoration(_v[r][c]),
            ),
          ));
          if (c < _cols) {
            final owner = _owner[r][c];
            edgeRow.add(AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: _box,
              height: _box,
              alignment: Alignment.center,
              decoration: owner == null
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x1420140D), Color(0x3320140D)],
                      ),
                      border: Border.all(color: Colors.white.withAlpha(20), width: .6),
                    )
                  : BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kPlayerColors[owner % kPlayerColors.length].withAlpha(205),
                          kPlayerColors[owner % kPlayerColors.length].withAlpha(125),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withAlpha(110),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPlayerColors[owner % kPlayerColors.length]
                              .withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
              child: owner == null
                  ? null
                  : Text(widget.players[owner].name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 5, offset: Offset(0, 2)),
                        ],
                      )),
            ));
          }
        }
        rowsWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: edgeRow));
      }
    }
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateX(-0.075),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          border: Border.all(color: const Color(0xFFD9AD75), width: 1.2),
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
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0x88351F11), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(mainAxisSize: MainAxisSize.min, children: rowsWidgets),
          ),
        ),
      ),
    );
  }

  BoxDecoration _edgeDecoration(bool active) => BoxDecoration(
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF6D9), Color(0xFFD7B976), Color(0xFF8B6333)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x665B4B37), Color(0x44372C21), Color(0x6635281C)],
              ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: active ? const Color(0xFFFFE7A4) : const Color(0x555C4A35),
          width: active ? 1 : .6,
        ),
        boxShadow: active
            ? const [
                BoxShadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 2)),
                BoxShadow(color: Color(0x66FFF0C3), blurRadius: 4),
              ]
            : const [
                BoxShadow(color: Color(0x55000000), blurRadius: 2, offset: Offset(0, 1)),
              ],
      );

  Widget _dotWidget() => Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-.35, -.4),
            colors: [Color(0xFFFFFFFF), Color(0xFFD9C5A3), Color(0xFF7E5835)],
          ),
          border: Border.all(color: const Color(0xFFFFF0D1), width: .7),
          boxShadow: const [
            BoxShadow(color: Color(0xAA000000), blurRadius: 3, offset: Offset(0, 2)),
            BoxShadow(color: Color(0x55FFFFFF), blurRadius: 2, offset: Offset(-1, -1)),
          ],
        ),
      );
}
