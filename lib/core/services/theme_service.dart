import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının tema tercihi: sistemi takip et, ya da uygulamanın kendi
/// açık/koyu markasını sabitle.
enum AppThemePreference { system, light, dark }

/// Ayarlar ekranından değiştirilen, kalıcı (SharedPreferences) tema tercihi.
/// `ChangeNotifier` olduğu için `MaterialApp` bunu dinleyip anında yeniden
/// çizer (bkz. `main.dart`'taki `ListenableBuilder`).
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _key = 'az_theme_preference_v1';

  AppThemePreference _preference = AppThemePreference.system;
  AppThemePreference get preference => _preference;

  ThemeMode get themeMode => switch (_preference) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _preference = AppThemePreference.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppThemePreference.system,
    );
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference pref) async {
    if (_preference == pref) return;
    _preference = pref;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, pref.name);
  }
}
