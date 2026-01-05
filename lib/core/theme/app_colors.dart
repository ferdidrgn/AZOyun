import 'package:flutter/material.dart';

/// 🎨 Uygulama renk paleti
class AppColors {
  // Oyun renkleri
  static const Color hangmanPrimary = Color(0xFFE74C3C);
  static const Color hangmanSecondary = Color(0xFFC0392B);
  static const Color golfPrimary = Color(0xFF27AE60);
  static const Color golfSecondary = Color(0xFF229954);
  static const Color freeKickPrimary = Color(0xFFF39C12);
  static const Color freeKickSecondary = Color(0xFFE67E22);
  static const Color racingPrimary = Color(0xFF3498DB);
  static const Color racingSecondary = Color(0xFF2980B9);

  // Ana renkler
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF4834DF);
  static const Color accent = Color(0xFFFF6B6B);

  // Gradient renkleri
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  static const LinearGradient hangmanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hangmanPrimary, hangmanSecondary],
  );

  static const LinearGradient golfGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [golfPrimary, golfSecondary],
  );

  static const LinearGradient freeKickGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [freeKickPrimary, freeKickSecondary],
  );

  static const LinearGradient racingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [racingPrimary, racingSecondary],
  );

  // Durum renkleri
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Nötr renkler
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color divider = Color(0xFFECF0F1);

  // Overlay renkleri
  static const Color overlay = Color(0x80000000);
  static const Color cardShadow = Color(0x1A000000);

  // Oyuncu renkleri
  static const Color player1Color = Color(0xFF3498DB);
  static const Color player2Color = Color(0xFFE74C3C);

  AppColors._(); // Private constructor
}

/// 🎨 Renk extension'ları
extension ColorExtension on Color {
  /// Rengi koyulaştır
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  /// Rengi açıklaştır
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }
}
