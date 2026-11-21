import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:AZOyun/features/quickgames/scuba_rules.dart';

void main() {
  final contract = jsonDecode(
    File('contracts/scuba.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final constants = contract['constants'] as Map<String, dynamic>;
  const epsilon = 1e-10;

  test('Scuba sabitleri ortak sözleşmeyle aynı', () {
    expect(scubaStepSeconds, constants['stepSeconds']);
    expect(scubaBoostPace, constants['boostPace']);
    expect(scubaDiverHomeY, constants['diverHomeY']);
    expect(scubaTrashSpawnSeconds, constants['trashSpawnSeconds']);
    expect(scubaEnemySpawnSeconds, constants['enemySpawnSeconds']);
    expect(scubaPearlSpawnSeconds, constants['pearlSpawnSeconds']);
    expect(scubaPearlShieldSeconds, constants['pearlShieldSeconds']);
    expect(scubaLevelPaces, constants['levelPaces']);
  });

  for (final vector in contract['paceCases'] as List<dynamic>) {
    final data = vector as Map<String, dynamic>;
    test('Scuba hız seviyesi ${data['level']}', () {
      expect(
        scubaPace(data['level'] as int, shielded: data['shielded'] as bool),
        closeTo(data['pace'] as num, epsilon),
      );
    });
  }
  for (final vector in contract['driftCases'] as List<dynamic>) {
    final data = vector as Map<String, dynamic>;
    test('Scuba nesne hareketi', () {
      expect(
        scubaMoveDriftX((data['x'] as num).toDouble(), (data['vx'] as num).toDouble(), (data['dt'] as num).toDouble()),
        closeTo(data['nextX'] as num, epsilon),
      );
      expect(
        scubaMoveDriftY((data['y'] as num).toDouble(), (data['pace'] as num).toDouble(), (data['dt'] as num).toDouble()),
        closeTo(data['nextY'] as num, epsilon),
      );
    });
  }
  for (final vector in contract['spawnCases'] as List<dynamic>) {
    final data = vector as Map<String, dynamic>;
    test('Scuba doğma sayacı', () {
      final result = scubaSpawnTick(
        (data['elapsed'] as num).toDouble(),
        (data['dt'] as num).toDouble(),
        (data['interval'] as num).toDouble(),
      );
      expect(result.elapsed, closeTo(data['nextElapsed'] as num, epsilon));
      expect(result.spawn, data['spawn']);
    });
  }
  for (final vector in contract['reachCases'] as List<dynamic>) {
    final data = vector as Map<String, dynamic>;
    test('Scuba çarpışma mesafesi: ${data['kind']}', () {
      expect(
        scubaCollisionReach(data['kind'] as String, (data['scale'] as num).toDouble()),
        closeTo(data['reach'] as num, epsilon),
      );
    });
  }
  for (final vector in contract['overlapCases'] as List<dynamic>) {
    final data = vector as Map<String, dynamic>;
    test('Scuba yakınlık testi', () {
      expect(
        scubaOverlap(
          (data['ax'] as num).toDouble(),
          (data['ay'] as num).toDouble(),
          (data['bx'] as num).toDouble(),
          (data['by'] as num).toDouble(),
          (data['reach'] as num).toDouble(),
        ),
        data['overlap'],
      );
    });
  }
  for (final vector in contract['contactCases'] as List<dynamic>) {
    final data = vector as Map<String, dynamic>;
    test('Scuba temas kuralı: ${data['kind']}', () {
      final result = scubaResolveContact(
        kind: data['kind'] as String,
        score: data['score'] as int,
        level: data['level'] as int,
        shieldSeconds: (data['shieldSeconds'] as num).toDouble(),
      );
      expect(result.score, data['nextScore']);
      expect(result.level, data['nextLevel']);
      expect(result.shieldSeconds, closeTo(data['nextShield'] as num, epsilon));
      expect(result.gameOver, data['gameOver']);
    });
  }
}
