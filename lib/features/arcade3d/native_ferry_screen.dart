import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fully native, touch-first ferry game. No browser or WebView is involved.
class NativeFerryScreen extends StatefulWidget {
  const NativeFerryScreen({super.key});

  @override
  State<NativeFerryScreen> createState() => _NativeFerryScreenState();
}

class _NativeFerryScreenState extends State<NativeFerryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _FerryWorld _world = _FerryWorld();
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<int> _frame = ValueNotifier(0);
  Duration? _previous;
  bool _started = false;
  bool _paused = false;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadBest());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  Future<void> _loadBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _best = prefs.getInt('az_ferry_best') ?? 0);
    } catch (error) {
      debugPrint('Vapur rekoru okunamadı: $error');
    }
  }

  Future<void> _saveBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_world.score > (prefs.getInt('az_ferry_best') ?? 0)) {
        await prefs.setInt('az_ferry_best', _world.score);
      }
    } catch (error) {
      debugPrint('Vapur rekoru kaydedilemedi: $error');
    }
  }

  void _start() {
    _world.reset();
    setState(() {
      _started = true;
      _paused = false;
    });
    _previous = null;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final previous = _previous;
    _previous = elapsed;
    if (previous == null) return;
    _world.advance(math.min(.05, (elapsed - previous).inMicroseconds / 1e6));
    _frame.value++;
    if (_world.done) {
      _ticker.stop();
      _best = math.max(_best, _world.score);
      unawaited(_saveBest());
      setState(() {});
    }
  }

  void _steer(Offset delta) {
    if (_ticker.isActive) _world.steer(delta.dx, delta.dy);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _ticker.isActive) {
      _ticker.stop();
      setState(() => _paused = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF101923),
        appBar: AppBar(title: const Text('Vapur 84')),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('BİLET', '${_world.score}'),
                  _stat('CAN', '${_world.lives}'),
                  _stat('SÜRE', '${_world.remaining}s'),
                  _stat('REKOR', '$_best'),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, bounds) {
                final size = Size(bounds.maxWidth, bounds.maxHeight);
                return Stack(fit: StackFit.expand, children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (event) => _steer(event.delta),
                    onTapDown: (event) {
                      final center = bounds.maxWidth / 2;
                      _steer(Offset(
                          event.localPosition.dx < center ? -48 : 48, 0));
                    },
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _FerryPainter(_world, _frame, size),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  if (!_started || _paused || _world.done)
                    Center(
                      child: Card(
                        color: const Color(0xEE172333),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                                _world.done
                                    ? 'Sefer tamamlandı'
                                    : _paused
                                        ? 'Duraklatıldı'
                                        : 'Vapur 84',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(
                                _world.done
                                    ? '${_world.score} bilet topladın.'
                                    : 'Vapurunu sürükle. Biletleri topla, şamandıralardan kaç.',
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Color(0xFFD2E3E8))),
                            const SizedBox(height: 16),
                            FilledButton(
                                onPressed: _start,
                                child: Text(_world.done
                                    ? 'Yeniden oyna'
                                    : _paused
                                        ? 'Devam et'
                                        : 'Seferi başlat')),
                          ]),
                        ),
                      ),
                    ),
                ]);
              }),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                  'Sürükle veya ekranın sağına/soluna dokun · Bilet +10 · Şamandıra −1 can',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB8C6D3))),
            ),
          ]),
        ),
      );

  Widget _stat(String label, String value) => Column(children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF9CB1BE), fontSize: 10, letterSpacing: 1.2)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: Color(0xFFFFD28C),
                fontSize: 19,
                fontWeight: FontWeight.w800)),
      ]);
}

class _FerryItem {
  _FerryItem(this.x, this.y, this.ticket);
  double x;
  double y;
  final bool ticket;
}

class _FerryWorld {
  final random = math.Random();
  final items = <_FerryItem>[];
  double x = .5;
  double elapsed = 0;
  double spawn = .5;
  int score = 0;
  int lives = 3;
  bool done = false;
  int get remaining => math.max(0, 60 - elapsed.floor());

  void reset() {
    items.clear();
    x = .5;
    elapsed = 0;
    spawn = .5;
    score = 0;
    lives = 3;
    done = false;
  }

  void steer(double dx, double dy) {
    x = (x + dx / 280).clamp(.08, .92);
  }

  void advance(double dt) {
    if (done) return;
    elapsed += dt;
    spawn -= dt;
    if (spawn <= 0) {
      items.add(_FerryItem(
          .1 + random.nextDouble() * .8, -.05, random.nextDouble() > .32));
      spawn = math.max(.38, 1.05 - elapsed * .008) + random.nextDouble() * .42;
    }
    final speed = .30 + elapsed * .002;
    for (final item in items) {
      item.y += speed * dt;
      if (item.y > .78 && item.y < .93 && (item.x - x).abs() < .12) {
        if (item.ticket) {
          score += 10;
          item.y = 2;
        } else {
          lives--;
          item.y = 2;
          if (lives <= 0) done = true;
        }
      }
    }
    items.removeWhere((item) => item.y > 1.12);
    if (elapsed >= 60) done = true;
  }
}

