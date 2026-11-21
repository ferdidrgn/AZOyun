import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:AZOyun/features/quickgames/tic_tac_toe_rules.dart';

void main() {
  final contract = jsonDecode(
    File('contracts/xox.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final testCase in contract['cases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('XOX ortak kuralı: ${data['name']}', () {
      final board = List<String?>.from(data['board'] as List<dynamic>);
      final result = ticTacToeOutcome(board);

      expect(result.winner, data['winner']);
      expect(result.winningLine, data['winningLine']);
      expect(result.draw, data['draw']);
    });
  }
}
