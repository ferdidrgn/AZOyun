import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/connect_four_rules.dart';

List<String?> _decodeBoard(List<dynamic> rows) => [
      for (final row in rows)
        for (final cell in (row as String).split(''))
          if (cell == '.') null else cell,
    ];

void main() {
  final contract = jsonDecode(
    File('contracts/connect4.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final testCase in contract['cases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Dörtlü Diz ortak kuralı: ${data['name']}', () {
      final outcome = connectFourOutcome(
        _decodeBoard(data['board'] as List<dynamic>),
      );
      expect(outcome.winner, data['winner']);
      expect(outcome.winningLine, data['winningLine']);
      expect(outcome.draw, data['draw']);
    });
  }

  for (final testCase in contract['dropCases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Dörtlü Diz sütun hamlesi: ${data['name']}', () {
      expect(
        connectFourDropRow(
          _decodeBoard(data['board'] as List<dynamic>),
          data['column'] as int,
        ),
        data['row'],
      );
    });
  }
}