class _FerryPainter extends CustomPainter {
  _FerryPainter(this.world, this.frame, this.size) : super(repaint: frame);
  final _FerryWorld world;
  final ValueListenable<int> frame;
  final Size size;

  @override
  void paint(Canvas canvas, Size _) {
    final w = size.width, h = size.height;
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFF252642),
            Color(0xFF9B6275),
            Color(0xFF183448)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Offset.zero & size));
    final horizon = h * .53;
    final skyline = Paint()..color = const Color(0xFF343446);
    for (var i = 0; i < 24; i++) {
      final bx = w * i / 23;
      final bw = w / 28;
      final bh = h * (.07 + ((i * 17) % 9) / 100);
      canvas.drawRect(Rect.fromLTWH(bx, horizon - bh, bw, bh), skyline);
      for (var row = 0; row < 3; row++) {
        canvas.drawRect(
            Rect.fromLTWH(bx + bw * .25, horizon - bh + 5 + row * 8, 3, 3),
            Paint()..color = const Color(0xFFFFD28C).withValues(alpha: .45));
      }
    }
    final water = Paint()
      ..shader = const LinearGradient(
              colors: [Color(0xFF27485B), Color(0xFF0E2636)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, horizon, w, h - horizon));
    canvas.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), water);
    final wave = Paint()
      ..color = const Color(0xFF9ADACF).withValues(alpha: .18)
      ..strokeWidth = 2;
    for (var i = 0; i < 16; i++) {
      final yy = horizon + ((i * 31 + world.elapsed * 80) % (h - horizon));
      final xx = (i * 59.0 + world.elapsed * 46) % w;
      canvas.drawLine(Offset(xx, yy), Offset(xx + 18 + i % 4 * 7, yy), wave);
    }
    for (final item in world.items) {
      final px = item.x * w, py = horizon + item.y * (h - horizon);
      if (item.ticket) {
        final rect =
            Rect.fromCenter(center: Offset(px, py), width: 26, height: 18);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()..color = const Color(0xFFFFD284));
        canvas.drawLine(
            Offset(px - 5, py - 6),
            Offset(px - 5, py + 6),
            Paint()
              ..color = const Color(0xFF805737)
              ..strokeWidth = 2);
        canvas.drawCircle(
            Offset(px + 4, py), 2, Paint()..color = const Color(0xFF805737));
      } else {
        final path = Path()
          ..moveTo(px, py - 14)
          ..lineTo(px - 11, py + 9)
          ..lineTo(px + 11, py + 9)
          ..close();
        canvas.drawPath(path, Paint()..color = const Color(0xFFF0796E));
        canvas.drawCircle(
            Offset(px, py + 10), 9, Paint()..color = const Color(0xFFFFB6A1));
      }
    }
    _drawFerry(canvas, Offset(world.x * w, h * .84), math.min(w, h) / 300);
    final vignette = Paint()
      ..shader = RadialGradient(
              colors: [Colors.transparent, Colors.black.withValues(alpha: .34)],
              stops: const [.48, 1])
          .createShader(Offset(w / 2, h / 2) & Size(w, h));
    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _drawFerry(Canvas canvas, Offset c, double scale) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    final hull = Path()
      ..moveTo(-75, -5)
      ..lineTo(75, -5)
      ..lineTo(57, 25)
      ..lineTo(-55, 25)
      ..close();
    canvas.drawShadow(hull, Colors.black, 9, true);
    canvas.drawPath(hull, Paint()..color = const Color(0xFFED6E61));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-49, -34, 98, 31), const Radius.circular(7)),
        Paint()..color = const Color(0xFFFFF0D4));
    canvas.drawRect(const Rect.fromLTWH(-36, -51, 72, 17),
        Paint()..color = const Color(0xFFFAFAF1));
    canvas.drawRect(const Rect.fromLTWH(-23, -61, 46, 10),
        Paint()..color = const Color(0xFFFFD28C));
    final window = Paint()..color = const Color(0xFF5C8993);
    for (var i = -3; i <= 3; i++)
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(i * 12 - 4, -27, 8, 11), const Radius.circular(2)),
          window);
    canvas.drawLine(
        const Offset(-83, 27),
        const Offset(83, 27),
        Paint()
          ..color = const Color(0xFFF6C98A)
          ..strokeWidth = 4);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FerryPainter oldDelegate) =>
      oldDelegate.world != world || oldDelegate.size != size;
}
