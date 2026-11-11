import 'package:AZOyun/features/arcade3d/native_arcade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final mode in NativeArcadeGame.values) {
    testWidgets('${mode.title} starts, pauses and resumes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester
          .pumpWidget(MaterialApp(home: NativeArcadeScreen(game: mode)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Başla'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byTooltip('Duraklat'), findsOneWidget);
      if (mode == NativeArcadeGame.runway) {
        await tester.tap(find.text('Sol'));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byTooltip('Duraklat'));
      await tester.pumpAndSettle();
      expect(find.text('Duraklatıldı'), findsOneWidget);
      await tester.tap(find.text('Devam et'));
      await tester.pump();
      expect(find.byTooltip('Duraklat'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
