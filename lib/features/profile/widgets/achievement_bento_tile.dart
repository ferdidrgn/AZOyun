import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/achievement.dart';
import '../../../core/theme/dashboard_tokens.dart';
import 'bento_card.dart';

/// Bento-grid içinde tek bir başarım kartı. Açık başarımlar aksan
/// renginde bir rozet + "+XP" etiketiyle öne çıkar; kilitli olanlar
/// soluk ve kilit ikonuyla gösterilir.
class AchievementBentoTile extends StatelessWidget {
  const AchievementBentoTile({
    super.key,
    required this.def,
    required this.unlocked,
    this.animationIndex = 0,
  });

  final AchievementDef def;
  final bool unlocked;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final tile = BentoCard(
      padding: const EdgeInsets.all(14),
      color: unlocked ? DashTokens.surfaceHi : DashTokens.surface,
      borderColor: unlocked ? DashTokens.indigo.withAlpha(60) : DashTokens.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked ? DashTokens.indigo.withAlpha(30) : DashTokens.highlight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: Text(def.emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const Spacer(),
            if (unlocked)
              Icon(Icons.check_circle_rounded, color: DashTokens.emeraldSoft, size: 16)
            else
              Icon(Icons.lock_rounded, color: DashTokens.textTertiary, size: 14),
          ]),
          const SizedBox(height: 10),
          Text(def.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: unlocked ? DashTokens.textPrimary : DashTokens.textTertiary,
              )),
          const SizedBox(height: 3),
          Text(def.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: unlocked ? DashTokens.textSecondary : DashTokens.textTertiary.withAlpha(160),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: (unlocked ? DashTokens.emerald : DashTokens.textTertiary).withAlpha(24),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('+${def.xpReward} XP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? DashTokens.emeraldSoft : DashTokens.textTertiary,
                )),
          ),
        ],
      ),
    );

    return tile
        .animate(delay: (40 * animationIndex).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.12, curve: Curves.easeOutCubic);
  }
}
