import 'package:AZOyun/features/football/football_shot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mode in ShotMode.values) {
    testWidgets('${mode.title} animates and scores a swipe', (tester) async {
      tester.view.physicalSize = const Size(390, 790);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester
          .pumpWidget(MaterialApp(home: FootballShotScreen(mode: mode)));
      final pitch = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onPanStart != null,
      );
      final bounds = tester.getRect(pitch);
      final ball = Offset(bounds.center.dx, bounds.top + bounds.height * .8);
      await tester.dragFrom(
          ball, Offset(-bounds.width * .15, -bounds.height * .41));
      await tester.pumpAndSettle();
      expect(find.textContaining('Vuruş 1/6'), findsOneWidget);
      expect(
          find
              .textContaining(RegExp(
                  r'^(Köşeye gol|Gol ·|Aut$|Kaleci kurtardı$|Barajda kaldı$)'))
              .evaluate(),
          isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
