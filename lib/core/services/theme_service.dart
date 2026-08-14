import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/az_theme.dart';

/// Kullanıcının tema tercihi: bizim açık/koyu markamız, telefonun kendi
/// Material You (duvar kağıdından çıkarılan dinamik renk) teması, ya da
/// kendi seçtiği özel bir vurgu rengi. Belirsiz "Sistem" seçeneği
/// bilerek yok — onun yerine gerçekten telefonun kendi rengini çeken
/// "dynamic" seçeneği var.
enum AppThemePreference { light, dark, dynamic, custom }

/// Ayarlar ekranından değiştirilen, kalıcı (SharedPreferences) tema tercihi.
/// `ChangeNotifier` olduğu için `MaterialApp` bunu dinleyip anında yeniden
/// çizer (bkz. `main.dart`'taki `ListenableBuilder`).
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _key = 'az_theme_preference_v1';
  static const _colorKey = 'az_theme_custom_color_v1';

  AppThemePreference _preference = AppThemePreference.light;
  AppThemePreference get preference => _preference;

  Color _customColor = AZColors.purple;
  Color get customColor => _customColor;

  ThemeMode get themeMode => switch (_preference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        // Telefonun teması ve özel renk seçiliyken cihazın açık/koyu
        // anahtarına uyulur — sadece vurgu rengi kaynağı değişir (bkz.
        // AZTheme.fromScheme / AZTheme.fromSeed, main.dart).
        AppThemePreference.dynamic => ThemeMode.system,
        AppThemePreference.custom => ThemeMode.system,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _preference = AppThemePreference.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppThemePreference.light,
    );
    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) _customColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference pref) async {
    if (_preference == pref) return;
    _preference = pref;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, pref.name);
  }

  /// Ayarlar'daki renk paletinden bir renk seçilince çağrılır — hem rengi
  /// kaydeder hem de tercihi otomatik olarak "özel" yapar (bir renk
  /// seçmek zaten onu kullanma isteği anlamına gelir).
  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    _preference = AppThemePreference.custom;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
    await prefs.setString(_key, AppThemePreference.custom.name);
  }
}
