import 'package:flutter/material.dart';

const _ivory = Color(0xfff7edce);
const _brass = Color(0xffe6b777);

class OkeyStoneFace extends StatelessWidget {
  const OkeyStoneFace(
      {super.key,
      required this.label,
      required this.ink,
      this.width = 38,
      this.selected = false,
      this.marked = false,
      this.onTap});

  final String label;
  final Color ink;
  final double width;
  final bool selected, marked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        child: Material(
          elevation: selected ? 5 : 2,
          borderRadius: BorderRadius.circular(5),
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: selected
                    ? const [
                        Color(0xffffefb0),
                        Color(0xffe9b759),
                        Color(0xff976432)
                      ]
                    : const [
                        Color(0xfffffdf4),
                        Color(0xffeee2c1),
                        Color(0xffaa936e)
                      ],
                stops: const [0, .84, 1],
              ),
              border: Border.all(
                  color: marked
                      ? const Color(0xff209473)
                      : const Color(0xff604b32),
                  width: marked ? 2 : .65),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: onTap,
              child: SizedBox(
                width: width,
                height: width * 1.38,
                child: Center(
                    child: Text(label,
                        maxLines: 1,
                        style: TextStyle(
                            color: ink,
                            fontSize: width * .56,
                            height: 1,
                            fontWeight: FontWeight.w900))),
              ),
            ),
          ),
        ),
      );
}

class OkeyRack extends StatelessWidget {
  const OkeyRack(
      {super.key,
      required this.ids,
      required this.buildStone,
      required this.onMove});
  final List<String?> ids;
  final Widget Function(String id, double width, {required bool feedback})
      buildStone;
  final void Function(String id, int index) onMove;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xff4a281c), width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff8d5633), Color(0xff5e3423), Color(0xff9a603b)],
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: LayoutBuilder(builder: (context, bounds) {
            // A phone in landscape has room for the full 101 hand in one row.
            // Portrait fallback stays at two rows so stone faces remain usable.
            final columns = bounds.maxWidth < 270
                ? 8
                : bounds.maxWidth >= 680
                    ? 22
                    : 11;
            final width = ((bounds.maxWidth - (columns - 1) * 2) / columns)
                .clamp(12.0, 45.0);
            final rows = ids.length > columns * 2 ? 3 : 2;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              for (var row = 0; row < rows; row++) ...[
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: 2),
                    _slot(row * columns + col, width),
                  ],
                ]),
                if (row < rows - 1)
                  Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0xff552c21),
                          Color(0xffc19060),
                          Color(0xff552c21)
                        ]),
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      )),
              ],
            ]);
          }),
        ),
      );

  Widget _slot(int index, double width) {
    final id = index < ids.length ? ids[index] : null;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          index < ids.length && details.data != id,
      onAcceptWithDetails: (details) => onMove(details.data, index),
      builder: (_, targets, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width,
        height: width * 1.38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: targets.isNotEmpty
              ? Colors.amber.withAlpha(145)
              : Colors.black.withAlpha(40),
        ),
        child: id == null
            ? null
            : LongPressDraggable<String>(
                data: id,
                maxSimultaneousDrags: 1,
                feedback: Material(
                    color: Colors.transparent,
                    child: buildStone(id, width, feedback: true)),
                childWhenDragging: const SizedBox.shrink(),
                child: buildStone(id, width, feedback: false),
              ),
      ),
    );
  }
}

typedef OkeyTableSeat = ({String key, String name, int count});

class OkeyFeltBoard extends StatelessWidget {
  const OkeyFeltBoard(
      {super.key,
      required this.seats,
      required this.local,
      required this.turn,
      required this.status,
      required this.stock,
      required this.indicator,
      required this.openStone,
      required this.onStock,
      required this.onOpen,
      required this.onDrop});

  final List<OkeyTableSeat> seats;
  final String local;
  final String? turn;
  final String status;
  final int stock;
  final Widget? indicator, openStone;
  final VoidCallback? onStock, onOpen;
  final ValueChanged<String>? onDrop;

  @override
  Widget build(BuildContext context) {
    final start =
        seats.indexWhere((seat) => seat.key == local).clamp(0, seats.length);
    final ordered = [...seats.skip(start), ...seats.take(start)];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xff8d603c),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xffb5814a), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 5))
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const RadialGradient(
              colors: [Color(0xff356e56), Color(0xff143e34)], radius: .85),
          border: Border.all(color: const Color(0xff36281d), width: 2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (ordered.length >= 2) _seat(ordered[ordered.length == 2 ? 1 : 2]),
          const SizedBox(height: 8),
          Row(children: [
            if (ordered.length >= 3)
              Flexible(child: _seat(ordered[1], compact: true)),
            Expanded(
              flex: 4,
              child: Row(children: [
                Expanded(
                    child:
                        _pile('Kapalı · $stock', const _StoneBack(), onStock)),
                if (indicator != null)
                  Expanded(child: _pile('Gösterge', indicator!, null)),
                Expanded(
                    child: _pile(
                        'Açık taş', openStone ?? const _EmptyStone(), onOpen)),
              ]),
            ),
            if (ordered.length >= 4)
              Flexible(child: _seat(ordered[3], compact: true)),
          ]),
          const SizedBox(height: 8),
          if (ordered.isNotEmpty)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: _seat(ordered.first)),
              if (onDrop != null) ...[
                const SizedBox(width: 8),
                DragTarget<String>(
                  onAcceptWithDetails: (details) => onDrop!(details.data),
                  builder: (_, targets, __) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: targets.isEmpty
                          ? Colors.black26
                          : const Color(0xff835e31),
                      border: Border.all(color: _brass),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text('Buraya at',
                        style: TextStyle(color: _ivory, fontSize: 11)),
                  ),
                ),
              ],
            ]),
          const SizedBox(height: 6),
          Text(status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _ivory, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _seat(OkeyTableSeat seat, {bool compact = false}) {
    final active = seat.key == turn;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(maxWidth: compact ? 76 : 185),
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: compact ? 3 : 9),
      decoration: BoxDecoration(
        color: active ? const Color(0xff775531) : const Color(0xff122e28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? _brass : const Color(0xff58816d)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(seat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _ivory, fontWeight: FontWeight.w700, fontSize: 11)),
        Text('${active ? 'Sıra · ' : ''}${seat.count} taş',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _brass, fontSize: 10)),
      ]),
    );
  }

  Widget _pile(String caption, Widget stone, VoidCallback? onTap) => Semantics(
        button: onTap != null,
        child: Material(
          color: onTap != null ? const Color(0xff22483b) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(height: 40, child: Center(child: stone)),
                const SizedBox(height: 3),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(caption,
                        maxLines: 1,
                        style: TextStyle(
                            color: onTap != null ? _brass : _ivory,
                            fontSize: 11))),
              ]),
            ),
          ),
        ),
      );
}

class _StoneBack extends StatelessWidget {
  const _StoneBack();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 33,
        height: 39,
        child: Stack(children: [
          for (var offset = 2; offset >= 0; offset--)
            Positioned(
                left: offset * 2.0,
                top: offset * 2.0,
                width: 28,
                height: 34,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xff77472e),
                      border: Border.all(color: _brass),
                    ),
                    child: const Center(
                        child: Icon(Icons.diamond_outlined,
                            size: 13, color: _brass)))),
        ]),
      );
}

class _EmptyStone extends StatelessWidget {
  const _EmptyStone();
  @override
  Widget build(BuildContext context) => Container(
      width: 29,
      height: 37,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white38),
          borderRadius: BorderRadius.circular(4)));
}
