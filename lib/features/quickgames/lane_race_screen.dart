import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

class LaneRaceLobbyScreen extends StatelessWidget {
  const LaneRaceLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Şerit Yarışı',
        emoji: '🏎️',
        gradient: AZColors.gradRed,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Araba üç şeritte gider. Sol ve sağ ile şerit değiştir, engelden kaç.',
      );
}

class LaneRaceGameScreen extends StatelessWidget {
  const LaneRaceGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'lanerace',
        gradient: AZColors.gradRed,
        title: 'Şerit Yarışı',
        emoji: '🏎️',
        formatScore: (score) => '$score metre',
        sessionBuilder: (context, player, onFinished) =>
            _LaneSession(player: player, onFinished: onFinished),
      );
}

class _Block {
  _Block({required this.lane, required this.y});
  final int lane;
  double y;
}

class _LaneSession extends StatefulWidget {
  const _LaneSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_LaneSession> createState() => _LaneSessionState();
}

class _LaneSessionState extends State<_LaneSession> {
  final _rng = Random();
  final _blocks = <_Block>[];
  Timer? _timer;
  int _lane = 1;
  double _spawn = 0;
  int _score = 0;
  bool _started = false;
  bool _over = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) {
      return;
    }
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
  }

  void _move(int delta) {
    if (!_started || _over) {
      return;
    }
    setState(() => _lane = (_lane + delta).clamp(0, 2));
  }

  void _tick() {
    if (_over) {
      return;
    }
    _score++;
    _spawn += 0.03;
    final speed = min(0.02, 0.01 + _score * 0.00002);
    if (_spawn >= 0.7) {
      _spawn = 0;
      _blocks.add(_Block(lane: _rng.nextInt(3), y: -0.15));
    }
    for (final block in _blocks) {
      block.y += speed;
      if (block.lane == _lane && block.y > 0.72 && block.y < 0.9) {
        _end();
        return;
      }
    }
    _blocks.removeWhere((block) => block.y > 1.2);
    setState(() {});
  }

  void _end() {
    _over = true;
    _timer?.cancel();
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onFinished(_score ~/ 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  ${_score ~/ 4} m',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AZRadius.lg),
            child: CustomPaint(
              painter: _LanePainter(lane: _lane, blocks: _blocks, phase: _score),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        if (!_started)
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AZColors.redDk,
              ),
              child: const Text('Yarışa başla'),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _move(-1),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AZColors.redDk,
                    ),
                    child: const Text('Sol'),
                  ),
                ),
              ),
              const SizedBox(width: AZSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _move(1),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AZColors.redDk,
                    ),
                    child: const Text('Sağ'),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _LanePainter extends CustomPainter {
  _LanePainter({required this.lane, required this.blocks, required this.phase});

  final int lane;
  final List<_Block> blocks;
  final int phase;

  double _depth(double y) => .42 + y.clamp(0.0, 1.0).toDouble() * .62;

  double _horizonY(Size size) => size.height * .045;

  double _screenY(Size size, double y) =>
      _horizonY(size) + y * size.height * .94;

  double _roadHalfWidth(Size size, double y) => size.width * .43 * _depth(y);

  double _laneX(Size size, int laneIndex, double y) =>
      size.width * .5 + (laneIndex - 1) * _roadHalfWidth(size, y) * (2 / 3);

  void _polygon(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  Path _roadPath(Size size, {double expand = 0}) {
    final topHalf = size.width * .43 * _depth(0) + expand;
    final bottomHalf = size.width * .43 * _depth(1) + expand;
    return Path()
      ..moveTo(size.width * .5 - topHalf, _horizonY(size))
      ..lineTo(size.width * .5 + topHalf, _horizonY(size))
      ..lineTo(size.width * .5 + bottomHalf, _screenY(size, 1))
      ..lineTo(size.width * .5 - bottomHalf, _screenY(size, 1))
      ..close();
  }

  void _drawObstacle(Canvas canvas, Size size, _Block block) {
    final y = block.y;
    final depth = _depth(y);
    final center = Offset(_laneX(size, block.lane, y), _screenY(size, y));
    final laneWidth = _roadHalfWidth(size, y) * (2 / 3);
    final width = laneWidth * .52;
    final height = 32 * depth;
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final side = width * .17;
    final lift = height * .17;

    canvas.drawOval(
      Rect.fromCenter(center: center.translate(2, height * .35),
          width: width * 1.1, height: height * .42),
      Paint()..color = Colors.black.withAlpha(110)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + depth * 3),
    );
    _polygon(canvas, [
      Offset(rect.right, rect.top + lift),
      Offset(rect.right + side, rect.top),
      Offset(rect.right + side, rect.bottom - lift),
      Offset(rect.right, rect.bottom),
    ], Paint()..color = const Color(0xFF8E2431));
    _polygon(canvas, [
      Offset(rect.left, rect.top + lift),
      Offset(rect.left + side, rect.top),
      Offset(rect.right + side, rect.top),
      Offset(rect.right, rect.top + lift),
    ], Paint()..color = const Color(0xFFFFA26A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(5 * depth)),
      Paint()..shader = const LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Color(0xFFFF4D5D), Color(0xFFCC293D), Color(0xFF8F1F35)],
      ).createShader(rect),
    );
    final stripe = Rect.fromLTWH(rect.left + width * .12, center.dy - height * .08,
        width * .76, height * .18);
    canvas.drawRRect(RRect.fromRectAndRadius(stripe, Radius.circular(3 * depth)),
      Paint()..color = const Color(0xFFFFC27A).withAlpha(220));
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + width * .18, rect.top + height * .12,
          width * .64, height * .19), Radius.circular(4 * depth)),
      Paint()..color = const Color(0xFFFFE2B9).withAlpha(190));
  }

  void _drawCar(Canvas canvas, Size size) {
    const y = .82;
    final depth = _depth(y);
    final center = Offset(_laneX(size, lane, y), _screenY(size, y));
    final width = size.width * .13 * depth;
    final height = 48 * depth;
    final body = Path()
      ..moveTo(center.dx, center.dy - height * .55)
      ..quadraticBezierTo(center.dx + width * .38, center.dy - height * .38,
          center.dx + width * .43, center.dy - height * .08)
      ..lineTo(center.dx + width * .37, center.dy + height * .42)
      ..quadraticBezierTo(center.dx, center.dy + height * .58,
          center.dx - width * .37, center.dy + height * .42)
      ..lineTo(center.dx - width * .43, center.dy - height * .08)
      ..quadraticBezierTo(center.dx - width * .38, center.dy - height * .38,
          center.dx, center.dy - height * .55)
      ..close();

    canvas.drawOval(Rect.fromCenter(center: center.translate(2, height * .28),
        width: width * 1.14, height: height * .52),
      Paint()..color = Colors.black.withAlpha(150)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + depth * 5));
    final tirePaint = Paint()..color = const Color(0xFF10151B);
    for (final side in [-1.0, 1.0]) {
      for (final offset in [-.27, .24]) {
        final tire = Rect.fromCenter(
          center: Offset(center.dx + side * width * .38, center.dy + height * offset),
          width: width * .2, height: height * .27,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(tire, Radius.circular(width * .1)), tirePaint);
      }
    }
    canvas.drawPath(body, Paint()..shader = const LinearGradient(
      begin: Alignment.centerLeft, end: Alignment.centerRight,
      colors: [Color(0xFFB77C29), Color(0xFFFFD77B), Color(0xFFC58A32)],
    ).createShader(Rect.fromCenter(center: center, width: width, height: height)));
    final cabin = Path()
      ..moveTo(center.dx - width * .25, center.dy - height * .17)
      ..quadraticBezierTo(center.dx, center.dy - height * .36,
          center.dx + width * .25, center.dy - height * .17)
      ..lineTo(center.dx + width * .24, center.dy + height * .12)
      ..lineTo(center.dx - width * .24, center.dy + height * .12)
      ..close();
    canvas.drawPath(cabin, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFFBCEEFF), Color(0xFF244458)],
    ).createShader(Rect.fromCenter(center: center, width: width * .55, height: height * .6)));
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(center.dx + side * width * .25, center.dy - height * .38),
        1.8 * depth, Paint()..color = const Color(0xFFFFF1B5));
      canvas.drawCircle(Offset(center.dx + side * width * .25, center.dy + height * .4),
        1.7 * depth, Paint()..color = const Color(0xFFFF485A));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF182738), Color(0xFF53616A), Color(0xFF163B33)],
      stops: [0, .32, .54],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    // Far horizon and roadside lights establish camera depth.
    final horizon = _horizonY(size);
    canvas.drawRect(Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1E513F), Color(0xFF102A24)],
      ).createShader(Rect.fromLTWH(0, horizon, size.width, size.height - horizon)));
    for (var i = 0; i < 8; i++) {
      final y = i / 8;
      final d = _depth(y);
      final left = size.width * .5 - _roadHalfWidth(size, y) - 7 * d;
      final right = size.width * .5 + _roadHalfWidth(size, y) + 7 * d;
      final py = _screenY(size, y);
      for (final x in [left, right]) {
        canvas.drawCircle(Offset(x, py), 1.5 * d,
          Paint()..color = const Color(0xFFFFD17A).withAlpha((70 + d * 90).round()));
      }
    }

    final road = _roadPath(size);
    canvas.drawPath(_roadPath(size, expand: size.width * .018),
      Paint()..color = Colors.black.withAlpha(90));
    canvas.drawPath(road, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF555D65), Color(0xFF2A3038), Color(0xFF24292F)],
    ).createShader(Offset.zero & size));
    canvas.save();
    canvas.clipPath(road);

    // Three converging lanes. Dash spacing and width grow toward the camera;
    // phase advances with the existing game tick for the moving-road effect.
    for (var divider = 1; divider <= 2; divider++) {
      for (var dash = -1; dash < 13; dash++) {
        final y0 = (dash * .105 + (phase % 14) * .0075).clamp(0.0, 1.0).toDouble();
        final y1 = (y0 + .048 + y0 * .025).clamp(0.0, 1.0).toDouble();
        final x0 = size.width * .5 + (divider - 1.5) * _roadHalfWidth(size, y0) * (2 / 3);
        final x1 = size.width * .5 + (divider - 1.5) * _roadHalfWidth(size, y1) * (2 / 3);
        canvas.drawLine(Offset(x0, _screenY(size, y0)), Offset(x1, _screenY(size, y1)),
          Paint()..color = FeltColors.ivory.withAlpha(145)
            ..strokeWidth = 1.2 + _depth((y0 + y1) / 2) * 2.2
            ..strokeCap = StrokeCap.round);
      }
    }
    for (var dash = 0; dash < 11; dash++) {
      final y0 = (dash * .12 + (phase % 12) * .008).clamp(0.0, 1.0).toDouble();
      final y1 = (y0 + .035 + y0 * .02).clamp(0.0, 1.0).toDouble();
      final width = size.width * .006 * _depth(y0);
      final left0 = size.width * .5 - _roadHalfWidth(size, y0);
      final left1 = size.width * .5 - _roadHalfWidth(size, y1);
      final right0 = size.width * .5 + _roadHalfWidth(size, y0);
      final right1 = size.width * .5 + _roadHalfWidth(size, y1);
      canvas.drawLine(Offset(left0, _screenY(size, y0)), Offset(left1, _screenY(size, y1)),
        Paint()..color = const Color(0xFFE7D5A1).withAlpha(175)
          ..strokeWidth = width..strokeCap = StrokeCap.round);
      canvas.drawLine(Offset(right0, _screenY(size, y0)), Offset(right1, _screenY(size, y1)),
        Paint()..color = const Color(0xFFE7D5A1).withAlpha(175)
          ..strokeWidth = width..strokeCap = StrokeCap.round);
    }
    for (final block in blocks) {
      _drawObstacle(canvas, size, block);
    }
    _drawCar(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LanePainter oldDelegate) => true;
}
