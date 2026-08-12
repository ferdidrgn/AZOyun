import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/firebase_options.dart';
import 'core/quickplay/quickplay.dart';
import 'core/services/ad_service.dart';
import 'core/services/profile_service.dart';
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
import 'features/impostor/impostor_screens.dart';
import 'features/mystery/mystery_case_screen.dart';

// HIZLI OYUNLAR — aynı cihazda 2-6 kişi ya da bilgisayara karşı
import 'features/profile/profile_screen.dart';
import 'features/quickgames/tic_tac_toe_screen.dart';
import 'features/quickgames/connect_four_screen.dart';
import 'features/quickgames/reversi_screen.dart';
import 'features/quickgames/rps_screen.dart';
import 'features/quickgames/memory_match_screen.dart';
import 'features/quickgames/dots_boxes_screen.dart';
import 'features/quickgames/nim_screen.dart';
import 'features/quickgames/snake_screen.dart';
import 'features/quickgames/game_2048_screen.dart';
import 'features/quickgames/reflex_tap_screen.dart';
import 'features/quickgames/trivia_screen.dart';
import 'features/quickgames/bulls_cows_screen.dart';
import 'features/quickgames/balloon_pop_screen.dart';
import 'features/quickgames/dice_party_screen.dart';
import 'features/quickgames/sliding_puzzle_screen.dart';
import 'features/quickgames/jump_dash_screen.dart';
import 'features/quickgames/color_memory_screen.dart';
import 'features/quickgames/mini_bowling_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ProfileService.instance.load();
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
// HOME SCREEN — sabit üst kısım (başlık + profil) + iki sekme (Hızlı / Online)
// ════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AZColors.gradPurple),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildProfileCard(context),
                ]),
              ),
              const SizedBox(height: 14),
              const _HomeTabBar(),
              const Expanded(
                child: TabBarView(children: [
                  _QuickGamesTab(),
                  _OnlineGamesTab(),
                ]),
              ),
              const AdaptiveBannerAdWidget(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(children: [
    Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0x26FFFFFF), shape: BoxShape.circle),
      child: const Icon(Icons.sports_esports, size: 44, color: Colors.white),
    ),
    const SizedBox(height: 10),
    const Text('AZ OYUN',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 3)),
    const SizedBox(height: 4),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(20)),
      child: const Text('31 OYUN · ONLINE & AYNI CİHAZDA',
          style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
    ),
  ]);

  Widget _buildProfileCard(BuildContext context) => GestureDetector(
    onTap: () => _push(context, const ProfileScreen()),
    child: AZFrostCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profilim',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Seviye · Başarımlar · Liderlik Tablosu',
                  style: TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0x99FFFFFF), size: 14),
      ]),
    ),
  );
}

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(AZRadius.lg),
    ),
    child: TabBar(
      indicator: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AZRadius.md),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: AZColors.purple,
      unselectedLabelColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
      tabs: const [
        Tab(height: 42, text: '⚡ HIZLI OYUNLAR'),
        Tab(height: 42, text: '🌐 ONLINE OYUNLAR'),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// SEKME 1 — HIZLI OYUNLAR (aynı cihazda 1-6 kişi / AI)
// ════════════════════════════════════════════════════════════════════════════

class _QuickGamesTab extends StatelessWidget {
  const _QuickGamesTab();

  static const _strategyGrad = AZColors.gradPurple;
  static const _partyGrad = AZColors.gradOrange;
  static const _arcadeGrad = AZColors.gradCyan;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionHeader('🕵️  BÜYÜK OYUN'),
      AZGameCard(
        emoji: '🚂', title: 'Gece Ekspresi Cinayeti',
        subtitle: 'Polisiye · İz Sürme · Şaşırtıcı Final · ~10 dk',
        gradient: kNoirGradient,
        badge: 'YENİ',
        onTap: () => _push(context, const MysteryLobbyScreen()),
      ),
      const SizedBox(height: 26),

      _sectionHeader('🧠  STRATEJİ OYUNLARI'),
      _grid([
        _QuickTile(
          emoji: '❌⭕', title: 'XOX', subtitle: '2 Kişi · AI', gradient: _strategyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const TicTacToeLobbyScreen(),
              game: (p) => TicTacToeGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🔴🟡', title: "4'lü Bağlantı", subtitle: '2 Kişi · AI', gradient: _strategyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const ConnectFourLobbyScreen(),
              game: (p) => ConnectFourGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '⚫⚪', title: 'Reversi', subtitle: '2 Kişi · AI', gradient: _strategyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const ReversiLobbyScreen(),
              game: (p) => ReversiGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🪨', title: 'Taş Alma', subtitle: '2 Kişi · AI', gradient: _strategyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const NimLobbyScreen(),
              game: (p) => NimGameScreen(players: p)),
        ),
      ]),
      const SizedBox(height: 26),

      _sectionHeader('🎉  PARTİ OYUNLARI'),
      _grid([
        _QuickTile(
          emoji: '🪨📄✂️', title: 'Taş Kağıt Makas', subtitle: '2-6 Kişi · AI', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const RpsLobbyScreen(),
              game: (p) => RpsGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🧠', title: 'Hafıza Kartları', subtitle: '2-6 Kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const MemoryMatchLobbyScreen(),
              game: (p) => MemoryMatchGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '📦', title: 'Çizgi Doldurma', subtitle: '2-4 Kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const DotsBoxesLobbyScreen(),
              game: (p) => DotsBoxesGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '⚡', title: 'Refleks Çarpışması', subtitle: '2-6 Kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const ReflexTapLobbyScreen(),
              game: (p) => ReflexTapGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🧠❓', title: 'Kim Bilir?', subtitle: '1-6 Kişi · Skor', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const TriviaLobbyScreen(),
              game: (p) => TriviaGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🔢🕵️', title: 'Sayı Tahmin Düellosu', subtitle: '1-6 Kişi · Skor', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const BullsCowsLobbyScreen(),
              game: (p) => BullsCowsGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🎈', title: 'Balon Patlatma', subtitle: '1-6 Kişi · Skor', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const BalloonPopLobbyScreen(),
              game: (p) => BalloonPopGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🎲', title: 'Parti Zarı', subtitle: '1-6 Kişi · Skor', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const DicePartyLobbyScreen(),
              game: (p) => DicePartyGameScreen(players: p)),
        ),
      ]),
      const SizedBox(height: 26),

      _sectionHeader('🕹️  ARCADE & SKOR'),
      _grid([
        _QuickTile(
          emoji: '🐍', title: 'Yılan', subtitle: '1-6 Kişi · Skor', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const SnakeLobbyScreen(),
              game: (p) => SnakeGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🔢', title: '2048', subtitle: '1-6 Kişi · Skor', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const Game2048LobbyScreen(),
              game: (p) => Game2048GameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🧩', title: 'Kayan Yapboz', subtitle: '1-6 Kişi · Skor', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const SlidingPuzzleLobbyScreen(),
              game: (p) => SlidingPuzzleGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🐤', title: 'Zıpla Geç', subtitle: '1-6 Kişi · Skor', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const JumpDashLobbyScreen(),
              game: (p) => JumpDashGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🎨', title: 'Renk Hafızası', subtitle: '1-6 Kişi · Skor', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const ColorMemoryLobbyScreen(),
              game: (p) => ColorMemoryGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🎳', title: 'Mini Bovling', subtitle: '1-6 Kişi · 3D · Skor', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const MiniBowlingLobbyScreen(),
              game: (p) => MiniBowlingGameScreen(players: p)),
        ),
      ]),
    ]),
  );

  Widget _grid(List<Widget> tiles) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.35,
    children: tiles,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// SEKME 2 — ONLINE OYUNLAR (oda kodu ile uzaktan arkadaşlarla)
