import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/app_initializer.dart';
import 'core/config/firebase_options.dart';
import 'core/navigation/join_router.dart';
import 'core/navigation/room_invite.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_keys.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/az_theme.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/family/family_screen.dart';
import 'features/family/firebase_table_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final family = kIsWeb ? Uri.base.queryParameters['family'] : null;
  final tv = WidgetsBinding.instance.platformDispatcher.defaultRouteName == '/family-tv';
  if (tv) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(MaterialApp(
      title: 'AZOyun · Aile Masası',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: AZTheme.light,
      darkTheme: AZTheme.dark,
      home: const FirebaseTableMenu(),
    ));
    return;
  }
  if (family != null) {
    runApp(FamilyApp(host: family == 'tv',
        code: family == null || family == 'tv' || family == 'join' ? null : family));
    return;
  }
  await AppInitializer.runBlocking();
  runApp(const AZOyunApp());
  AppInitializer.runAfterFirstFrame(onDeepLink: _handleDeepLink);
}

void _handleDeepLink(Uri uri) {
  final joined = parseRoomInvite(uri);
  if (joined == null) {
    return;
  }
  PendingJoin.instance.offer(joined.game, joined.code);
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
