import 'package:flutter/material.dart';

import '../../../core/theme/dashboard_tokens.dart';

/// Bento-Grid'in temel yapı taşı: mikro-kenarlıklı, yumuşak gölgeli,
/// isteğe bağlı gradyanlı bir yüzey. Tüm dashboard kartları bunun
/// üzerine kurulur.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.gradient,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: bentoDecoration(
          color: color, gradient: gradient, borderColor: borderColor),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(DashTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashTokens.cardRadius),
        splashColor: DashTokens.accent(context).withAlpha(30),
        highlightColor: DashTokens.accent(context).withAlpha(15),
        child: content,
      ),
    );
  }
}

/// Bento grid içindeki bölüm başlıkları için ortak tipografi.
class BentoSectionLabel extends StatelessWidget {
  const BentoSectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(text.toUpperCase(), style: DashTokens.labelSm),
        const Spacer(),
        if (trailing != null) trailing!,
      ]);
}
