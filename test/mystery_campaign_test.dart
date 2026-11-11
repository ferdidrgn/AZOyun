import 'package:AZOyun/core/services/mystery_campaign_service.dart';
import 'package:AZOyun/features/mystery/mystery_case_data.dart';
import 'package:AZOyun/features/mystery/mystery_case_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a wrong deduction keeps chapter two locked', (tester) async {
    SharedPreferences.setMockInitialValues({
      'az_mystery_completed_cases_v1': ['night_express', 'sirius_gallery'],
    });
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MysteryLobbyScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Kırmızı Tortu'), findsNothing);
    await tester.tap(find.text('Soruşturmaya başla'));
    await tester.pumpAndSettle();

    Future<void> tapInChapter(String text) async {
      final target = find.text(text);
      await tester.scrollUntilVisible(target, 180);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    final first = kMysteryChapters.first;
    for (final evidence in first.evidence) {
      await tapInChapter(evidence.title);
    }
    await tapInChapter(first.answers.first);
    await tapInChapter('Çıkarımı doğrula');
    expect(MysteryCampaignService.instance.isCompleted(first.id), isFalse);

    final answer = find.text(first.answers[first.solution]);
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await tester.pumpAndSettle();
    await tapInChapter('Çıkarımı doğrula');
    expect(find.text('ÇIKARIM DOĞRULANDI'), findsOneWidget);
    await tapInChapter('Bölüm listesine dön');

    expect(find.text('Kırmızı Tortu'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('az_mystery_completed_cases_v1'),
        containsAll(['night_express', 'sirius_gallery', first.id]));
    expect(
        await MysteryCampaignService.instance.markCompleted(first.id), isFalse);
  });

  test('all ten chapters contain evidence and a valid deduction', () {
    expect(kMysteryChapters, hasLength(10));
    expect(
        kMysteryChapters.map((chapter) => chapter.id).toSet(), hasLength(10));
    for (var i = 0; i < kMysteryChapters.length; i++) {
      final chapter = kMysteryChapters[i];
      expect(chapter.number, i + 1);
      expect(chapter.evidence, hasLength(3));
      expect(chapter.answers, hasLength(3));
      expect(chapter.solution, inInclusiveRange(0, chapter.answers.length - 1));
    }
  });
}
