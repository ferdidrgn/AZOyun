import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/dashboard_tokens.dart';
import 'bento_card.dart';

/// Bir "kemik" (skeleton) dikdörtgeni — [ShimmerEffect] ile parlayan bir
/// yükleme placeholder'ı.
class _Bone extends StatelessWidget {
  const _Bone({this.width, this.height = 14, this.radius = 6});
  final double? width;
  final double height, radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: DashTokens.highlight,
          borderRadius: BorderRadius.circular(radius),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1400.ms,
          color: Colors.white.withAlpha(20));
}

/// Profil dashboard'ının tamamı yüklenirken gösterilen bento-grid
/// şeklindeki skeleton — gerçek layout'un kaba bir taklidi, böylece
/// veri gelince ekran "sıçramaz".
class ProfileDashboardShimmer extends StatelessWidget {
  const ProfileDashboardShimmer({super.key, this.desktop = false});
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final heroCard = BentoCard(
      child: Row(children: [
        const _Bone(width: 64, height: 64, radius: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Bone(width: 140, height: 18),
            const SizedBox(height: 10),
            const _Bone(height: 10, radius: 5),
            const SizedBox(height: 8),
            _Bone(width: 90, height: 10),
          ]),
        ),
      ]),
    );

    final kpiRow = Row(children: List.generate(3, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 12),
            child: BentoCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _Bone(width: 38, height: 38, radius: 11),
                const SizedBox(height: 16),
                const _Bone(width: 60, height: 22),
                const SizedBox(height: 6),
                const _Bone(width: 50, height: 10),
              ]),
            ),
          ),
        )));

    final chartCard = BentoCard(
      child: Column(children: [
        const SizedBox(height: 8),
        const _Bone(width: 120, height: 12),
        const SizedBox(height: 24),
        SizedBox(
          height: 120,
          child: Center(child: _Bone(width: 120, height: 120, radius: 60)),
        ),
      ]),
    );

    final achievementsCard = BentoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Bone(width: 130, height: 12),
        const SizedBox(height: 16),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              const _Bone(width: 40, height: 40, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Bone(height: 12),
                  const SizedBox(height: 6),
                  _Bone(width: 100, height: 10),
                ]),
              ),
            ]),
          ),
      ]),
    );

    if (desktop) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: Column(children: [
            heroCard,
            const SizedBox(height: 16),
            kpiRow,
            const SizedBox(height: 16),
            chartCard,
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: achievementsCard),
      ]);
    }

    return Column(children: [
      heroCard,
      const SizedBox(height: 14),
      kpiRow,
      const SizedBox(height: 14),
      chartCard,
      const SizedBox(height: 14),
      achievementsCard,
    ]);
  }
}
