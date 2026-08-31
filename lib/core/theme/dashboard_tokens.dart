import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'az_theme.dart';

/// "Dashboard" tasarım dili — Profil/İstatistik ekranı gibi veri-yoğun,
/// SaaS-tarzı yüzeyler için kullanılan token seti. Uygulamanın geri
/// kalanındaki oyun ekranları [AZTheme]/[AZColors]'ı kullanmaya devam
/// eder; bu dosya sadece Bento-Grid dashboard yüzeylerine özeldir ve
/// bilerek sabit (kullanıcının seçtiği tema rengine göre değişmeyen) koyu
/// bir palet kullanır. Palet, uygulama genelindeki "soft UI" yenilemesiyle
/// (bkz. `az_theme.dart`) aynı lacivert/sıcak-altın "token sheet" ailesine
/// taşındı — eskiden saf siyah/Zinc + parlak Tailwind neon (indigo/emerald/
/// rose) renkleri kullanıyordu, artık aynı mat/pastel dil burada da geçerli.
abstract class DashTokens {
  // ── Yüzeyler ────────────────────────────────────────────────────────────
  static const canvas    = Color(0xFF161C29); // en arka plan (AZColors.bgDark ile aynı aile)
  static const surface   = Color(0xFF212A3B); // kart yüzeyi
  static const surfaceHi = Color(0xFF2A3447); // hafif yükseltilmiş kart
  static const highlight = Color(0xFF323D53); // hover/aktif katman

  // ── Kenarlıklar ─────────────────────────────────────────────────────────
  static const border       = Color(0x1EFFFFFF); // ~%12 beyaz
  static const borderStrong = Color(0x30FFFFFF); // ~%19 beyaz

  // ── Metin ───────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFEDE7DD);
  static const textSecondary = Color(0xFFA8AEBB);
  static const textTertiary  = Color(0xFF7D8494);

  // ── Aksan renkleri ──────────────────────────────────────────────────────
  // `indigo`/`indigoSoft` sabitleri SADECE context'in olmadığı yerler için
  // (ör. bir CustomPainter) yedek olarak kalır. Görünür tüm marka aksanı
  // artık [accent]/[accentSoft] ile kullanıcının Ayarlar'da seçtiği renge
  // göre boyanıyor — önceden bu dashboard sabit indigo kullanıyordu, bu da
  // kullanıcı Ayarlar'dan başka bir renk seçse bile Profil ekranının hep
  // aynı mor/indigo kalmasına yol açıyordu ("Home/Settings'teki renkle
  // uyuşmuyor" şikayetinin kaynağı). Yedek değer artık uygulamanın yeni
  // koyu tema vurgusuyla (sıcak altın) aynı.
  static const indigo      = AZColors.accentGold; // varsayılan/yedek
  static const indigoSoft  = AZColors.accentGoldSoft;
  static const emerald     = AZColors.green; // başarı/galibiyet (sabit, semantik)
  static const emeraldSoft = Color(0xFFA8C3A0);
  static const amber       = AZColors.orange; // uyarı/coin (sabit, semantik)
  static const rose        = AZColors.red; // mağlubiyet/negatif (sabit, semantik)

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
