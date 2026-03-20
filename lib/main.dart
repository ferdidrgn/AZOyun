import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/firebase_options.dart';
import 'core/services/ad_service.dart';
import 'core/theme/az_theme.dart';
import 'core/widgets/az_widgets.dart';
import 'features/golf/golf_lobby_screen.dart';
import 'features/hangman/hangman_lobby_screen.dart';
import 'features/liar/liar_screens.dart';
import 'features/soccer/soccer_lobby_screen.dart';
import 'features/word/word_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  await AdService.instance.initialize();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    statusBarIconBrightness:  Brightness.light,
  ));

  runApp(const AZOyunApp());
}

class AZOyunApp extends StatelessWidget {
  const AZOyunApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title:                  'AZ Oyun',
    debugShowCheckedModeBanner: false,
    theme:                  AZTheme.light,
    home:                   const HomeScreen(),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradPurple,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 40),

            // Header
            Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.sports_esports, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('AZ OYUN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 4)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('GERÇEK ZAMANLI ÇOKLU OYUNCU',
                    style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
              ),
            ]),
            const SizedBox(height: 44),

            // ── Sports ────────────────────────────────────────────────
            _sectionTitle('⚽  SPOR OYUNLARI'),
            AZGameCard(emoji: '⛳', title: 'Mini Golf',
                subtitle: '2-4 Oyuncu · 5 Delik · En az vuruş kazanır',
                gradient: AZColors.gradGreen,
                onTap: () => _push(context, const GolfLobbyScreen())),
            const SizedBox(height: 14),
            AZGameCard(emoji: '⚽', title: 'Serbest Vuruş',
                subtitle: '2 Oyuncu · 5 Vuruş · Gol atan kazanır',
                gradient: AZColors.gradOrange,
                onTap: () => _push(context, const SoccerLobbyScreen())),
            const SizedBox(height: 32),

            // ── Mind ──────────────────────────────────────────────────
            _sectionTitle('🧠  ZİHİNSEL OYUNLAR'),
            AZGameCard(emoji: '🎯', title: 'Adam Asmaca',
                subtitle: '2 Oyuncu · Kelime Tahmin · 6 Tur',
                gradient: AZColors.gradRed,
                onTap: () => _push(context, const HangmanLobbyScreen())),
            const SizedBox(height: 14),
            AZGameCard(emoji: '🏙️', title: 'Şehir Bulmaca',
                subtitle: '2-4 Oyuncu · İpuçlarla şehri bul',
                gradient: AZColors.gradPink,
                onTap: () => _push(context, const CityLobbyScreen())),
            const SizedBox(height: 14),
            AZGameCard(emoji: '🔤', title: 'Kelime Bulmaca',
                subtitle: '2-4 Oyuncu · 60 Saniye · Harf karıştır',
                gradient: AZColors.gradCyan,
                onTap: () => _push(context, const WordLobbyScreen())),
            const SizedBox(height: 32),

            // ── Social ────────────────────────────────────────────────
            _sectionTitle('🎭  SOSYAL OYUNLAR'),
            AZGameCard(emoji: '🧛', title: 'Vampir Köylü',
                subtitle: '4-8 Oyuncu · Rol bazlı · Mafia tarzı',
                gradient: AZColors.gradDark,
                onTap: () => _push(context, const VampireLobbyScreen())),
            const SizedBox(height: 14),
            AZGameCard(emoji: '☕', title: 'Yalancilar Kahvesi',
                subtitle: '3-6 Oyuncu · 3 Tur · Yalanı yakala',
                gradient: AZColors.gradRose,
                onTap: () => _push(context, const LiarLobbyScreen())),
            const SizedBox(height: 32),

            // How to play
            AZFrostCard(opacity: 0.10, child: const Column(children: [
              Icon(Icons.info_outline_rounded, color: Colors.white70, size: 26),
              SizedBox(height: 10),
              Text('NASIL OYNANIR?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 10),
              Text('1. Oyun seç\n2. "Yeni Oda Oluştur" a bas\n'
                  '3. 6 haneli kodu arkadaşına gönder\n'
                  '4. Arkadaşın "Odaya Katıl" ile girer\n'
                  '5. Host "Oyunu Başlat" a basar → Oyna!',
                  style: TextStyle(color: Colors.white70, height: 1.7, fontSize: 13),
                  textAlign: TextAlign.center),
            ])),
            const SizedBox(height: 36),
          ]),
        )),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 17,
        fontWeight: FontWeight.bold, letterSpacing: 1)),
  );

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
