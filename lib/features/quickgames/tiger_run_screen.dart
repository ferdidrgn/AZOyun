import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

class TigerRunLobbyScreen extends StatelessWidget {
  const TigerRunLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Kaplan Koşusu',
        emoji: '🐯',
        gradient: AZColors.gradOrange,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Kaplan koşar. Zıpla ile engeli aş, altınları topla.',
      );
}

class TigerRunGameScreen extends StatelessWidget {
  const TigerRunGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'tigerrun',
        gradient: AZColors.gradOrange,
        title: 'Kaplan Koşusu',
        emoji: '🐯',
        formatScore: (score) => '$score altın',
        sessionBuilder: (context, player, onFinished) =>
            _TigerSession(player: player, onFinished: onFinished),
      );
}

class _Gate {
  _Gate({required this.x, required this.coin});
  double x;
  final bool coin;
  bool taken = false;
}

class _TigerSession extends StatefulWidget {
  const _TigerSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_TigerSession> createState() => _TigerSessionState();
}

class _TigerSessionState extends State<_TigerSession> {
  static const _ground = 0.72;
  static const _tigerX = 0.22;

  final _rng = Random();
  final _gates = <_Gate>[];
  Timer? _timer;
  double _y = _ground;
  double _vy = 0;
  double _spawn = 0;
  double _scenePhase = 0;
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

  void _jump() {
    if (!_started) {
      _start();
    }
    if (_over || _y < _ground - 0.02) {
      return;
    }
    setState(() => _vy = -0.034);
  }

  void _tick() {
    if (_over) {
      return;
    }
    _vy += 0.0022;
    _y += _vy;
    if (_y > _ground) {
      _y = _ground;
      _vy = 0;
    }
    _spawn += 0.012;
    _scenePhase += 0.012;
    if (_spawn >= 0.46) {
      _spawn = 0;
      _gates.add(_Gate(x: 1.15, coin: _rng.nextBool()));
    }
    for (final gate in _gates) {
      gate.x -= 0.012;
      final near = (gate.x - _tigerX).abs() < 0.05;
      if (!near) {
        continue;
      }
      if (gate.coin && !gate.taken && _y < _ground - 0.08) {
        gate.taken = true;
        _score++;
      }
      if (!gate.coin && _y > _ground - 0.12) {
        _end();
        return;
      }
    }
    _gates.removeWhere((gate) => gate.x < -0.2);
    setState(() {});
  }

  void _end() {
    _over = true;
    _timer?.cancel();
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onFinished(_score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Altın $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AZRadius.lg),
            child: CustomPaint(
              painter: _TigerPainter(y: _y, gates: _gates, phase: _scenePhase),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _over ? null : _jump,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AZColors.orangeDk,
            ),
            child: Text(_started ? 'Zıpla' : 'Koşmaya başla'),
          ),
        ),
      ],
    );
  }
}

class _TigerPainter extends CustomPainter {
  _TigerPainter({required this.y, required this.gates, required this.phase});

  final double y;
  final List<_Gate> gates;
  final double phase;

  double _approachScale(_Gate gate) => .48 +
      ((1.15 - gate.x) / (1.15 - .22))
          .clamp(0.0, 1.0).toDouble() * .64;

