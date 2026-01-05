import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 📝 Uygulama text stilleri
class AppTextStyles {
  // Başlık stilleri
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body stilleri
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Buton stilleri
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // Özel stiller
  static const TextStyle score = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle gameTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 10, color: Colors.black38, offset: Offset(2, 2)),
    ],
    letterSpacing: 1.5,
  );

  static const TextStyle playerName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle code = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 4,
  );

  AppTextStyles._(); // Private constructor
}

/// 📝 Text style extension'ları
extension TextStyleExtension on TextStyle {
  /// Renk değiştir
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Kalınlık değiştir
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);

  /// Boyut değiştir
  TextStyle withSize(double size) => copyWith(fontSize: size);

  /// Beyaz renkli yap
  TextStyle get white => copyWith(color: Colors.white);

  /// Bold yap
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// İtalik yap
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
}
