import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/cosmetic_service.dart';
import '../../core/services/iap_service.dart';
import '../../core/navigation/join_router.dart';
import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../checkers/dama_screens.dart';
import '../city/city_screens.dart';
import '../deck/deck_lobby_screen.dart';
import '../fighter/fighter_screens.dart';
import '../golf/golf_lobby_screen.dart';
import '../hangman/hangman_lobby_screen.dart';
import '../impostor/impostor_screens.dart';
import '../liar/liar_screens.dart';
import '../mystery/mystery_case_screen.dart';
import '../okey/okey_screens.dart';
import '../profile/profile_screen.dart';
import '../quickgames/balloon_pop_screen.dart';
import '../quickgames/bulls_cows_screen.dart';
import '../quickgames/carrom_screen.dart';
import '../quickgames/chess_screen.dart';
import '../quickgames/color_memory_screen.dart';
import '../quickgames/connect_four_screen.dart';
import '../quickgames/count_numbers_screen.dart';
import '../quickgames/dice_party_screen.dart';
import '../quickgames/dots_boxes_screen.dart';
import '../quickgames/draw_smash_screen.dart';
import '../quickgames/elite_quiz_screen.dart';
import '../quickgames/game_2048_screen.dart';
import '../quickgames/jump_dash_screen.dart';
import '../quickgames/kid_party_screens.dart';
import '../quickgames/lane_race_screen.dart';
import '../quickgames/math_puzzle_screen.dart';
import '../quickgames/memory_match_screen.dart';
import '../quickgames/mini_bowling_screen.dart';
import '../quickgames/monkey_touch_screen.dart';
import '../quickgames/nail_salon_screen.dart';
import '../quickgames/nim_screen.dart';
import '../quickgames/pac_maze_screen.dart';
import '../quickgames/reflex_tap_screen.dart';
import '../quickgames/reversi_screen.dart';
import '../quickgames/rps_screen.dart';
import '../quickgames/scuba_sweep_screen.dart';
import '../quickgames/sliding_puzzle_screen.dart';
import '../quickgames/snake_screen.dart';
import '../quickgames/spot_diff_screen.dart';
import '../quickgames/tic_tac_toe_screen.dart';
import '../quickgames/tiger_run_screen.dart';
import '../quickgames/triple_match_screen.dart';
import '../quickgames/trivia_screen.dart';
import '../quickgames/word_mania_screen.dart';
import '../racing/racing_screens.dart';
import '../settings/settings_screen.dart';
import '../store/play_hub_screen.dart';
import '../soccer/soccer_lobby_screen.dart';
import '../vampire_wolf/vampire_screens.dart';
import '../word/word_screens.dart';

// ════════════════════════════════════════════════════════════════════════════
// HOME SCREEN — sabit üst kısım (başlık + profil) + iki sekme (Hızlı / Online)
// ════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _section = 0;
  late final StreamSubscription<String> _purchaseNotes;

  @override
  void initState() {
    super.initState();
    PendingJoin.instance.addListener(_openPendingInvite);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingInvite());
    _purchaseNotes = IAPService.instance.notes.listen((message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _purchaseNotes.cancel();
    PendingJoin.instance.removeListener(_openPendingInvite);
    super.dispose();
  }

  void _openPendingInvite() {
    final invite = PendingJoin.instance.take();
    if (invite == null || !mounted) {
      return;
    }
    openGameInvite(context, invite.game, invite.code);
  }

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final pages = <Widget>[
      const _QuickGamesTab(),
      const _OnlineGamesTab(),
      const _TableTab(),
    ];
    final body = Column(
      children: [
        _HomeHeader(onSettings: () => _push(context, const SettingsScreen())),
        Expanded(
          child: IndexedStack(index: _section, children: pages),
        ),
        const AdaptiveBannerAdWidget(),
      ],
    );
    return Scaffold(
      bottomNavigationBar: wide
          ? null
          : _SectionBar(
              index: _section,
              onSelect: (index) => setState(() => _section = index),
              ink: palette.ink,
            ),
      body: ListenableBuilder(
        listenable: CosmeticService.instance,
        builder: (context, _) {
          final cloth = CosmeticService.instance.equipped;
          final classic = cloth.id == 'classic';
          return FeltBackdrop(
            canvasTop: classic ? null : cloth.top,
            canvasBottom: classic ? null : cloth.bottom,
            child: SafeArea(
              child: wide
                  ? Row(
                      children: [
                        _SectionRail(
                          index: _section,
                          onSelect: (index) => setState(() => _section = index),
                        ),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          const FeltMark(size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AZ Oyun', style: feltDisplay(palette.ink, 28)),
                Text('Aynı masada', style: feltUi(palette.muted, 13)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Play mağazası',
            onPressed: () => _push(context, const PlayHubScreen()),
            icon: Icon(Icons.storefront_rounded, color: palette.ink),
          ),
          IconButton(
            tooltip: 'Profil',
            onPressed: () => _push(context, const ProfileScreen()),
            icon: Icon(Icons.person_rounded, color: palette.ink),
          ),
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: onSettings,
            icon: Icon(Icons.settings_rounded, color: palette.ink),
          ),
        ],
      ),
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.index, required this.onSelect, required this.ink});

  final int index;
  final ValueChanged<int> onSelect;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      height: 68,
      backgroundColor: FeltPalette.of(context).surface,
      indicatorColor: FeltColors.brass.withValues(alpha: 0.28),
      labelTextStyle: WidgetStatePropertyAll(feltUi(ink, 12, weight: FontWeight.w600)),
      onDestinationSelected: onSelect,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.bolt_rounded), label: 'Hızlı'),
        NavigationDestination(icon: Icon(Icons.public_rounded), label: 'Online'),
        NavigationDestination(icon: Icon(Icons.table_restaurant_rounded), label: 'Masa'),
      ],
    );
  }
}

