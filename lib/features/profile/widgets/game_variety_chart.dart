import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/quickplay/game_ids.dart';
import '../../../core/theme/dashboard_tokens.dart';
import 'bento_card.dart';

/// "Oyun çeşitliliği" bar grafiği — kullanıcının Hızlı Oyunlar ve Online
/// Odalar kategorilerinden kaç FARKLI oyunu en az bir kez denediğini
/// gösterir. Gerçek [PlayerProfile.playedGameIds] verisinden türetilir,
/// uydurma zaman serisi değildir.
class GameVarietyChart extends StatelessWidget {
  const GameVarietyChart({super.key, required this.playedGameIds});

  final Set<String> playedGameIds;

  @override
  Widget build(BuildContext context) {
    final quickPlayed = playedGameIds.where(kQuickGameIds.contains).length;
    final onlinePlayed = playedGameIds.where(kOnlineGameIds.contains).length;
    final quickTotal = kQuickGameIds.length;
    final onlineTotal = kOnlineGameIds.length;
    final maxTotal = [quickTotal, onlineTotal].reduce((a, b) => a > b ? a : b);

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoSectionLabel('Oyun Çeşitliliği'),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxTotal.toDouble(),
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          value == 0 ? 'Hızlı Oyunlar' : 'Online Odalar',
                          style: DashTokens.labelSm,
                        ),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: quickPlayed.toDouble(),
                      color: DashTokens.indigo,
                      width: 34,
                      borderRadius: BorderRadius.circular(8),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true, toY: quickTotal.toDouble(), color: DashTokens.highlight,
                      ),
                    ),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: onlinePlayed.toDouble(),
                      color: DashTokens.emerald,
                      width: 34,
                      borderRadius: BorderRadius.circular(8),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true, toY: onlineTotal.toDouble(), color: DashTokens.highlight,
                      ),
                    ),
                  ]),
                ],
              ),
              duration: const Duration(milliseconds: 700),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 16),
          Row(children: [
            _CoverageChip(
                color: DashTokens.indigo, played: quickPlayed, total: quickTotal, label: 'Hızlı'),
            const SizedBox(width: 16),
            _CoverageChip(
                color: DashTokens.emerald, played: onlinePlayed, total: onlineTotal, label: 'Online'),
          ]),
        ],
      ),
    );
  }
}

class _CoverageChip extends StatelessWidget {
  const _CoverageChip(
      {required this.color, required this.played, required this.total, required this.label});
  final Color color;
  final int played, total;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$played/$total ', style: DashTokens.body.copyWith(color: DashTokens.textPrimary, fontWeight: FontWeight.w700)),
        Text(label, style: DashTokens.labelSm),
      ]);
}
