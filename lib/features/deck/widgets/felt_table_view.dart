import 'package:flutter/material.dart';

import '../../../core/theme/felt.dart';
import '../deck_repository.dart';
import 'playing_card_view.dart';

class FeltTableView extends StatelessWidget {
  const FeltTableView({
    super.key,
    required this.table,
    required this.seats,
    required this.turn,
    required this.captured,
  });

  final List<String> table;
  final List<DeckSeat> seats;
  final String turn;
  final Map<String, int> captured;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final cardWidth = wide ? 96.0 : 72.0;
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final seat in seats)
              _SeatChip(
                seat: seat,
                active: seat.key == turn,
                captured: captured[seat.key] ?? 0,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.35,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FeltColors.felt,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: FeltColors.brass.withValues(alpha: 0.7)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
                  ],
                ),
                child: Center(child: _pile(cardWidth)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pile(double cardWidth) {
    if (table.isEmpty) {
      return Text('Masa boş', style: feltUi(FeltColors.ivory, 16, weight: FontWeight.w600));
    }
    final visible = table.length <= 4 ? table : table.sublist(table.length - 4);
    final mid = (visible.length - 1) / 2;
    return SizedBox(
      height: cardWidth * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < visible.length; i++)
            Transform.translate(
              offset: Offset((i - mid) * 26, 0),
              child: Transform.rotate(
                angle: (i - mid) * 0.06,
                child: PlayingCardView(card: visible[i], width: cardWidth),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({required this.seat, required this.active, required this.captured});

  final DeckSeat seat;
  final bool active;
  final int captured;

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    final note = seat.isTable ? 'Masa' : '$captured kart';
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? FeltColors.brass : palette.line, width: active ? 1.6 : 1),
      ),
      child: Text(
        '${seat.name}, $note',
        style: feltUi(palette.ink, 13, weight: FontWeight.w600),
      ),
    );
  }
}
