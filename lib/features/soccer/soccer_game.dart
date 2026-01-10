import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

/// ⚽ Serbest Vuruş Oyunu
class SoccerGame extends FlameGame with TapDetector {
  final String roomId;
  final String playerName;
  final Function(String message) onGameEvent;
  final VoidCallback onGameEnd;

  // Game state
  Ball? ball;
  Goal? goal;
  Goalkeeper? goalkeeper;
  Vector2? dragStart;
  Vector2? dragCurrent;
  bool isDragging = false;
  bool ballMoving = false;
  bool isMyTurn = true;
  int myScore = 0;
  int opponentScore = 0;
  int currentRound = 1;
  int totalRounds = 5;
  String? myPlayerKey;

  // Firebase
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;

  // Visual
  final Random _random = Random();

  SoccerGame({
    required this.roomId,
    required this.playerName,
    required this.onGameEvent,
    required this.onGameEnd,
  }) {
    roomRef = _database.child('soccer_rooms/$roomId');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    // Arkaplan
    add(SoccerField());

    // Kale
    goal = Goal(position: Vector2(size.x * 0.5, size.y * 0.15));
    await add(goal!);

    // Kaleci
    goalkeeper = Goalkeeper(position: Vector2(size.x * 0.5, size.y * 0.2));
    await add(goalkeeper!);

    // Top
    ball = Ball(position: Vector2(size.x * 0.5, size.y * 0.75));
    await add(ball!);

    _listenToRoom();
  }

  void _listenToRoom() {
    roomRef.onValue.listen((event) {
      if (event.snapshot.value == null || !isMounted) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      // Player key bul
      if (myPlayerKey == null) {
        final players = Map<String, dynamic>.from(data['players'] as Map);
        players.forEach((key, value) {
          if (value['name'] == playerName) {
            myPlayerKey = key;
          }
        });
      }

      // Skorlar
      currentRound = data['currentRound'] ?? 1;
      final players = Map<String, dynamic>.from(data['players'] as Map);
      myScore = players[myPlayerKey]['score'] ?? 0;

      // Oyun bitti mi?
      if (data['status'] == 'finished') {
        onGameEnd();
      }

      // Sıra kim?
      isMyTurn = data['currentPlayer'] == myPlayerKey;
    });
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (!isMyTurn || ballMoving || myPlayerKey == null) return;

    isDragging = true;
    dragStart = info.eventPosition.global;
    dragCurrent = dragStart;
  }

  @override
  void onTapUp(TapUpInfo info) {
    if (!isDragging || dragStart == null) return;

    final dragEnd = info.eventPosition.global;
    final delta = dragStart! - dragEnd;
    final power = (delta.length / 200).clamp(0.5, 2.5);
    final direction = delta.normalized();

    _shootBall(direction, power);

    isDragging = false;
    dragStart = null;
    dragCurrent = null;
  }

  @override
  void onTapCancel() {
    isDragging = false;
    dragStart = null;
    dragCurrent = null;
  }

  Future<void> _shootBall(Vector2 direction, double power) async {
    ballMoving = true;
    ball!.shoot(direction, power);

    // Kaleci hareketi
    goalkeeper!.moveRandom();

    // Partikül
    _addKickParticles(ball!.position);

    await Future.delayed(const Duration(milliseconds: 100));
    while (ball!.velocity.length > 0.5 && isMounted) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    ballMoving = false;

    // Gol mü?
    _checkGoal();
  }

  void _addKickParticles(Vector2 position) {
    for (int i = 0; i < 20; i++) {
      final angle = pi / 2 + (_random.nextDouble() - 0.5) * pi;
      final speed = _random.nextDouble() * 150 + 100;
      final velocity = Vector2(cos(angle), sin(angle)) * speed;

      add(
        SoccerParticle(
          position: position.clone(),
          velocity: velocity,
          radius: _random.nextDouble() * 3 + 2,
          color: Colors.white,
          lifespan: 0.6,
        ),
      );
    }
  }

  Future<void> _checkGoal() async {
    if (ball == null || goal == null || goalkeeper == null) return;

    final ballInGoal =
        ball!.position.y < goal!.position.y + 30 &&
        ball!.position.x > goal!.position.x - 80 &&
        ball!.position.x < goal!.position.x + 80;

    final blockedByKeeper = (ball!.position - goalkeeper!.position).length < 50;

    if (ballInGoal && !blockedByKeeper) {
      // GOL!
      onGameEvent('⚽ GOL! Harika vuruş!');
      myScore++;

      // Gol partikülü
      _addGoalParticles(goal!.position);

      await roomRef.update({'players/$myPlayerKey/score': myScore});
    } else {
      onGameEvent(blockedByKeeper ? '🧤 Kaleci kurtardı!' : '❌ Iskaladın!');
    }

    // Sonraki round
    await _nextRound();
  }

  void _addGoalParticles(Vector2 position) {
    for (int i = 0; i < 40; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 200 + 150;
      final velocity = Vector2(cos(angle), sin(angle)) * speed;

      add(
        SoccerParticle(
          position: position.clone(),
          velocity: velocity,
          radius: _random.nextDouble() * 5 + 3,
          color: [Colors.yellow, Colors.orange, Colors.red][_random.nextInt(3)],
          lifespan: 1.0,
        ),
      );
    }
  }

