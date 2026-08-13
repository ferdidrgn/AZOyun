import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { tr, en, de, fr, es, ru }

/// Uygulama içi dil tercihi. Flutter'ın resmi `gen-l10n` (ARB) sistemi
/// burada BİLEREK kullanılmadı — o sistem derleme zamanında kod üretimi
/// gerektiriyor ve bu ortamda Flutter SDK çalıştırılamadığından üretilen
/// kod doğrulanamaz. Bunun yerine basit, elle yazılmış bir çeviri haritası
/// (`AppStrings`) kullanılıyor. Yeni bir dil eklemek `AppLanguage`'e bir
/// değer ve `AppStrings`'e yeni bir `Map` eklemek kadar basit — bkz. RU
/// gibi Latin olmayan alfabeler de sorunsuz çalışıyor, Flutter metinleri
/// zaten UTF-8/Unicode olarak render ediyor.
class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _key = 'az_language_v1';

  AppLanguage _language = AppLanguage.tr;
  AppLanguage get language => _language;

  Locale get locale => Locale(_language.name);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _language = AppLanguage.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppLanguage.tr,
    );
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang.name);
  }
}
