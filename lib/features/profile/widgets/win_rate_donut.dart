import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/dashboard_tokens.dart';
import 'bento_card.dart';

/// Galibiyet/mağlubiyet oranını gösteren donut (halka) grafik — gerçek
/// [PlayerProfile] verisinden (wins / gamesPlayed) türetilir, uydurma
/// zaman serisi kullanılmaz.
class WinRateDonut extends StatelessWidget {
  const WinRateDonut({
    super.key,
    required this.wins,
    required this.gamesPlayed,
    required this.bestStreak,
  });

  final int wins, gamesPlayed, bestStreak;

  @override
  Widget build(BuildContext context) {
    final losses = (gamesPlayed - wins).clamp(0, gamesPlayed);
    final hasData = gamesPlayed > 0;
    final winRate = hasData ? (wins / gamesPlayed * 100) : 0.0;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoSectionLabel('Galibiyet Oranı',
              trailing:
                  bestStreak > 0 ? _StreakChip(bestStreak: bestStreak) : null),
          const SizedBox(height: 18),
          if (!hasData)
            const _EmptyChartPlaceholder()
          else
            SizedBox(
              height: 160,
              child: Stack(alignment: Alignment.center, children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: wins.toDouble().clamp(0.0001, double.infinity),
                        color: DashTokens.emerald(context),
                        showTitle: false,
                        radius: 22,
                      ),
                      PieChartSectionData(
                        value: losses.toDouble().clamp(0.0001, double.infinity),
                        color: DashTokens.highlight(context),
                        showTitle: false,
                        radius: 22,
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 700),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${winRate.toStringAsFixed(0)}%',
                      style: DashTokens.metricValue(context)
                          .copyWith(fontSize: 24)),
                  Text('galibiyet', style: DashTokens.labelSm(context)),
                ]),
              ]),
            ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Row(children: [
            _Legend(
                color: DashTokens.emerald(context),
                label: 'Galibiyet',
                value: '$wins'),
            const SizedBox(width: 20),
            _Legend(
                color: DashTokens.highlight(context),
                label: 'Mağlubiyet',
                value: '$losses'),
          ]),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label, value;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$value ',
            style: DashTokens.body(context).copyWith(
                color: DashTokens.textPrimary(context),
                fontWeight: FontWeight.w700)),
        Text(label, style: DashTokens.labelSm(context)),
      ]);
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.bestStreak});
  final int bestStreak;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: DashTokens.amber(context).withAlpha(24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('🔥 $bestStreak seri',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: DashTokens.amber(context))),
      );
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 160,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.donut_large_rounded,
                color: DashTokens.textTertiary(context), size: 40),
            const SizedBox(height: 8),
            Text('Henüz maç verisi yok', style: DashTokens.labelSm(context)),
          ]),
        ),
      );
}
