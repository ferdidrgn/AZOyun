import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

class ScubaSweepLobbyScreen extends StatelessWidget {
  const ScubaSweepLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Scuba Sweep',
        emoji: '🤿',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Dalgıç kendiliğinden yükselir. Sola ve sağa sürükle. '
            'Şişe, cam, poşet ve pipet topla. '
            'Köpek balığı, balon balığı ve deniz anasından kaç. '
            'İnci kısa süre kalkan verir ve yükselişi hızlandırır.',
      );
}

class ScubaSweepGameScreen extends StatelessWidget {
  const ScubaSweepGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'scubasweep',
        gradient: AZColors.gradCyan,
        title: 'Scuba Sweep',
        emoji: '🤿',
        formatScore: (score) => '$score plastik',
        sessionBuilder: (context, player, onFinished) =>
            _ScubaSession(player: player, onFinished: onFinished),
      );
}

enum _Kind { bottle, glass, bag, straw, shark, puffer, jelly, pearl }

class _Drift {
  _Drift({
    required this.kind,
    required this.x,
    required this.y,
    required this.vx,
  });

  final _Kind kind;
  double x;
  double y;
  double vx;
  double scale = 1;
}

bool scubaOverlap(double ax, double ay, double bx, double by, double reach) {
  final dx = ax - bx;
  final dy = ay - by;
  return dx * dx + dy * dy <= reach * reach;
}

class _ScubaSession extends StatefulWidget {
  const _ScubaSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_ScubaSession> createState() => _ScubaSessionState();
}

class _ScubaSessionState extends State<_ScubaSession> {
  static const _speeds = [0.19, 0.31, 0.38, 0.50, 0.62, 0.82, 0.94, 1.0];
  static const _boost = 0.82;
  static const _diverHome = 0.72;
  static const _tips = [
    'Plastik şişeyi geri dönüştür.',
    'Poşet yerine file çanta kullan.',
    'Pipeti yalnızca gerektiğinde iste.',
    'Cam şişe denizde yıllarca kalır.',
  ];

  final Random _rng = Random();
  final List<_Drift> _items = [];
  final List<Offset> _bubbles = [];
  Timer? _timer;

  double _x = 0.5;
  double _diverY = 0.92;
  double _lean = 0;
  double _trashIn = 0;
  double _enemyIn = 0.8;
  double _pearlIn = 4;
  double _shield = 0;
  double _collectFlash = 0;
  double _time = 0;
  int _score = 0;
  int _level = 1;
  bool _started = false;
  bool _paused = false;
  bool _over = false;
  String _tip = _tips.first;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _pace {
    final base = _speeds[(_level - 1).clamp(0, _speeds.length - 1)];
    if (_shield > 0 && base < _boost) {
      return _boost;
    }
    return base;
  }

  void _start() {
    if (_started) {
      return;
    }
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
  }

  void _togglePause() {
    if (!_started || _over) {
      return;
    }
    if (_paused) {
      _paused = false;
      _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
    } else {
      _paused = true;
      _timer?.cancel();
    }
    setState(() {});
  }

  void _tick() {
    if (!mounted || _over || _paused) {
      return;
    }
    const step = 0.03;
    _time += step;
    _collectFlash = max(0.0, _collectFlash - step * 2.6).toDouble();
    if (_diverY > _diverHome) {
      _diverY = max(_diverHome, _diverY - 0.01);
    }
    final pace = _pace;
    if (_shield > 0) {
      _shield -= step;
    }
    _trashIn += step;
    _enemyIn += step;
    _pearlIn += step;
    if (_trashIn >= 1.2) {
      _trashIn = 0;
      _items.add(_plastic());
    }
    if (_enemyIn >= 2.3) {
      _enemyIn = 0;
      _items.add(_enemy());
    }
    if (_pearlIn >= 10) {
      _pearlIn = 0;
      _items.add(_Drift(kind: _Kind.pearl, x: _lane(), y: -0.08, vx: 0));
    }
    for (final item in _items) {
      item.y += pace * step;
      item.x = (item.x + item.vx * step).clamp(0.06, 0.94);
      if (item.kind == _Kind.puffer && item.scale < 2.4) {
        item.scale += step * 0.35;
      }
    }
    _items.removeWhere((item) => item.y > 1.25);
    _bubbles.clear();
    if (!MediaQuery.disableAnimationsOf(context)) {
      for (var i = 0; i < 5; i++) {
        _bubbles.add(Offset(
          (_x + sin(_time * 2 + i) * 0.04).clamp(0.05, 0.95),
          _diverY - 0.08 - ((_time * 0.15 + i * 0.12) % 0.5),
        ));
      }
    }
    for (final item in List<_Drift>.of(_items)) {
      final reach = switch (item.kind) {
        _Kind.shark => 0.09,
        _Kind.puffer => 0.045 * item.scale,
        _Kind.jelly => 0.055,
        _Kind.pearl => 0.05,
        _ => 0.045,
      };
      if (!scubaOverlap(_x, _diverY, item.x, item.y, reach)) {
        continue;
      }
      _items.remove(item);
      if (item.kind == _Kind.pearl) {
        _shield = 4;
      } else if (item.kind == _Kind.shark ||
          item.kind == _Kind.puffer ||
          item.kind == _Kind.jelly) {
        if (_shield <= 0) {
          _end();
          return;
        }
      } else {
        _score += 1;
        _collectFlash = 1;
        if (_score % 10 == 0) {
          _level += 1;
        }
      }
    }
    _lean *= 0.9;
    setState(() {});
  }

