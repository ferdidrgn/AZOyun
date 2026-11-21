import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/snake_rules.dart';

({int x, int y}) _point(dynamic value) {
  final coordinates = (value as List<dynamic>).cast<int>();
  return (x: coordinates[0], y: coordinates[1]);
}

SnakeDirection _direction(String value) => switch (value) {
      'up' => SnakeDirection.up,
      'down' => SnakeDirection.down,
      'left' => SnakeDirection.left,
      'right' => SnakeDirection.right,
      _ => throw ArgumentError.value(value),
    };

void main() {
  final contract = jsonDecode(
    File('contracts/snake.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final testCase in contract['cases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Yılan ortak kuralı: ${data['name']}', () {
      final foodData = data['food'] as List<dynamic>;
      final result = stepSnake(
        snake: (data['snake'] as List<dynamic>).map(_point).toList(),
        direction: _direction(data['direction'] as String),
        food: _point(foodData),
      );
      expect(result.snake, (data['nextSnake'] as List<dynamic>).map(_point).toList());
      expect(result.ate, data['ate']);
      expect(result.collided, data['collided']);
      expect(result.score, data['score']);
    });
  }

  for (final testCase in contract['turnCases'] as List<dynamic>) {
    final data = testCase as Map<String, dynamic>;
    test('Yılan dönüş kuralı: ${data['current']} → ${data['next']}', () {
      expect(
        canTurnSnake(
          _direction(data['current'] as String),
          _direction(data['next'] as String),
        ),
        data['allowed'],
      );
    });
  }
}

