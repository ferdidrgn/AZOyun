import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
//
// "Soft UI" görsel dili: sıcak, mat, yumuşak köşeli, düşük doygunlukta
// pastel renkler (açık temada krem/toprak tonları) ve koyu lacivert +
// sıcak altın vurgulu bir "token sheet" hissi (koyu temada). Eski parlak/
// doygun mor-kırmızı-turuncu-camgöbeği paleti kasıtlı olarak kaldırıldı —
// sabit isimler (purple/red/green/orange/blue...) korunuyor ki 100'den
// fazla çağrı yerini tek tek değiştirmeye gerek kalmasın; sadece DEĞERLERİ
// yeni, yumuşak paletle güncellendi. Bu yüzden bu dosyadaki değişiklik tüm
// uygulamaya (30+ oyun ekranı dahil) otomatik yansır.
// ═══════════════════════════════════════════════════════════════════════════

abstract class AZColors {
  // Marka — yumuşak toprak/lavanta ailesi (eski parlak #6C63FF mor yerine)
  static const purple   = Color(0xFF9B8FC9);
  static const purpleDk = Color(0xFF7D6FB0);

  // Oyun renkleri — hepsi aynı mat/pastel aileden, eski neon tonların yerine
  static const red      = Color(0xFFCB8A7E);
  static const redDk    = Color(0xFFAD6F63);
  static const green    = Color(0xFF93AE8C);
  static const greenDk  = Color(0xFF77916F);
  static const orange   = Color(0xFFD9A25C);
  static const orangeDk = Color(0xFFBD8748);
  static const blue     = Color(0xFF83ABC7);
  static const blueDk   = Color(0xFF6390AC);

  // Semantik
  static const success = green;
  static const warning = orange;
  static const error   = Color(0xFFC97B6E);

  // Yüzey — açık temada sıcak krem, koyu temada soğuk lacivert (bkz. 2. ve
  // 3. görsel referans: açık = sıcak clay UI, koyu = lacivert token sheet)
  static const bg      = Color(0xFFF6F1E9);
  static const surface = Color(0xFFFDFBF6);

  // Metin
  static const textPrimary   = Color(0xFF3A342C);
  static const textSecondary = Color(0xFF8C8378);

  // Koyu tema yüzeyleri
  static const bgDark          = Color(0xFF161C29);
  static const surfaceDark     = Color(0xFF212A3B);
  static const surfaceDarkHi   = Color(0xFF2A3447); // bir ton daha açık (kart üstü kart)
  static const accentGold      = Color(0xFFD9A25C); // koyu temanın birincil vurgusu
  static const accentGoldSoft  = Color(0xFFE8C08A);
  static const textPrimaryDark   = Color(0xFFEDE7DD);
  static const textSecondaryDark = Color(0xFF9098A8);

  // Gradyanlar — hepsi yumuşak, düşük kontrast; artık "hangi oyun hangi
  // neon renk" değil, "hangi oyun hangi yumuşak ton" mantığıyla ayrışıyor
  static const gradPurple = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFB3A7DB), purpleDk],
  );
  static const gradRed = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFDDA69B), redDk],
  );
  static const gradGreen = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFA8C3A0), greenDk],
  );
  static const gradOrange = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE3B583), orangeDk],
  );
  static const gradBlue = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF9CC0D8), blueDk],
  );
  static const gradPink = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE8C4C0), Color(0xFFCB8A7E)],
  );
  static const gradCyan = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFA9D4C9), Color(0xFF7FA79B)],
  );
  static const gradDark = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF232A3A), bgDark],
  );
  static const gradRose = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE0B8AE), Color(0xFFCB8A7E)],
  );

  /// Koyu temanın kendi "token sheet" gradyanı — Ayarlar/Splash/Onboarding
  /// gibi ekranların koyu modda kullandığı marka arka planı.
  static const gradNavy = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [surfaceDarkHi, bgDark],
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
  static const lg  = 18.0;
  static const xl  = 24.0;
  static const xxl = 32.0;
}

