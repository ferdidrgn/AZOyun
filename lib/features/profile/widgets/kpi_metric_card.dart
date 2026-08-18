import 'package:flutter/material.dart';

import '../../../core/theme/dashboard_tokens.dart';
import 'bento_card.dart';

/// Kurumsal SaaS dashboard'larındaki klasik "KPI kartı": büyük bir sayı,
/// altında etiket, sağ üstte renkli bir ikon rozeti. Vurgu rengi,
/// metriğin anlamına göre (indigo/emerald/amber) seçilir.
class KpiMetricCard extends StatelessWidget {
  const KpiMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.trend,
    this.trendPositive = true,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final String? trend;
  final bool trendPositive;

  @override
  Widget build(BuildContext context) => BentoCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: accent, size: 19),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (trendPositive ? DashTokens.emerald : DashTokens.rose)
                          .withAlpha(24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        trendPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: trendPositive ? DashTokens.emeraldSoft : DashTokens.rose,
                      ),
                      const SizedBox(width: 2),
                      Text(trend!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: trendPositive ? DashTokens.emeraldSoft : DashTokens.rose,
                          )),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: DashTokens.metricValue),
            const SizedBox(height: 4),
            Text(label, style: DashTokens.label),
          ],
        ),
      );
}