  void _drawCoin(Canvas canvas, Offset center, double scale) {
    final width = 19 * scale;
    final height = 24 * scale;
    canvas.drawOval(Rect.fromCenter(center: center.translate(3 * scale, 7 * scale),
        width: width * 1.3, height: height * .4),
      Paint()..color = Colors.black.withAlpha(90)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * scale));
    canvas.drawOval(Rect.fromCenter(center: center.translate(2 * scale, 0),
        width: width, height: height), Paint()..color = const Color(0xFF9B5B18));
    canvas.drawOval(Rect.fromCenter(center: center,
        width: width * .78, height: height), Paint()..shader = const LinearGradient(
      begin: Alignment.centerLeft, end: Alignment.centerRight,
      colors: [Color(0xFFE49A28), Color(0xFFFFE78B), Color(0xFFC77A1D)],
    ).createShader(Rect.fromCenter(center: center, width: width, height: height)));
    canvas.drawOval(Rect.fromCenter(center: center,
        width: width * .43, height: height * .7), Paint()
      ..color = const Color(0xFFFFF2BD).withAlpha(190)
      ..style = PaintingStyle.stroke..strokeWidth = 1.4 * scale);
    canvas.drawLine(center.translate(-1 * scale, -height * .27),
        center.translate(-1 * scale, height * .27),
      Paint()..color = Colors.white.withAlpha(150)..strokeWidth = 1.1 * scale);
  }

  void _drawObstacle(Canvas canvas, Offset foot, double scale) {
    final width = 34 * scale;
    final height = 54 * scale;
    final body = Rect.fromLTWH(foot.dx, foot.dy - height, width, height);
    canvas.drawOval(Rect.fromCenter(center: foot.translate(width * .55, 1),
        width: width * 1.45, height: height * .24),
      Paint()..color = Colors.black.withAlpha(105)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale));

    final rock = Path()
      ..moveTo(body.left + width * .08, body.bottom - height * .1)
      ..lineTo(body.left, body.top + height * .45)
      ..quadraticBezierTo(body.left + width * .12, body.top + height * .12,
          body.left + width * .42, body.top + height * .18)
      ..quadraticBezierTo(body.left + width * .7, body.top - height * .02,
          body.right, body.top + height * .32)
      ..lineTo(body.right - width * .05, body.bottom - height * .08)
      ..quadraticBezierTo(body.center.dx, body.bottom + height * .06,
          body.left + width * .08, body.bottom - height * .1)
      ..close();
    canvas.drawPath(rock, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFD98039), Color(0xFF98502D), Color(0xFF583322)],
    ).createShader(body));
    final face = Path()
      ..moveTo(body.left + width * .12, body.top + height * .47)
      ..lineTo(body.left + width * .45, body.top + height * .26)
      ..lineTo(body.left + width * .56, body.top + height * .55)
      ..lineTo(body.left + width * .32, body.top + height * .77)
      ..close();
    canvas.drawPath(face, Paint()..color = const Color(0xFFFFB45B).withAlpha(170));
    canvas.drawLine(body.topLeft.translate(width * .1, height * .62),
        body.topLeft.translate(width * .35, height * .43),
      Paint()..color = const Color(0xFF693923).withAlpha(190)
        ..strokeWidth = 1.5 * scale..strokeCap = StrokeCap.round);
    canvas.drawOval(Rect.fromCenter(center: body.bottomCenter.translate(-width * .16, -height * .08),
        width: width * .14, height: height * .08), Paint()..color = const Color(0xFF37231D));
  }

  void _drawTiger(Canvas canvas, Offset center, double ground, double jumpHeight) {
    final bodyWidth = 55.0;
    final bodyHeight = 33.0;
    final shadowOpacity = (135 - jumpHeight * .65).clamp(35, 135).toInt();
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 4, ground - 2),
        width: bodyWidth * (1.05 + jumpHeight / 500), height: 12 + jumpHeight * .035),
      Paint()..color = Colors.black.withAlpha(shadowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));

    // Tail swings behind the runner, with dark stripes embedded in the shape.
    final tail = Path()
      ..moveTo(center.dx - 20, center.dy + 2)
      ..cubicTo(center.dx - 43, center.dy - 5, center.dx - 39, center.dy - 25,
          center.dx - 51, center.dy - 18);
    canvas.drawPath(tail, Paint()..color = const Color(0xFFE98B29)
      ..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round);
    canvas.drawPath(tail, Paint()..color = const Color(0xFF4A2B1E)
      ..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);

    // Paws and body are layered so the tiger reads as a small 3D character.
    for (final x in [-16.0, 12.0]) {
      final stride = sin(phase * 18 + x) * 4;
      final leg = Rect.fromCenter(center: Offset(center.dx + x, center.dy + 12 + stride),
          width: 9, height: 19);
      canvas.drawRRect(RRect.fromRectAndRadius(leg, const Radius.circular(5)),
        Paint()..shader = const LinearGradient(begin: Alignment.centerLeft,
          end: Alignment.centerRight, colors: [Color(0xFFC65C1A), Color(0xFFFFB646)])
          .createShader(leg));
      canvas.drawOval(Rect.fromCenter(center: leg.bottomCenter.translate(2, -1),
          width: 12, height: 6), Paint()..color = const Color(0xFFFFD277));
    }
    final body = Rect.fromCenter(center: center.translate(-3, 1),
        width: bodyWidth, height: bodyHeight);
    canvas.drawOval(body, Paint()..shader = const RadialGradient(
      center: Alignment(-.35, -.45), radius: 1.15,
      colors: [Color(0xFFFFC45B), Color(0xFFF18A2C), Color(0xFFB84B18)],
    ).createShader(body));
    for (var i = 0; i < 4; i++) {
      final x = body.left + 15 + i * 8;
      final stripe = Path()
        ..moveTo(x, body.top + 1)
        ..quadraticBezierTo(x - 7, body.center.dy, x + 1, body.bottom - 2);
      canvas.drawPath(stripe, Paint()..color = const Color(0xFF4B2B1D)
        ..style = PaintingStyle.stroke..strokeWidth = 3.3..strokeCap = StrokeCap.round);
    }
    final head = Rect.fromCenter(center: center.translate(19, -7), width: 27, height: 25);
    canvas.drawOval(head, Paint()..shader = const RadialGradient(
      center: Alignment(-.4, -.55), colors: [Color(0xFFFFD475), Color(0xFFF18E31), Color(0xFFBD511C)],
    ).createShader(head));
    for (final x in [-8.0, 8.0]) {
      canvas.drawCircle(center.translate(19 + x, -18), 5.5,
        Paint()..color = const Color(0xFFD56A24));
      canvas.drawCircle(center.translate(19 + x, -18), 2.8,
        Paint()..color = const Color(0xFFFFD27A));
    }
    canvas.drawOval(Rect.fromCenter(center: center.translate(29, -2), width: 11, height: 8),
      Paint()..color = const Color(0xFFFFE7B5));
    canvas.drawCircle(center.translate(23, -9), 2.2, Paint()..color = const Color(0xFF2A201B));
    canvas.drawCircle(center.translate(32, -9), 2.2, Paint()..color = const Color(0xFF2A201B));
    canvas.drawCircle(center.translate(34, -3), 1.5, Paint()..color = const Color(0xFF2A201B));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF85D6D0), Color(0xFFB8D98E), Color(0xFF426E46)],
      stops: [0, .46, 1],
    ).createShader(Offset.zero & size));
    final horizon = size.height * .48;
    canvas.drawCircle(Offset(size.width * .78, size.height * .2), size.width * .08,
      Paint()..color = const Color(0xFFFFF3BE).withAlpha(160));
    final farHill = Path()
      ..moveTo(0, horizon + 16)
      ..quadraticBezierTo(size.width * .2, horizon - 42, size.width * .42, horizon + 8)
      ..quadraticBezierTo(size.width * .7, horizon - 35, size.width, horizon + 12)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farHill, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF54895F), Color(0xFF315B3F)],
    ).createShader(Offset.zero & size));
    for (var i = 0; i < 12; i++) {
      final x = (i / 11) * size.width;
      final scale = .45 + ((i * 37) % 7) * .09;
      final base = horizon + 10 + scale * 26;
      final trunk = Rect.fromLTWH(x, base - 44 * scale, 5 * scale, 44 * scale);
      canvas.drawRect(trunk, Paint()..color = const Color(0xFF68472D).withAlpha(160));
      for (var branch = 0; branch < 3; branch++) {
        final crown = Path()
          ..moveTo(x - 16 * scale, trunk.top + branch * 12 * scale)
          ..lineTo(x + 2.5 * scale, trunk.top - 20 * scale + branch * 10 * scale)
          ..lineTo(x + 21 * scale, trunk.top + branch * 12 * scale)
          ..close();
        canvas.drawPath(crown, Paint()..color = const Color(0xFF285B3E).withAlpha(190));
      }
    }
    final ground = size.height * 0.78;
    final groundPlane = Path()
      ..moveTo(size.width * .39, horizon + 22)
      ..lineTo(size.width * .61, horizon + 22)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(groundPlane, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFFB69052), Color(0xFF80613A), Color(0xFF443923)],
    ).createShader(Offset.zero & size));
    canvas.save();
    canvas.clipPath(groundPlane);
    for (var i = -1; i < 12; i++) {
      final y = horizon + 22 +
          ((i * 29 + phase * 170) % (size.height - horizon + 50)).toDouble();
      final t = ((y - horizon) / (size.height - horizon)).clamp(0.0, 1.0).toDouble();
      final width = 1.0 + 4 * t;
      final offset = size.width * (.39 + .22 * t);
      for (final x in [size.width * .5 - offset, size.width * .5 + offset]) {
        canvas.drawLine(Offset(x, y), Offset(x + (x < size.width * .5 ? -1 : 1) * width * 4, y + 2 + 8 * t),
          Paint()..color = const Color(0xFFE8C77C).withAlpha((45 + t * 65).round())
            ..strokeWidth = width..strokeCap = StrokeCap.round);
      }
    }
    canvas.restore();

    for (final gate in gates) {
      final scale = _approachScale(gate);
      final groundPoint = Offset(gate.x * size.width, ground);
      if (gate.coin) {
        if (!gate.taken) {
          _drawCoin(canvas, groundPoint.translate(0, -70 * scale), scale);
        }
      } else {
        _drawObstacle(canvas, groundPoint.translate(-2 * scale, 0), scale);
      }
    }
    final tiger = Offset(size.width * .22, y / .72 * ground - 18);
    _drawTiger(canvas, tiger, ground,
        max(0, (_TigerSessionState._ground - y) * ground / _TigerSessionState._ground).toDouble());
    final vignette = Paint()..shader = RadialGradient(
      colors: [Colors.transparent, Colors.black.withAlpha(52)],
      stops: const [.55, 1],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _TigerPainter oldDelegate) => true;
}
