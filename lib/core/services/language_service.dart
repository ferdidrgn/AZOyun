import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { tr, en }

/// Uygulama içi dil tercihi. Flutter'ın resmi `gen-l10n` (ARB) sistemi
/// burada BİLEREK kullanılmadı — o sistem derleme zamanında kod üretimi
/// gerektiriyor ve bu ortamda Flutter SDK çalıştırılamadığından üretilen
/// kod doğrulanamaz. Bunun yerine basit, elle yazılmış bir çeviri haritası
/// (`AppStrings`) kullanılıyor.
class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _key = 'az_language_v1';

  AppLanguage _language = AppLanguage.tr;
  AppLanguage get language => _language;

  Locale get locale => _language == AppLanguage.en ? const Locale('en') : const Locale('tr');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _language = raw == 'en' ? AppLanguage.en : AppLanguage.tr;
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