class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: onSelect,
      backgroundColor: palette.surface,
      indicatorColor: FeltColors.brass.withValues(alpha: 0.28),
      labelType: NavigationRailLabelType.all,
      minWidth: 88,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.bolt_rounded), label: Text('Hızlı')),
        NavigationRailDestination(icon: Icon(Icons.public_rounded), label: Text('Online')),
        NavigationRailDestination(icon: Icon(Icons.table_restaurant_rounded), label: Text('Masa')),
      ],
    );
  }
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
      _sectionHeader('🎈  ÇOCUK MASASI'),
      _grid(context, [
        _QuickTile(
          emoji: '🐱', title: 'Ters Mama', subtitle: '1-6 kişi, kediyi besle', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const TersMamaLobbyScreen(),
              game: (p) => TersMamaGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🥞', title: 'Hıçkırık Kulesi', subtitle: '1-6 kişi, ritme bas', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const HiccupTowerLobbyScreen(),
              game: (p) => HiccupTowerGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🥣', title: 'Geri Sar Çorba', subtitle: '1-6 kişi, kaşığı durdur', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const SoupBackLobbyScreen(),
              game: (p) => SoupBackGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🍃', title: 'Saçtaki Yaprak', subtitle: '1-6 kişi, üfle', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const HairLeafLobbyScreen(),
              game: (p) => HairLeafGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🩴', title: 'Tek Terlik', subtitle: '1-6 kişi, eşiyle oturt', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const SlipperFlipLobbyScreen(),
              game: (p) => SlipperFlipGameScreen(players: p)),
        ),
      ]),
      const SizedBox(height: 26),

      _sectionHeader('🕵️  BÜYÜK OYUN'),
      AZGameCard(
        emoji: '🕵️', title: 'Dedektif Dosyaları',
        subtitle: 'Polisiye · Birbirine Bağlı Vakalar · Şok Final',
        gradient: kNoirGradient,
        badge: 'YENİ',
        onTap: () => _push(context, const MysteryLobbyScreen()),
      ),
      const SizedBox(height: 26),

      _sectionHeader('🧠  STRATEJİ OYUNLARI'),
      _grid(context, [
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
        _QuickTile(
          emoji: '♟️', title: 'Satranç', subtitle: '2 Kişi', gradient: _strategyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const ChessLobbyScreen(),
              game: (p) => ChessGameScreen(players: p)),
        ),
      ]),
      const SizedBox(height: 26),

      _sectionHeader('🎉  PARTİ OYUNLARI'),
      _grid(context, [
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
        _QuickTile(
          emoji: '🎯', title: 'Quiz Eliti', subtitle: '1-6 kişi, jokerli', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const EliteQuizLobbyScreen(),
              game: (p) => EliteQuizGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '➗', title: 'Matematik Bulmaca', subtitle: '1-6 kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const MathPuzzleLobbyScreen(),
              game: (p) => MathPuzzleGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🔤', title: 'Kelime Avı', subtitle: '1-6 kişi, 6 deneme', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const WordManiaLobbyScreen(),
              game: (p) => WordManiaGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🔍', title: 'Farkı Bul', subtitle: '1-6 kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const SpotDiffLobbyScreen(),
              game: (p) => SpotDiffGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🍒', title: 'Üçlü Eşle', subtitle: '1-6 kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const TripleMatchLobbyScreen(),
              game: (p) => TripleMatchGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '1️⃣', title: 'Sayı Say', subtitle: '1-6 kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const CountNumbersLobbyScreen(),
              game: (p) => CountNumbersGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '💅', title: 'Oje Atölyesi', subtitle: '1-6 kişi', gradient: _partyGrad,
          onTap: () => _openQuickGame(context,
              lobby: const NailSalonLobbyScreen(),
              game: (p) => NailSalonGameScreen(players: p)),
        ),
      ]),
      const SizedBox(height: 26),

      _sectionHeader('🕹️  ARCADE & SKOR'),
      _grid(context, [
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
          emoji: '🤿', title: 'Scuba Sweep', subtitle: '1-6 kişi, okyanusu temizle', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const ScubaSweepLobbyScreen(),
              game: (players) => ScubaSweepGameScreen(players: players)),
        ),
        _QuickTile(
          emoji: '🐯', title: 'Kaplan Koşusu', subtitle: '1-6 kişi, altın topla', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const TigerRunLobbyScreen(),
              game: (p) => TigerRunGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🐵', title: 'Maymun Dokunuşu', subtitle: '1-6 kişi', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const MonkeyTouchLobbyScreen(),
              game: (p) => MonkeyTouchGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '✏️', title: 'Çiz Kazan', subtitle: '1-6 kişi', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const DrawSmashLobbyScreen(),
              game: (p) => DrawSmashGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🏎️', title: 'Şerit Yarışı', subtitle: '1-6 kişi', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const LaneRaceLobbyScreen(),
              game: (p) => LaneRaceGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '🟠', title: 'Karambol', subtitle: '1-6 kişi', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const CarromLobbyScreen(),
              game: (p) => CarromGameScreen(players: p)),
        ),
        _QuickTile(
          emoji: '😮', title: 'Pelet Labirenti', subtitle: '1-6 kişi', gradient: _arcadeGrad,
          onTap: () => _openQuickGame(context,
              lobby: const PacMazeLobbyScreen(),
              game: (p) => PacMazeGameScreen(players: p)),
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

  Widget _grid(BuildContext context, List<Widget> tiles) {
    final width = MediaQuery.sizeOf(context).width;
    var columns = 2;
    if (width >= 1100) {
      columns = 4;
    } else if (width >= 720) {
      columns = 3;
    }
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: columns >= 3 ? 1.45 : 1.22,
      children: tiles,
    );
  }
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
          colors: [Color(0xFF3A4356), Color(0xFF232B3A)],
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
          colors: [Color(0xFF5C4A3D), Color(0xFF2E241D)],
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
          colors: [Color(0xFF5C3530), Color(0xFF2E1A17)],
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
          colors: [Color(0xFF2A3540), Color(0xFF35434D), Color(0xFF425461)],
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

      Text(
        'Oda kur, QR kodu TV, bilgisayar veya telefonda aç. Arkadaşın aynı odaya düşer.',
        style: feltUi(FeltPalette.of(context).muted, 14),
      ),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// ORTAK YARDIMCILAR
