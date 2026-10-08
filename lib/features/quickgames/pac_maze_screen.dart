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
    final cell = size.width / grid.length;
    for (var y = 0; y < grid.length; y++) {
      for (var x = 0; x < grid[y].length; x++) {
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        canvas.drawRect(
          rect,
          Paint()..color = grid[y][x] == '#' ? FeltColors.feltDeep : const Color(0xFF102028),
        );
        if (grid[y][x] == '.') {
          canvas.drawCircle(rect.center, 3, Paint()..color = FeltColors.brass);
        }
      }
    }
    canvas.drawCircle(Offset((px + 0.5) * cell, (py + 0.5) * cell), cell * 0.35, Paint()..color = FeltColors.brass);
    canvas.drawCircle(Offset((gx + 0.5) * cell, (gy + 0.5) * cell), cell * 0.35, Paint()..color = AZColors.red);
  }

  @override
  bool shouldRepaint(covariant _MazePainter oldDelegate) => true;
}
