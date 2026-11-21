import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'connect_four_rules.dart';

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
  static const _rows = connectFourRows;
  static const _cols = connectFourColumns;
  static const _colWeights = [3, 4, 5, 7, 5, 4, 3];

  late List<List<String?>> _board;
  int _turn = 0;
  bool _busy = false;
  String? _winnerMark;
  final _rng = Random();

  QPPlayer get _current => widget.players[_turn];
  String _mark(int idx) => idx == 0 ? 'R' : 'Y';
  Color _color(String mark) =>
      mark == 'R' ? AZColors.redDk : AZColors.accentGoldSoft;

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

  int? _dropRow(List<List<String?>> b, int col) =>
      connectFourDropRow(flattenConnectFourBoard(b), col);

  String? _checkWinner(List<List<String?>> b) =>
      connectFourOutcome(flattenConnectFourBoard(b)).winner;

  bool _isFull(List<List<String?>> b) =>
      connectFourOutcome(flattenConnectFourBoard(b)).draw;

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

  List<int> _validColumns(List<List<String?>> b) => [
        for (var c = 0; c < _cols; c++)
          if (b[0][c] == null) c
      ];

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
      resultMessage:
          draw ? 'Tahta doldu, kazanan yok.' : '${winner!.name} 4\'lü yaptı!',
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
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var c = 0; c < _cols; c++)
                Expanded(
                  child: IconButton(
                    onPressed:
                        (_busy || _winnerMark != null || _board[0][c] != null)
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
              child: Center(
                child: AspectRatio(
                  aspectRatio: _cols / _rows,
                  child: CustomPaint(
                    painter: _ConnectFourBoardPainter(
                      board: _board,
                      red: _color('R'),
                      gold: _color('Y'),
                    ),
                    child: const SizedBox.expand(),
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

class _ConnectFourBoardPainter extends CustomPainter {
  const _ConnectFourBoardPainter({
    required this.board,
    required this.red,
    required this.gold,
  });

  final List<List<String?>> board;
  final Color red;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 6;
    const cols = 7;
    final w = size.width;
    final h = size.height;

    // Narrow the far edge to give the board and its sockets depth without
    // changing the underlying row/column mapping or any game rule.
    Offset project(double u, double v) {
      final taper = .035 * (1 - v);
      return Offset(
          w * (.045 + taper + u * (.91 - taper * 2)), h * (.035 + v * .91));
    }

    Path boardPath(double inset, {double drop = 0}) {
      final points = [
        project(inset, inset).translate(0, drop),
        project(1 - inset, inset).translate(0, drop),
        project(1 - inset, 1 - inset).translate(0, drop),
        project(inset, 1 - inset).translate(0, drop),
      ];
      return Path()..addPolygon(points, true);
    }

    final face = boardPath(0);
    final rim = boardPath(.022);
    final inner = boardPath(.048);

    canvas.drawPath(
      boardPath(0, drop: h * .025),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF193E83), Color(0xFF091A44)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      face.shift(Offset(0, h * .012)),
      Paint()
        ..color = Colors.black.withAlpha(115)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8EC0FF), Color(0xFF397BE0), Color(0xFF174AAB)],
          stops: [0, .52, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      rim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F91F1), Color(0xFF1C58BC), Color(0xFF124091)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withAlpha(125),
    );

    canvas.save();
    canvas.clipPath(inner);
    canvas.drawPath(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF235EBE), Color(0xFF17499F), Color(0xFF10377D)],
        ).createShader(Offset.zero & size),
    );

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final u = (col + .5) / cols;
        final v = (row + .5) / rows;
        final center = project(u, v);
        final boardWidthAtDepth = .91 - .07 * (1 - v);
        final depthScale = .78 + v * .22;
        final radius = w / cols * boardWidthAtDepth * .38 * depthScale;
        final hole = Rect.fromCircle(center: center, radius: radius);

        // A shadowed, recessed well with a bright bevel around its edge.
        canvas.drawCircle(center.translate(0, radius * .14), radius * 1.08,
            Paint()..color = const Color(0xFF071D48).withAlpha(185));
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [const Color(0xFF06152F), const Color(0xFF0B2C65)],
            ).createShader(hole),
        );
        canvas.drawCircle(
          center,
          radius * .96,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * .085
            ..color = const Color(0xFF9EC9FF).withAlpha(165),
        );

        final mark = board[row][col];
        if (mark == null) continue;
        final color = mark == 'R' ? red : gold;
        final token = Rect.fromCircle(center: center, radius: radius * .8);
        final dark = Color.lerp(color, Colors.black, .25)!;

        canvas.drawCircle(
          center.translate(radius * .04, radius * .27),
          radius * .83,
          Paint()
            ..color = Colors.black.withAlpha(165)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(center.translate(0, radius * .1), radius * .84,
            Paint()..color = dark);
        canvas.drawCircle(
          center,
          radius * .8,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.42, -.52),
              radius: 1.1,
              colors: [Colors.white, color, dark],
              stops: const [0, .48, 1],
            ).createShader(token),
        );
        canvas.drawCircle(
          center,
          radius * .66,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * .055
            ..color = Colors.white.withAlpha(140),
        );
        canvas.drawCircle(
          center.translate(-radius * .24, -radius * .27),
          radius * .13,
          Paint()..color = Colors.white.withAlpha(205),
        );
      }
    }
    canvas.restore();

    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(170),
    );
  }

  // The game mutates the same nested board list on each move, so identity
  // comparison would miss updates. Repaint on every parent rebuild.
  @override
  bool shouldRepaint(covariant _ConnectFourBoardPainter oldDelegate) => true;
}