// ════════════════════════════════════════════════════════════════════════════

Widget _sectionHeader(String title) => Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(title, style: feltUi(FeltPalette.of(context).ink, 18, weight: FontWeight.w700)),
      ),
    );

class _TableTab extends StatelessWidget {
  const _TableTab();

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Text('Masa', style: feltDisplay(palette.ink, 36)),
        const SizedBox(height: 8),
        Text(
          'Bir ekranı ortaya koy. Telefonlar eldeki kartları gösterir. QR kodunu TV, bilgisayar veya başka bir telefonda aç.',
          style: feltUi(palette.muted, 15),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () => _push(context, const DeckLobbyScreen()),
            style: FilledButton.styleFrom(
              backgroundColor: FeltColors.felt,
              foregroundColor: FeltColors.ivory,
            ),
            child: Text('Pişti masasına geç', style: feltUi(FeltColors.ivory, 16, weight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Diğer online odaların kodunun altında da aynı QR vardır. Oyun, kodu açan her cihazda başlar.',
          style: feltUi(palette.muted, 14),
        ),
      ],
    );
  }
}

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
    final palette = FeltPalette.of(context);
    final accent = gradient is LinearGradient ? (gradient as LinearGradient).colors.first : AZColors.purple;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 28, height: 4, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4))),
                const Spacer(),
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: feltUi(palette.ink, 14, weight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: feltUi(palette.muted, 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
