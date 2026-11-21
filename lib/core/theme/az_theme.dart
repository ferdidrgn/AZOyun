import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
//
// AZ Oyun'un oyun arayüzü paleti. Renkler isim olarak sabit tutulur ki oyun
// tahtalarının anlamı korunurken uygulama genelindeki görünüm tek yerden
// değiştirilebilsin.
// ═══════════════════════════════════════════════════════════════════════════

abstract class AZColors {
  // Marka — elektrik moru ve yüksek kontrastlı oyun aksanları.
  static const purple = Color(0xFF9B6DFF);
  static const purpleDk = Color(0xFF6035C9);

  // Oyun durumları — kazanma, uyarı, kayıp ve etkileşimlerde ortak renkler.
  static const red = Color(0xFFFF647C);
  static const redDk = Color(0xFFB82F50);
  static const green = Color(0xFF4FE0A1);
  static const greenDk = Color(0xFF168A68);
  static const orange = Color(0xFFFFC857);
  static const orangeDk = Color(0xFFCC7A17);
  static const blue = Color(0xFF52B8FF);
  static const blueDk = Color(0xFF2870D4);

  // Semantik
  static const success = green;
  static const warning = orange;
  static const error = Color(0xFFFF647C);

  // Açık ve koyu yüzeyler; oyun aksanları her iki parlaklıkta da korunur.
  static const bg = Color(0xFFF3F2FA);
  static const surface = Color(0xFFFFFFFF);

  // Metin
  static const textPrimary = Color(0xFF171525);
  static const textSecondary = Color(0xFF59566B);

  // Koyu tema yüzeyleri
  static const bgDark = Color(0xFF0D0C16);
  static const surfaceDark = Color(0xFF171522);
  static const surfaceDarkHi = Color(0xFF211E31);
  static const accentGold = Color(0xFFB18AFF);
  static const accentGoldSoft = Color(0xFFD1B8FF);
  static const textPrimaryDark = Color(0xFFF5F1FF);
  static const textSecondaryDark = Color(0xFFB5AEC8);

  // Gradyanlar — hepsi yumuşak, düşük kontrast; artık "hangi oyun hangi
  // neon renk" değil, "hangi oyun hangi yumuşak ton" mantığıyla ayrışıyor
  static const gradPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, purpleDk],
  );
  static const gradRed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redDk],
  );
  static const gradGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green, greenDk],
  );
  static const gradOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, orangeDk],
  );
  static const gradBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, blueDk],
  );
  static const gradPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF76B7), Color(0xFFB73778)],
  );
  static const gradCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38D9D1), Color(0xFF168A92)],
  );
  static const gradDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF29233D), bgDark],
  );
  static const gradRose = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF647C), Color(0xFFB82F50)],
  );

  /// Koyu tema yüzey gradyanı.
  static const gradNavy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceDarkHi, bgDark],
  );
}

abstract class AZSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract class AZRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// "Soft UI" gölge seviyeleri — referans tasarımlardaki 3 kademeli
/// (soft/medium/deep) gölge sistemi. Sıcak/soğuk tema ayrımı için gölge
/// rengi de parametrik: açık temada ılık kahve-gri, koyu temada saf siyah.
abstract class AZShadow {
  static List<BoxShadow> soft(Color tint) => [
        BoxShadow(
            color: tint.withAlpha(28),
            blurRadius: 14,
            offset: const Offset(0, 4)),
      ];
  static List<BoxShadow> medium(Color tint) => [
        BoxShadow(
            color: tint.withAlpha(40),
            blurRadius: 22,
            offset: const Offset(0, 8)),
      ];
  static List<BoxShadow> deep(Color tint) => [
        BoxShadow(
            color: tint.withAlpha(60),
            blurRadius: 32,
            offset: const Offset(0, 14)),
      ];

  static const lightTint = Color(0xFF3A342C);
  static const darkTint = Color(0xFF000000);
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════

abstract class AZTheme {
  static ThemeData get light => _build(
      ColorScheme.fromSeed(
          seedColor: AZColors.orange, brightness: Brightness.light),
      Brightness.light);

