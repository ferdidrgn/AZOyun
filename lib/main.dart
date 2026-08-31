import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/app_initializer.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_keys.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/az_theme.dart';
import 'features/onboarding/splash_screen.dart';

void main() async {
  await AppInitializer.runBlocking();
  runApp(const AZOyunApp());
  AppInitializer.runAfterFirstFrame(onDeepLink: _handleDeepLink);
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
