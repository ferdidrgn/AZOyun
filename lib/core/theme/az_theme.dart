import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════

abstract class AZColors {
  // Brand
  static const purple   = Color(0xFF6C63FF);
  static const purpleDk = Color(0xFF4834DF);

  // Game colours
  static const red      = Color(0xFFE74C3C);
  static const redDk    = Color(0xFFC0392B);
  static const green    = Color(0xFF27AE60);
  static const greenDk  = Color(0xFF1E8449);
  static const orange   = Color(0xFFF39C12);
  static const orangeDk = Color(0xFFE67E22);
  static const blue     = Color(0xFF3498DB);
  static const blueDk   = Color(0xFF2980B9);

  // Semantic
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFF39C12);
  static const error   = Color(0xFFE74C3C);

  // Surface
  static const bg      = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);

  // Text
  static const textPrimary   = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);

  // Gradients
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
  static const gradOrange = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
  );
  static const gradBlue = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
  );
  static const gradPink = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
  );
  static const gradCyan = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
  );
  static const gradDark = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF434343), Color(0xFF000000)],
  );
  static const gradRose = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFd66d75), Color(0xFFe29587)],
  );
}

abstract class AZSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

abstract class AZRadius {
  static const sm  = 8.0;
  static const md  = 12.0;
  static const lg  = 16.0;
  static const xl  = 20.0;
  static const xxl = 28.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════

abstract class AZTheme {
  static ThemeData get light => _build(
      ColorScheme.fromSeed(seedColor: AZColors.purple), Brightness.light);

  static ThemeData get dark => _build(
      ColorScheme.fromSeed(seedColor: AZColors.purple, brightness: Brightness.dark),
      Brightness.dark);

  /// Ayarlar'da kullanıcının seçtiği özel bir vurgu rengine göre üretilen
  /// tema — `light`/`dark` ile aynı yapıyı kullanır, sadece tohum (seed)
  /// rengi değişir.
  static ThemeData fromSeed(Color seed, Brightness brightness) =>
      _build(ColorScheme.fromSeed(seedColor: seed, brightness: brightness), brightness);

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121218) : AZColors.bg;
    final surface = isDark ? const Color(0xFF1E1E28) : Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? bg : null,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:            Colors.transparent,
          statusBarIconBrightness:   Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AZRadius.lg)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AZRadius.md)),
        filled: true,
        fillColor: surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? surface : null,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.xl)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.md)),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: isDark ? surface : null,
        shadowColor: isDark ? Colors.black45 : Colors.black12,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.lg)),
      ),
    );
  }

  /// Ayarlar/Splash/Onboarding gibi "chrome" ekranlarında koyu temada
  /// kullanılan marka gradyanı.
  static const darkBrandGradient = AZColors.gradDark;

  /// Ayarlar'daki "Özel Renk" seçicisinde sunulan hazır palet.
  static const List<Color> customColorSwatches = [
    AZColors.purple,
    Color(0xFFE74C3C), // kırmızı
    Color(0xFFE67E22), // turuncu
    Color(0xFFF1C40F), // sarı
    Color(0xFF2ECC71), // yeşil
    Color(0xFF1ABC9C), // turkuaz
    Color(0xFF3498DB), // mavi
    Color(0xFF9B59B6), // mor
    Color(0xFFE84393), // pembe
    Color(0xFF2C3E50), // lacivert
    Color(0xFF16A085), // çam yeşili
    Color(0xFFD35400), // tarçın
  ];
}
