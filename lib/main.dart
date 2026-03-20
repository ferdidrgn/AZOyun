import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/hangman/hangman_game.dart';
import 'features/golf/golf_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const AZOyunApp());
}

class AZOyunApp extends StatelessWidget {
  const AZOyunApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AZ Oyun',
    debugShowCheckedModeBanner: false,
    theme: AZTheme.light,
    home: const _Home(),
  );
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      gradient: AZColors.gradPurple,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.sports_esports, size: 56, color: Colors.white)),
          const SizedBox(height: 16),
          const Text('AZ OYUN',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
              color: Colors.white, letterSpacing: 4)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('GERÇEK ZAMANLI ÇOKLU OYUNCU',
              style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5))),
          const SizedBox(height: 48),
          _Card(
            emoji: '🎯', title: 'Adam Asmaca',
            sub: '2 Oyuncu · Kelime Tahmin · 6 Tur',
            colors: [const Color(0xFFD32F2F), const Color(0xFFB71C1C)],
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HangmanLobbyScreen()))),
          const SizedBox(height: 16),
          _Card(
            emoji: '⛳', title: 'Mini Golf',
            sub: '2-4 Oyuncu · 5 Delik · En Az Vuruş',
            colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GolfLobbyScreen()))),
          const SizedBox(height: 48),
          FrostCard(opacity: 0.08, child: const Column(children: [
            Icon(Icons.info_outline, color: Colors.white70, size: 24),
            SizedBox(height: 10),
            Text('NASIL OYNANIR?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            SizedBox(height: 8),
            Text(
              '1. Oyun seç\n'
              '2. "Yeni Oda Oluştur" a bas\n'
              '3. 6 haneli kodu arkadaşına gönder\n'
              '4. Arkadaşın "Odaya Katıl" ile girer\n'
              '5. Host "Oyunu Başlat" a basar\n'
              '6. Oyna!',
              style: TextStyle(color: Colors.white70, height: 1.7, fontSize: 13),
              textAlign: TextAlign.center),
          ])),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(
      {required this.emoji, required this.title, required this.sub,
       required this.colors, required this.onTap});
  final String emoji, title, sub;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(
          color: colors.first.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))]),
      child: Row(children: [
        Container(width: 68, height: 68,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36)))),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
        ])),
        const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 20),
      ]),
    ),
  );
}
