import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/game_2048_rules.dart';

void main() {
  final contract = jsonDecode(
    File('contracts/2048.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final testCase in contract['cases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('2048 ortak kuralı: ${data['name']}', () {
      final result = apply2048Move(
        (data['board'] as List<dynamic>).cast<int>(),
        data['direction'] as String,
      );
      expect(result.board, data['nextBoard']);
      expect(result.score, data['score']);
      expect(result.changed, data['changed']);
      expect(result.gameOver, data['gameOver']);
      expect(result.won, data['won']);
    });
  }
}