  static ThemeData get dark => _build(
      ColorScheme.fromSeed(
          seedColor: AZColors.accentGold, brightness: Brightness.dark),
      Brightness.dark);

  /// Ayarlar'da kullanıcının seçtiği özel bir vurgu rengine göre üretilen
  /// tema — `light`/`dark` ile aynı yapıyı kullanır, sadece tohum (seed)
  /// rengi değişir.
  static ThemeData fromSeed(Color seed, Brightness brightness) => _build(
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      brightness);

  /// Telefonun kendi Material You (dinamik renk) şemasından üretilen tema
  /// — `dynamic_color` paketinin sağladığı gerçek `ColorScheme`'i kullanır.
  static ThemeData fromScheme(ColorScheme scheme) =>
      _build(scheme, scheme.brightness);

  /// Ana sayfa/Splash/Onboarding gibi "hero" gradyanlarında kullanılan,
  /// aktif temanın vurgu rengine göre üretilen dinamik gradyan — böylece
  /// kullanıcı Özel Renk ya da Telefonun Teması seçtiğinde ana sayfa da
  /// gerçekten o renge boyanır, sabit kalmaz.
  static LinearGradient dynamicGradient(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primary);
    final darker =
        hsl.withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, darker],
    );
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AZColors.bgDark : AZColors.bg;
    final surface = isDark ? AZColors.surfaceDark : AZColors.surface;
    final surfaceHi = isDark ? AZColors.surfaceDarkHi : Colors.white;
    final shadowTint = isDark ? AZShadow.darkTint : AZShadow.lightTint;
    final textPrimary =
        isDark ? AZColors.textPrimaryDark : AZColors.textPrimary;
    final textSecondary =
        isDark ? AZColors.textSecondaryDark : AZColors.textSecondary;
    final borderColor =
        isDark ? const Color(0x22FFFFFF) : const Color(0x14000000);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(
        surface: surface,
        surfaceContainerLowest: bg,
        surfaceContainerLow: surface,
        surfaceContainer: surfaceHi,
        surfaceContainerHigh: surfaceHi,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.figtreeTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceHi,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowTint.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AZRadius.xl),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AZRadius.xxl)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AZRadius.xxl)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: borderColor.withAlpha(255), width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AZRadius.xxl)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AZRadius.lg)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AZRadius.lg),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AZRadius.lg),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AZRadius.lg),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        filled: true,
        fillColor: surfaceHi,
        hintStyle: TextStyle(color: textSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHi,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AZRadius.xxl),
          side: BorderSide(color: borderColor, width: 1),
        ),
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle:
            TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AZColors.surfaceDarkHi : AZColors.textPrimary,
        contentTextStyle: TextStyle(
            color: isDark ? AZColors.textPrimaryDark : Colors.white,
            fontSize: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.lg)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? scheme.primary : surfaceHi),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary.withAlpha(90)
                : borderColor.withAlpha(255)),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: borderColor,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withAlpha(40),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: borderColor,
        circularTrackColor: borderColor,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.lg)),
        tileColor: surfaceHi,
        selectedTileColor: scheme.primary.withAlpha(30),
        textColor: textPrimary,
        iconColor: textSecondary,
      ),
      dividerTheme:
          DividerThemeData(color: borderColor, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: textPrimary),
    );
  }

  /// Ayarlar/Splash/Onboarding ekranlarının marka gradyanı.
  static const darkBrandGradient = AZColors.gradNavy;

  /// Ayarlar'daki özel vurgu rengi paleti.
  static const List<Color> customColorSwatches = [
    AZColors.purple,
    AZColors.blue,
    Color(0xFF38D9D1),
    AZColors.green,
    AZColors.orange,
    AZColors.red,
    Color(0xFFFF76B7),
    Color(0xFF5865F2),
    Color(0xFF8C7CFF),
    Color(0xFF23A6D5),
    Color(0xFF22C55E),
    Color(0xFFFF8A3D),
  ];
}
