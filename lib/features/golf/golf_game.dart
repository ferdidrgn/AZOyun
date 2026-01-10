import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 🎮 GOLF OYUNU - Sıra Hatası Düzeltildi
class GolfGame extends StatefulWidget {
  final String roomId;
  final String playerName;
  final Function(String message) onGameEvent;
  final VoidCallback onGameEnd;

  const GolfGame({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.onGameEvent,
    required this.onGameEnd,
  });

  @override
  State<GolfGame> createState() => _GolfGameState();
}

class _GolfGameState extends State<GolfGame>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;

  Offset ballPosition = const Offset(0.5, 0.9);
  Offset holePosition = const Offset(0.5, 0.1);
  Offset? dragStart;
  Offset? dragCurrent;

  Offset ballVelocity = Offset.zero;
  bool ballMoving = false;

  List<Offset> obstacles = [];
  List<Offset> windmills = [];
  List<double> windmillAngles = [];

  String? myPlayerKey;
  int myShots = 0;
  int currentHole = 1;
  bool isMyFinished = false;

  late AnimationController _animationController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    roomRef = _database.child('golf_rooms/${widget.roomId}');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateBall);

    _setupHole();
    _listenToRoom();
  }

  void _setupHole() {
    ballPosition = Offset(0.5, 0.9);
    ballVelocity = Offset.zero;

    holePosition = Offset(
      0.3 + _random.nextDouble() * 0.4,
      0.1 + _random.nextDouble() * 0.05,
    );

    obstacles.clear();
    windmills.clear();
    windmillAngles.clear();

    final obstacleCount = min(2 + currentHole, 5);
    for (int i = 0; i < obstacleCount; i++) {
      obstacles.add(
        Offset(
          0.15 + _random.nextDouble() * 0.7,
          0.25 + _random.nextDouble() * 0.5,
        ),
      );
    }

    if (currentHole >= 2) {
      final windmillCount = min((currentHole - 1) ~/ 2, 2);
      for (int i = 0; i < windmillCount; i++) {
        windmills.add(
          Offset(
            0.2 + _random.nextDouble() * 0.6,
            0.4 + _random.nextDouble() * 0.3,
          ),
        );
        windmillAngles.add(_random.nextDouble() * 2 * pi);
      }
    }

    myShots = 0;
    isMyFinished = false;
  }

  void _listenToRoom() {
    roomRef.onValue.listen((final event) {
      if (event.snapshot.value == null || !mounted) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      // Player key bul
      if (myPlayerKey == null) {
        final players = Map<String, dynamic>.from(data['players'] as Map);
        players.forEach((final key, final value) {
          if (value['name'] == widget.playerName) {
            myPlayerKey = key;
          }
        });
      }

      // Delik değişti mi?
      final newHole = data['currentHole'] ?? 1;
      if (newHole != currentHole && mounted) {
        setState(() {
          currentHole = newHole;
          _setupHole();
        });
      }

      // Oyun bitti mi?
      if (data['status'] == 'finished') {
        widget.onGameEnd();
      }
    });
  }

  void _updateBall() {
    if (!ballMoving) return;

    setState(() {
      ballPosition = Offset(
        ballPosition.dx + ballVelocity.dx * 0.025,
        ballPosition.dy + ballVelocity.dy * 0.025,
      );

      ballVelocity = Offset(
        ballVelocity.dx * 0.98,
        ballVelocity.dy * 0.98,
      );

      if (ballPosition.dx < 0.03 || ballPosition.dx > 0.97) {
        ballVelocity = Offset(-ballVelocity.dx * 0.7, ballVelocity.dy);
        ballPosition = Offset(
          ballPosition.dx.clamp(0.03, 0.97),
          ballPosition.dy,
        );
      }

      if (ballPosition.dy < 0.03 || ballPosition.dy > 0.97) {
        ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy * 0.7);
        ballPosition = Offset(
          ballPosition.dx,
          ballPosition.dy.clamp(0.03, 0.97),
        );
      }

      // Engel çarpışması
      for (var obstacle in obstacles) {
        final distance = sqrt(
          pow(ballPosition.dx - obstacle.dx, 2) +
              pow(ballPosition.dy - obstacle.dy, 2),
        );

        if (distance < 0.06) {
          final dx = ballPosition.dx - obstacle.dx;
          final dy = ballPosition.dy - obstacle.dy;
          final angle = atan2(dy, dx);

          ballVelocity = Offset(
            cos(angle) * ballVelocity.distance * 0.7,
            sin(angle) * ballVelocity.distance * 0.7,
          );

          ballPosition = Offset(
            obstacle.dx + cos(angle) * 0.06,
            obstacle.dy + sin(angle) * 0.06,
          );
        }
      }

      // Yel değirmeni çarpışması
      for (int i = 0; i < windmills.length; i++) {
        windmillAngles[i] += 0.05;

        final windmill = windmills[i];
        final distance = sqrt(
          pow(ballPosition.dx - windmill.dx, 2) +
              pow(ballPosition.dy - windmill.dy, 2),
        );

        if (distance < 0.08) {
          final dx = ballPosition.dx - windmill.dx;
          final dy = ballPosition.dy - windmill.dy;
          final angle = atan2(dy, dx);

          ballVelocity = Offset(cos(angle) * 0.5, sin(angle) * 0.5);
        }
      }

      if (ballVelocity.distance < 0.001) {
        ballMoving = false;
        _animationController.stop();
        ballVelocity = Offset.zero;
        _checkHole();
      }
    });
  }

  void _checkHole() {
    final distance = sqrt(
      pow(ballPosition.dx - holePosition.dx, 2) +
          pow(ballPosition.dy - holePosition.dy, 2),
    );

    if (distance < 0.04) {
      _handleHoleComplete();
    }
  }

  Future<void> _handleHoleComplete() async {
    if (myPlayerKey == null || isMyFinished) return;

    setState(() {
      isMyFinished = true;
    });

    widget.onGameEvent('🎉 Deliğe girdi! $myShots atış');

    try {
      await roomRef.update({
        'players/$myPlayerKey/holeScores/$currentHole': myShots,
        'players/$myPlayerKey/isFinished': true,
        'players/$myPlayerKey/finishedAt': ServerValue.timestamp,
      });

      await _checkAllPlayersFinished();
    } catch (e) {
      debugPrint('Hole complete error: $e');
    }
  }

  Future<void> _checkAllPlayersFinished() async {
    try {
      final snapshot = await roomRef.get();
      if (!snapshot.exists) return;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final players = Map<String, dynamic>.from(data['players'] as Map);

      final allFinished = players.values.every(
            (final player) => player['isFinished'] == true,
      );

      if (allFinished) {
        if (currentHole >= 9) {
          // Oyun bitti
          await roomRef.update({'status': 'finished'});
        } else {
          // Sonraki delik - SADECE PLAYER1
          if (myPlayerKey == 'player1') {
            // Tüm oyuncuları resetle
            final updates = <String, dynamic>{
              'currentHole': currentHole + 1,
            };

            for (var key in players.keys) {
              updates['players/$key/isFinished'] = false;
            }

            await roomRef.update(updates);
          }
        }
      }
    } catch (e) {
      debugPrint('Check all players error: $e');
    }
  }

  void _onPanStart(final DragStartDetails details, final Size size) {
    if (ballMoving || isMyFinished) return;

    dragStart = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    dragCurrent = dragStart;
  }

  void _onPanUpdate(final DragUpdateDetails details, final Size size) {
    if (dragStart == null) return;

    setState(() {
      dragCurrent = Offset(
        details.localPosition.dx / size.width,
        details.localPosition.dy / size.height,
      );
    });
  }

  void _onPanEnd(final DragEndDetails details, final Size size) {
    if (dragStart == null || dragCurrent == null) return;

    final delta = Offset(
      dragStart!.dx - dragCurrent!.dx,
      dragStart!.dy - dragCurrent!.dy,
    );

    final power = (delta.distance * 5).clamp(0.5, 3.5);

    setState(() {
      myShots++;
      ballMoving = true;
      ballVelocity = Offset(delta.dx * power, delta.dy * power);

      dragStart = null;
      dragCurrent = null;
    });

    _animationController.repeat();

    if (myPlayerKey != null) {
      roomRef.update({'players/$myPlayerKey/shots': myShots});
    }
  }

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final context, final constraints) {
        return GestureDetector(
          onPanStart: (final details) =>
              _onPanStart(details, constraints.biggest),
          onPanUpdate: (final details) =>
              _onPanUpdate(details, constraints.biggest),
          onPanEnd: (final details) => _onPanEnd(details, constraints.biggest),
          child: CustomPaint(
            size: constraints.biggest,
            painter: GolfPainter(
              ballPosition: ballPosition,
              holePosition: holePosition,
              obstacles: obstacles,
              windmills: windmills,
              windmillAngles: windmillAngles,
              dragStart: dragStart,
              dragCurrent: dragCurrent,
              ballMoving: ballMoving,
              isFinished: isMyFinished,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// 🎨 Golf Painter
class GolfPainter extends CustomPainter {
  final Offset ballPosition;
  final Offset holePosition;
  final List<Offset> obstacles;
  final List<Offset> windmills;
  final List<double> windmillAngles;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final bool ballMoving;
  final bool isFinished;

  GolfPainter({
    required this.ballPosition,
    required this.holePosition,
    required this.obstacles,
    required this.windmills,
    required this.windmillAngles,
    this.dragStart,
    this.dragCurrent,
    required this.ballMoving,
    required this.isFinished,
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    final grassGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = grassGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    _drawHole(canvas, size);
    _drawObstacles(canvas, size);
    _drawWindmills(canvas, size);
    _drawBall(canvas, size);

    if (dragStart != null && dragCurrent != null && !ballMoving) {
      _drawPowerIndicator(canvas, size);
    }

    if (isFinished) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
    }
  }

  void _drawHole(final Canvas canvas, final Size size) {
    final holeX = holePosition.dx * size.width;
    final holeY = holePosition.dy * size.height;

    canvas.drawCircle(
      Offset(holeX + 2, holeY + 2),
      size.width * 0.025,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      Offset(holeX, holeY),
      size.width * 0.025,
      Paint()..color = Colors.black,
    );

    final flagPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final flagPath = Path()
      ..moveTo(holeX + size.width * 0.015, holeY - size.width * 0.04)
      ..lineTo(holeX + size.width * 0.015, holeY)
      ..lineTo(holeX + size.width * 0.05, holeY - size.width * 0.025)
      ..close();

    canvas.drawPath(flagPath, flagPaint);

    canvas.drawLine(
      Offset(holeX + size.width * 0.015, holeY),
      Offset(holeX + size.width * 0.015, holeY - size.width * 0.04),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  void _drawObstacles(final Canvas canvas, final Size size) {
    for (var obstacle in obstacles) {
      final x = obstacle.dx * size.width;
      final y = obstacle.dy * size.height;
      final radius = size.width * 0.04;

      canvas.drawCircle(
        Offset(x + 3, y + 3),
        radius,
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
      );

      final rockGradient = RadialGradient(
        colors: [Color(0xFF8B4513), Color(0xFF654321)],
      );

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..shader = rockGradient.createShader(
            Rect.fromCircle(center: Offset(x, y), radius: radius),
          ),
      );

      canvas.drawCircle(
        Offset(x - radius * 0.3, y - radius * 0.3),
        radius * 0.3,
        Paint()..color = Colors.white.withOpacity(0.2),
      );
    }
  }

  void _drawWindmills(final Canvas canvas, final Size size) {
    for (int i = 0; i < windmills.length; i++) {
      final windmill = windmills[i];
      final x = windmill.dx * size.width;
      final y = windmill.dy * size.height;
      final angle = windmillAngles[i];

      canvas.drawCircle(
        Offset(x, y),
        size.width * 0.02,
        Paint()..color = Color(0xFF8B4513),
      );

      final wingLength = size.width * 0.06;

      for (int j = 0; j < 4; j++) {
        final wingAngle = angle + (j * pi / 2);

        final wingPath = Path()
          ..moveTo(x, y)
          ..lineTo(
            x + cos(wingAngle) * wingLength,
            y + sin(wingAngle) * wingLength,
          )
          ..lineTo(
            x + cos(wingAngle + 0.3) * wingLength * 0.7,
            y + sin(wingAngle + 0.3) * wingLength * 0.7,
          )
          ..close();

        canvas.drawPath(
          wingPath,
          Paint()
            ..color = Color(0xFFD2691E)
            ..style = PaintingStyle.fill,
        );

        canvas.drawPath(
          wingPath,
          Paint()
            ..color = Color(0xFF8B4513)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _drawBall(final Canvas canvas, final Size size) {
    final x = ballPosition.dx * size.width;
    final y = ballPosition.dy * size.height;
    final radius = size.width * 0.02;

    canvas.drawCircle(
      Offset(x + 2, y + 3),
      radius * 0.8,
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(Offset(x, y), radius, Paint()..color = Colors.white);

    canvas.drawCircle(
      Offset(x - radius * 0.4, y - radius * 0.4),
      radius * 0.4,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }

  void _drawPowerIndicator(final Canvas canvas, final Size size) {
    if (dragStart == null || dragCurrent == null) return;

    final startX = ballPosition.dx * size.width;
    final startY = ballPosition.dy * size.height;
    final endX = dragCurrent!.dx * size.width;
    final endY = dragCurrent!.dy * size.height;

    final dx = startX - endX;
    final dy = startY - endY;
    final distance = sqrt(dx * dx + dy * dy);
    final power = (distance / size.width * 3).clamp(0.0, 1.0);

    final linePaint = Paint()
      ..color = Color.lerp(Colors.white, Colors.red, power)!
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + dx * 1.5, startY + dy * 1.5),
      linePaint,
    );

    for (int i = 1; i <= 5; i++) {
      final alpha = power >= i / 5 ? 255 : 60;
      final t = i / 6;

      canvas.drawCircle(
        Offset(startX + dx * 1.5 * t, startY + dy * 1.5 * t),
        5,
        Paint()..color = Colors.yellow.withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => true;
}