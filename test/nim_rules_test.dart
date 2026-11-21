import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:AZOyun/features/quickgames/nim_rules.dart';

void main() {
  final contract = jsonDecode(
    File('contracts/nim.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('Flutter Nim uses the shared four-pile start state', () {
    expect(contract['initialPiles'], [3, 5, 7, 9]);
  });

  for (final testCase in contract['cases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Nim ortak kuralı: ${data['name']}', () {
      final piles = List<int>.from(data['piles'] as List<dynamic>);
      final result = nimApplyMove(
        piles,
        pileIndex: data['pileIndex'] as int,
        removeCount: data['remove'] as int,
      );

      expect(result.piles, data['nextPiles']);
      expect(result.finished, data['finished']);
    });
  }

  for (final invalidCase in contract['invalidCases'] as List<dynamic>) {
    final data = invalidCase as Map<String, dynamic>;
    test('Nim geçersiz hamleyi reddeder', () {
      expect(
        () => nimApplyMove(
          List<int>.from(data['piles'] as List<dynamic>),
          pileIndex: data['pileIndex'] as int,
          removeCount: data['remove'] as int,
        ),
        throwsArgumentError,
      );
    });
  }
}
