import 'package:flutter/material.dart';

import '../../core/models/achievement.dart';
import '../../core/services/play_games_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _connectingPlayGames = false;

  @override
  void initState() {
    super.initState();
    ProfileService.instance.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _connectPlayGames() async {
    setState(() => _connectingPlayGames = true);
    await PlayGamesService.instance.signIn();
    if (!mounted) return;
    setState(() => _connectingPlayGames = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(PlayGamesService.instance.isSignedIn
          ? 'Google Play Games\'e bağlandın!'
          : 'Bağlanılamadı — Play Games henüz yapılandırılmamış olabilir'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AZGradientScaffold(
        gradient: AZColors.gradPurple,
        child: Center(
            child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final profile = ProfileService.instance.profile;
    final progress = profile.xpIntoLevel / 100;
    final unlocked = kAchievements
        .where((a) => profile.unlockedAchievementIds.contains(a.id))
        .toList();
    final locked =
        kAchievements.where((a) => !unlocked.contains(a)).toList();

    return AZGradientScaffold(
      gradient: AZColors.gradPurple,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text('PROFİL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 12),

          // ── Seviye kartı ──────────────────────────────────────────────
          AZFrostCard(
            child: Column(children: [
              Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                      color: Color(0x33FFFFFF), shape: BoxShape.circle),
                  child: Center(
                    child: Text('${profile.level}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seviye ${profile.level}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1).toDouble(),
                          minHeight: 8,
                          backgroundColor: const Color(0x33FFFFFF),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${profile.xpIntoLevel}/100 XP',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // ── İstatistikler ─────────────────────────────────────────────
          Row(children: [
            Expanded(
                child: _StatTile(
                    emoji: '🎮', label: 'Maç', value: '${profile.gamesPlayed}')),
            const SizedBox(width: 10),
            Expanded(
                child:
                    _StatTile(emoji: '🏆', label: 'Galibiyet', value: '${profile.wins}')),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    emoji: '💰', label: 'Coin', value: '${profile.coins}')),
          ]),
          const SizedBox(height: 14),

          // ── Google Play Games ────────────────────────────────────────
          AZFrostCard(
            child: Row(children: [
              const Icon(Icons.videogame_asset_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  PlayGamesService.instance.isSignedIn
                      ? 'Google Play Games\'e bağlı'
                      : 'Google Play Games\'e bağlan — ilerlemeni buluta yedekle',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (!PlayGamesService.instance.isSignedIn)
                TextButton(
                  onPressed: _connectingPlayGames ? null : _connectPlayGames,
                  child: _connectingPlayGames
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('BAĞLAN',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Başarımlar ────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'BAŞARIMLAR (${unlocked.length}/${kAchievements.length})',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 10),
          for (final a in unlocked) _AchievementTile(a: a, unlocked: true),
          for (final a in locked) _AchievementTile(a: a, unlocked: false),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.emoji, required this.label, required this.value});

  final String emoji, label, value;

  @override
  Widget build(BuildContext context) => AZFrostCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
      );
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.a, required this.unlocked});

  final AchievementDef a;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AZFrostCard(
          opacity: unlocked ? 0.16 : 0.06,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Opacity(
              opacity: unlocked ? 1 : 0.35,
              child: Text(a.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: TextStyle(
                          color: unlocked ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(a.description,
                      style: TextStyle(
                          color: unlocked ? Colors.white70 : Colors.white38,
                          fontSize: 12)),
                ],
              ),
            ),
            if (unlocked)
              const Icon(Icons.check_circle_rounded,
                  color: AZColors.success, size: 20)
            else
              const Icon(Icons.lock_rounded, color: Colors.white24, size: 18),
          ]),
        ),
      );
}
