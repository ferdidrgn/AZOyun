import 'dart:math' as math;

import 'package:flutter/material.dart';

class Point3 {
  const Point3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

/// A small perspective renderer for the arcade's opaque, low-poly meshes.
class ArcadeCamera {
  const ArcadeCamera(this.size);

  final Size size;

  double _depth(Point3 p) => 8 + p.z + (4 - p.y) * .45;
  double scaleAt(Point3 p) => size.shortestSide * 1.28 / _depth(p);

  Offset project(Point3 p) {
    final scale = scaleAt(p);
    return Offset(size.width / 2 + p.x * scale,
        size.height * .50 + ((4 - p.y) * .88 - p.z * .31) * scale);
  }

  void line(Canvas canvas, Point3 a, Point3 b, Paint paint) {
    canvas.drawLine(project(a), project(b), paint);
  }

  void box(
    Canvas canvas,
    Point3 center,
    Color color, {
    required double width,
    required double height,
    required double length,
    double angle = 0,
  }) {
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final vertices = [
      for (final y in [-height / 2, height / 2])
        for (final z in [-length / 2, length / 2])
          for (final x in [-width / 2, width / 2])
            Point3(center.x + x * cosine - z * sine, center.y + y,
                center.z + x * sine + z * cosine),
    ];
    const indices = [
      [0, 1, 5, 4],
      [2, 3, 7, 6],
      [0, 2, 6, 4],
      [1, 3, 7, 5],
      [4, 5, 7, 6],
      [0, 1, 3, 2],
    ];
    const light = [.15, .28, .34, .17, 0.0, .48];
    final order = List.generate(indices.length, (index) => index);
    double depth(int face) =>
        indices[face].fold(0, (sum, v) => sum + _depth(vertices[v]));
    order.sort((a, b) => depth(b).compareTo(depth(a)));
    for (final face in order) {
      final points = indices[face].map((v) => project(vertices[v])).toList();
      final path = Path()..addPolygon(points, true);
      final shaded = face == 4
          ? Color.lerp(color, Colors.white, .22)!
          : Color.lerp(color, Colors.black, light[face])!;
      canvas.drawPath(path, Paint()..color = shaded);
    }
  }
}
