// lib/core/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Renkler
  static const Color primaryDark = Color(0xFF0F0F1E);
  static const Color secondaryDark = Color(0xFF1A1A2E);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentAmber = Color(0xFFFFB300);

  // Gradient Renkler
  static const List<Color> purpleGradient = [
    Color(0xFF6A1B9A),
    Color(0xFF4A148C),
  ];

  static const List<Color> blueGradient = [
    Color(0xFF1976D2),
    Color(0xFF0D47A1),
  ];

  static const List<Color> cyanGradient = [
    Color(0xFF00BCD4),
    Color(0xFF006064),
  ];

  // Ana Tema
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accentCyan,
      scaffoldBackgroundColor: primaryDark,

      // AppBar Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Teması
      cardTheme: CardThemeData(
        color: secondaryDark,
        elevation: 8,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Buton Teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // TextField Teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // Dialog Teması
      dialogTheme: DialogThemeData(
        backgroundColor: secondaryDark,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // BottomSheet Teması
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: secondaryDark,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Drawer Teması
      drawerTheme: const DrawerThemeData(
        backgroundColor: secondaryDark,
        elevation: 16,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentCyan,
        circularTrackColor: Colors.white24,
      ),
    );
  }

  // Gradient Box Decoration Yardımcıları
  static BoxDecoration gradientBox(List<Color> colors) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: colors.first.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Glow Effect
  static BoxDecoration glowBox(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3), width: 2),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.white54,
  );

  static const TextStyle accentText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: accentCyan,
  );
}
