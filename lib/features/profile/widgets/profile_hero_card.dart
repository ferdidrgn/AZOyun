import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/dashboard_tokens.dart';

/// Dashboard'ın "hero" kartı: seviye rozeti, XP ilerleme çubuğu ve coin
/// göstergesi. Diğer Bento kartlarından farklı olarak indigo gradyanlı
/// bir yüzey kullanır — grid içindeki en dikkat çeken öğe budur.
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.level,
    required this.xpIntoLevel,
    required this.xpPerLevel,
    required this.coins,
    required this.playerName,
  });

  final int level, xpIntoLevel, xpPerLevel, coins;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final progress = (xpIntoLevel / xpPerLevel).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DashTokens.cardRadius),
        border: Border.all(color: DashTokens.indigo.withAlpha(60)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DashTokens.indigo.withAlpha(46), DashTokens.surface],
        ),
        boxShadow: [
          BoxShadow(color: DashTokens.indigo.withAlpha(30), blurRadius: 32, offset: const Offset(0, 16)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [DashTokens.indigo, DashTokens.indigoSoft],
              ),
              boxShadow: [
                BoxShadow(color: DashTokens.indigo.withAlpha(90), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Text('$level',
                style: const TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DashTokens.headline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DashTokens.amber.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.paid_rounded, size: 13, color: DashTokens.amber),
                      const SizedBox(width: 4),
                      Text('$coins',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: DashTokens.amber)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 3),
                Text('Seviye $level', style: DashTokens.label),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [
                    Container(height: 8, color: DashTokens.highlight),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [DashTokens.indigo, DashTokens.indigoSoft]),
                        ),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 6),
                Text('$xpIntoLevel/$xpPerLevel XP · Seviye ${level + 1}\'e kadar',
                    style: DashTokens.labelSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
