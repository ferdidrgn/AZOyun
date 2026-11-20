import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'batak_match.dart';

const _cream = Color(0xfffff0cc);
const _gold = Color(0xffedbc65);

class BatakCard extends StatelessWidget {
  const BatakCard(
      {super.key,
      required this.card,
      this.width = 54,
      this.enabled = true,
      this.onPlay});
  final int card;
  final double width;
  final bool enabled;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final suit = batakSuit(card);
    final red = suit == 1 || suit == 2;
    final ink = red ? const Color(0xffb62c38) : const Color(0xff20313c);
    final label = batakCardLabel(card);
    return Semantics(
      label: '$label${enabled ? '' : ', şu an oynanamaz'}',
      button: onPlay != null,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : .46,
        child: Material(
          elevation: 3,
          color: const Color(0xfffffcf2),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: enabled ? onPlay : null,
            child: Container(
              width: width,
              height: width * 1.43,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xffc0ae86)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            fontSize: width * .24,
                            height: 1.1)),
                    Expanded(
                        child: Center(
                            child: Text(batakSuits[suit],
                                style: TextStyle(
                                    fontSize: width * .55,
                                    color: ink,
                                    height: 1)))),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: Text(label,
                            style: TextStyle(
                                color: ink, fontSize: width * .19, height: 1))),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class BatakTable extends StatelessWidget {
  const BatakTable(
      {super.key,
      required this.room,
      required this.seat,
      required this.onPlay,
      required this.canPlay});
  final BatakRoom room;
  final String seat;
  final ValueChanged<int> onPlay;
  final bool canPlay;

  @override
  Widget build(BuildContext context) {
    final players = batakMap(room['players']);
    final home = batakPlayerSeats.contains(seat) ? seat : 'p1';
    final start = batakPlayerSeats.indexOf(home);
    final relative = [
      for (var n = 0; n < 4; n++) batakPlayerSeats[(start + n) % 4]
    ];
    final trick = batakTrick(room['trick']);
    final legal = canPlay ? batakLegalCards(room, seat) : <int>[];
    final trump = room['trump'] as int?;
    return LayoutBuilder(builder: (context, size) {
      final width = math.min(size.maxWidth, 620.0);
      final height = (width * .92).clamp(320.0, 480.0);
      final cardWidth = (width * .14).clamp(42.0, 64.0);
      final table = Stack(children: [
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(42),
          border: Border.all(color: const Color(0xff79492e), width: 9),
          gradient: const RadialGradient(
              colors: [Color(0xff237864), Color(0xff123f35)]),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ],
        ))),
        Positioned.fill(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                    decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(color: const Color(0xffa0bca1), width: .5),
                )))),
        Align(
            alignment: Alignment.center,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 85),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (trump != null)
                    Text('KOZ ${batakSuits[trump]}',
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  Text(
                      room['phase'] == 'bid'
                          ? 'İHALE'
                          : 'EL ${room['trickNumber'] ?? 1} / 13',
                      style: const TextStyle(
                          color: _cream, fontSize: 11, letterSpacing: 1.2)),
                ]))),
        for (var n = 0; n < 4; n++)
          Align(
              alignment: [
                const Alignment(0, .94),
                const Alignment(.96, 0),
                const Alignment(0, -.94),
                const Alignment(-.96, 0)
              ][n],
              child: _seatLabel(relative[n], players, compact: n.isOdd)),
        for (final play in trick)
          Align(
              alignment: [
                const Alignment(0, .53),
                const Alignment(.48, 0),
                const Alignment(0, -.53),
                const Alignment(-.48, 0)
              ][relative.indexOf(play['seat'] as String)],
              child: TweenAnimationBuilder<double>(
                key: ValueKey(
                    '${room['round']}-${room['trickNumber']}-${play['seat']}'),
                tween: Tween(begin: .75, end: 1),
                duration: const Duration(milliseconds: 250),
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: room['trickWinner'] == play['seat']
                              ? _gold
                              : Colors.transparent,
                          width: 2)),
                  child: BatakCard(card: play['card'] as int, width: cardWidth),
                ),
              )),
      ]);
      return Center(
          child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => legal.contains(details.data),
        onAcceptWithDetails: (details) => onPlay(details.data),
        builder: (context, candidates, rejected) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(42),
              border: Border.all(
                  color: candidates.isEmpty ? Colors.transparent : _gold,
                  width: 3)),
          width: width,
          height: height,
          child: table,
        ),
      ));
    });
  }

  Widget _seatLabel(String id, BatakRoom players, {required bool compact}) {
    final player = batakMap(players[id]);
    final active = room['turn'] == id &&
        room['phase'] != 'roundEnd' &&
        room['status'] != 'finished';
    final bids = batakMap(room['bids']);
    final bid = bids[id];
    final detail = room['phase'] == 'bid'
        ? (bid == 'pass'
            ? 'Pas'
            : bid == null
                ? 'Bekliyor'
                : '$bid ihale')
        : '${player['taken'] ?? 0} el · ${player['score'] ?? 0} p';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(maxWidth: compact ? 77 : 160),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: active ? const Color(0xff815f27) : const Color(0xff123d33),
        border: Border.all(
            color: active ? _gold : const Color(0xff577b63),
            width: active ? 2 : 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${player['name'] ?? id}${id == seat ? ' · Sen' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _cream, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(detail,
            maxLines: 1, style: const TextStyle(color: _gold, fontSize: 10)),
        Text('${batakHand(player['hand']).length} kart',
            style: const TextStyle(color: Color(0xffbdd2c1), fontSize: 10)),
      ]),
    );
  }
}

class BatakHand extends StatelessWidget {
  const BatakHand(
      {super.key,
      required this.room,
      required this.seat,
      required this.busy,
      required this.onPlay});
  final BatakRoom room;
  final String seat;
  final bool busy;
  final ValueChanged<int> onPlay;

  @override
  Widget build(BuildContext context) {
    final hand = batakHand(batakMap(batakMap(room['players'])[seat])['hand'])
      ..sort();
    final legal = busy ? <int>[] : batakLegalCards(room, seat);
    return LayoutBuilder(builder: (context, bounds) {
      final width = ((bounds.maxWidth - 30) / 7).clamp(30.0, 58.0);
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 7,
        children: [
          for (final card in hand)
            LongPressDraggable<int>(
              data: card,
              maxSimultaneousDrags: legal.contains(card) ? 1 : 0,
              feedback: BatakCard(card: card, width: 65),
              childWhenDragging: Opacity(
                  opacity: .2, child: BatakCard(card: card, width: width)),
              child: BatakCard(
                  card: card,
                  width: width,
                  enabled: room['phase'] != 'play' || legal.contains(card),
                  onPlay: legal.contains(card) ? () => onPlay(card) : null),
            )
        ],
      );
    });
  }
}
