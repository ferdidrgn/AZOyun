import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/achievement.dart';
import '../../core/models/player_profile.dart';
import '../../core/services/play_games_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/dashboard_tokens.dart';
import 'leaderboard_screen.dart';
import 'widgets/achievement_bento_tile.dart';
import 'widgets/bento_card.dart';
import 'widgets/game_variety_chart.dart';
import 'widgets/kpi_metric_card.dart';
import 'widgets/play_games_banner.dart';
import 'widgets/profile_hero_card.dart';
import 'widgets/profile_shimmer.dart';
import 'widgets/win_rate_donut.dart';

/// Profil / İstatistik ekranı — Bento-Grid tabanlı, dark-mode SaaS
/// dashboard dili. Web/masaüstünde (>=1024px) çok sütunlu bir yerleşim,
/// mobilde tek sütunlu bir `CustomScrollView` kullanır.
///
/// Veri kaynağı ve iş mantığı [ProfileService]/[PlayGamesService]'ten
/// gelir — bu ekran sadece sunum katmanıdır.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _connectingPlayGames = false;
  String? _connectError;

  @override
  void initState() {
    super.initState();
    ProfileService.instance.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _connectPlayGames() async {
    setState(() { _connectingPlayGames = true; _connectError = null; });
    await PlayGamesService.instance.signIn();
    if (!mounted) return;
    final ok = PlayGamesService.instance.isSignedIn;
    setState(() {
      _connectingPlayGames = false;
      _connectError = ok ? null : 'Bağlanılamadı — Play Games henüz yapılandırılmamış olabilir';
    });
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_connectError!)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DashTokens.canvas,
        body: LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= DashTokens.desktopBreakpoint;
          return isDesktop ? _buildDesktopDashboard(context) : _buildMobileDashboard(context);
        }),
      );

  // ═══════════════════════════════════════════════════════════════════
  // MOBİL (< 1024px) — SliverAppBar + tek sütunlu CustomScrollView
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMobileDashboard(BuildContext context) => CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: DashTokens.canvas,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 96,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: DashTokens.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text('Profil', style: DashTokens.displayLg.copyWith(fontSize: 22)),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [DashTokens.accent(context).withAlpha(24), DashTokens.canvas],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverToBoxAdapter(
              child: _loading
                  ? const ProfileDashboardShimmer()
                  : _MobileContent(
                      connecting: _connectingPlayGames,
                      onConnectPlayGames: _connectPlayGames,
                    ),
            ),
          ),
        ],
      );

  // ═══════════════════════════════════════════════════════════════════
  // MASAÜSTÜ / WEB (>= 1024px) — çok sütunlu Bento-Grid
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDesktopDashboard(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: DashTokens.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text('Profil & İstatistikler', style: DashTokens.displayLg),
              ]),
              const SizedBox(height: 28),
              Expanded(
                child: _loading
                    ? const SingleChildScrollView(child: ProfileDashboardShimmer(desktop: true))
                    : SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: _DesktopContent(
                            connecting: _connectingPlayGames,
                            onConnectPlayGames: _connectPlayGames,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════
// ORTAK VERİ ÖZETİ
// ═══════════════════════════════════════════════════════════════════════

class _DashboardData {
  _DashboardData()
      : profile = ProfileService.instance.profile,
        unlocked = kAchievements
            .where((a) => ProfileService.instance.profile.unlockedAchievementIds.contains(a.id))
            .toList(),
        locked = kAchievements
            .where((a) => !ProfileService.instance.profile.unlockedAchievementIds.contains(a.id))
            .toList();

  final PlayerProfile profile;
  final List<AchievementDef> unlocked;
  final List<AchievementDef> locked;
}

// ═══════════════════════════════════════════════════════════════════════
// MOBİL İÇERİK
// ═══════════════════════════════════════════════════════════════════════

class _MobileContent extends StatelessWidget {
  const _MobileContent({required this.connecting, required this.onConnectPlayGames});
  final bool connecting;
  final VoidCallback onConnectPlayGames;

  @override
  Widget build(BuildContext context) {
    final d = _DashboardData();
    final p = d.profile;
    final isNewPlayer = p.gamesPlayed == 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (isNewPlayer) ...[
        const _NewPlayerBanner(),
        const SizedBox(height: 14),
      ],
      ProfileHeroCard(
        level: p.level,
        xpIntoLevel: p.xpIntoLevel,
        xpPerLevel: 100,
        coins: p.coins,
        playerName: 'Oyuncu',
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: KpiMetricCard(
            icon: Icons.sports_esports_rounded,
            value: '${p.gamesPlayed}',
            label: 'Oynanan Maç',
            accent: DashTokens.accent(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiMetricCard(
            icon: Icons.emoji_events_rounded,
            value: '${p.wins}',
            label: 'Galibiyet',
            accent: DashTokens.emerald,
            trend: p.gamesPlayed > 0 ? '${(p.wins / p.gamesPlayed * 100).round()}%' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiMetricCard(
            icon: Icons.local_fire_department_rounded,
            value: '${p.bestWinStreak}',
            label: 'En İyi Seri',
            accent: DashTokens.amber,
          ),
        ),
      ]).animate().fadeIn(duration: 400.ms, delay: 80.ms),
      const SizedBox(height: 14),
      WinRateDonut(wins: p.wins, gamesPlayed: p.gamesPlayed, bestStreak: p.bestWinStreak),
      const SizedBox(height: 14),
      GameVarietyChart(playedGameIds: p.playedGameIds),
      const SizedBox(height: 14),
      PlayGamesBanner(
        connected: PlayGamesService.instance.isSignedIn,
        connecting: connecting,
        onConnect: onConnectPlayGames,
      ),
      const SizedBox(height: 14),
      const _LeaderboardEntryCard(),
      const SizedBox(height: 24),
      BentoSectionLabel('Başarımlar (${d.unlocked.length}/${kAchievements.length})'),
      const SizedBox(height: 12),
      _AchievementGrid(unlocked: d.unlocked, locked: d.locked),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MASAÜSTÜ İÇERİK — sol geniş panel + sağ dar panel
// ═══════════════════════════════════════════════════════════════════════

class _DesktopContent extends StatelessWidget {
  const _DesktopContent({required this.connecting, required this.onConnectPlayGames});
  final bool connecting;
  final VoidCallback onConnectPlayGames;

  @override
  Widget build(BuildContext context) {
    final d = _DashboardData();
    final p = d.profile;
    final isNewPlayer = p.gamesPlayed == 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isNewPlayer) ...[
        const _NewPlayerBanner(),
        const SizedBox(height: 20),
      ],
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Sol panel ──────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ProfileHeroCard(
                level: p.level,
                xpIntoLevel: p.xpIntoLevel,
                xpPerLevel: 100,
                coins: p.coins,
                playerName: 'Oyuncu',
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: KpiMetricCard(
                    icon: Icons.sports_esports_rounded,
                    value: '${p.gamesPlayed}',
                    label: 'Oynanan Maç',
                    accent: DashTokens.accent(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiMetricCard(
                    icon: Icons.emoji_events_rounded,
                    value: '${p.wins}',
                    label: 'Galibiyet',
                    accent: DashTokens.emerald,
                    trend: p.gamesPlayed > 0 ? '${(p.wins / p.gamesPlayed * 100).round()}%' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiMetricCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '${p.bestWinStreak}',
                    label: 'En İyi Seri',
                    accent: DashTokens.amber,
                  ),
                ),
              ]).animate().fadeIn(duration: 400.ms, delay: 80.ms),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: WinRateDonut(
                      wins: p.wins, gamesPlayed: p.gamesPlayed, bestStreak: p.bestWinStreak),
                ),
                const SizedBox(width: 16),
                Expanded(child: GameVarietyChart(playedGameIds: p.playedGameIds)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          // ── Sağ panel ──────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PlayGamesBanner(
                connected: PlayGamesService.instance.isSignedIn,
                connecting: connecting,
                onConnect: onConnectPlayGames,
              ),
              const SizedBox(height: 16),
              const _LeaderboardEntryCard(),
              const SizedBox(height: 16),
              BentoCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  BentoSectionLabel('Başarımlar (${d.unlocked.length}/${kAchievements.length})'),
                  const SizedBox(height: 16),
                  _AchievementGrid(unlocked: d.unlocked, locked: d.locked, columns: 2, shrinkWrap: true),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PAYLAŞILAN ALT-BİLEŞENLER
// ═══════════════════════════════════════════════════════════════════════

class _NewPlayerBanner extends StatelessWidget {
  const _NewPlayerBanner();

  @override
  Widget build(BuildContext context) => BentoCard(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [DashTokens.emerald.withAlpha(38), DashTokens.surface],
        ),
        borderColor: DashTokens.emerald.withAlpha(60),
        child: Row(children: [
          Text('👋', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Henüz hiç maç oynamadın',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: DashTokens.textPrimary)),
                const SizedBox(height: 3),
                Text('İlk maçını oyna, istatistiklerin burada canlanmaya başlasın.',
                    style: DashTokens.labelSm),
              ],
            ),
          ),
        ]),
      ).animate().fadeIn(duration: 350.ms);
}

/// Profil ekranından Liderlik Tablosu'na giden tıklanabilir kart — Home
/// ekranındaki profil kartının vaat ettiği "Liderlik Tablosu" bağlantısı.
class _LeaderboardEntryCard extends StatelessWidget {
  const _LeaderboardEntryCard();

  @override
  Widget build(BuildContext context) => BentoCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DashTokens.amber.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.emoji_events_rounded, color: DashTokens.amber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Liderlik Tablosu',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: DashTokens.textPrimary)),
                const SizedBox(height: 2),
                Text('Yılan ve 2048\'de en iyi skorlar', style: DashTokens.labelSm),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: DashTokens.textTertiary),
        ]),
      ).animate().fadeIn(duration: 350.ms);
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({
    required this.unlocked,
    required this.locked,
    this.columns = 2,
    this.shrinkWrap = false,
  });

  final List<AchievementDef> unlocked;
  final List<AchievementDef> locked;
  final int columns;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final all = [...unlocked, ...locked];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: all.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: shrinkWrap ? 0.98 : 0.88,
      ),
      itemBuilder: (context, i) => AchievementBentoTile(
        def: all[i],
        unlocked: i < unlocked.length,
        animationIndex: i,
      ),
    );
  }
}
