import 'package:AZOyun/core/config/firebase_options.dart';
import 'package:AZOyun/game_menu_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/ad_manager.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ad Manager'ı başlat
  await AdManager().initialize();

  // System UI ayarları
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Multiplayer Games',
      theme: AppTheme.lightTheme,
      home: const GameMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
