import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/firebase_options.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/deep_link_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/play_games_service.dart';
import 'services/profile_service.dart';
import 'services/theme_service.dart';

/// Uygulama açılışındaki tüm servis başlatmalarını tek, sıralı bir yerden
/// yönetir — `main()`'i "hangi servis ne zaman başlıyor" mantığından
/// ayrıştırıp okunabilir tutmak için.
///
/// İki aşama var, kasıtlı olarak ayrı:
/// - [runBlocking]: `runApp()`'tan ÖNCE tamamlanması GEREKEN, hızlı ve
///   yerel (ağ/native SDK'ya bağımlı olmayan) servisler.
/// - [runAfterFirstFrame]: `runApp()`'tan SONRA, ilk kareyi bloklamadan
///   arka planda başlatılan servisler.
///
/// **Yeni bir servis eklerken**: ağ isteği yapan veya bir native SDK'yı
/// başlatan hiçbir şey [runBlocking]'e eklenmemeli — bkz. ROADMAP 8.24:
/// `AdService.initialize()`'ın (MobileAds SDK'sı) burada `await` edilmesi,
/// emülatörde/zayıf ağda süresiz asılı kalıp uygulamayı splash ekranında
/// tamamen kilitlemişti.
class AppInitializer {
  AppInitializer._();

  static Future<void> runBlocking() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Web'de arka plan bildirimleri ayrı bir service worker mekanizması
    // gerektirir (bu Dart handler'ın bir karşılığı yoktur) — bu yüzden
    // sadece native platformlarda kaydediliyor.
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    _wireCrashlytics();

    await ProfileService.instance.load();
    await ThemeService.instance.load();
    await LanguageService.instance.load();

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  /// Yakalanmayan tüm hataları Crashlytics'e gönderir. `firebase_crashlytics`
  /// sadece Android/iOS/macOS destekler — Web'de bu paket hiç yok,
  /// `FirebaseCrashlytics.instance`'a erişmek uygulamanın en açılışında
  /// (`runApp()`'tan önce) patlamasına yol açardı.
  static void _wireCrashlytics() {
    if (kIsWeb) return;
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// `runApp()` çağrıldıktan hemen sonra çağrılır. Buradaki hiçbir şey
  /// `await` edilmez (`unawaited`) — Play Games oturumu varsa sessizce
  /// bağlanır (yoksa no-op), reklam SDK'sı + bildirim/token altyapısı
  /// hazırlanır, deep link dinleyicisi kurulur. Biri yavaş kalsa ya da hiç
  /// bitmese bile uygulama arayüzü zaten açılmış olur.
  static void runAfterFirstFrame({required void Function(Uri uri) onDeepLink}) {
    unawaited(AnalyticsService.instance.logAppOpen());
    unawaited(
      AdService.instance.initialize().then((_) => AdService.instance.applyPremiumStateIfActive()),
    );
    unawaited(PlayGamesService.instance.signIn());
    unawaited(NotificationService.instance.initialize());
    unawaited(DeepLinkService.instance.initialize(onLink: onDeepLink));
  }
}
