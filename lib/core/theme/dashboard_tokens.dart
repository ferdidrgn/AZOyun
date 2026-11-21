import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


/// Profil ve istatistik kartları uygulamanın Material 3 renk şemasını izler.
/// Tema veya vurgu rengi değiştiğinde bu ekran da beraber güncellenir.
abstract class DashTokens {
  // ── Yüzeyler ────────────────────────────────────────────────────────────
  static Color canvas(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  static Color surfaceHi(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;
  static Color highlight(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHigh;

  // ── Kenarlıklar ─────────────────────────────────────────────────────────
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;
  static Color borderStrong(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  // ── Metin ───────────────────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textTertiary(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  // ── Aksan renkleri ──────────────────────────────────────────────────────
  // `indigo`/`indigoSoft` sabitleri SADECE context'in olmadığı yerler için
  // (ör. bir CustomPainter) yedek olarak kalır. Görünür tüm marka aksanı
  // artık [accent]/[accentSoft] ile kullanıcının Ayarlar'da seçtiği renge
  // göre boyanıyor — önceden bu dashboard sabit indigo kullanıyordu, bu da
  // kullanıcı Ayarlar'dan başka bir renk seçse bile Profil ekranının hep
  // aynı mor/indigo kalmasına yol açıyordu ("Home/Settings'teki renkle
  // uyuşmuyor" şikayetinin kaynağı). Yedek değer artık uygulamanın yeni
  // koyu tema vurgusuyla (sıcak altın) aynı.
  static Color indigo(BuildContext context) => accent(context);
  static Color indigoSoft(BuildContext context) => accentSoft(context);
  static Color emerald(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color emeraldSoft(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color amber(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color rose(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// Kullanıcının o an aktif temasının birincil rengi — Ayarlar'da "Özel
  /// Renk" ya da "Telefonun Teması" seçiliyse gerçekten o renk, aksi halde
  /// uygulamanın varsayılan mor/indigo'su. Dashboard'un marka aksanı
  /// (seviye rozeti, XP çubuğu, vurgulanan kartlar) buradan gelir.
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// [accent]'in daha açık/parlak varyantı — gradyanların ikinci durağı,
  /// "bağlı/aktif" ikon rengi gibi yerlerde kullanılır.
  static Color accentSoft(BuildContext context) {
    final hsl = HSLColor.fromColor(accent(context));
    return hsl
        .withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation - 0.05).clamp(0.0, 1.0))
        .toColor();
  }

  static const cardRadius = 20.0;
  static const chipRadius = 12.0;

  /// Bento kartlarında ortak kullanılan ince gölge — glassmorphism
  /// yüzeyleri "havada" gibi hissettirir, ama abartılı değildir.
  static List<BoxShadow> cardShadow(BuildContext context) => [
        BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(36),
            blurRadius: 22,
            offset: const Offset(0, 9)),
      ];

  static TextTheme textTheme(BuildContext context, TextTheme base) =>
      GoogleFonts.plusJakartaSansTextTheme(base).apply(
        bodyColor: textPrimary(context),
        displayColor: textPrimary(context),
      );

  /// Dashboard yüzeylerinde kullanılan hazır metin stilleri.
  static TextStyle displayLg(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimary(context),
          height: 1.15,
          letterSpacing: -0.5);
  static TextStyle headline(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary(context),
          letterSpacing: -0.2);
  static TextStyle metricValue(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrimary(context),
          letterSpacing: -0.5);
  static TextStyle label(BuildContext context) => GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: textSecondary(context),
      letterSpacing: 0.2);
  static TextStyle labelSm(BuildContext context) => GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: textTertiary(context),
      letterSpacing: 0.4);
  static TextStyle body(BuildContext context) => GoogleFonts.plusJakartaSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: textSecondary(context),
      height: 1.4);

  /// Web/masaüstü breakpoint — bu genişliğin üzerinde çok sütunlu
  /// Bento-Grid, altında tek sütunlu mobil yerleşim kullanılır.
  static const double desktopBreakpoint = 1024;
}

/// Glassmorphism + mikro-kenarlık dekorasyonu — tüm Bento kartlarının
/// ortak temeli.
BoxDecoration bentoDecoration({
  required BuildContext context,
  Color? color,
  double radius = DashTokens.cardRadius,
  Color? borderColor,
  List<BoxShadow>? shadow,
  Gradient? gradient,
}) =>
    BoxDecoration(
      color: gradient == null ? (color ?? DashTokens.surface(context)) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color: borderColor ?? DashTokens.border(context), width: 1),
      boxShadow: shadow ?? DashTokens.cardShadow(context),
    );
