import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/firebase_options.dart';
import 'core/services/ad_service.dart';
import 'core/theme/az_theme.dart';
import 'core/widgets/az_widgets.dart';
import 'core/widgets/banner_ad_widget.dart';

import 'features/golf/golf_lobby_screen.dart';
import 'features/hangman/hangman_lobby_screen.dart';
import 'features/liar/liar_screens.dart';
import 'features/soccer/soccer_lobby_screen.dart';
import 'features/vampire_wolf/vampire_screens.dart';
import 'features/word/word_screens.dart';
import 'features/city/city_screens.dart';
// YENİ OYUNLAR
import 'features/okey/okey_screens.dart';
import 'features/fighter/fighter_screens.dart';
import 'features/racing/racing_screens.dart';
import 'features/checkers/dama_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AdService.instance.initialize();
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
    home: const HomeScreen(),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AZColors.gradPurple),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Expanded(
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: 36),

                      // ── Header ──────────────────────────────────────────
                      Column(children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                              color: Color(0x26FFFFFF), shape: BoxShape.circle),
                          child: const Icon(Icons.sports_esports, size: 52, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        const Text('AZ OYUN',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                                color: Colors.white, letterSpacing: 4)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0x26FFFFFF),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('GERÇEK ZAMANLI · 11 OYUN',
                              style: TextStyle(color: Colors.white70,
                                  fontSize: 11, letterSpacing: 1.5)),
                        ),
                      ]),
                      const SizedBox(height: 36),

                      // ── SPOR ────────────────────────────────────────────
                      _Section('⚽  SPOR'),
                      AZGameCard(
                        emoji: '⛳', title: 'Mini Golf',
                        subtitle: '2-4 Oyuncu · 5 Delik',
                        gradient: AZColors.gradGreen,
                        onTap: () => _push(context, const GolfLobbyScreen()),
                      ),
                      const SizedBox(height: 12),
                      AZGameCard(
                        emoji: '⚽', title: 'Serbest Vuruş',
                        subtitle: '2 Oyuncu · 5 Vuruş · Gol at',
                        gradient: AZColors.gradOrange,
                        onTap: () => _push(context, const SoccerLobbyScreen()),
                      ),
                      const SizedBox(height: 12),
                      AZGameCard(
                        emoji: '🏁', title: 'Araba Yarışı',
                        subtitle: '2-4 Oyuncu · 3 Tur · Top-down',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => _push(context, const RacingLobbyScreen()),
                        badge: 'YENİ',
                      ),
                      const SizedBox(height: 28),

                      // ── ZİHİN ───────────────────────────────────────────
                      _Section('🧠  ZİHİN'),
                      AZGameCard(
                        emoji: '🎯', title: 'Adam Asmaca',
                        subtitle: '2 Oyuncu · Kelime tahmin · 6 tur',
                        gradient: AZColors.gradRed,
                        onTap: () => _push(context, const HangmanLobbyScreen()),
                      ),
                      const SizedBox(height: 12),
                      AZGameCard(
                        emoji: '🏙️', title: 'Şehir Bulmaca',
                        subtitle: '2-4 Oyuncu · İpuçlarla şehri bul',
                        gradient: AZColors.gradPink,
                        onTap: () => _push(context, const CityLobbyScreen()),
                      ),
                      const SizedBox(height: 12),
                      AZGameCard(
                        emoji: '🔤', title: 'Kelime Bulmaca',
                        subtitle: '2-4 Oyuncu · 60 saniye · Harf karıştır',
                        gradient: AZColors.gradCyan,
                        onTap: () => _push(context, const WordLobbyScreen()),
                      ),
                      const SizedBox(height: 28),

                      // ── KART & MASA ─────────────────────────────────────
                      _Section('🃏  KART & MASA'),
                      AZGameCard(
                        emoji: '🀄', title: 'Okey',
                        subtitle: '2-4 Oyuncu · Seri & grup · El aç kazan',
                        gradient: AZColors.gradGreen,
                        onTap: () => _push(context, const OkeyLobbyScreen(mode: 'okey')),
                        badge: 'YENİ',
                      ),
                      const SizedBox(height: 12),
                      AZGameCard(
                        emoji: '🃏', title: 'Okey 101',
                        subtitle: '2-4 Oyuncu · 101 puana ulaşan elenır',
                        gradient: AZColors.gradOrange,
                        onTap: () => _push(context, const OkeyLobbyScreen(mode: '101')),
                        badge: 'YENİ',
                      ),
                      const SizedBox(height: 12),
                      AZGameCard(
                        emoji: '⚪⚫', title: 'Dama',
                        subtitle: '2 Oyuncu · Türk Dama · Klasik strateji',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4E342E), Color(0xFF1A0A00)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => _push(context, const DamaLobbyScreen()),
                        badge: 'YENİ',
                      ),
                      const SizedBox(height: 28),

                      // ── AKSİYON ─────────────────────────────────────────
                      _Section('⚔️  AKSİYON'),
                      AZGameCard(
                        emoji: '⚔️', title: 'Dövüşçüler',
                        subtitle: '1v1 · 6 karakter · Kombo & özel yetenek',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A0000), Color(0xFF1A0010)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => _push(context, const FighterLobbyScreen()),
                        badge: 'YENİ',
                      ),
                      const SizedBox(height: 28),

                      // ── SOSYAL ──────────────────────────────────────────
                      _Section('🎭  SOSYAL'),
                      AZGameCard(
                        emoji: '🧛', title: 'Vampir Köylü',
                        subtitle: '4-8 Oyuncu · Rol bazlı · Mafia tarzı',
                        gradient: AZColors.gradDark,
                        onTap: () => _push(context, const VampireLobbyScreen()),
                      ),
                      const SizedBox(height: 12),
                      AZGameCard(
                        emoji: '☕', title: 'Yalancilar Kahvesi',
                        subtitle: '3-6 Oyuncu · 3 tur · Yalanı yakala',
                        gradient: AZColors.gradRose,
                        onTap: () => _push(context, const LiarLobbyScreen()),
                      ),
                      const SizedBox(height: 28),

                      // ── Nasıl oynanır ───────────────────────────────────
                      AZFrostCard(
                        opacity: 0.10,
                        child: const Column(children: [
                          Icon(Icons.info_outline_rounded, color: Colors.white70, size: 24),
                          SizedBox(height: 10),
                          Text('NASIL OYNANIR?', style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, letterSpacing: 1)),
                          SizedBox(height: 10),
                          Text(
                            '1. Oyun seç\n'
                            '2. "Oda Oluştur" a bas\n'
                            '3. 6 haneli kodu arkadaşına gönder\n'
                            '4. Arkadaşın "Odaya Katıl" ile girer\n'
                            '5. Host "Başlat" a basar → Oyna! 🎮',
                            style: TextStyle(color: Colors.white70,
                                height: 1.7, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ]),
            ),
            const AdaptiveBannerAdWidget(),
          ]),
        ),
      ),
    );
  }

  Widget _Section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(
        color: Colors.white, fontSize: 16,
        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
  );

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
