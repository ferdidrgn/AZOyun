import 'package:flutter/material.dart';

import 'mahalle_match.dart';

const _groups = [
  Color(0xffbab092),
  Color(0xffb96248),
  Color(0xff42818d),
  Color(0xff896297),
  Color(0xff54805a),
];
const _tokens = [
  Color(0xffb43d31),
  Color(0xff2a5e9c),
  Color(0xff24815e),
  Color(0xff9a5a03)
];

Color mahalleSeatColor(String seat) =>
    _tokens[int.parse(seat.substring(1)) - 1];

class MahalleBoard extends StatelessWidget {
  const MahalleBoard({
    super.key,
    required this.room,
    required this.highlight,
    required this.selected,
  });
  final MahalleRoom room;
  final ValueChanged<int> highlight;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final players = mahalleMap(room['players']);
    final deeds = mahalleMap(room['deeds']);
    final dice = room['dice'] as List? ?? const [];
    final board = {
      for (final (index, cell) in districtCells.indexed) cell: index
    };
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff8a583a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffca9764), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 10, offset: Offset(0, 5))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LayoutBuilder(builder: (context, bounds) {
            final step = bounds.maxWidth / 5;
            return Stack(children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                      gradient: RadialGradient(
                    colors: [Color(0xff326653), Color(0xff183e34)],
                    radius: .88,
                  )),
                  child: Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('MAHALLELER',
                          style: TextStyle(
                              fontSize: (step * .26).clamp(12.0, 28.0),
                              color: const Color(0xfff3dfb4),
                              fontWeight: FontWeight.w900)),
                      Text('Tur ${room['round'] ?? 1} / 10',
                          style: const TextStyle(color: Color(0xfff3dfb4))),
                      if (dice.length == 2) ...[
                        const SizedBox(height: 5),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          for (final value in dice)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _DiceFace(value as int)),
                        ]),
                      ],
                    ],
                  )),
                ),
              ),
              for (final cell in board.keys)
                Positioned(
                  left: cell % 5 * step,
                  top: cell ~/ 5 * step,
                  width: step,
                  height: step,
                  child: _Lot(
                    district: districts[board[cell]!],
                    deed: mahalleMap(deeds['d${board[cell]}']),
                    selected: selected == board[cell],
                    onTap: () => highlight(board[cell]!),
                  ),
                ),
              for (final (index, id) in mahalleSeats(room).indexed)
                if (players[id]['out'] != true &&
                    players[id]['position'] is int)
                  AnimatedPositioned(
                    key: ValueKey(id),
                    left: (districtCells[players[id]['position'] as int] % 5) *
                            step +
                        3 +
                        index * (step - 8) / 4,
                    top: (districtCells[players[id]['position'] as int] ~/ 5) *
                            step +
                        step -
                        16,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: IgnorePointer(
                        child: Semantics(
                      label: players[id]['name'] as String?,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mahalleSeatColor(id),
                            border:
                                Border.all(color: Colors.white, width: 1.4)),
                      ),
                    )),
                  ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _Lot extends StatelessWidget {
  const _Lot(
      {required this.district,
      required this.deed,
      required this.selected,
      required this.onTap});
  final District district;
  final MahalleRoom deed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final owner = deed['owner'] as String?;
    final level = deed['level'] as int? ?? 0;
    return Material(
      color: selected ? const Color(0xffffe7b3) : const Color(0xfff8edd5),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
            color: selected ? const Color(0xfff39e44) : const Color(0xff8d7958),
            width: selected ? 2 : .7,
          )),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 6, color: _groups[district.group]),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                        child: Text(district.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xff332d23),
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w800))),
                    if (district.price > 0)
                      Text(
                          owner == null
                              ? '${district.price}'
                              : 'Kira ${district.rent * (level + 1)}',
                          maxLines: 1,
                          style: TextStyle(
                              color: owner == null
                                  ? const Color(0xff5d4f34)
                                  : mahalleSeatColor(owner),
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                  ]),
            )),
            const SizedBox(height: 13),
          ]),
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace(this.value);
  final int value;
  static const _dots = [
    [4],
    [0, 8],
    [0, 4, 8],
    [0, 2, 6, 8],
    [0, 2, 4, 6, 8],
    [0, 2, 3, 5, 6, 8]
  ];

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$value',
        child: Container(
          width: 30,
          height: 30,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xfff8edd5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xffaa8057))),
          child: GridView.count(
            crossAxisCount: 3,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var index = 0; index < 9; index++)
                Center(
                    child: _dots[value - 1].contains(index)
                        ? const CircleAvatar(
                            radius: 2, backgroundColor: Color(0xff47382c))
                        : null),
            ],
          ),
        ),
      );
}
