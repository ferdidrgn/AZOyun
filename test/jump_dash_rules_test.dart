import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/jump_dash_rules.dart';

void main() {
  final contract = jsonDecode(
    File('contracts/jump-dash.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final vector in contract['cases'] as List<dynamic>) {
    final data = vector as Map<String, dynamic>;
    test('Zıpla Geç ortak kuralı: ${data['name']}', () {
      if (data.containsKey('nextVelocity')) {
        expect(jumpDashNextVelocity((data['velocity'] as num).toDouble()), closeTo(data['nextVelocity'] as num, 1e-12));
      }
      if (data.containsKey('nextBirdY')) {
        expect(jumpDashNextBirdY((data['birdY'] as num).toDouble(), (data['velocity'] as num).toDouble()), closeTo(data['nextBirdY'] as num, 1e-12));
      }
      if (data.containsKey('nextPipeX')) {
        expect(jumpDashNextPipeX((data['pipeX'] as num).toDouble()), closeTo(data['nextPipeX'] as num, 1e-12));
      }
      if (data.containsKey('shouldSpawn')) {
        expect(jumpDashShouldSpawn((data['spawnTimer'] as num).toDouble()), data['shouldSpawn']);
      }
      if (data.containsKey('passed')) {
        expect(jumpDashPipePassed((data['pipeX'] as num).toDouble()), data['passed']);
      }
      if (data.containsKey('collision')) {
        expect(
          jumpDashCollision(
            (data['birdY'] as num).toDouble(),
            (data['pipeX'] as num).toDouble(),
            (data['gapCenter'] as num).toDouble(),
          ),
          data['collision'],
        );
      }
    });
  }
}

