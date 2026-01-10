import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// 🎯 2.5D Adam Asmaca Görselleştirme
class HangmanVisualizer extends FlameGame {
  int wrongGuesses = 0;
  List<String> guessedLetters = [];
  String currentWord = '';

  late HangmanDrawing hangmanDrawing;
  late WordDisplay wordDisplay;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Arkaplan
    add(Background3D());

    // Darağacı
    hangmanDrawing = HangmanDrawing();
    add(hangmanDrawing);

    // Kelime gösterimi
    wordDisplay = WordDisplay();
    add(wordDisplay);
  }

  void updateGame(
    final int wrong,
    final List<String> guessed,
    final String word,
  ) {
    wrongGuesses = wrong;
    guessedLetters = guessed;
    currentWord = word;

    hangmanDrawing.wrongGuesses = wrong;
    wordDisplay.updateWord(word, guessed);
  }
}

/// 🎨 3D Arkaplan
class Background3D extends Component with HasGameRef<HangmanVisualizer> {
  @override
  void render(final Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y);

    // Gradient arkaplan
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1A1A2E),
          const Color(0xFF16213E),
          const Color(0xFF0F3460),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    // Yıldızlar efekti
    final random = Random(42); // Sabit seed
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * gameRef.size.x;
      final y = random.nextDouble() * gameRef.size.y;
      final size = random.nextDouble() * 2 + 1;

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), size, starPaint);
    }
  }
}

/// 🎭 Darağacı Çizimi (3D efektli)
class HangmanDrawing extends PositionComponent
    with HasGameRef<HangmanVisualizer> {
  int wrongGuesses = 0;

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x * 0.5, gameRef.size.y * 0.4);
    size = Vector2(250, 300);
    anchor = Anchor.center;
  }

  @override
  void render(final Canvas canvas) {
    _drawGallows(canvas);
    _drawPerson(canvas);
  }

  void _drawGallows(final Canvas canvas) {
    final woodColor = const Color(0xFF8B4513);
    final shadowColor = Colors.black.withOpacity(0.3);

    // Gölge
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Taban gölgesi
    canvas.drawRect(Rect.fromLTWH(-100 + 3, 110 + 3, 150, 8), shadowPaint);

    // Ana boya
    final woodPaint = Paint()
      ..color = woodColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = woodColor.darken(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Taban (kalın)
    canvas.drawRect(Rect.fromLTWH(-100, 110, 150, 8), woodPaint);
    canvas.drawRect(Rect.fromLTWH(-100, 110, 150, 8), outlinePaint);

    // Dikey direk (3D efektli)
    final verticalPath = Path()
      ..moveTo(-70, 110)
      ..lineTo(-70, -100)
      ..lineTo(-60, -102)
      ..lineTo(-60, 108)
      ..close();

    final verticalGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [woodColor.darken(0.2), woodColor, woodColor.lighten(0.1)],
    ).createShader(Rect.fromLTWH(-70, -100, 10, 210));

    canvas.drawPath(verticalPath, Paint()..shader = verticalGradient);
    canvas.drawPath(verticalPath, outlinePaint);

    // Üst yatay çubuk (3D)
    final horizontalPath = Path()
      ..moveTo(-70, -100)
      ..lineTo(50, -100)
      ..lineTo(52, -92)
      ..lineTo(-68, -92)
      ..close();

    final horizontalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [woodColor.lighten(0.1), woodColor, woodColor.darken(0.2)],
    ).createShader(Rect.fromLTWH(-70, -100, 120, 8));

    canvas.drawPath(horizontalPath, Paint()..shader = horizontalGradient);
    canvas.drawPath(horizontalPath, outlinePaint);

    // İp (3D halat efekti)
    if (wrongGuesses >= 0) {
      final ropePaint = Paint()
        ..color = const Color(0xFFD2691E)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      // Halat bükümleri
      for (double i = -100; i <= -60; i += 3) {
        canvas.drawLine(
          Offset(50 + sin(i * 0.5) * 1, i),
          Offset(50 + sin((i + 3) * 0.5) * 1, i + 3),
          ropePaint,
        );
      }
    }
  }

  void _drawPerson(final Canvas canvas) {
    final personPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Kafa (1. hata)
    if (wrongGuesses >= 1) {
      // Gölge
      canvas.drawCircle(const Offset(52, -48), 18, shadowPaint);
      // Kafa
      canvas.drawCircle(const Offset(50, -50), 18, personPaint);

      // Yüz detayları
      if (wrongGuesses >= 6) {
        // Ölü X gözler
        final eyePaint = Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(42, -55), const Offset(46, -51), eyePaint);
        canvas.drawLine(const Offset(46, -55), const Offset(42, -51), eyePaint);
        canvas.drawLine(const Offset(54, -55), const Offset(58, -51), eyePaint);
        canvas.drawLine(const Offset(58, -55), const Offset(54, -51), eyePaint);

        // Üzgün ağız
        final mouthPath = Path()
          ..moveTo(42, -43)
          ..quadraticBezierTo(50, -39, 58, -43);
        canvas.drawPath(mouthPath, eyePaint);
      } else {
        // Normal gözler
        canvas.drawCircle(
          const Offset(44, -53),
          2,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          const Offset(56, -53),
          2,
          Paint()..color = Colors.white,
        );
      }
    }

    // Gövde (2. hata)
    if (wrongGuesses >= 2) {
      canvas.drawLine(const Offset(52, -30), const Offset(52, 18), shadowPaint);
      canvas.drawLine(const Offset(50, -32), const Offset(50, 15), personPaint);
    }

    // Sol kol (3. hata)
    if (wrongGuesses >= 3) {
      canvas.drawLine(const Offset(52, -18), const Offset(22, -3), shadowPaint);
      canvas.drawLine(const Offset(50, -20), const Offset(20, -5), personPaint);
    }

    // Sağ kol (4. hata)
    if (wrongGuesses >= 4) {
      canvas.drawLine(const Offset(52, -18), const Offset(82, -3), shadowPaint);
      canvas.drawLine(const Offset(50, -20), const Offset(80, -5), personPaint);
    }

    // Sol bacak (5. hata)
    if (wrongGuesses >= 5) {
      canvas.drawLine(const Offset(52, 18), const Offset(27, 48), shadowPaint);
      canvas.drawLine(const Offset(50, 15), const Offset(25, 45), personPaint);
    }

    // Sağ bacak (6. hata - ölüm)
    if (wrongGuesses >= 6) {
      canvas.drawLine(const Offset(52, 18), const Offset(77, 48), shadowPaint);
      canvas.drawLine(const Offset(50, 15), const Offset(75, 45), personPaint);

      // Titreşim efekti
      final shakePaint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(const Offset(50, -50), 20, shakePaint);
    }
  }
}