  _Drift _plastic() {
    const kinds = [_Kind.bottle, _Kind.glass, _Kind.bag, _Kind.straw];
    return _Drift(kind: kinds[_rng.nextInt(kinds.length)], x: _lane(), y: -0.08, vx: 0);
  }

  _Drift _enemy() {
    final pool = min(_level, 3);
    final kind = switch (_rng.nextInt(pool)) {
      0 => _Kind.shark,
      1 => _Kind.puffer,
      _ => _Kind.jelly,
    };
    final x = _lane();
    final vx = kind == _Kind.shark ? (x < 0.5 ? 0.18 : -0.18) : 0.0;
    return _Drift(kind: kind, x: x, y: -0.1, vx: vx);
  }

  double _lane() => 0.12 + _rng.nextDouble() * 0.76;

  void _end() {
    _over = true;
    _timer?.cancel();
    _tip = _tips[_score % _tips.length];
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        widget.onFinished(_score);
      }
    });
  }

  void _drag(double dx, double width) {
    if (!_started || _paused || _over || width <= 0) {
      return;
    }
    setState(() {
      _x = (_x + dx / width).clamp(0.08, 0.92);
      _lean = (dx / 18).clamp(-1.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shield = _shield > 0;
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Seviye $_level  Plastik $_score${shield ? '  Kalkan' : ''}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Semantics(
              label: 'Dalgıcı sola veya sağa sürükle',
              child: GestureDetector(
                onHorizontalDragUpdate: (details) =>
                    _drag(details.delta.dx, constraints.maxWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AZRadius.lg),
                  child: CustomPaint(
                    painter: _OceanPainter(
                      diverX: _x,
                      diverY: _diverY,
                      lean: _lean,
                      items: _items,
                      bubbles: _bubbles,
                      shielded: shield,
                      parallax: _x,
                      time: _time,
                      collectFlash: _collectFlash,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
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
                foregroundColor: AZColors.blueDk,
              ),
              child: const Text('Dalışa başla'),
            ),
          )
        else if (_over)
          Text(
            'Çarptın. $_score plastik. $_tip',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          )
        else
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: _togglePause,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AZColors.blueDk,
              ),
              child: Text(_paused ? 'Devam et' : 'Duraklat'),
            ),
          ),
      ],
    );
  }
}

class _OceanPainter extends CustomPainter {
  _OceanPainter({
    required this.diverX,
    required this.diverY,
    required this.lean,
    required this.items,
    required this.bubbles,
    required this.shielded,
    required this.parallax,
    required this.time,
    required this.collectFlash,
  });

