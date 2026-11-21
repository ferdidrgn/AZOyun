import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/balloon_rules.dart';

void main() {
  final contract = jsonDecode(
    File('contracts/balloon.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('Balon sabitleri ortak sözleşmeyle aynı', () {
    expect(balloonSessionSeconds, contract['sessionSeconds']);
    expect(balloonLifetimeMs, contract['balloonLifetimeMs']);
    expect(balloonScore, contract['scorePerPop']);
  });

  for (final testCase in contract['popCases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Balon puanı: ${data['name']}', () {
      final result = popBalloon(
        score: data['score'] as int,
        visible: data['visible'] as bool,
        running: data['running'] as bool,
      );
      expect(result.score, data['nextScore']);
      expect(result.popped, data['popped']);
    });
  }

  for (final testCase in contract['tickCases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Balon sayacı: ${data['secondsLeft']} sn', () {
      final result = tickBalloonSession(data['secondsLeft'] as int);
      expect(result.secondsLeft, data['nextSeconds']);
      expect(result.running, data['running']);
    });
  }
}

