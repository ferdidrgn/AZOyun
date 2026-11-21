import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/monkey_rules.dart';

void main() {
  final contract = jsonDecode(
    File('contracts/monkey.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('Maymun sabitleri ortak sözleşmeyle aynı', () {
    expect(monkeySessionSeconds, contract['sessionSeconds']);
    expect(monkeyMoveIntervalMs, contract['moveIntervalMs']);
    expect(monkeyScore, contract['scorePerHit']);
  });

  for (final testCase in contract['tapCases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Maymun hedef kuralı: ${data['name']}', () {
      final result = tapMonkey(
        score: data['score'] as int,
        targetIndex: data['targetIndex'] as int,
        tappedIndex: data['tappedIndex'] as int,
        running: data['running'] as bool,
      );
      expect(result.score, data['nextScore']);
      expect(result.hit, data['hit']);
    });
  }

  for (final testCase in contract['tickCases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Maymun sayacı: ${data['secondsLeft']} sn', () {
      final result = tickMonkeySession(data['secondsLeft'] as int);
      expect(result.secondsLeft, data['nextSeconds']);
      expect(result.running, data['running']);
    });
  }
}

