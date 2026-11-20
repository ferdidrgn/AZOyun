import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

bool carromNearPocket(double x, double y) {
  const pockets = [0.08, 0.92];
  for (final px in pockets) {
    for (final py in pockets) {
      final dx = x - px;
      final dy = y - py;
      if (dx * dx + dy * dy < 0.07 * 0.07) {
        return true;
      }
    }
  }
  return false;
}

class CarromLobbyScreen extends StatelessWidget {
  const CarromLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Karambol',
        emoji: '🟠',
        gradient: AZColors.gradGreen,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Açıyı ve gücü ayarla, vur. Pulları köşe ceplerine sok. Üç atış.',
      );
}

class CarromGameScreen extends StatelessWidget {
  const CarromGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'carrom',
        gradient: AZColors.gradGreen,
        title: 'Karambol',
        emoji: '🟠',
        formatScore: (score) => '$score pul',
        sessionBuilder: (context, player, onFinished) =>
            _CarromSession(player: player, onFinished: onFinished),
      );
}

class _Disk {
  _Disk({required this.x, required this.y, required this.coin});
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  final bool coin;
  bool gone = false;
}

class _CarromSession extends StatefulWidget {
  const _CarromSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_CarromSession> createState() => _CarromSessionState();
}

class _CarromSessionState extends State<_CarromSession> {
  static const _radius = 0.035;
  late List<_Disk> _disks = _rack();
  Timer? _timer;
  double _angle = 0;
  double _power = 0.6;
  int _shots = 0;
  int _score = 0;
  bool _moving = false;

  List<_Disk> _rack() {
    final disks = <_Disk>[_Disk(x: 0.5, y: 0.78, coin: false)];
    const spots = [
      (0.50, 0.40),
      (0.44, 0.46),
      (0.56, 0.46),
      (0.50, 0.52),
      (0.42, 0.36),
      (0.58, 0.36),
    ];
    for (final spot in spots) {
      disks.add(_Disk(x: spot.$1, y: spot.$2, coin: true));
    }
    return disks;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _shoot() {
    if (_moving || _shots >= 3) {
      return;
    }
    final striker = _disks.firstWhere((disk) => !disk.coin && !disk.gone);
    final radians = _angle * pi / 180;
    striker.vx = sin(radians) * _power * 0.04;
    striker.vy = -cos(radians) * _power * 0.04;
    _shots++;
    _moving = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _step());
  }

  void _step() {
    for (var n = 0; n < 4; n++) {
      for (final disk in _disks) {
        if (disk.gone) {
          continue;
        }
        disk.x += disk.vx;
        disk.y += disk.vy;
        disk.vx *= 0.985;
        disk.vy *= 0.985;
        if (disk.x < 0.08 || disk.x > 0.92) {
          disk.vx = -disk.vx;
          disk.x = disk.x.clamp(0.08, 0.92);
        }
        if (disk.y < 0.08 || disk.y > 0.92) {
          disk.vy = -disk.vy;
          disk.y = disk.y.clamp(0.08, 0.92);
        }
        if (disk.coin && carromNearPocket(disk.x, disk.y)) {
          disk.gone = true;
          disk.vx = 0;
          disk.vy = 0;
          _score++;
        }
        if (!disk.coin && carromNearPocket(disk.x, disk.y)) {
          disk.x = 0.5;
          disk.y = 0.78;
          disk.vx = 0;
          disk.vy = 0;
        }
      }
      for (var i = 0; i < _disks.length; i++) {
        for (var j = i + 1; j < _disks.length; j++) {
          final a = _disks[i];
          final b = _disks[j];
          if (a.gone || b.gone) {
            continue;
          }
          final dx = b.x - a.x;
          final dy = b.y - a.y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist == 0 || dist > _radius * 2) {
            continue;
          }
          final nx = dx / dist;
          final ny = dy / dist;
          final overlap = _radius * 2 - dist;
          a.x -= nx * overlap / 2;
          a.y -= ny * overlap / 2;
          b.x += nx * overlap / 2;
          b.y += ny * overlap / 2;
          final rel = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny;
          if (rel > 0) {
            a.vx -= rel * nx;
            a.vy -= rel * ny;
            b.vx += rel * nx;
            b.vy += rel * ny;
          }
        }
      }
    }
    final resting = _disks.where((disk) => !disk.gone).every(
          (disk) => disk.vx.abs() < 0.0008 && disk.vy.abs() < 0.0008,
        );
    if (resting) {
      _timer?.cancel();
      _moving = false;
      if (_shots >= 3 || _disks.where((disk) => disk.coin && !disk.gone).isEmpty) {
        widget.onFinished(_score);
        return;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Atış $_shots/3  $_score pul',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _CarromPainter(disks: _disks),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Text('Açı ${_angle.round()}°', style: const TextStyle(color: Colors.white)),
        Slider(
          value: _angle,
          min: -50,
          max: 50,
          activeColor: FeltColors.brass,
          onChanged: _moving ? null : (value) => setState(() => _angle = value),
        ),
        Text('Güç ${(_power * 100).round()}', style: const TextStyle(color: Colors.white)),
        Slider(
          value: _power,
          min: 0.3,
          max: 1,
          activeColor: FeltColors.brass,
          onChanged: _moving ? null : (value) => setState(() => _power = value),
        ),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _moving ? null : _shoot,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AZColors.greenDk,
            ),
            child: const Text('Vur'),
          ),
        ),
      ],
    );
  }
}