// ════════════════════════════════════════════════════════════════════════════

class _OnlineGamesTab extends StatelessWidget {
  const _OnlineGamesTab();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionHeader('⚽  SPOR'),
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
      const SizedBox(height: 24),

      _sectionHeader('🧠  ZİHİN'),
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
      const SizedBox(height: 24),

      _sectionHeader('🃏  KART & MASA'),
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
      const SizedBox(height: 24),

      _sectionHeader('⚔️  AKSİYON'),
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
      const SizedBox(height: 24),

      _sectionHeader('🎭  SOSYAL'),
      AZGameCard(
        emoji: '👨‍🚀', title: 'Hain Kim?',
        subtitle: '4-10 Oyuncu · Görev tamamla · Gizli haini bul',
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        onTap: () => _push(context, const ImpostorLobbyScreen()),
        badge: 'YENİ',
      ),
      const SizedBox(height: 12),
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
      const SizedBox(height: 24),

      AZFrostCard(
        opacity: 0.10,
        child: const Column(children: [
          Icon(Icons.info_outline_rounded, color: Colors.white70, size: 22),
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
    ]),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// ORTAK YARDIMCILAR
// ════════════════════════════════════════════════════════════════════════════

Widget _sectionHeader(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(t, style: const TextStyle(
      color: Colors.white, fontSize: 15,
      fontWeight: FontWeight.bold, letterSpacing: 0.5)),
);

void _push(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

/// Kurulum ekranını açar (oyuncu sayısı/adı/AI seçimi), oyuncu listesiyle
/// dönerse oyun ekranına geçer. Kullanıcı kurulumdan geri dönerse hiçbir şey
/// olmaz.
Future<void> _openQuickGame(
  BuildContext context, {
  required Widget lobby,
  required Widget Function(List<QPPlayer> players) game,
}) async {
  final players = await Navigator.push<List<QPPlayer>>(
    context,
    MaterialPageRoute(builder: (_) => lobby),
  );
  if (players == null || !context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => game(players)));
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final String emoji, title, subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        gradient is LinearGradient ? (gradient as LinearGradient).colors.first : AZColors.purple;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AZRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AZRadius.lg),
            boxShadow: [
              BoxShadow(color: accent.withAlpha(70), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration:
                      const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(height: 10),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 10.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