  Future<void> _nextRound() async {
    // Topu resetle
    ball!.position = Vector2(size.x * 0.5, size.y * 0.75);
    ball!.velocity = Vector2.zero();

    if (currentRound >= totalRounds) {
      // Oyun bitti
      await roomRef.update({'status': 'finished'});
    } else {
      // Sırayı değiştir
      final players = await roomRef.child('players').get();
      final playerList = (players.value as Map).keys.toList();
      final currentIndex = playerList.indexOf(myPlayerKey);
      final nextIndex = (currentIndex + 1) % playerList.length;

      if (nextIndex == 0) {
        // Yeni round
        await roomRef.update({
          'currentRound': currentRound + 1,
          'currentPlayer': playerList[nextIndex],
        });
      } else {
        await roomRef.update({'currentPlayer': playerList[nextIndex]});
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Güç göstergesi
    if (isDragging && dragStart != null && ball != null) {
      _renderPowerIndicator(canvas);
    }
  }

  void _renderPowerIndicator(Canvas canvas) {
    final dragEnd = dragCurrent ?? dragStart!;
    final delta = dragStart! - dragEnd;
    final power = (delta.length / 200).clamp(0.0, 1.0);
    final direction = delta.normalized();
    final targetPos = ball!.position + direction * delta.length * 2;

    final paint = Paint()
      ..color = Color.lerp(Colors.white, Colors.red, power)!
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(ball!.position.toOffset(), targetPos.toOffset(), paint);

    // Power bars
    for (int i = 1; i <= 5; i++) {
      final alpha = power >= i / 5 ? 255 : 60;
      final barPaint = Paint()
        ..color = Colors.yellow.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      final t = i / 6;
      final barPos = Vector2(
        ball!.position.x + (targetPos.x - ball!.position.x) * t,
        ball!.position.y + (targetPos.y - ball!.position.y) * t,
      );
      canvas.drawCircle(barPos.toOffset(), 5, barPaint);
    }
  }
}

/// ⚽ Top
class Ball extends CircleComponent {
  Vector2 velocity = Vector2.zero();

  Ball({required super.position})
    : super(
        radius: 15,
        anchor: Anchor.center,
        paint: Paint()..color = Colors.white,
      );

  void shoot(Vector2 direction, double power) {
    velocity = direction * power * 150;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (velocity.length > 0.5) {
      position += velocity * dt;
      velocity *= 0.95;

      final game = findGame()!;
      if (position.x < radius || position.x > game.size.x - radius) {
        velocity.x *= -0.7;
        position.x = position.x.clamp(radius, game.size.x - radius);
      }
      if (position.y < radius) {
        velocity.y *= -0.5;
        position.y = radius;
      }
    } else {
      velocity = Vector2.zero();
    }
  }

  @override
  void render(Canvas canvas) {
    // Gölge
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(3, 4), radius * 0.9, shadowPaint);

    // Top
    super.render(canvas);

    // Desenler (futbol topu)
    final patternPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5);
      canvas.drawCircle(
        Offset(cos(angle) * radius * 0.6, sin(angle) * radius * 0.6),
        radius * 0.15,
        patternPaint,
      );
    }

    // Işık yansıması
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(
      Offset(-radius * 0.4, -radius * 0.4),
      radius * 0.3,
      highlightPaint,
    );
  }
}

/// 🥅 Kale
class Goal extends RectangleComponent {
  Goal({required super.position})
    : super(size: Vector2(160, 60), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    // Kale ağı
    final netPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dikey çizgiler
    for (double x = 0; x <= size.x; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), netPaint);
    }

    // Yatay çizgiler
    for (double y = 0; y <= size.y; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), netPaint);
    }

    // Kale direği
    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), postPaint);
  }
}

/// 🧤 Kaleci
class Goalkeeper extends CircleComponent {
  final Random _random = Random();
  Vector2 targetPosition = Vector2.zero();
  double moveSpeed = 200;

  Goalkeeper({required super.position})
    : super(
        radius: 20,
        anchor: Anchor.center,
        paint: Paint()..color = Colors.orange,
      );

  void moveRandom() {
    final game = findGame()!;
    targetPosition = Vector2(
      game.size.x * (0.3 + _random.nextDouble() * 0.4),
      position.y,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if ((position - targetPosition).length > 5) {
      final direction = (targetPosition - position).normalized();
      position += direction * moveSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // Gölge
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(2, 3), radius, shadowPaint);

    // Kaleci
    super.render(canvas);

    // Yüz
    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius * 0.7, facePaint);

    // Gözler
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(-radius * 0.3, -radius * 0.2), 3, eyePaint);
    canvas.drawCircle(Offset(radius * 0.3, -radius * 0.2), 3, eyePaint);

    // Ağız
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.4),
      0,
      pi,
      false,
      mouthPaint,
    );
  }
}

/// 🏟️ Futbol Sahası
class SoccerField extends Component with HasGameRef<SoccerGame> {
  @override
  void render(Canvas canvas) {
    // Çim gradient
    final grassGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      Paint()
        ..shader = grassGradient.createShader(
          Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
        ),
    );

    // Orta çizgi
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, gameRef.size.y * 0.5),
      Offset(gameRef.size.x, gameRef.size.y * 0.5),
      linePaint,
    );

    // Orta daire
    canvas.drawCircle(
      Offset(gameRef.size.x * 0.5, gameRef.size.y * 0.5),
      40,
      linePaint..style = PaintingStyle.stroke,
    );
  }
}

/// ✨ Partikül
class SoccerParticle extends PositionComponent {
  Vector2 velocity;
  double lifespan;
  double age = 0;
  Color color;
  double radius;

  SoccerParticle({
    required super.position,
    required this.velocity,
    required this.lifespan,
    required this.color,
    required this.radius,
  });

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;

    if (age >= lifespan) {
      removeFromParent();
      return;
    }

    position += velocity * dt;
    velocity *= 0.94;
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((1 - age / lifespan) * 255).toInt().clamp(0, 255);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