/// 📝 Kelime Gösterimi (3D kartlar)
class WordDisplay extends PositionComponent with HasGameRef<HangmanVisualizer> {
  List<LetterCard> letterCards = [];

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x * 0.5, gameRef.size.y * 0.75);
    anchor = Anchor.center;
  }

  void updateWord(final String word, final List<String> guessed) {
    // Eski kartları temizle
    for (var card in letterCards) {
      card.removeFromParent();
    }
    letterCards.clear();

    final letters = word.split('');
    final cardWidth = 50.0;
    final cardSpacing = 10.0;
    final totalWidth = letters.length * (cardWidth + cardSpacing) - cardSpacing;
    final startX = -totalWidth / 2;

    for (int i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final isRevealed = guessed.contains(letter) || letter == ' ';

      final card = LetterCard(
        letter: letter,
        isRevealed: isRevealed,
        position: Vector2(startX + i * (cardWidth + cardSpacing), 0),
      );

      letterCards.add(card);
      add(card);
    }
  }
}

/// 🎴 Harf Kartı (3D efektli)
class LetterCard extends PositionComponent {
  final String letter;
  final bool isRevealed;

  LetterCard({
    required this.letter,
    required this.isRevealed,
    required final Vector2 position,
  }) : super(position: position, size: Vector2(50, 60));

  @override
  void render(final Canvas canvas) {
    if (letter == ' ') return; // Boşluk için kart çizme

    // Gölge
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 3, 50, 60),
        const Radius.circular(8),
      ),
      shadowPaint,
    );

    // Kart arkaplanı (3D gradient)
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isRevealed
          ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
          : [const Color(0xFF424242), const Color(0xFF212121)],
    );

    final cardPaint = Paint()
      ..shader = cardGradient.createShader(const Rect.fromLTWH(0, 0, 50, 60));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 50, 60),
        const Radius.circular(8),
      ),
      cardPaint,
    );

    // Kenar çizgisi
    final borderPaint = Paint()
      ..color = isRevealed ? Colors.lightGreen : Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 50, 60),
        const Radius.circular(8),
      ),
      borderPaint,
    );

    // Harf
    if (isRevealed) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black38,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset((50 - textPainter.width) / 2, (60 - textPainter.height) / 2),
      );
    } else {
      // Alt çizgi
      final linePaint = Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 3;

      canvas.drawLine(const Offset(10, 50), const Offset(40, 50), linePaint);
    }
  }
}

// Renk extension'ları
extension ColorExtension on Color {
  Color darken(final double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color lighten(final double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
