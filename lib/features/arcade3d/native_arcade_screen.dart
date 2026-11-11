import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arcade_camera.dart';

enum NativeArcadeGame {
  runway('Neon Pist',
      'Engellerden kaç, enerji küplerini topla ve 35 saniyeyi tamamla.'),
  drones('Sinyal Avı',
      'Yaklaşan keşif dronlarına dokun. Dört dron kaçarsa görev biter.');

  const NativeArcadeGame(this.title, this.instructions);
  final String title;
  final String instructions;
}

class NativeArcadeScreen extends StatefulWidget {
  const NativeArcadeScreen({super.key, required this.game});

  final NativeArcadeGame game;

  @override
  State<NativeArcadeScreen> createState() => _NativeArcadeScreenState();
}

class _NativeArcadeScreenState extends State<NativeArcadeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _world = _ArcadeWorld(widget.game);
  late final _ticker = createTicker(_tick);
  final _paintFrame = ValueNotifier<int>(0);
  Duration? _previous;
  bool _started = false;
  bool _finished = false;
  bool _paused = false;
  int _best = 0;
  bool get _runway => widget.game == NativeArcadeGame.runway;

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
    _paintFrame.dispose();
    _keyboard.dispose();
    super.dispose();
  }

  String get _scoreKey => 'az_arcade3d_best_${widget.game.name}';

  Future<void> _loadBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted)
        setState(() => _best = math.max(_best, prefs.getInt(_scoreKey) ?? 0));
    } catch (error) {
      debugPrint('3D arcade rekor okuma: $error');
    }
  }

  Future<void> _saveBest(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (score > (prefs.getInt(_scoreKey) ?? 0)) {
        await prefs.setInt(_scoreKey, score);
      }
    } catch (error) {
      debugPrint('3D arcade rekor kaydı: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _ticker.isActive) _pause();
  }

  void _start() {
    _world.reset();
    setState(() {
      _started = true;
      _finished = false;
      _paused = false;
    });
    _resume();
  }

  void _pause() {
    _ticker.stop();
    setState(() => _paused = true);
  }

  void _resume() {
    _previous = null;
    _ticker.start();
    setState(() => _paused = false);
  }

  void _tick(Duration elapsed) {
    final previous = _previous;
    _previous = elapsed;
    if (previous == null) return;
    final dt = math.min(.05, (elapsed - previous).inMicroseconds / 1000000);
    final hud = (_world.score, _world.lives, _world.remaining);
    _world.advance(dt);
    _paintFrame.value++;
    if (_world.done) {
      _ticker.stop();
      _finished = true;
      _best = math.max(_best, _world.score);
      unawaited(_saveBest(_world.score));
    }
    if (_finished || hud != (_world.score, _world.lives, _world.remaining)) {
      setState(() {});
    }
  }

  void _move(int direction) {
    if (_ticker.isActive) _world.move(direction);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF101923),
        appBar: AppBar(title: Text(widget.game.title)),
        body: SafeArea(
          child: KeyboardListener(
            focusNode: _keyboard,
            autofocus: true,
            onKeyEvent: (event) {
              if (event is! KeyDownEvent || !_runway) return;
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _move(-1);
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) _move(1);
            },
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Skor ${_world.score}', style: _hud),
                      Text('Rekor $_best', style: _hud),
                      Text('Can ${_world.lives}', style: _hud),
                      Text('${_world.remaining} sn', style: _hud),
                      if (_ticker.isActive)
                        IconButton(
                          onPressed: _pause,
                          color: Colors.white,
                          tooltip: 'Duraklat',
                          icon: const Icon(Icons.pause),
                        ),
                    ],
                  ),
                ),
                Expanded(child: LayoutBuilder(builder: (context, constraints) {
                  final size = constraints.biggest;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: !_runway && _ticker.isActive
                            ? (event) => setState(() => _world.tag(
                                event.localPosition, ArcadeCamera(size)))
                            : null,
                        child: RepaintBoundary(
                            child: CustomPaint(
                          painter: _ArcadePainter(_world, _paintFrame),
                        )),
                      ),
                      if (!_started || _paused || _finished)
                        Center(
                            child: SingleChildScrollView(child: _roundPanel())),
                    ],
                  );
                })),
                if (_runway)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                            onPressed:
                                _ticker.isActive ? () => _move(-1) : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Sol')),
                        const SizedBox(width: 18),
                        FilledButton.tonalIcon(
                            onPressed: _ticker.isActive ? () => _move(1) : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Sağ')),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Dronları hedef almak için üzerlerine dokun.',
                        style: _hud),
                  ),
              ],
            ),
          ),
        ),
      );

  final _keyboard = FocusNode();

  Widget _roundPanel() => Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: const Color(0xFF202F3A),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _finished
                        ? (_world.lives > 0
                            ? 'Görev tamamlandı'
                            : 'Tur sona erdi')
                        : _paused
                            ? 'Duraklatıldı'
                            : widget.game.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      _finished
                          ? '${_world.score} puan'
                          : widget.game.instructions,
                      textAlign: TextAlign.center,
                      style: _hud),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _paused ? _resume : _start,
                    child: Text(_paused
                        ? 'Devam et'
                        : _finished
                            ? 'Tekrar oyna'
                            : 'Başla'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

const _hud = TextStyle(color: Color(0xFFE1F5F4), fontSize: 14);

class _ArcadeWorld {
  _ArcadeWorld(this.game) {
    reset();
  }

  final NativeArcadeGame game;
  final _random = math.Random();
  final items = <_Object3>[];
  double time = 0;
  double _untilSpawn = .55;
  double x = 0;
  int _lane = 0;
  int score = 0;
  int lives = 3;

  bool get runway => game == NativeArcadeGame.runway;
  int get remaining => math.max(0, ((runway ? 35 : 40) - time).ceil());
  bool get done => remaining == 0 || lives == 0;
  double get speed => runway ? 10 + time * .24 : 5 + time * .15;

  void reset() {
    items.clear();
    time = 0;
    _untilSpawn = .55;
    x = 0;
    _lane = 0;
    score = 0;
    lives = runway ? 3 : 4;
  }

  void move(int direction) => _lane = (_lane + direction).clamp(-1, 1);

  void advance(double dt) {
    time += dt;
    x += (_lane * 2.1 - x) * math.min(1, dt * 12);
    _untilSpawn -= dt;
    if (_untilSpawn <= 0) {
      _untilSpawn = runway ? math.max(.64, 1.32 - time * .017) : 1.26;
      _spawn();
    }
    for (final item in items) {
      item.z -= speed * dt;
    }
    items.removeWhere((item) {
      if (item.z > .5) return false;
      if (!runway || (!item.energy && (item.x - x).abs() < .9)) {
        lives = math.max(0, lives - 1);
      } else if (!item.energy || (item.x - x).abs() < .9) {
        score += item.energy ? 5 : 1;
      }
      return true;
    });
  }

  void _spawn() {
    if (runway) {
      final blocked = _random.nextInt(3);
      final energy = (blocked + 1 + _random.nextInt(2)) % 3;
      items.add(_Object3((blocked - 1) * 2.1, .52, 32));
      items.add(_Object3((energy - 1) * 2.1, .68, 32, energy: true));
    } else {
      items.add(_Object3((_random.nextDouble() - .5) * 7,
          .8 + _random.nextDouble() * 2.5, 27));
    }
  }

  void tag(Offset tap, ArcadeCamera camera) {
    _Object3? hit;
    for (final item in items) {
      final point = item.point;
      final radius = math.max(20, camera.scaleAt(point) * .83);
      if ((camera.project(point) - tap).distance <= radius &&
          (hit == null || item.z < hit.z)) {
        hit = item;
      }
    }
    if (hit != null) {
      items.remove(hit);
      score += 10;
    }
  }
}

class _Object3 {
  _Object3(this.x, this.y, this.z, {this.energy = false});

  final double x;
  final double y;
  double z;
  final bool energy;

  Point3 get point => Point3(x, y, z);
}

class _ArcadePainter extends CustomPainter {
  _ArcadePainter(this.world, Listenable frames) : super(repaint: frames);

  final _ArcadeWorld world;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final camera = ArcadeCamera(size);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF19213F), Color(0xFF173A40), Color(0xFF0A171C)],
          ).createShader(Offset.zero & size));
    final grid = Paint()
      ..color = const Color(0x8056BAAA)
      ..strokeWidth = 1;
    for (final x in [-5.25, -3.15, -1.05, 1.05, 3.15, 5.25]) {
      camera.line(canvas, Point3(x, 0, -3), Point3(x, 0, 55), grid);
    }
    for (var z = -3.0; z < 54; z += 3) {
      final offset = z + 3 - (world.time * world.speed) % 3;
      camera.line(
          canvas, Point3(-5.25, 0, offset), Point3(5.25, 0, offset), grid);
    }
    final items = world.items.toList()..sort((a, b) => b.z.compareTo(a.z));
    for (final item in items) {
      if (world.runway) {
        camera.box(canvas, item.point,
            item.energy ? const Color(0xFF48F2C6) : const Color(0xFFFA7062),
            width: item.energy ? .62 : 1.3,
            height: item.energy ? .62 : 1.04,
            length: .7,
            angle: item.energy ? world.time * 2.8 : 0);
      } else {
        camera.box(canvas, item.point, const Color(0xFFFFB658),
            width: 1.45, height: .42, length: .68, angle: world.time * 2);
        camera.box(canvas, Point3(item.x, item.y + .27, item.z),
            const Color(0xFFA8FFF0),
            width: .52, height: .3, length: .51, angle: world.time * 2);
      }
    }
    if (world.runway) {
      camera.box(canvas, Point3(world.x, .3, 0), const Color(0xFF57D8FF),
          width: 1.15, height: .6, length: 1.32);
      camera.box(canvas, Point3(world.x, .72, .1), const Color(0xFFB1EBFF),
          width: .58, height: .27, length: .68);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcadePainter oldDelegate) => true;
}
