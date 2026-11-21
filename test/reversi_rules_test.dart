import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/reversi_rules.dart';

List<int> _parse(List<dynamic> rows) => rows.join('').split('').map((cell) {
      if (cell == 'B') return reversiBlack;
      if (cell == 'W') return reversiWhite;
      return reversiEmpty;
    }).toList();

void main() {
  final contract = jsonDecode(
    File('contracts/reversi.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('Reversi standard opening and legal moves match shared vectors', () {
    expect(reversiInitialBoard(), _parse(contract['initial'] as List<dynamic>));
    final moves = contract['initialMoves'] as Map<String, dynamic>;
    expect(
        reversiLegalMoves(reversiInitialBoard(), reversiBlack), moves['black']);
    expect(
        reversiLegalMoves(reversiInitialBoard(), reversiWhite), moves['white']);
  });

  for (final value in contract['moves'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    test('Reversi ortak hamlesi: ${vector['name']}', () {
      final result = reversiApplyMove(
        _parse(contract['initial'] as List<dynamic>),
        vector['index'] as int,
        vector['side'] as int,
      );
      if (vector['next'] == null) {
        expect(result, isNull);
        expect(reversiLegalMoves(reversiInitialBoard(), vector['side'] as int),
            isNot(contains(vector['index'])));
        return;
      }
      expect(result, _parse(vector['next'] as List<dynamic>));
      expect(
          reversiFlips(reversiInitialBoard(), vector['index'] as int,
              vector['side'] as int),
          vector['flips']);
      expect(
          reversiNextSide(result!, vector['side'] as int), vector['nextSide']);
    });
  }

  test('Reversi skips a side without legal moves', () {
    final pass = contract['pass'] as Map<String, dynamic>;
    expect(
        reversiNextSide(
            _parse(pass['board'] as List<dynamic>), pass['currentSide'] as int),
        pass['nextSide']);
  });

  test('Reversi scores a terminal board and names the winner', () {
    final finished = contract['finished'] as Map<String, dynamic>;
    expect(reversiOutcome(_parse(finished['board'] as List<dynamic>)),
        finished['outcome']);
    expect(reversiOutcome(reversiInitialBoard()), isNull);
  });
}
