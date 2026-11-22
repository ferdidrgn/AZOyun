import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'snake_rules.dart';

class SnakeLobbyScreen extends StatelessWidget {
  const SnakeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Yılan',
        emoji: '🐍',
        gradient: AZColors.gradGreen,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Cihazı sırayla birbirinize verin, herkes bir kez oynar. '
            'Yemleri ye, duvara ya da kendine çarpma. En yüksek skor kazanır!',
      );
}

enum _Dir { up, down, left, right }

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  static const _gridSize = 14;
  final _rng = Random();

  late List<int> _scores;
  int _playerIndex = 0;
  bool _waitingHandoff = true;

  List<Point<int>> _snake = const [];
  Point<int>? _food;
  _Dir _dir = _Dir.right;
  _Dir _pendingDir = _Dir.right;
  Timer? _timer;
  int _score = 0;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _scores = List.filled(widget.players.length, 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    _snake = const [Point(6, 7), Point(5, 7), Point(4, 7)];
    _dir = _Dir.right;
    _pendingDir = _Dir.right;
    _score = 0;
    _over = false;
    _spawnFood();
    setState(() => _waitingHandoff = false);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _spawnFood() {
    final empty = [
      for (var x = 0; x < _gridSize; x++)
        for (var y = 0; y < _gridSize; y++)
          if (!_snake.contains(Point<int>(x, y))) Point<int>(x, y),
    ];
    _food = empty.isEmpty ? null : empty[_rng.nextInt(empty.length)];
  }

  void _setDir(_Dir d) {
    if (!canTurnSnake(_asSnakeDirection(_dir), _asSnakeDirection(d))) return;
    _pendingDir = d;
  }

  void _tick() {
    if (_over) return;
    _dir = _pendingDir;
    final result = stepSnake(
      snake: _snake.map((point) => (x: point.x, y: point.y)).toList(),
      direction: _asSnakeDirection(_dir),
      food: _food == null ? null : (x: _food!.x, y: _food!.y),
      size: _gridSize,
    );
    if (result.collided) {
      _endSession();
      return;
    }
    setState(() {
      _snake = result.snake.map((point) => Point(point.x, point.y)).toList();
      _score += result.score;
      if (result.ate) {
        _spawnFood();
        if (_food == null) {
          _timer?.cancel();
          _scores[_playerIndex] = _score;
          _over = true;
        }
      }
    });
  }

  SnakeDirection _asSnakeDirection(_Dir direction) => switch (direction) {
        _Dir.up => SnakeDirection.up,
        _Dir.down => SnakeDirection.down,
        _Dir.left => SnakeDirection.left,
        _Dir.right => SnakeDirection.right,
      };

  void _endSession() {
    _timer?.cancel();
    _scores[_playerIndex] = _score;
    setState(() => _over = true);
  }

  void _goNext() {
    if (_playerIndex < widget.players.length - 1) {
      setState(() {
        _playerIndex++;
        _waitingHandoff = true;
      });
    } else {
      _finishAll();
    }
  }

  Future<void> _finishAll() async {
    var bestScore = _scores[0];
    for (var i = 1; i < _scores.length; i++) {
      if (_scores[i] > bestScore) bestScore = _scores[i];
    }
    // Skoru en iyi olan TÜM oyuncular — birden fazlaysa gerçek bir berabere,
    // ilk sıradaki oyuncuyu "kazandı" ilan etmek yanlış olurdu.
    final bestIdxs = [
      for (var i = 0; i < _scores.length; i++) if (_scores[i] == bestScore) i
    ];
    final draw = bestIdxs.length > 1;
    final winner = draw ? null : widget.players[bestIdxs.first];
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'snake',
      resultTitle: draw ? 'Berabere! 🤝' : '${winner!.name} kazandı! 🏆',
      resultMessage: draw
          ? 'Birden fazla oyuncu $bestScore puan ile eşit skor yaptı.'
          : '${winner!.name}: $bestScore puan',
      humanWon: true,
      score: bestScore,
      scorerName: winner?.name,
      onRematch: () {
        setState(() {
          _playerIndex = 0;
          _waitingHandoff = true;
          _scores = List.filled(widget.players.length, 0);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final singlePlayer = widget.players.length == 1;
    return AZGradientScaffold(
      gradient: AZColors.gradGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'Yılan'),
          const SizedBox(height: 12),
          if (_waitingHandoff)
            _buildHandoff(singlePlayer)
          else
            Expanded(child: _buildPlaying()),
        ]),
      ),
    );
  }

  Widget _buildHandoff(bool singlePlayer) {
    final p = widget.players[_playerIndex];
    return Expanded(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🐍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(singlePlayer ? 'Hazır mısın?' : 'Sıra: ${p.name}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AZButton(
              label: 'BAŞLA',
              icon: Icons.play_arrow_rounded,
              color: AZColors.greenDk,
              onPressed: _startSession),
        ]),
      ),
    );
  }

  Widget _buildPlaying() {
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.players[_playerIndex].name}: $_score puan',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(AZRadius.md)),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AZRadius.md),
              child: CustomPaint(
                painter: _SnakeBoardPainter(
                  gridSize: _gridSize,
                  snake: _snake,
                  food: _food,
                  direction: _dir,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (_over)
        AZButton(
            label: 'DEVAM',
            icon: Icons.arrow_forward_rounded,
            color: AZColors.greenDk,
            onPressed: _goNext)
      else
        _buildDpad(),
    ]);
  }

  Widget _buildDpad() {
    Widget btn(IconData icon, _Dir d) => IconButton(
          onPressed: () => _setDir(d),
          icon: Icon(icon, color: Colors.white, size: 32),
        );
    return Column(children: [
      btn(Icons.keyboard_arrow_up_rounded, _Dir.up),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        btn(Icons.keyboard_arrow_left_rounded, _Dir.left),
        const SizedBox(width: 40),
        btn(Icons.keyboard_arrow_right_rounded, _Dir.right),
      ]),
      btn(Icons.keyboard_arrow_down_rounded, _Dir.down),
    ]);
  }
}

