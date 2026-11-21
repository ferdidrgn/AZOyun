import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'jump_dash_rules.dart';

class JumpDashLobbyScreen extends StatelessWidget {
  const JumpDashLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Zıpla Geç',
        emoji: '🐤',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Cihazı sırayla birbirinize verin. Ekrana dokunarak zıpla, '
            'borulara çarpmadan olabildiğince ileri git. En çok boru geçen kazanır!',
      );
}

class _Pipe {
  _Pipe({required this.x, required this.gapCenter});
  double x;
  final double gapCenter;
  bool passed = false;
}

class JumpDashGameScreen extends StatelessWidget {
  const JumpDashGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'jumpdash',
        gradient: AZColors.gradCyan,
        title: 'Zıpla Geç',
        emoji: '🐤',
        formatScore: (s) => '$s boru',
        sessionBuilder: (context, player, onFinished) =>
            _JumpDashSession(player: player, onFinished: onFinished),
      );
}

class _JumpDashSession extends StatefulWidget {
  const _JumpDashSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_JumpDashSession> createState() => _JumpDashSessionState();
}

class _JumpDashSessionState extends State<_JumpDashSession> {
  static const _jumpImpulse = jumpDashImpulse;
  static const _pipeSpeed = jumpDashPipeSpeed;
  static const _pipeWidth = jumpDashPipeWidth;
  static const _gapHalf = jumpDashGapHalf;
  static const _birdX = jumpDashBirdX;

