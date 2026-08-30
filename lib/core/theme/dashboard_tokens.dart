import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Dashboard" tasarım dili — Profil/İstatistik ekranı gibi veri-yoğun,
/// SaaS-tarzı yüzeyler için kullanılan token seti. Uygulamanın geri
/// kalanındaki oyun ekranları [AZTheme]/[AZColors]'ı kullanmaya devam
/// eder; bu dosya sadece Bento-Grid dashboard yüzeylerine özeldir ve
/// bilerek sabit (kullanıcının seçtiği tema rengine göre değişmeyen)
/// koyu bir Slate/Zinc paleti kullanır — Linear/Vercel referanslı bir
/// "kurumsal analytics" hissi hedefler.
abstract class DashTokens {
  // ── Yüzeyler ────────────────────────────────────────────────────────────
  static const canvas    = Color(0xFF09090B); // en arka plan
  static const surface   = Color(0xFF18181B); // kart yüzeyi
  static const surfaceHi = Color(0xFF1F1F23); // hafif yükseltilmiş kart
  static const highlight = Color(0xFF27272A); // hover/aktif katman

  // ── Kenarlıklar ─────────────────────────────────────────────────────────
  static const border       = Color(0x14FFFFFF); // ~%8 beyaz
  static const borderStrong = Color(0x24FFFFFF); // ~%14 beyaz

  // ── Metin ───────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textTertiary  = Color(0xFF71717A);

  // ── Aksan renkleri ──────────────────────────────────────────────────────
  // `indigo`/`indigoSoft` sabitleri SADECE context'in olmadığı yerler için
  // (ör. bir CustomPainter) yedek olarak kalır. Görünür tüm marka aksanı
  // artık [accent]/[accentSoft] ile kullanıcının Ayarlar'da seçtiği renge
  // göre boyanıyor — önceden bu dashboard sabit indigo kullanıyordu, bu da
  // kullanıcı Ayarlar'dan başka bir renk seçse bile Profil ekranının hep
  // aynı mor/indigo kalmasına yol açıyordu ("Home/Settings'teki renkle
  // uyuşmuyor" şikayetinin kaynağı).
  static const indigo      = Color(0xFF6366F1); // Elektrik İndigo — varsayılan/yedek
  static const indigoSoft  = Color(0xFF818CF8);
  static const emerald     = Color(0xFF10B981); // Zümrüt Nane — başarı/galibiyet (sabit, semantik)
  static const emeraldSoft = Color(0xFF34D399);
  static const amber       = Color(0xFFF59E0B); // uyarı/coin (sabit, semantik)
  static const rose        = Color(0xFFF43F5E); // mağlubiyet/negatif (sabit, semantik)

  /// Kullanıcının o an aktif temasının birincil rengi — Ayarlar'da "Özel
  /// Renk" ya da "Telefonun Teması" seçiliyse gerçekten o renk, aksi halde
  /// uygulamanın varsayılan mor/indigo'su. Dashboard'un marka aksanı
  /// (seviye rozeti, XP çubuğu, vurgulanan kartlar) buradan gelir.
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;

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
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.plusJakartaSansTextTheme(base).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      );

  /// Dashboard yüzeylerinde kullanılan hazır metin stilleri.
  static TextStyle get displayLg => GoogleFonts.plusJakartaSans(
      fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary, height: 1.15, letterSpacing: -0.5);
  static TextStyle get headline => GoogleFonts.plusJakartaSans(
      fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.2);
  static TextStyle get metricValue => GoogleFonts.plusJakartaSans(
      fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5);
  static TextStyle get label => GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.2);
  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w600, color: textTertiary, letterSpacing: 0.4);
  static TextStyle get body => GoogleFonts.plusJakartaSans(
      fontSize: 13.5, fontWeight: FontWeight.w500, color: textSecondary, height: 1.4);

  /// Web/masaüstü breakpoint — bu genişliğin üzerinde çok sütunlu
  /// Bento-Grid, altında tek sütunlu mobil yerleşim kullanılır.
  static const double desktopBreakpoint = 1024;
}

/// Glassmorphism + mikro-kenarlık dekorasyonu — tüm Bento kartlarının
/// ortak temeli.
BoxDecoration bentoDecoration({
  Color? color,
  double radius = DashTokens.cardRadius,
  Color? borderColor,
  List<BoxShadow>? shadow,
  Gradient? gradient,
}) =>
    BoxDecoration(
      color: gradient == null ? (color ?? DashTokens.surface) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? DashTokens.border, width: 1),
      boxShadow: shadow ?? DashTokens.cardShadow,
    );
