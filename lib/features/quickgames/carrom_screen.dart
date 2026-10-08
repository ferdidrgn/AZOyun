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
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = FeltColors.felt,
    );
    final pocket = Paint()..color = FeltColors.ink;
    for (final x in [0.08, 0.92]) {
      for (final y in [0.08, 0.92]) {
        canvas.drawCircle(Offset(x * size.width, y * size.height), 10, pocket);
      }
    }
    for (final disk in disks) {
      if (disk.gone) {
        continue;
      }
      canvas.drawCircle(
        Offset(disk.x * size.width, disk.y * size.height),
        size.width * 0.035,
        Paint()..color = disk.coin ? FeltColors.ivory : FeltColors.brass,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CarromPainter oldDelegate) => true;
}
