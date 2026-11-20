import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

class PacMazeLobbyScreen extends StatelessWidget {
  const PacMazeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Pelet Labirenti',
        emoji: '😮',
        gradient: AZColors.gradBlue,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Oklarla yürü, noktaları topla, hayaletten kaç.',
      );
}

class PacMazeGameScreen extends StatelessWidget {
  const PacMazeGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'pacmaze',
        gradient: AZColors.gradBlue,
        title: 'Pelet Labirenti',
        emoji: '😮',
        formatScore: (score) => '$score pelet',
        sessionBuilder: (context, player, onFinished) =>
            _PacSession(player: player, onFinished: onFinished),
      );
}

class _PacSession extends StatefulWidget {
  const _PacSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_PacSession> createState() => _PacSessionState();
}

class _PacSessionState extends State<_PacSession> {
  static const _map = [
    '###########',
    '#.........#',
    '#.###.###.#',
    '#.#.....#.#',
    '#.#.###.#.#',
    '#...#.#...#',
    '#.###.#.#.#',
    '#.#...#.#.#',
    '#.###.###.#',
    '#.........#',
    '###########',
  ];

  late List<List<String>> _grid = [
    for (final row in _map) row.split(''),
  ];
  int _px = 1;
  int _py = 1;
  int _gx = 9;
  int _gy = 1;
  int _score = 0;
  bool _started = false;
  bool _over = false;
  Timer? _ghost;

  @override
  void initState() {
    super.initState();
    if (_grid[_py][_px] == '.') {
      _grid[_py][_px] = ' ';
    }
  }

