import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/quickplay/game_ids.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/theme/dashboard_tokens.dart';
import 'widgets/bento_card.dart';

/// Liderlik Tablosu — skor tabanlı hızlı oyunların (Yılan, 2048) yerel
/// "en iyi 10" listesini gösterir. Veri [LeaderboardService]'ten gelir;
/// bu ekran sadece sunum katmanıdır. Profil ekranıyla aynı Bento-Grid /
/// dashboard görsel dilini kullanır.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const _games = ['snake', '2048'];

  String _gameId = _games.first;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DashTokens.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: DashTokens.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text('Liderlik Tablosu', style: DashTokens.displayLg.copyWith(fontSize: 22)),
                ]),
                const SizedBox(height: 16),
                _GamePicker(
                  games: _games,
                  selected: _gameId,
                  onChanged: (id) => setState(() => _gameId = id),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<List<LeaderboardEntry>>(
                    key: ValueKey(_gameId),
                    future: LeaderboardService.instance.topScores(_gameId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white24),
                        );
                      }
                      final entries = snapshot.data!;
                      if (entries.isEmpty) {
                        return _EmptyState(gameTitle: kQuickGameTitles[_gameId] ?? _gameId);
                      }
                      return ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _LeaderboardRow(rank: i + 1, entry: entries[i])
                            .animate()
                            .fadeIn(duration: 300.ms, delay: (i * 40).ms)
                            .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _GamePicker extends StatelessWidget {
  const _GamePicker({required this.games, required this.selected, required this.onChanged});
  final List<String> games;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: games.map((id) {
          final isSelected = id == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(id),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? DashTokens.accent(context) : DashTokens.surface,
                  borderRadius: BorderRadius.circular(DashTokens.chipRadius),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : DashTokens.border,
                  ),
                ),
                child: Text(
                  kQuickGameTitles[id] ?? id,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? DashTokens.canvas : DashTokens.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry});
  final int rank;
  final LeaderboardEntry entry;

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};

  @override
  Widget build(BuildContext context) {
    final medal = _medals[rank];
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: rank <= 3 ? DashTokens.amber.withAlpha(70) : null,
      child: Row(children: [
        SizedBox(
          width: 32,
          child: medal != null
              ? Text(medal, style: const TextStyle(fontSize: 20))
              : Text('$rank', style: DashTokens.label.copyWith(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(entry.name,
              style: DashTokens.headline.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis),
        ),
        Text('${entry.score}', style: DashTokens.metricValue.copyWith(fontSize: 18)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.gameTitle});
  final String gameTitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🏆', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('Henüz $gameTitle skoru yok', style: DashTokens.headline),
          const SizedBox(height: 6),
          Text('İlk skoru sen kaydet, adın burada görünsün.', style: DashTokens.body),
        ]),
      );
}
