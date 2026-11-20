import 'dart:math';

import 'package:AZOyun/features/mahalleler/mahalle_match.dart';
import 'package:flutter_test/flutter_test.dart';

MahalleRoom _game() {
  const table = {
    'kind': 'mahalle',
    'status': 'waiting',
    'host': 'table',
    'players': {
      'table': {'name': 'Ortak ekran'}
    }
  };
  final one = joinMahalle(table, 'Ada')!;
  final two = joinMahalle(one, 'Can')!;
  return startMahalle(two, 'table')!;
}

MahalleRoom _move(MahalleRoom room, String seat, String action,
        {int? square, String? buyer, int? price}) =>
    playMahalle(room, seat, room['revision'] as int, action,
        random: _Dice(), square: square, buyer: buyer, price: price)!;

class _Dice implements Random {
  int _index = 0;
  @override
  int nextInt(int max) => (_index++ % 2) % max;
  @override
  bool nextBool() => nextInt(2) == 0;
  @override
  double nextDouble() => nextInt(100) / 100;
}

void main() {
  test('opponents roll in order, buy a property, and pay rent', () {
    final initial = _game();
    expect(mahalleSeats(initial).join(','), 'p1,p2');
    expect(playMahalle(initial, 'p2', 1, 'roll', random: _Dice()), isNull);
    var room = _move(initial, 'p1', 'roll');
    expect(room['players']['p1']['position'], 3);
    expect(room['phase'], 'property');
    expect(playMahalle(room, 'p1', 1, 'buy', random: _Dice()), isNull);
    room = _move(room, 'p1', 'buy');
    expect(room['players']['p1']['money'], 400);
    room = _move(room, 'p1', 'end');
    room = _move(room, 'p2', 'roll');
    expect(room['players']['p2']['money'], 483);
    expect(room['players']['p1']['money'], 417);
    expect(initial['players']['p1']['money'], 500);
  });

  test('the bidder rotates and the winning bid transfers the deed once', () {
    var room = _move(_game(), 'p1', 'roll');
    room = _move(room, 'p1', 'auction');
    expect(room['auction']['bidder'], 'p1');
    room = _move(room, 'p1', 'bid');
    expect(room['auction']['bidder'], 'p2');
    room = _move(room, 'p2', 'pass');
    expect(room['deeds']['d3']['owner'], 'p1');
    expect(room['players']['p1']['money'], 490);
    expect(room['phase'], 'end');
  });

  test('a complete group can be upgraded and sold to the selected buyer', () {
    var room = {
      ..._game(),
      'deeds': {
        'd1': {'owner': 'p1', 'level': 0},
        'd3': {'owner': 'p1', 'level': 0},
      }
    };
    room = _move(room, 'p1', 'build', square: 1);
    expect(room['deeds']['d1']['level'], 1);
    expect(room['players']['p1']['money'], 440);
    room = _move(room, 'p1', 'trade', square: 1, buyer: 'p2', price: 120);
    expect(
        playMahalle(room, 'p1', room['revision'] as int, 'accept',
            random: _Dice()),
        isNull);
    room = _move(room, 'p2', 'accept');
    expect(room['deeds']['d1']['owner'], 'p2');
    expect(room['players']['p2']['money'], 380);
    expect(room['players']['p1']['money'], 560);
  });

  test('insufficient rent causes bankruptcy and the surviving player wins', () {
    final initial = _game();
    final room = _move({
      ...initial,
      'players': {
        ...mahalleMap(initial['players']),
        'p1': {'name': 'Ada', 'money': 8, 'position': 0}
      },
      'deeds': {
        'd3': {'owner': 'p2', 'level': 0}
      },
    }, 'p1', 'roll');
    expect(room['players']['p1']['out'], true);
    expect(room['players']['p2']['money'], 508);
    expect(room['status'], 'finished');
    expect(room['winner'], 'p2');
  });

  test(
      'the tenth round concludes with wealth and the perimeter has all 16 lots',
      () {
    final room = _move({
      ..._game(),
      'phase': 'end',
      'turn': 'p2',
      'round': 10,
      'deeds': {
        'd1': {'owner': 'p1', 'level': 1}
      },
    }, 'p2', 'end');
    expect(room['status'], 'finished');
    expect(room['winner'], 'p1');
    expect(room['wealth']['p1'], 640);
    expect(districtCells.toSet().length, districts.length);
  });
}
