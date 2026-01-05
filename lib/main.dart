import 'package:a_z_oyun/core/config/firebase_options.dart';
import 'package:a_z_oyun/game_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/services/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI ayarları
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ad Manager'ı başlat
  await AdManager().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplayer Games',
      theme: AppTheme.lightTheme,
      home: const GameMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
