import 'dart:async';
import 'package:AZOyun/room_service.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class HangmanGame extends FlameGame with TapDetector {
  final String roomCode;
  HangmanGame({required this.roomCode});

  late DatabaseReference roomRef;
  StreamSubscription<DatabaseEvent>? sub;

  String maskedWord = '';
  int lives = 6;
  Set<String> guessedLetters = {};

  final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  @override
  Future<void> onLoad() async {
    roomRef = FirebaseDatabase.instance.ref('rooms/$roomCode');

    sub = roomRef.onValue.listen((event) {
      if (!event.snapshot.exists) return;

      final data =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      maskedWord = data['maskedWord'];
      lives = data['livesLeft'];

      guessedLetters.clear();
      if (data['guessedLetters'] != null) {
        guessedLetters.addAll(
          (data['guessedLetters'] as Map).values.cast<String>(),
        );
      }
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPaint = TextPaint(
      style: const TextStyle(color: Colors.white, fontSize: 32),
    );

    textPaint.render(canvas, maskedWord, Vector2(20, 40));
    textPaint.render(canvas, 'Can: $lives', Vector2(20, 90));

    _drawHangman(canvas);
    _drawKeyboard(canvas);
    _checkGameOver(canvas);
  }

  // 🎯 A–Z KLAVYE
  void _drawKeyboard(Canvas canvas) {
    final textPaint = TextPaint(
      style: const TextStyle(color: Colors.white, fontSize: 20),
    );

    for (int i = 0; i < letters.length; i++) {
      final x = 20 + (i % 7) * 45;
      final y = 200 + (i ~/ 7) * 45;
      final letter = letters[i];

      if (guessedLetters.contains(letter)) continue;

      textPaint.render(canvas, letter, Vector2(x.toDouble(), y.toDouble()));
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    final pos = info.eventPosition.global;

    for (int i = 0; i < letters.length; i++) {
      final x = 20 + (i % 7) * 45;
      final y = 200 + (i ~/ 7) * 45;
      final rect = Rect.fromLTWH(x.toDouble(), y.toDouble(), 30, 30);

      if (rect.contains(pos.toOffset())) {
        RoomService().guessLetter(
          roomCode: roomCode,
          letter: letters[i],
        );
        break;
      }
    }
  }

  // 🧍‍♂️ 2️⃣ ADAM ASMACA ÇİZİMİ
  void _drawHangman(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    if (lives <= 5) canvas.drawLine(const Offset(300, 200), const Offset(300, 100), paint); // direk
    if (lives <= 4) canvas.drawLine(const Offset(300, 100), const Offset(350, 100), paint);
    if (lives <= 3) canvas.drawCircle(const Offset(350, 120), 20, paint); // kafa
    if (lives <= 2) canvas.drawLine(const Offset(350, 140), const Offset(350, 200), paint); // gövde
    if (lives <= 1) canvas.drawLine(const Offset(350, 160), const Offset(320, 180), paint); // kol
    if (lives <= 0) canvas.drawLine(const Offset(350, 160), const Offset(380, 180), paint); // kol
  }

  // 🏁 3️⃣ WIN / LOSE
  void _checkGameOver(Canvas canvas) {
    final textPaint = TextPaint(
      style: const TextStyle(color: Colors.red, fontSize: 40),
    );

    if (!maskedWord.contains('_')) {
      textPaint.render(canvas, 'KAZANDIN 🎉', Vector2(80, 350));
    } else if (lives <= 0) {
      textPaint.render(canvas, 'KAYBETTİN 💀', Vector2(80, 350));
    }
  }

  @override
  void onRemove() {
    sub?.cancel();
    super.onRemove();
  }
}
