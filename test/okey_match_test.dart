import 'package:AZOyun/features/okey/okey_match.dart';
import 'package:flutter_test/flutter_test.dart';

OkeyRoom _waiting(String mode, {String host = 'p1'}) => {
      'status': 'waiting',
      'mode': mode,
      'rulesVersion': 2,
      'host': host,
      'players': {
        for (final seat in [
          'p3',
          'p1',
          'p4',
          'p2',
          if (host == 'table') 'table'
        ])
          seat: {'name': seat}
      },
    };

List<OTile> _hand(OkeyRoom room, String seat) =>
    okeyTiles(room['players'][seat]['hand']);

OkeyRoom _move(OkeyRoom room, String seat, String move, {String? tile}) =>
    playOkeyMove(room, seat, room['revision'] as int, move, tile: tile)!;

OTile _tile(String id, int num, TColor color, {bool fake = false}) =>
    OTile(id: id, num: num, color: color, joker: fake);

void main() {
  test('classic and 101 shuffle 106 distinct pieces with different hand sizes',
      () {
    for (final (mode, count) in [('okey', 14), ('101', 21)]) {
      final game = dealOkeyRoom(_waiting(mode, host: 'table'), 'table', 5)!;
      final seats = okeySeats(game);
      expect(seats.join(','), 'p1,p2,p3,p4');
      expect(_hand(game, 'p1').length, count + 1);
      expect(_hand(game, 'p2').length, count);
      expect(_hand(game, 'table').length, 0);
      expect(game['indicator']['j'], false);
      final pieces = [
        for (final seat in seats) ..._hand(game, seat),
        ...okeyTiles(game['deck']),
        OTile.fromMap(game['indicator']),
      ];
      expect(pieces.map((piece) => piece.id).toSet().length, 106);
      final other = dealOkeyRoom(_waiting(mode, host: 'table'), 'table', 99)!;
      expect(
          _hand(game, 'p1').map((tile) => tile.id).join(',') ==
              _hand(other, 'p1').map((tile) => tile.id).join(','),
          false);
    }
  });

  test(
      'the active seat must draw once before its discard and turns wrap in order',
      () {
    var room = dealOkeyRoom(_waiting('okey'), 'p1', 5)!;
    expect(playOkeyMove(room, 'p2', 1, 'stock'), isNull);
    expect(playOkeyMove(room, 'p1', 1, 'stock'), isNull);
    for (final (seat, next) in [
      ('p1', 'p2'),
      ('p2', 'p3'),
      ('p3', 'p4'),
      ('p4', 'p1')
    ]) {
      if (seat != 'p1') room = _move(room, seat, 'stock');
      expect(_hand(room, seat).length, 15);
      expect(
          playOkeyMove(room, seat, room['revision'] as int, 'stock'), isNull);
      final revision = room['revision'] as int;
      final discarded = _hand(room, seat).first.id;
      room = _move(room, seat, 'discard', tile: discarded);
      expect(room['phase'], 'draw');
      expect(room['turn'], next);
      expect(room['discards'][seat]['id'], discarded);
      expect(playOkeyMove(room, next, revision, 'stock'), isNull);
    }
  });

  test('101 requires a taken discard to be used or returned', () {
    var room = dealOkeyRoom(_waiting('101'), 'p1', 19)!;
    final tile = _hand(room, 'p1').first.id;
    room = _move(room, 'p1', 'discard', tile: tile);
    room = _move(room, 'p2', 'discardDraw');
    expect(room['requiredTile'], tile);
    var rejected = false;
    try {
      _move(room, 'p2', 'discard', tile: _hand(room, 'p2').first.id);
    } on OkeyMoveError {
      rejected = true;
    }
    expect(rejected, true);
    room = _move(room, 'p2', 'return');
    expect(room['phase'], 'draw');
    expect(room['discards']['p1']['id'], tile);
    expect(_hand(room, 'p2').length, 21);
  });

  test('101 validates opening threshold, groups and later extensions', () {
    var room = dealOkeyRoom(_waiting('101'), 'p1', 17)!;
    final hand = [
      for (final color in [TColor.mavi, TColor.kirmizi, TColor.siyah])
        for (var n = 9; n <= 13; n++) _tile('${color.index}-$n', n, color),
      _tile('last', 2, TColor.sari),
    ];
    room = {
      ...room,
      'okeyN': 1,
      'okeyC': TColor.sari.index,
      'players': {
        ...okeyMap(room['players']),
        'p1': {'hand': hand.map((tile) => tile.toMap()).toList()}
      }
    };
    final groups = [
      for (final color in [TColor.mavi, TColor.kirmizi, TColor.siyah])
        [
          '${color.index}-10',
          '${color.index}-11',
          '${color.index}-12',
          '${color.index}-13'
        ],
    ];
    var rejected = false;
    try {
      playOkeyMove(room, 'p1', 1, 'meld', groups: [groups.first]);
    } on OkeyMoveError {
      rejected = true;
    }
    expect(rejected, true);
    room = playOkeyMove(room, 'p1', 1, 'meld', groups: groups)!;
    expect(room['players']['p1']['opened'], true);
    expect((room['melds'] as List).length, 3);
    room = playOkeyMove(room, 'p1', 2, 'extend',
        tile: '${TColor.mavi.index}-9', meldIndex: 0)!;
    expect((room['melds'][0]['tiles'] as List).length, 5);
  });

  test(
      'a fake joker represents the okey value and seven pairs can finish classic',
      () {
    final room = {'okeyN': 13, 'okeyC': TColor.sari.index};
    final fake = _tile('fake', 0, TColor.siyah, fake: true);
    expect(isWildTile(fake, room), false);
    expect(effectiveOkeyTile(fake, room).num, 13);
    final pairs = [
      for (var n = 1; n <= 7; n++)
        for (var copy = 0; copy < 2; copy++) _tile('$n-$copy', n, TColor.mavi),
    ];
    expect(winningOkeyHand(pairs, room), true);
    expect(winningOkeyHand(pairs.take(13).toList(), room), false);
  });

  test('101 allows five valid pairs and ends after the final discard', () {
    var room = dealOkeyRoom(_waiting('101'), 'p1', 20)!;
    final pairs = [
      for (var n = 1; n <= 5; n++) ['a$n', 'b$n'],
    ];
    final hand = [
      for (var n = 1; n <= 5; n++)
        for (final id in pairs[n - 1]) _tile(id, n, TColor.mavi),
      _tile('last', 13, TColor.siyah),
    ];
    room = {
      ...room,
      'okeyN': 8,
      'okeyC': TColor.sari.index,
      'players': {
        ...okeyMap(room['players']),
        'p1': {'hand': hand.map((tile) => tile.toMap()).toList()},
      },
    };
    room = playOkeyMove(room, 'p1', 1, 'meld', groups: pairs, pairs: true)!;
    expect(room['players']['p1']['pairs'], true);
    expect(_hand(room, 'p1').length, 1);
    room = _move(room, 'p1', 'discard', tile: 'last');
    expect(room['status'], 'finished');
    expect(room['winner'], 'p1');
  });
}