  @override
  void dispose() {
    _ghost?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) {
      return;
    }
    setState(() => _started = true);
    _ghost = Timer.periodic(const Duration(milliseconds: 420), (_) => _haunt());
  }

  bool _wall(int x, int y) => _grid[y][x] == '#';

  void _step(int dx, int dy) {
    if (!_started || _over) {
      return;
    }
    final nx = _px + dx;
    final ny = _py + dy;
    if (_wall(nx, ny)) {
      return;
    }
    if (_grid[ny][nx] == '.') {
      _grid[ny][nx] = ' ';
      _score++;
    }
    _px = nx;
    _py = ny;
    if (_px == _gx && _py == _gy) {
      _finish();
      return;
    }
    if (!_grid.any((row) => row.contains('.'))) {
      _score += 20;
      _finish();
      return;
    }
    setState(() {});
  }

  void _haunt() {
    if (_over) {
      return;
    }
    final options = <(int, int)>[
      (_gx + 1, _gy),
      (_gx - 1, _gy),
      (_gx, _gy + 1),
      (_gx, _gy - 1),
    ].where((cell) => !_wall(cell.$1, cell.$2));
    if (options.isNotEmpty) {
      var best = options.first;
      var bestDist = 99;
      for (final cell in options) {
        final dist = (cell.$1 - _px).abs() + (cell.$2 - _py).abs();
        if (dist < bestDist) {
          bestDist = dist;
          best = cell;
        }
      }
      _gx = best.$1;
      _gy = best.$2;
    }
    if (_gx == _px && _gy == _py) {
      _finish();
      return;
    }
    setState(() {});
  }

  void _finish() {
    if (_over) {
      return;
    }
    _over = true;
    _ghost?.cancel();
    widget.onFinished(_score);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  $_score pelet',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _MazePainter(grid: _grid, px: _px, py: _py, gx: _gx, gy: _gy),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        if (!_started)
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AZColors.blueDk,
              ),
              child: const Text('Labirente gir'),
            ),
          )
        else
          Column(
            children: [
              _Pad(label: 'Yukarı', onPressed: () => _step(0, -1)),
              Row(
                children: [
                  Expanded(child: _Pad(label: 'Sol', onPressed: () => _step(-1, 0))),
                  const SizedBox(width: AZSpacing.sm),
                  Expanded(child: _Pad(label: 'Sağ', onPressed: () => _step(1, 0))),
                ],
              ),
              _Pad(label: 'Aşağı', onPressed: () => _step(0, 1)),
            ],
          ),
      ],
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AZColors.blueDk,
        ),
        child: Text(label),
      ),
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter({
    required this.grid,
    required this.px,
    required this.py,
    required this.gx,
    required this.gy,
  });

  final List<List<String>> grid;
  final int px;
  final int py;
  final int gx;
  final int gy;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = grid.length;
    final columns = grid.first.length;
    final top = size.height * .075;
    final floorHeight = size.height * .84;
    final cellHeight = floorHeight / rows;
    final centerX = size.width / 2;
    final farWidth = size.width * .57;
    final nearWidth = size.width * .94;

    double depth(double y) => (y / rows).clamp(0.0, 1.0).toDouble();
    double scaleAt(double y) => .62 + depth(y) * .38;

    Offset project(double x, double y, {double elevation = 0}) {
      final t = depth(y);
      final width = farWidth + (nearWidth - farWidth) * t;
      return Offset(
        centerX + (x / columns - .5) * width,
        top + floorHeight * t - elevation * cellHeight * scaleAt(y),
      );
    }

    Path cellPath(int x, int y, {double elevation = 0}) => Path()
      ..moveTo(project(x.toDouble(), y.toDouble(), elevation: elevation).dx,
          project(x.toDouble(), y.toDouble(), elevation: elevation).dy)
      ..lineTo(project((x + 1).toDouble(), y.toDouble(), elevation: elevation).dx,
          project((x + 1).toDouble(), y.toDouble(), elevation: elevation).dy)
      ..lineTo(project((x + 1).toDouble(), (y + 1).toDouble(), elevation: elevation).dx,
          project((x + 1).toDouble(), (y + 1).toDouble(), elevation: elevation).dy)
      ..lineTo(project(x.toDouble(), (y + 1).toDouble(), elevation: elevation).dx,
          project(x.toDouble(), (y + 1).toDouble(), elevation: elevation).dy)
      ..close();

    final backdrop = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF101927), Color(0xFF070C15)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backdrop);

    final boardPath = Path()
      ..moveTo(project(0, 0).dx, project(0, 0).dy)
      ..lineTo(project(columns.toDouble(), 0).dx, project(columns.toDouble(), 0).dy)
      ..lineTo(project(columns.toDouble(), rows.toDouble()).dx,
          project(columns.toDouble(), rows.toDouble()).dy)
      ..lineTo(project(0, rows.toDouble()).dx, project(0, rows.toDouble()).dy)
      ..close();
    canvas.drawPath(
      boardPath,
      Paint()
        ..color = const Color(0xFF13232E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Draw the walkable floor from the far edge toward the player.
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final isWall = grid[y][x] == '#';
        if (isWall) continue;
        canvas.drawPath(
          cellPath(x, y),
          Paint()
            ..color = (x + y).isEven
                ? const Color(0xFF142A36)
                : const Color(0xFF10232E),
        );
        canvas.drawPath(
          cellPath(x, y),
          Paint()
            ..color = const Color(0xFF6BA5B5).withAlpha(18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
      }
    }

    // Raised wall blocks: shadow, front face, side face, then illuminated top.
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        if (grid[y][x] != '#') continue;
        final base = [
          project(x.toDouble(), y.toDouble()),
          project((x + 1).toDouble(), y.toDouble()),
          project((x + 1).toDouble(), (y + 1).toDouble()),
          project(x.toDouble(), (y + 1).toDouble()),
        ];
        final lift = .48;
        final elevated = [
          project(x.toDouble(), y.toDouble(), elevation: lift),
          project((x + 1).toDouble(), y.toDouble(), elevation: lift),
          project((x + 1).toDouble(), (y + 1).toDouble(), elevation: lift),
          project(x.toDouble(), (y + 1).toDouble(), elevation: lift),
        ];
        Path polygon(List<Offset> points) => Path()
          ..moveTo(points.first.dx, points.first.dy)
          ..addPolygon(points.skip(1).toList(), true);

        canvas.drawPath(
          polygon(base),
          Paint()
            ..color = Colors.black.withAlpha(105)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawPath(
          polygon([base[3], base[2], elevated[2], elevated[3]]),
          Paint()..color = const Color(0xFF173E50),
        );
        canvas.drawPath(
          polygon([base[1], base[2], elevated[2], elevated[1]]),
          Paint()..color = const Color(0xFF0B202D),
        );
        canvas.drawPath(
          polygon(elevated),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FeltColors.feltDeep.withBlue(120),
                const Color(0xFF20536A),
              ],
            ).createShader(Rect.fromPoints(elevated[0], elevated[2])),
        );
        canvas.drawPath(
          polygon(elevated),
          Paint()
            ..color = const Color(0xFF78C7D4).withAlpha(100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Small pellets shrink toward the back of the board.
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        if (grid[y][x] != '.') continue;
        final center = project(x.toDouble() + .5, y.toDouble() + .5);
        final radius = cellHeight * scaleAt(y + .5) * .075;
        canvas.drawCircle(
          center.translate(0, radius * .8),
          radius * 1.45,
          Paint()..color = Colors.black.withAlpha(70),
        );
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [const Color(0xFFFFF1B2), FeltColors.brass],
            ).createShader(Rect.fromCircle(center: center, radius: radius)),
        );
      }
    }

    void orb(int x, int y, Color color, {required bool ghost}) {
      final center = project(x.toDouble() + .5, y.toDouble() + .5);
      final radius = cellHeight * scaleAt(y + .5) * (ghost ? .32 : .34);
      final shadow = Rect.fromCenter(
        center: center.translate(radius * .12, radius * .72),
        width: radius * 1.72,
        height: radius * .64,
      );
      canvas.drawOval(
        shadow,
        Paint()
          ..color = Colors.black.withAlpha(105)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.35, -.45),
            colors: [Color.lerp(color, Colors.white, .62)!, color, Color.lerp(color, Colors.black, .38)!],
            stops: const [.04, .55, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center.translate(-radius * .28, -radius * .32),
        radius * .13,
        Paint()..color = Colors.white.withAlpha(190),
      );
      if (ghost) {
        final eye = Paint()..color = const Color(0xFFF7F7FF);
        canvas.drawOval(
          Rect.fromCenter(center: center.translate(-radius * .25, -radius * .03),
              width: radius * .28, height: radius * .42),
          eye,
        );
        canvas.drawOval(
          Rect.fromCenter(center: center.translate(radius * .25, -radius * .03),
              width: radius * .28, height: radius * .42),
          eye,
        );
        final pupil = Paint()..color = const Color(0xFF263553);
        canvas.drawCircle(center.translate(-radius * .22, 0), radius * .08, pupil);
        canvas.drawCircle(center.translate(radius * .28, 0), radius * .08, pupil);
      }
    }

    orb(px, py, FeltColors.brass, ghost: false);
    orb(gx, gy, AZColors.red, ghost: true);

    canvas.drawPath(
      boardPath,
      Paint()
        ..color = const Color(0xFF76B9C8).withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _MazePainter oldDelegate) => true;
}