  final _rng = Random();
  Timer? _timer;
  double _birdY = 0.5;
  double _velocity = 0;
  double _spawnTimer = 0;
  double _scenePhase = 0;
  final List<_Pipe> _pipes = [];
  int _score = 0;
  bool _over = false;
  bool _started = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
  }

  void _onTap() {
    if (!_started) {
      _start();
      return;
    }
    if (_over) return;
    setState(() => _velocity = _jumpImpulse);
  }

  void _tick() {
    if (_over) return;
    setState(() {
      _velocity = jumpDashNextVelocity(_velocity);
      _birdY = jumpDashNextBirdY(_birdY, _velocity);
      _scenePhase += _pipeSpeed;
      _spawnTimer += _pipeSpeed;
      if (jumpDashShouldSpawn(_spawnTimer)) {
        _spawnTimer = 0;
        _pipes.add(_Pipe(x: 1.15, gapCenter: 0.22 + _rng.nextDouble() * 0.56));
      }
      for (final p in _pipes) {
        p.x -= _pipeSpeed;
        if (!p.passed && jumpDashPipePassed(p.x)) {
          p.passed = true;
          _score++;
        }
      }
      _pipes.removeWhere((p) => p.x < -0.2);

      if (jumpDashHitBoundary(_birdY)) {
        _end();
        return;
      }
      for (final p in _pipes) {
        if (jumpDashPipeCollision(_birdY, p.x, p.gapCenter)) {
          _end();
          return;
        }
      }
    });
  }

  void _end() {
    _over = true;
    _timer?.cancel();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onFinished(_score);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.player.name} · Skor: $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: GestureDetector(
          onTap: _onTap,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return ClipRRect(
              borderRadius: BorderRadius.circular(AZRadius.md),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0x1FFFFFFF),
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(
                    painter: _JumpDashBackdropPainter(
                      pipes: _pipes,
                      phase: _scenePhase,
                      birdY: _birdY,
                    ),
                  )),
                  Positioned(
                    left: _birdX * w - 16,
                    top: _birdY * h - 16,
                    child: const Text('🐤', style: TextStyle(fontSize: 32, shadows: [Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(3, 5))])),
                  ),
                  for (final p in _pipes) ...[
                    Positioned(
                      left: p.x * w,
                      top: 0,
                      width: _pipeWidth * w,
                      height: (p.gapCenter - _gapHalf) * h,
                      child: Container(decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                        gradient: const LinearGradient(begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF7AD697), Color(0xFF3D9B68), Color(0xFF216246)],
                          stops: [0, .5, 1]),
                        border: Border.all(color: const Color(0xFFB3F1BE).withAlpha(145), width: 1),
                        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 7, offset: Offset(4, 3))],
                      )),
                    ),
                    Positioned(
                      left: p.x * w,
                      top: (p.gapCenter + _gapHalf) * h,
                      width: _pipeWidth * w,
                      height: h - (p.gapCenter + _gapHalf) * h,
                      child: Container(decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        gradient: const LinearGradient(begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF7AD697), Color(0xFF3D9B68), Color(0xFF216246)],
                          stops: [0, .5, 1]),
                        border: Border.all(color: const Color(0xFFB3F1BE).withAlpha(145), width: 1),
                        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 7, offset: Offset(4, 3))],
                      )),
                    ),
                  ],
                  if (!_started)
                    Center(
                      child: AZFrostCard(
                        child: Column(mainAxisSize: MainAxisSize.min, children: const [
                          Text('Başlamak için dokun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  if (_over)
                    Center(
                      child: AZFrostCard(
                        child: Text('Çarptın! 💥  Skor: $_score',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 8),
      const Text('Ekrana dokun, zıpla!', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}

class _JumpDashBackdropPainter extends CustomPainter {
  const _JumpDashBackdropPainter({required this.pipes, required this.phase, required this.birdY});

  final List<_Pipe> pipes;
  final double phase;
  final double birdY;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF6CC6DF), Color(0xFFB8E5DA), Color(0xFFE9F0CB)],
      stops: [0, .55, 1],
    ).createShader(bounds));
    canvas.drawCircle(Offset(size.width * .8, size.height * .16), size.width * .075,
      Paint()..color = const Color(0xFFFFF1BD).withAlpha(185));

    for (var i = 0; i < 5; i++) {
      final shift = ((phase * .018 * size.width) % (size.width * 1.3)).toDouble();
      final x = ((i * size.width * .28 - shift + size.width * 1.3) %
          (size.width * 1.3)).toDouble() - size.width * .1;
      final cy = size.height * (.13 + (i % 2) * .08);
      final cloudPaint = Paint()..color = Colors.white.withAlpha(125);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, cy),
          width: size.width * .12, height: size.height * .045), cloudPaint);
      canvas.drawCircle(Offset(x - size.width * .027, cy - size.height * .015), size.width * .027, cloudPaint);
      canvas.drawCircle(Offset(x + size.width * .022, cy - size.height * .012), size.width * .024, cloudPaint);
    }

    final farHill = Path()
      ..moveTo(0, size.height * .65)
      ..quadraticBezierTo(size.width * .19, size.height * .46,
          size.width * .42, size.height * .64)
      ..quadraticBezierTo(size.width * .68, size.height * .5,
          size.width, size.height * .62)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farHill, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF91C87F), Color(0xFF4A9564)],
    ).createShader(bounds));
    for (var i = 0; i < 9; i++) {
      final x = (i / 8) * size.width;
      final scale = .5 + (i % 4) * .12;
      final trunk = Rect.fromLTWH(x, size.height * .56, 4 * scale, 30 * scale);
      canvas.drawRect(trunk, Paint()..color = const Color(0xFF725135).withAlpha(130));
      for (var layer = 0; layer < 3; layer++) {
        final y = trunk.top - layer * 11 * scale;
        final crown = Path()
          ..moveTo(x - 15 * scale, y + 8 * scale)
          ..lineTo(x + 2 * scale, y - 11 * scale)
          ..lineTo(x + 19 * scale, y + 8 * scale)
          ..close();
        canvas.drawPath(crown, Paint()..color = const Color(0xFF39764F).withAlpha(180));
      }
    }

    final roadTop = size.height * .62;
    final road = Path()
      ..moveTo(size.width * .4, roadTop)
      ..lineTo(size.width * .6, roadTop)
      ..lineTo(size.width * 1.08, size.height)
      ..lineTo(size.width * -.08, size.height)
      ..close();
    canvas.drawPath(road, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF9D906F), Color(0xFF6D6855), Color(0xFF3D3C35)],
    ).createShader(bounds));

    canvas.save();
    canvas.clipPath(road);
    for (var i = -1; i < 11; i++) {
      final t = ((i * .13 + phase * .8) % 1).toDouble();
      final y = roadTop + t * (size.height - roadTop);
      final half = size.width * (.1 + t * .48);
      final width = 1.0 + t * 4.0;
      canvas.drawLine(Offset(size.width * .5 - half, y), Offset(size.width * .5 + half, y),
        Paint()..color = const Color(0xFFE6D4A1).withAlpha((45 + t * 75).round())
          ..strokeWidth = width..strokeCap = StrokeCap.round);
    }
    canvas.restore();

    // Perspective side faces and cast shadows sit behind the pipe fronts.
    canvas.save();
    canvas.clipRect(bounds);
    for (final pipe in pipes) {
      final left = pipe.x * size.width;
      final width = _JumpDashSessionState._pipeWidth * size.width;
      final top = (pipe.gapCenter - _JumpDashSessionState._gapHalf) * size.height;
      final bottom = (pipe.gapCenter + _JumpDashSessionState._gapHalf) * size.height;
      final depth = .55 + ((1.15 - pipe.x) / 1.1).clamp(0.0, 1.0).toDouble() * .45;
      final extrusion = 7 * depth;
      final sidePaint = Paint()..shader = const LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Color(0xFF2A774F), Color(0xFF103A30)],
      ).createShader(Rect.fromLTWH(left + width - extrusion, 0, extrusion, size.height));
      _drawSide(canvas, left, width, 0, top, extrusion, sidePaint);
      _drawSide(canvas, left, width, bottom, size.height, extrusion, sidePaint);
      canvas.drawRect(Rect.fromLTWH(left + 4 * depth, 0, width, top),
        Paint()..color = Colors.black.withAlpha(18));
      canvas.drawRect(Rect.fromLTWH(left + 4 * depth, bottom, width, size.height - bottom),
        Paint()..color = Colors.black.withAlpha(18));
    }
    canvas.restore();

    final birdX = size.width * _JumpDashSessionState._birdX;
    final birdY = _birdYToPixel(size);
    final ground = size.height * .84;
    final altitude = (ground - birdY).clamp(0.0, ground).toDouble();
    final shadowScale = 1.0 - altitude / max(1, ground).toDouble() * .4;
    canvas.drawOval(Rect.fromCenter(center: Offset(birdX + 3, ground - 1),
        width: size.width * .075 * shadowScale, height: size.height * .02 * shadowScale),
      Paint()..color = Colors.black.withAlpha((100 * shadowScale).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + (1 - shadowScale) * 4));

    canvas.drawRect(bounds, Paint()..shader = RadialGradient(
      colors: [Colors.transparent, Colors.black.withAlpha(38)],
      stops: const [.6, 1],
    ).createShader(bounds));
  }

  double _birdYToPixel(Size size) => size.height * birdY;

  void _drawSide(Canvas canvas, double left, double width, double top, double bottom,
      double extrusion, Paint paint) {
    if (bottom <= top) return;
    final right = left + width;
    final path = Path()
      ..moveTo(right, top)
      ..lineTo(right + extrusion, top + extrusion * .6)
      ..lineTo(right + extrusion, bottom + extrusion * .6)
      ..lineTo(right, bottom)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _JumpDashBackdropPainter oldDelegate) => true;
}

