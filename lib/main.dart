import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/firebase_options.dart';
import 'core/services/ad_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_keys.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/language_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/play_games_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/az_theme.dart';
import 'features/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Yakalanmayan tüm hataları Crashlytics'e gönder — debug modda konsola da
  // yazdırılmaya devam eder (kDebugMode kontrolü Crashlytics'in kendi
  // varsayılan davranışı, burada ayrıca engellemiyoruz ki geliştirme
  // sırasında da raporlama test edilebilsin).
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await ProfileService.instance.load();
  await ThemeService.instance.load();
  await LanguageService.instance.load();
  await AdService.instance.initialize();
  await AdService.instance.applyPremiumStateIfActive();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const AZOyunApp());

  unawaited(AnalyticsService.instance.logAppOpen());

  // Bu servisler ilk kareyi bloklamadan, arka planda başlatılır: Play Games
  // oturumu varsa sessizce bağlanır (yoksa no-op), bildirim/token altyapısı
  // hazırlanır, deep link dinleyicisi kurulur.
  unawaited(PlayGamesService.instance.signIn());
  unawaited(NotificationService.instance.initialize());
  unawaited(DeepLinkService.instance.initialize(onLink: _handleDeepLink));
}

void _handleDeepLink(Uri uri) {
  final joined = DeepLinkService.parseJoinLink(uri);
  if (joined == null) return;
  final messenger = scaffoldMessengerKey.currentState;
  messenger?.showSnackBar(
    SnackBar(
      content: Text('Davet linki: ${joined.game} · Kod: ${joined.code}'),
      duration: const Duration(seconds: 4),
    ),
  );
}

class AZOyunApp extends StatelessWidget {
  const AZOyunApp({super.key});

  @override
  Widget build(BuildContext context) => DynamicColorBuilder(
    builder: (lightDynamic, darkDynamic) => ListenableBuilder(
      listenable: Listenable.merge([ThemeService.instance, LanguageService.instance]),
      builder: (context, _) {
        final pref = ThemeService.instance.preference;
        final customColor = ThemeService.instance.customColor;
        // Telefon Material You desteklemiyorsa (Android <12 ya da iOS),
        // lightDynamic/darkDynamic null gelir — o durumda sessizce bizim
        // kendi açık/koyu markamıza düşer.
        final lightTheme = switch (pref) {
          AppThemePreference.dynamic =>
            lightDynamic != null ? AZTheme.fromScheme(lightDynamic) : AZTheme.light,
          AppThemePreference.custom => AZTheme.fromSeed(customColor, Brightness.light),
          _ => AZTheme.light,
        };
        final darkTheme = switch (pref) {
          AppThemePreference.dynamic =>
            darkDynamic != null ? AZTheme.fromScheme(darkDynamic) : AZTheme.dark,
          AppThemePreference.custom => AZTheme.fromSeed(customColor, Brightness.dark),
          _ => AZTheme.dark,
        };
        return MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'AZ Oyun',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeService.instance.themeMode,
          navigatorObservers: [AnalyticsService.instance.navigatorObserver],
          home: const SplashScreen(),
        );
      },
    ),
  );
}
