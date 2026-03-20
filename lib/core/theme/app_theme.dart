import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Color palette ─────────────────────────────────────────────────────────────

class AZColors {
  AZColors._();
  static const purple    = Color(0xFF6C63FF);
  static const purpleDk  = Color(0xFF4834DF);
  static const red       = Color(0xFFE74C3C);
  static const redDk     = Color(0xFFC0392B);
  static const green     = Color(0xFF27AE60);
  static const greenDk   = Color(0xFF1E8449);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Colors.white;
  static const success   = Color(0xFF2ECC71);
  static const error     = Color(0xFFE74C3C);

  static const gradPurple = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );
  static const gradRed = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
  );
  static const gradGreen = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
  );
}

// ── Theme ──────────────────────────────────────────────────────────────────────

class AZTheme {
  AZTheme._();
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AZColors.purple),
    scaffoldBackgroundColor: AZColors.bg,
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true, systemOverlayStyle: SystemUiOverlayStyle.light),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: Colors.white,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({super.key, required this.gradient, required this.child, this.resizeToAvoidBottomInset = true});
  final Gradient gradient;
  final Widget child;
  final bool resizeToAvoidBottomInset;
  @override
  Widget build(final BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: Container(decoration: BoxDecoration(gradient: gradient), child: SafeArea(child: child)),
  );
}

class AZCard extends StatelessWidget {
  const AZCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child; final EdgeInsets padding;
  @override
  Widget build(final BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 6))]),
    child: child,
  );
}

class FrostCard extends StatelessWidget {
  const FrostCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.opacity = 0.15});
  final Widget child; final EdgeInsets padding; final double opacity;
  @override
  Widget build(final BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(opacity), borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: child,
  );
}

class BigButton extends StatelessWidget {
  const BigButton({super.key, required this.label, required this.onPressed, this.icon, this.color = AZColors.purple, this.loading = false, this.width = 300});
  final String label; final VoidCallback? onPressed; final IconData? icon;
  final Color color; final bool loading; final double width;
  @override
  Widget build(final BuildContext context) => SizedBox(
    width: width, height: 56,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: loading
          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: color, strokeWidth: 2.5))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
    ),
  );
}

class JoinButton extends StatelessWidget {
  const JoinButton({super.key, required this.onPressed, this.loading = false});
  final VoidCallback? onPressed; final bool loading;
  @override
  Widget build(final BuildContext context) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.login),
      label: const Text('ODAYA KATIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
  );
}

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