/// "Soft UI" gölge seviyeleri — referans tasarımlardaki 3 kademeli
/// (soft/medium/deep) gölge sistemi. Sıcak/soğuk tema ayrımı için gölge
/// rengi de parametrik: açık temada ılık kahve-gri, koyu temada saf siyah.
abstract class AZShadow {
  static List<BoxShadow> soft(Color tint) => [
        BoxShadow(color: tint.withAlpha(28), blurRadius: 14, offset: const Offset(0, 4)),
      ];
  static List<BoxShadow> medium(Color tint) => [
        BoxShadow(color: tint.withAlpha(40), blurRadius: 22, offset: const Offset(0, 8)),
      ];
  static List<BoxShadow> deep(Color tint) => [
        BoxShadow(color: tint.withAlpha(60), blurRadius: 32, offset: const Offset(0, 14)),
      ];

  static const lightTint = Color(0xFF3A342C);
  static const darkTint  = Color(0xFF000000);
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════

abstract class AZTheme {
  static ThemeData get light => _build(
      ColorScheme.fromSeed(seedColor: AZColors.orange, brightness: Brightness.light),
      Brightness.light);

  static ThemeData get dark => _build(
      ColorScheme.fromSeed(seedColor: AZColors.accentGold, brightness: Brightness.dark),
      Brightness.dark);

  /// Ayarlar'da kullanıcının seçtiği özel bir vurgu rengine göre üretilen
  /// tema — `light`/`dark` ile aynı yapıyı kullanır, sadece tohum (seed)
  /// rengi değişir.
  static ThemeData fromSeed(Color seed, Brightness brightness) =>
      _build(ColorScheme.fromSeed(seedColor: seed, brightness: brightness), brightness);

  /// Telefonun kendi Material You (dinamik renk) şemasından üretilen tema
  /// — `dynamic_color` paketinin sağladığı gerçek `ColorScheme`'i kullanır.
  static ThemeData fromScheme(ColorScheme scheme) => _build(scheme, scheme.brightness);

  /// Ana sayfa/Splash/Onboarding gibi "hero" gradyanlarında kullanılan,
  /// aktif temanın vurgu rengine göre üretilen dinamik gradyan — böylece
  /// kullanıcı Özel Renk ya da Telefonun Teması seçtiğinde ana sayfa da
  /// gerçekten o renge boyanır, sabit kalmaz.
  static LinearGradient dynamicGradient(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primary);
    final darker = hsl.withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, darker],
    );
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg      = isDark ? AZColors.bgDark      : AZColors.bg;
    final surface = isDark ? AZColors.surfaceDark : AZColors.surface;
    final surfaceHi = isDark ? AZColors.surfaceDarkHi : Colors.white;
    final shadowTint = isDark ? AZShadow.darkTint : AZShadow.lightTint;
    final textPrimary   = isDark ? AZColors.textPrimaryDark   : AZColors.textPrimary;
    final textSecondary = isDark ? AZColors.textSecondaryDark : AZColors.textSecondary;
    final borderColor = isDark ? const Color(0x22FFFFFF) : const Color(0x14000000);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: textPrimary,
            displayColor: textPrimary,
          ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
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
        contentTextStyle: TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AZColors.surfaceDarkHi : AZColors.textPrimary,
        contentTextStyle: TextStyle(
            color: isDark ? AZColors.textPrimaryDark : Colors.white, fontSize: 14),
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
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: textPrimary),
    );
  }

  /// Ayarlar/Splash/Onboarding gibi "chrome" ekranlarında koyu temada
  /// kullanılan marka gradyanı — artık lacivert "token sheet" tonunda.
  static const darkBrandGradient = AZColors.gradNavy;

  /// Ayarlar'daki "Özel Renk" seçicisinde sunulan hazır palet — hepsi yeni
  /// yumuşak/mat aileden.
  static const List<Color> customColorSwatches = [
    AZColors.orange,
    AZColors.red,
    Color(0xFFDCC17A), // hardal
    AZColors.green,
    Color(0xFF7FBBAE), // deniz yeşili
    AZColors.blue,
    AZColors.purple,
    Color(0xFFCE94B0), // toz pembe
    Color(0xFF5C6B7A), // arduvaz lacivert
    Color(0xFF6FA394), // çam yeşili
    Color(0xFFB07C4F), // tarçın
    AZColors.accentGold,
  ];
}
