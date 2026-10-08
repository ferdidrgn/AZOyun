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
  });

  final double diverX;
  final double diverY;
  final double lean;
  final List<_Drift> items;
  final List<Offset> bubbles;
  final bool shielded;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A6B8A), Color(0xFF0C3A4A), Color(0xFF08242E)],
        ).createShader(rect),
    );
    final bubblePaint = Paint()..color = const Color(0x66F4EFE6);
    for (final bubble in bubbles) {
      canvas.drawCircle(
        Offset(bubble.dx * size.width, bubble.dy * size.height),
        4,
        bubblePaint,
      );
    }
    for (final item in items) {
      _drawItem(canvas, size, item);
    }
    _drawDiver(canvas, size);
  }

  void _drawItem(Canvas canvas, Size size, _Drift item) {
    final center = Offset(item.x * size.width, item.y * size.height);
    switch (item.kind) {
      case _Kind.bottle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 16, height: 36),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFF7FD0C8),
        );
      case _Kind.glass:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 18, height: 32),
            const Radius.circular(4),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFD7EDE4),
        );
      case _Kind.bag:
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 28, height: 34),
          Paint()..color = const Color(0xAAF4EFE6),
        );
      case _Kind.straw:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 6, height: 40),
            const Radius.circular(3),
          ),
          Paint()..color = FeltColors.brass,
        );
      case _Kind.jelly:
        canvas.drawArc(
          Rect.fromCenter(center: center, width: 36, height: 28),
          pi,
          pi,
          true,
          Paint()..color = const Color(0xFFC9A0D4),
        );
      case _Kind.shark:
        final nose = item.vx >= 0 ? 26.0 : -26.0;
        final path = Path()
          ..moveTo(center.dx + nose, center.dy)
          ..lineTo(center.dx - nose, center.dy - 12)
          ..lineTo(center.dx - nose, center.dy + 12)
          ..close();
        canvas.drawPath(path, Paint()..color = const Color(0xFF1C2830));
      case _Kind.puffer:
        final radius = 14.0 * item.scale;
        canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFE6C36A));
        final spike = Paint()
          ..color = const Color(0xFF8A6230)
          ..strokeWidth = 2;
        for (var i = 0; i < 6; i++) {
          final angle = i * pi / 3;
          canvas.drawLine(
            center + Offset(cos(angle), sin(angle)) * radius,
            center + Offset(cos(angle), sin(angle)) * (radius + 8),
            spike,
          );
        }
      case _Kind.pearl:
        canvas.drawCircle(center, 10, Paint()..color = FeltColors.ivory);
        canvas.drawCircle(
          center,
          14,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = FeltColors.brass,
        );
    }
  }

  void _drawDiver(Canvas canvas, Size size) {
    final center = Offset(diverX * size.width, diverY * size.height);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(lean * 0.35);
    canvas.translate(-center.dx, -center.dy);
    if (shielded) {
      canvas.drawCircle(
        center,
        36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = FeltColors.brass,
      );
    }
    canvas.drawCircle(center.translate(0, -16), 10, Paint()..color = const Color(0xFFE7C8A8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 22, height: 28),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF12343F),
    );
    canvas.drawCircle(center.translate(0, -16), 7, Paint()..color = const Color(0xFF8FD4E8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OceanPainter oldDelegate) => true;
}
