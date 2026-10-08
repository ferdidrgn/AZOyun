import 'package:flutter/material.dart';

import '../../../core/theme/felt.dart';
import '../deck_engine.dart';

class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    required this.card,
    this.width = 72,
    this.faceDown = false,
    this.selected = false,
  });

  final String? card;
  final double width;
  final bool faceDown;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    final label = card == null || faceDown ? 'Kapalı kart' : cardLabel(card!);
    return Semantics(
      label: label,
      selected: selected,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 140),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: faceDown ? FeltColors.felt : FeltColors.cardFace,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? FeltColors.brass : const Color(0xFFD9CDB8),
            width: selected ? 2.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: faceDown || card == null ? _back() : _face(card!),
      ),
    );
  }

  Widget _back() => Center(
        child: Container(
          width: width * 0.55,
          height: width * 0.55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: FeltColors.brass, width: 1.2),
          ),
        ),
      );

  Widget _face(String id) {
    final red = cardIsRed(id);
    final color = red ? FeltColors.clay : FeltColors.ink;
    final style = feltUi(color, width * 0.22, weight: FontWeight.w700, height: 1);
    return Padding(
      padding: EdgeInsets.all(width * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cardRank(id), style: style),
          Text(cardSuitSymbol(id), style: style),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(cardSuitSymbol(id), style: feltUi(color, width * 0.34, height: 1)),
          ),
        ],
      ),
    );
  }
}