class _SnakeBoardPainter extends CustomPainter {
  const _SnakeBoardPainter({
    required this.gridSize,
    required this.snake,
    required this.food,
    required this.direction,
  });

  final int gridSize;
  final List<Point<int>> snake;
  final Point<int>? food;
  final _Dir direction;

  Offset _project(Size size, double x, double y) {
    final depth = .68 + (y / gridSize).clamp(0.0, 1.0).toDouble() * .38;
    return Offset(size.width * .5 + (x / gridSize - .5) * size.width * .96 * depth,
        size.height * (.025 + y / gridSize * .92));
  }

  Path _cellPath(Size size, int x, int y, {double inset = 0}) {
    return Path()
      ..moveTo(_project(size, x + inset, y + inset).dx,
          _project(size, x + inset, y + inset).dy)
      ..lineTo(_project(size, x + 1 - inset, y + inset).dx,
          _project(size, x + 1 - inset, y + inset).dy)
      ..lineTo(_project(size, x + 1 - inset, y + 1 - inset).dx,
          _project(size, x + 1 - inset, y + 1 - inset).dy)
      ..lineTo(_project(size, x + inset, y + 1 - inset).dx,
          _project(size, x + inset, y + 1 - inset).dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF133D35), Color(0xFF1B6249), Color(0xFF0D352C)],
    ).createShader(bounds));

    final topLeft = _project(size, 0, 0);
    final topRight = _project(size, gridSize.toDouble(), 0);
    final bottomLeft = _project(size, 0, gridSize.toDouble());
    final bottomRight = _project(size, gridSize.toDouble(), gridSize.toDouble());
    final shadow = Path()
      ..moveTo(topLeft.dx, topLeft.dy + 8)
      ..lineTo(topRight.dx, topRight.dy + 8)
      ..lineTo(bottomRight.dx, bottomRight.dy + 8)
      ..lineTo(bottomLeft.dx, bottomLeft.dy + 8)
      ..close();
    canvas.drawPath(shadow, Paint()..color = Colors.black.withAlpha(150)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    final side = Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomRight.dx + 2, bottomRight.dy + 9)
      ..lineTo(bottomLeft.dx - 2, bottomLeft.dy + 9)
      ..close();
    canvas.drawPath(side, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF0D392E), Color(0xFF071F1A)],
    ).createShader(bounds));

    final board = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.drawPath(board, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF267653), Color(0xFF164F3E), Color(0xFF0C3A2F)],
    ).createShader(bounds));
    canvas.save();
    canvas.clipPath(board);

    final snakePositions = <Point<int>, int>{};
    for (var i = 0; i < snake.length; i++) {
      snakePositions[snake[i]] = i;
    }
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final cell = _cellPath(size, x, y, inset: .055);
        final shade = (x + y).isEven ? 24 : 15;
        canvas.drawPath(cell, Paint()..color = Colors.white.withAlpha(shade));
        final cellRect = Rect.fromPoints(_project(size, x.toDouble(), y.toDouble()),
            _project(size, x + 1.0, y + 1.0));
        canvas.drawPath(cell, Paint()..color = Colors.white.withAlpha(13)
          ..style = PaintingStyle.stroke..strokeWidth = .7);

        final segment = snakePositions[Point(x, y)];
        if (segment != null) {
          final insetPath = _cellPath(size, x, y, inset: .13);
          canvas.drawPath(insetPath.shift(const Offset(1.4, 2.2)),
              Paint()..color = Colors.black.withAlpha(115));
          final head = segment == 0;
          final colors = head
              ? const [Color(0xFFE7FFF0), Color(0xFF93E9B0), Color(0xFF43AA70)]
              : const [Color(0xFF8CE2AA), Color(0xFF36A96F), Color(0xFF19744F)];
          canvas.drawPath(insetPath, Paint()..shader = LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: colors,
          ).createShader(cellRect));
          final first = _project(size, x + .18, y + .18);
          final second = _project(size, x + .78, y + .27);
          canvas.drawLine(first, second,
              Paint()..color = Colors.white.withAlpha(head ? 145 : 85)
            ..strokeWidth = max(1, cellRect.width * .08).toDouble());
          if (head) _drawEyes(canvas, size, x, y, cellRect);
        }

        if (food == Point(x, y)) _drawFood(canvas, size, x, y, cellRect);
      }
    }
    canvas.restore();

    final frame = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.drawPath(frame, Paint()..color = const Color(0xFFBCEFD0).withAlpha(170)
      ..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRect(bounds, Paint()..shader = RadialGradient(
      colors: [Colors.transparent, Colors.black.withAlpha(50)],
      stops: const [.55, 1],
    ).createShader(bounds));
  }

  void _drawEyes(Canvas canvas, Size size, int x, int y, Rect cellRect) {
    final center = _project(size, x + .5, y + .5);
    final eyeOffset = cellRect.width * .18;
    final eyeY = cellRect.height * .12;
    final positions = switch (direction) {
      _Dir.up => [Offset(-eyeOffset, -eyeY), Offset(eyeOffset, -eyeY)],
      _Dir.down => [Offset(-eyeOffset, eyeY), Offset(eyeOffset, eyeY)],
      _Dir.left => [Offset(-eyeY, -eyeOffset), Offset(-eyeY, eyeOffset)],
      _Dir.right => [Offset(eyeY, -eyeOffset), Offset(eyeY, eyeOffset)],
    };
    for (final offset in positions) {
      canvas.drawCircle(center.translate(offset.dx, offset.dy), max(1.2, cellRect.width * .07).toDouble(),
          Paint()..color = const Color(0xFF10251B));
      canvas.drawCircle(center.translate(offset.dx - .5, offset.dy - .5),
          max(.45, cellRect.width * .025).toDouble(), Paint()..color = Colors.white);
    }
  }

  void _drawFood(Canvas canvas, Size size, int x, int y, Rect cellRect) {
    final center = _project(size, x + .5, y + .5);
    final radius = min(cellRect.width, cellRect.height).toDouble() * .3;
    canvas.drawOval(Rect.fromCenter(center: center.translate(2, radius * .62),
        width: radius * 2.2, height: radius * .8),
      Paint()..color = Colors.black.withAlpha(125)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .35));
    canvas.drawCircle(center.translate(1.2, 1.8), radius,
      Paint()..color = const Color(0xFF9A3C19));
    canvas.drawCircle(center, radius, Paint()..shader = const RadialGradient(
      center: Alignment(-.38, -.48), radius: 1.05,
      colors: [Color(0xFFFFD28A), Color(0xFFFF8B35), Color(0xFFC94325)],
    ).createShader(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawArc(Rect.fromCircle(center: center.translate(0, radius * .12), radius: radius * .64),
        -2.7, 1.6, false, Paint()..color = Colors.white.withAlpha(190)
          ..style = PaintingStyle.stroke..strokeWidth = max(1, radius * .14).toDouble());
    final stem = Path()
      ..moveTo(center.dx, center.dy - radius * .82)
      ..quadraticBezierTo(center.dx + radius * .12, center.dy - radius * 1.5,
          center.dx + radius * .46, center.dy - radius * 1.34);
    canvas.drawPath(stem, Paint()..color = const Color(0xFF3A6E38)
      ..style = PaintingStyle.stroke..strokeWidth = max(1, radius * .17).toDouble()
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter oldDelegate) => true;
}