class _CarromPainter extends CustomPainter {
  _CarromPainter({required this.disks});

  final List<_Disk> disks;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bilinear-ish projection: the far edge narrows, while the near rail
    // grows toward the player. Disk coordinates stay normalized, so the
    // existing collision and pocket rules are unchanged.
    Offset project(double x, double y) {
      final taper = .08 * (1 - y);
      return Offset(w * (.055 + taper + x * (.89 - taper * 2)),
          h * (.035 + y * .93));
    }

    Path polygon(List<Offset> points) => Path()..addPolygon(points, true);

    Path boardPath(double inset) => polygon([
          project(inset, inset),
          project(1 - inset, inset),
          project(1 - inset, 1 - inset),
          project(inset, 1 - inset),
        ]);

    final outline = boardPath(0);
    final rail = boardPath(.028);
    final playSurface = boardPath(.052);

    // Drop shadow and a layered, beveled wood frame.
    canvas.drawPath(
      outline.shift(Offset(0, h * .018)),
      Paint()
        ..color = Colors.black.withAlpha(125)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECCB91), Color(0xFF9C5B32), Color(0xFF4B281C)],
          stops: [0, .48, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      rail,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE3B3), Color(0xFFBD7944), Color(0xFF744127)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      rail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFFFE8C1).withAlpha(150),
    );

    canvas.save();
    canvas.clipPath(playSurface);
    canvas.drawPath(
      playSurface,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8EACD), Color(0xFFE6D1A9), Color(0xFFD8BE91)],
        ).createShader(Offset.zero & size),
    );

    // Soft wood-grain lines along the board face.
    for (var i = 0; i < 8; i++) {
      final y = .12 + i * .105;
      canvas.drawLine(
        project(.07, y),
        project(.93, y + .012),
        Paint()
          ..color = const Color(0xFF8D6945).withAlpha(i.isEven ? 15 : 9)
          ..strokeWidth = 1,
      );
    }

    // Carrom guide rings, baseline and arrows, projected onto the same board.
    final center = project(.5, .5);
    for (final scale in [1.0, .78]) {
      final oval = Rect.fromCenter(
        center: center,
        width: w * .31 * scale,
        height: h * .22 * scale,
      );
      canvas.drawOval(
        oval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale == 1 ? 1.6 : 1
          ..color = FeltColors.brass.withAlpha(scale == 1 ? 125 : 80),
      );
    }
    canvas.drawCircle(center, w * .012,
        Paint()..color = FeltColors.brass.withAlpha(135));
    for (final y in [.735, .825]) {
      canvas.drawLine(
        project(.13, y),
        project(.87, y),
        Paint()
          ..color = FeltColors.brass.withAlpha(y < .8 ? 130 : 85)
          ..strokeWidth = y < .8 ? 1.8 : 1,
      );
    }
    for (final x in [.08, .92]) {
      for (final y in [.08, .92]) {
        final point = project(x, y);
        final depth = .74 + y * .26;
        final radius = w * .041 * depth;
        canvas.drawCircle(point.translate(0, radius * .12), radius * 1.34,
            Paint()..color = const Color(0xFF9B713D).withAlpha(85));
        canvas.drawCircle(point, radius * 1.12,
            Paint()..color = const Color(0xFF3A211A));
        canvas.drawCircle(point.translate(-radius * .1, -radius * .12), radius * .89,
            Paint()
              ..shader = RadialGradient(
                colors: [const Color(0xFF241710), const Color(0xFF080707)],
              ).createShader(Rect.fromCircle(center: point, radius: radius)));
        canvas.drawCircle(
          point,
          radius * 1.12,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFFFE5B5).withAlpha(175),
        );
      }
    }
    canvas.restore();

    // Raised inset lip catches a narrow highlight along the playing face.
    canvas.drawPath(
      playSurface,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withAlpha(155),
    );

    for (final disk in disks) {
      if (disk.gone) {
        continue;
      }
      final point = project(disk.x, disk.y);
      final depth = .76 + disk.y * .34;
      final radius = w * .035 * depth;
      final body = Rect.fromCircle(center: point, radius: radius);
      final base = disk.coin ? const Color(0xFFFFF8E9) : const Color(0xFFD79842);
      final shade = disk.coin ? const Color(0xFFAA895B) : const Color(0xFF79501E);

      // Floating contact shadow and deep outer rim make each piece read as
      // a thick, rounded disk instead of a flat dot.
      canvas.drawOval(
        Rect.fromCenter(
          center: point.translate(radius * .12, radius * .42),
          width: radius * 2.35,
          height: radius * 1.05,
        ),
        Paint()
          ..color = Colors.black.withAlpha(105)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(point.translate(0, radius * .12), radius * 1.07,
          Paint()..color = shade.withAlpha(230));
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.42, -.52),
            radius: 1.1,
            colors: [Colors.white, base, shade],
            stops: const [0, .62, 1],
          ).createShader(body),
      );
      canvas.drawCircle(
        point,
        radius * .76,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .075
          ..color = (disk.coin ? const Color(0xFFB49668) : Colors.white).withAlpha(155),
      );
      canvas.drawCircle(
        point.translate(-radius * .28, -radius * .3),
        radius * .18,
        Paint()..color = Colors.white.withAlpha(disk.coin ? 205 : 150),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CarromPainter oldDelegate) => true;
}
