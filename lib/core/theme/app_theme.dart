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
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: Container(decoration: BoxDecoration(gradient: gradient), child: SafeArea(child: child)),
  );
}

class AZCard extends StatelessWidget {
  const AZCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child; final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
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
  Widget build(BuildContext context) => Container(
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
  Widget build(BuildContext context) => SizedBox(
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
  Widget build(BuildContext context) => SizedBox(
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
