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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffd2a16a), Color(0xff815033), Color(0xff503122)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe1b47b), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 8)),
            BoxShadow(color: Color(0x66f3d1a0), blurRadius: 2, offset: Offset(0, -1)),
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
                  child: CustomPaint(
                    painter: const _CityCenterPainter(),
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

class _CityCenterPainter extends CustomPainter {
  const _CityCenterPainter();

  void _building(Canvas canvas, Rect rect, Color color) {
    final lift = rect.height * .20;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, lift)), const Radius.circular(3)),
      Paint()..color = Colors.black.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final front = Path()
      ..moveTo(rect.left, rect.top + lift)
      ..lineTo(rect.right - lift * .45, rect.top + lift)
      ..lineTo(rect.right - lift * .45, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    final side = Path()
      ..moveTo(rect.right - lift * .45, rect.top + lift)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom - lift * .55)
      ..lineTo(rect.right - lift * .45, rect.bottom)
      ..close();
    final roof = Path()
      ..moveTo(rect.left, rect.top + lift)
      ..lineTo(rect.left + lift * .55, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right - lift * .45, rect.top + lift)
      ..close();
    canvas.drawPath(front, Paint()..color = color);
    canvas.drawPath(side, Paint()..color = Color.lerp(color, Colors.black, .28)!);
    canvas.drawPath(roof, Paint()..color = Color.lerp(color, Colors.white, .22)!);
    final window = Paint()..color = const Color(0xFFFFE4A0).withAlpha(185);
    final windowW = rect.width * .12;
    final windowH = rect.height * .12;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + rect.width * (.20 + col * .32),
              rect.top + lift + rect.height * (.35 + row * .32), windowW, windowH),
          const Radius.circular(1)), window);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = w / 5;
    final street = Paint()..color = const Color(0xFF344A43);
    final curb = Paint()..color = const Color(0xFF9B9B7E);
    final horizontal = Rect.fromLTWH(w * .205, h * .442, w * .59, h * .116);
    final vertical = Rect.fromLTWH(w * .442, h * .205, w * .116, h * .59);
    canvas.drawRRect(RRect.fromRectAndRadius(horizontal.inflate(2), const Radius.circular(5)), curb);
    canvas.drawRRect(RRect.fromRectAndRadius(vertical.inflate(2), const Radius.circular(5)), curb);
    canvas.drawRRect(RRect.fromRectAndRadius(horizontal, const Radius.circular(4)), street);
    canvas.drawRRect(RRect.fromRectAndRadius(vertical, const Radius.circular(4)), street);

    final dash = Paint()
      ..color = const Color(0x99E7D39F)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var x = w * .24; x < w * .76; x += unit * .24) {
      canvas.drawLine(Offset(x, h * .5), Offset(x + unit * .11, h * .5), dash);
    }
    for (var y = h * .24; y < h * .76; y += unit * .24) {
      canvas.drawLine(Offset(w * .5, y), Offset(w * .5, y + unit * .11), dash);
    }

    final blocks = [
      Rect.fromLTWH(w * .245, h * .245, unit * .78, unit * .72),
      Rect.fromLTWH(w * .60, h * .245, unit * .78, unit * .72),
      Rect.fromLTWH(w * .245, h * .605, unit * .78, unit * .72),
      Rect.fromLTWH(w * .60, h * .605, unit * .78, unit * .72),
    ];
    const colors = [
      Color(0xFFD58E59), Color(0xFF9C788E),
      Color(0xFFCCB06F), Color(0xFF77947A),
    ];
    for (var i = 0; i < blocks.length; i++) {
      _building(canvas, blocks[i], colors[i]);
    }

    final park = Rect.fromCenter(center: Offset(w * .5, h * .5),
        width: w * .12, height: h * .12);
    canvas.drawOval(park.shift(Offset(0, unit * .045)),
        Paint()..color = Colors.black.withAlpha(70));
    canvas.drawOval(park, Paint()..color = const Color(0xFF4F8A58));
    for (final point in [
      Offset(w * .475, h * .49), Offset(w * .525, h * .49),
      Offset(w * .475, h * .525), Offset(w * .525, h * .525),
    ]) {
      canvas.drawCircle(point.translate(0, 2), unit * .035,
          Paint()..color = Colors.black.withAlpha(70));
      canvas.drawCircle(point.translate(0, -unit * .008), unit * .032,
          Paint()..color = const Color(0xFF78A968));
    }
  }

  @override
  bool shouldRepaint(covariant _CityCenterPainter oldDelegate) => false;
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
      elevation: selected ? 5 : 1.2,
      shadowColor: selected ? const Color(0xAAE69134) : Colors.black45,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? const [Color(0xfffff1cf), Color(0xfff2dca9)]
                    : const [Color(0xfffff9e9), Color(0xffe8d9bb)],
              ),
              border: Border.all(
            color: selected ? const Color(0xfff39e44) : const Color(0xff8d7958),
            width: selected ? 2 : .7,
          )),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 6,
              child: Row(children: [
                Expanded(child: ColoredBox(color: _groups[district.group])),
                if (owner != null)
                  SizedBox(width: 12, child: ColoredBox(color: mahalleSeatColor(owner))),
              ]),
            ),
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
            SizedBox(
              height: 13,
              child: CustomPaint(
                painter: _PropertyBuildingPainter(
                  level: level,
                  color: owner == null ? _groups[district.group] : mahalleSeatColor(owner),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PropertyBuildingPainter extends CustomPainter {
  const _PropertyBuildingPainter({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final count = level.clamp(0, 4).toInt();
    if (count == 0 || size.width <= 0) return;
    final buildingWidth = (size.width / (count * 2.1)).clamp(4.0, 9.0).toDouble();
    final buildingHeight = size.height * .72;
    final gap = buildingWidth * .30;
    final total = count * buildingWidth + (count - 1) * gap;
    final startX = (size.width - total) / 2;
    final frontColor = Color.lerp(color, Colors.white, .12)!;
    final sideColor = Color.lerp(color, Colors.black, .30)!;
    final roofColor = Color.lerp(color, Colors.white, .38)!;
    for (var i = 0; i < count; i++) {
      final left = startX + i * (buildingWidth + gap);
      final top = size.height - buildingHeight;
      final rect = Rect.fromLTWH(left, top, buildingWidth, buildingHeight);
      final bevel = buildingWidth * .20;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.translate(0, 1.2), const Radius.circular(1)),
        Paint()..color = Colors.black.withAlpha(70),
      );
      final front = Path()
        ..moveTo(rect.left, rect.top + bevel)
        ..lineTo(rect.right - bevel * .45, rect.top + bevel)
        ..lineTo(rect.right - bevel * .45, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
      final side = Path()
        ..moveTo(rect.right - bevel * .45, rect.top + bevel)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom - bevel * .45)
        ..lineTo(rect.right - bevel * .45, rect.bottom)
        ..close();
      final roof = Path()
        ..moveTo(rect.left, rect.top + bevel)
        ..lineTo(rect.left + bevel * .5, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right - bevel * .45, rect.top + bevel)
        ..close();
      canvas.drawPath(front, Paint()..color = frontColor);
      canvas.drawPath(side, Paint()..color = sideColor);
      canvas.drawPath(roof, Paint()..color = roofColor);
      final window = Paint()..color = const Color(0xFFFFE7AD).withAlpha(210);
      canvas.drawRect(Rect.fromLTWH(rect.left + buildingWidth * .24,
          rect.top + bevel + buildingHeight * .46, buildingWidth * .12,
          buildingHeight * .14), window);
    }
  }

  @override
  bool shouldRepaint(covariant _PropertyBuildingPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.color != color;
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