  final double diverX;
  final double diverY;
  final double lean;
  final List<_Drift> items;
  final List<Offset> bubbles;
  final bool shielded;
  final double parallax;
  final double time;
  final double collectFlash;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF45B2C9), Color(0xFF17627C), Color(0xFF0A3448)],
        ).createShader(rect),
    );

    final w = size.width;
    final h = size.height;
    final cameraShift = (parallax - .5) * w;

    // Narrow light shafts and layered reef silhouettes create distant depth.
    for (var i = 0; i < 4; i++) {
      final x = w * (.14 + i * .23) - cameraShift * .035;
      final beam = Path()
        ..moveTo(x - w * .035, 0)
        ..lineTo(x + w * .045, 0)
        ..lineTo(x + w * .18, h * .72)
        ..lineTo(x - w * .08, h * .72)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withAlpha(28), Colors.white.withAlpha(0)],
          ).createShader(rect),
      );
    }

    // Slow caustic bands move across the upper water to sell its depth.
    for (var i = 0; i < 5; i++) {
      final phase = time * .7 + i * 1.25;
      final x = w * (((i * .23 + phase * .035) % 1.2) - .1);
      final y = h * (.16 + (i % 3) * .11 + sin(phase) * .018);
      final caustic = Rect.fromCenter(
        center: Offset(x - cameraShift * .02, y),
        width: w * (.13 + (i % 2) * .045),
        height: h * .018,
      );
      canvas.drawOval(
        caustic,
        Paint()
          ..color = const Color(0xFFB6FCF1).withAlpha(21)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final farReef = Path()
      ..moveTo(0, h * .69)
      ..cubicTo(w * .18, h * .61, w * .25, h * .72, w * .43, h * .67)
      ..cubicTo(w * .66, h * .60, w * .79, h * .73, w, h * .64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.save();
    canvas.translate(-cameraShift * .045, 0);
    canvas.drawPath(farReef, Paint()..color = const Color(0xFF0E4657).withAlpha(140));
    canvas.restore();

    final seabed = Path()
      ..moveTo(0, h * .80)
      ..quadraticBezierTo(w * .50, h * .74, w, h * .80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      seabed,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF176176), Color(0xFF0A3645), Color(0xFF062A37)],
        ).createShader(rect),
    );

    final floorLine = Paint()
      ..color = const Color(0xFF8ED3D4).withAlpha(30)
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = h * (.82 + i * .027);
      canvas.drawLine(Offset(w * .05, y), Offset(w * .95, y + h * .01), floorLine);
    }
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(w * .5 + i * w * .06, h * .77),
        Offset(w * .5 + i * w * .22 - cameraShift * .08, h),
        floorLine,
      );
    }

    // Foreground coral scrolls faster than the background for camera parallax.
    canvas.save();
    canvas.translate(-cameraShift * .12, 0);
    _drawCoral(canvas, Offset(w * .04, h * .89), h * .13, const Color(0xFFDA786D));
    _drawCoral(canvas, Offset(w * .91, h * .91), h * .18, const Color(0xFFD9A26F));
    canvas.restore();

    for (final bubble in bubbles) {
      final depth = bubble.dy.clamp(0.0, 1.0).toDouble();
      final radius = 1.8 + depth * 3.1;
      final center = Offset(bubble.dx * w - cameraShift * .025, bubble.dy * h);
      canvas.drawCircle(
        center.translate(radius * .3, radius * .6),
        radius * 1.25,
        Paint()..color = Colors.black.withAlpha((24 + 26 * depth).round()),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withAlpha(145), const Color(0x6672D7E6)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center.translate(-radius * .16, -radius * .16), radius: radius * .58),
        pi * 1.05,
        pi * .8,
        false,
        Paint()
          ..color = Colors.white.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, radius * .12),
      );
    }
    for (final item in items) {
      _drawItem(canvas, size, item);
    }
    if (collectFlash > 0) {
      final center = Offset(diverX * w - cameraShift * .02, diverY * h);
      final radius = 30 + 64 * collectFlash;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFB8FFE7).withAlpha((70 * collectFlash).round()),
              const Color(0xFF68F4D2).withAlpha((40 * collectFlash).round()),
              Colors.transparent,
            ],
            stops: const [0, .48, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
    _drawDiver(canvas, size);
  }

  void _drawItem(Canvas canvas, Size size, _Drift item) {
    final w = size.width;
    final h = size.height;
    final depth = ((item.y + .1) / 1.25).clamp(0.0, 1.0).toDouble();
    final depthScale = .52 + depth * .72;
    final center = Offset(item.x * w - (parallax - .5) * w * .035, item.y * h);
    final sizeFactor = depthScale * (item.kind == _Kind.puffer ? item.scale : 1.0);
    final glowColor = switch (item.kind) {
      _Kind.pearl => const Color(0xFFFFD98B),
      _Kind.shark || _Kind.puffer || _Kind.jelly => const Color(0xFF9ACBFF),
      _ => const Color(0xFF9AF4E5),
    };
    final glowRadius = (item.kind == _Kind.pearl ? 26.0 : 18.0) * depthScale;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [glowColor.withAlpha((38 + depth * 28).round()), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );
    final shadowRadius = switch (item.kind) {
      _Kind.shark => 25.0,
      _Kind.puffer => 19.0 * item.scale,
      _Kind.jelly => 18.0,
      _Kind.bottle || _Kind.glass || _Kind.bag || _Kind.straw => 15.0,
      _Kind.pearl => 12.0,
    } * depthScale;

    // Soft offset shadows ground each moving object against the distant water.
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(shadowRadius * .18, shadowRadius * .82),
        width: shadowRadius * 2.2,
        height: shadowRadius * .78,
      ),
      Paint()
        ..color = const Color(0xFF03141E).withAlpha((38 + depth * 46).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + depth * 4),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(sizeFactor);
    switch (item.kind) {
      case _Kind.bottle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(1, 2), width: 22, height: 46),
            const Radius.circular(7),
          ),
          Paint()..color = const Color(0xFF286A70),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 20, height: 44),
            const Radius.circular(7),
          ),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD6FFF0), Color(0xFF77D6CA), Color(0xFF318A90)],
            ).createShader(Rect.fromLTWH(-10, -22, 20, 44)),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -24), width: 8, height: 9),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFBCE9D7),
        );
        canvas.drawLine(const Offset(-5, -13), const Offset(-5, 13),
            Paint()..color = Colors.white.withAlpha(190)..strokeWidth = 2);
      case _Kind.glass:
        final glass = Path()
          ..moveTo(-11, -17)
          ..lineTo(11, -17)
          ..lineTo(7, 18)
          ..quadraticBezierTo(0, 22, -7, 18)
          ..close();
        canvas.drawPath(glass.shift(const Offset(1.5, 2)),
            Paint()..color = const Color(0xFF7697A0));
        canvas.drawPath(
          glass,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xAAD7F6F4), Color(0x447BD3D7)],
            ).createShader(Rect.fromLTWH(-11, -17, 22, 39)),
        );
        canvas.drawPath(
          glass,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFE1FFF7),
        );
        canvas.drawLine(const Offset(-7, 2), const Offset(7, 2),
            Paint()..color = Colors.white.withAlpha(135)..strokeWidth = 1.5);
      case _Kind.bag:
        final bag = Path()
          ..moveTo(-12, -12)
          ..quadraticBezierTo(-16, 10, -9, 18)
          ..quadraticBezierTo(0, 24, 11, 17)
          ..quadraticBezierTo(15, 2, 11, -12)
          ..lineTo(7, -7)
          ..quadraticBezierTo(0, -14, -7, -7)
          ..close();
        canvas.drawPath(bag.shift(const Offset(1, 2)), Paint()..color = const Color(0xFF7C9E9E));
        canvas.drawPath(
          bag,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4FFEB), Color(0xBFE1E7D8), Color(0x8097B1B4)],
            ).createShader(Rect.fromLTWH(-16, -14, 32, 40)),
        );
        canvas.drawPath(
          bag,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFEFFFF0),
        );
        canvas.drawLine(const Offset(-7, -8), const Offset(-10, -19),
            Paint()..color = const Color(0xFFE4F2E3)..strokeWidth = 3);
        canvas.drawLine(const Offset(7, -8), const Offset(10, -19),
            Paint()..color = const Color(0xFFE4F2E3)..strokeWidth = 3);
      case _Kind.straw:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(1.5, 2), width: 8, height: 44),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFF8D5A31),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 7, height: 43),
            const Radius.circular(3),
          ),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFFE7A1), Color(0xFFD89A45), Color(0xFFAC692E)],
            ).createShader(Rect.fromLTWH(-4, -22, 8, 44)),
        );
        canvas.drawLine(const Offset(-1.5, -18), const Offset(-1.5, 15),
            Paint()..color = Colors.white.withAlpha(150)..strokeWidth = 1.2);
      case _Kind.jelly:
        final bell = Rect.fromCenter(center: const Offset(0, -2), width: 36, height: 29);
        canvas.drawArc(bell, pi, pi, true,
            Paint()
              ..shader = const RadialGradient(
                colors: [Color(0xFFF1C9F4), Color(0xFFC68BD7), Color(0xFF875AAB)],
              ).createShader(bell));
        canvas.drawArc(
          bell,
          pi,
          pi,
          true,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(0xFFF6D9F5),
        );
        for (var i = -2; i <= 2; i++) {
          final x = i * 5.0;
          final tentacle = Path()
            ..moveTo(x, 10)
            ..cubicTo(x - 5, 17, x + 5, 23, x, 31);
          canvas.drawPath(
            tentacle,
            Paint()
              ..color = const Color(0xFFDDA8E2).withAlpha(210)
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke,
          );
        }
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(-5, -7), width: 14, height: 10),
          pi,
          pi,
          false,
          Paint()..color = Colors.white.withAlpha(170)..strokeWidth = 2,
        );
      case _Kind.shark:
        final body = Path()
          ..moveTo(28, 0)
          ..quadraticBezierTo(7, -18, -18, -9)
          ..lineTo(-28, -15)
          ..lineTo(-24, -3)
          ..lineTo(-30, 7)
          ..lineTo(-15, 8)
          ..quadraticBezierTo(6, 19, 28, 0)
          ..close();
        canvas.drawPath(body.shift(const Offset(1, 3)), Paint()..color = const Color(0xFF101F2A));
        canvas.drawPath(
          body,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7A9CAA), Color(0xFF354E60), Color(0xFF172C3A)],
            ).createShader(Rect.fromLTWH(-30, -16, 60, 36)),
        );
        final fin = Path()
          ..moveTo(-3, -8)
          ..lineTo(3, -23)
          ..lineTo(9, -5)
          ..close();
        canvas.drawPath(fin, Paint()..color = const Color(0xFF293E4B));
        canvas.drawCircle(const Offset(16, -3), 1.8, Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(16, -3), 1, Paint()..color = Colors.black87);
        canvas.drawArc(
          Rect.fromLTWH(16, 1, 8, 5),
          0,
          pi,
          false,
          Paint()..color = Colors.white.withAlpha(210)..strokeWidth = 1,
        );
      case _Kind.puffer:
        final radius = 14.0 * item.scale;
        final spike = Paint()
          ..color = const Color(0xFF9E6B31)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 10; i++) {
          final angle = i * pi / 5;
          canvas.drawLine(
            Offset(cos(angle), sin(angle)) * radius,
            Offset(cos(angle), sin(angle)) * (radius + 7),
            spike,
          );
        }
        canvas.drawCircle(
          Offset.zero,
          radius,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.4, -.5),
              colors: [const Color(0xFFFFF0A9), const Color(0xFFE6C36A), const Color(0xFFB78038)],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
        );
        canvas.drawCircle(const Offset(-5, -3), 2.1, Paint()..color = Colors.black87);
        canvas.drawCircle(const Offset(5, -3), 2.1, Paint()..color = Colors.black87);
        canvas.drawArc(
          Rect.fromLTWH(-4, 1, 8, 5),
          0,
          pi,
          false,
          Paint()..color = const Color(0xFF754A32)..strokeWidth = 1.4,
        );
      case _Kind.pearl:
        canvas.drawCircle(Offset.zero, 14,
            Paint()..color = FeltColors.brass.withAlpha(100));
        canvas.drawCircle(
          Offset.zero,
          11,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.4, -.45),
              colors: [Color(0xFFFFFFFF), Color(0xFFF9EBD6), Color(0xFFB89F82)],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: 11)),
        );
        canvas.drawCircle(
          Offset.zero,
          14,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = FeltColors.brass,
        );
        canvas.drawCircle(const Offset(-3, -4), 2,
            Paint()..color = Colors.white.withAlpha(220));
    }
    canvas.restore();
  }
  void _drawDiver(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(diverX * w - (parallax - .5) * w * .02, diverY * h);
    final depth = .7 + diverY * .38;

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(w * .015, h * .026),
        width: w * .15 * depth,
        height: h * .035 * depth,
      ),
      Paint()
        ..color = Colors.black.withAlpha(95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(lean * .35);
    canvas.scale(depth);

    if (shielded) {
      canvas.drawCircle(
        Offset.zero,
        38,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x4478E9FF), Color(0x2278E9FF), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: 40)),
      );
      canvas.drawCircle(
        Offset.zero,
        36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = FeltColors.brass,
      );
      canvas.drawCircle(
        Offset.zero,
        40,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withAlpha(145),
      );
    }

    // Fins and backpack sit behind the suit body.
    final finPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF42A9B8), Color(0xFF125166), Color(0xFF082C3C)],
      ).createShader(Rect.fromLTWH(-28, 0, 56, 30));
    final leftFin = Path()
      ..moveTo(-7, 10)
      ..lineTo(-26, 17)
      ..lineTo(-33, 28)
      ..lineTo(-4, 24)
      ..close();
    final rightFin = Path()
      ..moveTo(7, 10)
      ..lineTo(26, 17)
      ..lineTo(33, 28)
      ..lineTo(4, 24)
      ..close();
    canvas.drawPath(leftFin.shift(const Offset(1, 2)), Paint()..color = Colors.black45);
    canvas.drawPath(rightFin.shift(const Offset(1, 2)), Paint()..color = Colors.black45);
    canvas.drawPath(leftFin, finPaint);
    canvas.drawPath(rightFin, finPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -2), width: 31, height: 34),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFF173A45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-17, -2), width: 8, height: 25),
        const Radius.circular(4),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD47C), Color(0xFFB67734)],
        ).createShader(Rect.fromLTWH(-21, -15, 8, 25)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(17, -2), width: 8, height: 25),
        const Radius.circular(4),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD47C), Color(0xFFB67734)],
        ).createShader(Rect.fromLTWH(13, -15, 8, 25)),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, 0), width: 25, height: 31),
        const Radius.circular(9),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E91A4), Color(0xFF1A596B), Color(0xFF0B3448)],
        ).createShader(Rect.fromLTWH(-13, -16, 26, 32)),
    );
    canvas.drawLine(const Offset(-9, -10), const Offset(9, -10),
        Paint()..color = Colors.white.withAlpha(110)..strokeWidth = 2);

    // Helmet, glass visor and reflected surface glint.
    canvas.drawCircle(const Offset(0, -22), 14, Paint()..color = const Color(0xFFDBB395));
    canvas.drawCircle(
      const Offset(0, -22),
      12,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          colors: [Color(0xFFE7FFFF), Color(0xFF8FD6E8), Color(0xFF337D98)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 13)),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(-2, -27), width: 13, height: 8),
      pi,
      pi * .72,
      false,
      Paint()
        ..color = Colors.white.withAlpha(210)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(const Offset(8, -18), 2.4, Paint()..color = const Color(0xFFFFD47C));
    canvas.restore();
  }

  void _drawCoral(Canvas canvas, Offset base, double height, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: base, width: height * .7, height: height * .14),
      Paint()..color = Colors.black.withAlpha(70),
    );
    final branch = Paint()
      ..color = color
      ..strokeWidth = height * .095
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final highlight = Paint()
      ..color = Colors.white.withAlpha(65)
      ..strokeWidth = height * .025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final paths = <Path>[
      Path()..moveTo(base.dx, base.dy)..cubicTo(base.dx - 5, base.dy - height * .3,
          base.dx - height * .12, base.dy - height * .45, base.dx - height * .08, base.dy - height * .72),
      Path()..moveTo(base.dx - height * .06, base.dy - height * .48)
        ..quadraticBezierTo(base.dx - height * .25, base.dy - height * .62,
            base.dx - height * .23, base.dy - height * .88),
      Path()..moveTo(base.dx - height * .08, base.dy - height * .67)
        ..quadraticBezierTo(base.dx + height * .07, base.dy - height * .77,
            base.dx + height * .02, base.dy - height * .96),
      Path()..moveTo(base.dx, base.dy - height * .25)
        ..quadraticBezierTo(base.dx + height * .16, base.dy - height * .39,
            base.dx + height * .17, base.dy - height * .64),
    ];
    for (final path in paths) {
      canvas.drawPath(path.shift(const Offset(2, 3)), Paint()
        ..color = Colors.black.withAlpha(65)
        ..strokeWidth = branch.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);
      canvas.drawPath(path, branch);
      canvas.drawPath(path, highlight);
    }
    for (final point in [
      Offset(base.dx - height * .08, base.dy - height * .72),
      Offset(base.dx - height * .23, base.dy - height * .88),
      Offset(base.dx + height * .02, base.dy - height * .96),
      Offset(base.dx + height * .17, base.dy - height * .64),
    ]) {
      canvas.drawCircle(point, height * .05, Paint()..color = color.withAlpha(230));
      canvas.drawCircle(point.translate(-height * .012, -height * .016), height * .021,
          Paint()..color = Colors.white.withAlpha(140));
    }
  }
  @override
  bool shouldRepaint(covariant _OceanPainter oldDelegate) => true;
}
