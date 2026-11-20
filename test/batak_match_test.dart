import 'package:AZOyun/core/navigation/room_invite.dart';
import 'package:AZOyun/features/batak/batak_match.dart';
import 'package:flutter_test/flutter_test.dart';

BatakRoom _waiting() {
  var room = <String, dynamic>{
    'kind': 'batak',
    'status': 'waiting',
    'host': 'table',
    'players': {
      'table': {'name': 'Ortak ekran'}
    },
  };
  for (final name in ['Ada', 'Can', 'Deniz', 'Ece']) {
    room = joinBatak(room, name)!;
  }
  return room;
}

BatakRoom _move(BatakRoom room, String action,
        {int? bid, int? trump, int? card}) =>
    playBatak(room, room['turn'] as String, room['revision'] as int, action,
        bid: bid, trump: trump, card: card)!;

BatakRoom _playing(List<int> hand, List<BatakRoom> trick,
        {bool broken = true, int trump = 3}) =>
    {
      'kind': 'batak',
      'status': 'playing',
      'phase': 'play',
      'revision': 1,
      'turn': 'p1',
      'trump': trump,
      'trumpBroken': broken,
      'trick': trick,
      'trickNumber': 1,
      'round': 1,
      'players': {
        for (final seat in batakPlayerSeats)
          seat: {
            'name': seat,
            'hand': seat == 'p1' ? hand : <int>[],
            'taken': 0,
            'score': 0
          }
      },
    };

void main() {
  test('retry and rejoin recover the same seat without redealing its cards',
      () {
    final waiting = _waiting();
    waiting['players']['p2']['token'] = 'phone-two';
    final retry = joinBatak(waiting, 'Can', token: 'phone-two')!;
    expect(batakSeats(retry).length, 4);
    expect(batakSeatForToken(retry, 'phone-two'), 'p2');
    var playing = dealBatak(retry, 'table', 5)!;
    playing = _move(playing, 'bid', bid: 6);
    final previousHand = playing['players']['p2']['hand'].join(',');
    final recovered = joinBatak(playing, 'Can', token: 'phone-two')!;
    expect(recovered['revision'], playing['revision']);
    expect(recovered['phase'], 'bid');
    expect(recovered['players']['p2']['hand'].join(','), previousHand);
    expect(joinBatak(playing, 'Can', token: 'different-phone'), null);
    expect(batakSeatForToken(playing, ''), null);
    final empty = <String, dynamic>{'kind': 'batak', 'status': 'waiting'};
    final first = joinBatak(empty, 'Ada', token: 'phone-one')!;
    final second = joinBatak(first, 'Ada', token: 'phone-one')!;
    expect(batakSeats(second).join(','), 'p1');
  });

  test('four seats get 52 distinct cards and the spectator never gets a hand',
      () {
    final waiting = _waiting();
    expect(joinBatak(waiting, 'Beşinci'), null);
    expect(dealBatak(waiting, 'p1', 5), null);
    final room = dealBatak(waiting, 'table', 5)!;
    final cards = <int>[];
    for (final seat in batakPlayerSeats) {
      final hand = batakHand(room['players'][seat]['hand']);
      expect(hand.length, 13);
      cards.addAll(hand);
    }
    expect(cards.toSet().length, 52);
    expect(batakHand(room['players']['table']['hand']).length, 0);
    expect(waiting['status'], 'waiting');
    final other = dealBatak(waiting, 'table', 7)!;
    expect(
        room['players']['p1']['hand'].join(',') ==
            other['players']['p1']['hand'].join(','),
        false);
    expect(joinBatak(room, 'Geç kalan'), null);
  });

  test('auction rejects stale, out-of-turn and low bids and handles all-pass',
      () {
    var room = dealBatak(_waiting(), 'table', 5)!;
    expect(room['turn'], 'p2');
    expect(playBatak(room, 'p1', 1, 'pass'), null);
    expect(playBatak(room, 'p2', 0, 'pass'), null);
    expect(playBatak(room, 'p2', 1, 'bid', bid: 4), null);
    for (var n = 0; n < 4; n++) {
      room = _move(room, 'pass');
    }
    expect(room['bidder'], 'p2');
    expect(room['contract'], 4);
    expect(room['phase'], 'trump');
    room = _move(room, 'trump', trump: 2);
    expect(room['phase'], 'play');
    expect(room['turn'], 'p2');
    expect(room['trump'], 2);
  });

  test('passed players stay out and a maximum bid ends the auction', () {
    var room = dealBatak(_waiting(), 'table', 3)!;
    room = _move(room, 'bid', bid: 5); // p2
    room = _move(room, 'pass'); // p3
    room = _move(room, 'bid', bid: 6); // p4
    room = _move(room, 'pass'); // p1
    expect(room['turn'], 'p2');
    room = _move(room, 'bid', bid: 7);
    expect(room['turn'], 'p4');
    room = _move(room, 'pass');
    expect(room['bidder'], 'p2');
    expect(room['contract'], 7);
    expect(room['phase'], 'trump');
    final maximum = _move(dealBatak(_waiting(), 'table', 3)!, 'bid', bid: 13);
    expect(maximum['phase'], 'trump');
    expect(maximum['bidder'], 'p2');
  });

  test('follow suit and beat the leading card when possible', () {
    final room = _playing([
      0,
      10,
      12,
      39
    ], [
      {'seat': 'p4', 'card': 8}
    ]);
    expect(batakLegalCards(room, 'p1').join(','), '10,12');
    expect(playBatak(room, 'p1', 1, 'card', card: 0), null);
    expect(playBatak(room, 'p1', 1, 'card', card: 39), null);
    expect(
        batakLegalCards({
          ...room,
          'trick': [
            {'seat': 'p3', 'card': 8},
            {'seat': 'p4', 'card': 40}
          ]
        }, 'p1')
            .join(','),
        '0,10,12');
    expect(room['players']['p1']['hand'].length, 4);
  });

  test('missing lead suit forces a trump and a higher trump when available',
      () {
    final room = _playing([
      14,
      39,
      45,
      50
    ], [
      {'seat': 'p3', 'card': 8},
      {'seat': 'p4', 'card': 44}
    ]);
    expect(batakLegalCards(room, 'p1').join(','), '45,50');
    expect(
        batakLegalCards(_playing([14, 39], batakTrick(room['trick'])), 'p1')
            .join(','),
        '39');
    expect(
        batakLegalCards(_playing([14, 28], batakTrick(room['trick'])), 'p1')
            .join(','),
        '14,28');
    expect(
        batakLegalCards(
                _playing([
                  39,
                  50
                ], [
                  {'seat': 'p4', 'card': 44}
                ]),
                'p1')
            .join(','),
        '50');
  });

  test('unbroken trumps cannot lead unless the hand contains only trumps', () {
    final room = _playing([0, 39, 51], [], broken: false);
    expect(batakLegalCards(room, 'p1').join(','), '0');
    expect(
        batakLegalCards(_playing([39, 51], [], broken: false), 'p1').join(','),
        '39,51');
    final cut = _move(
        _playing([
          40
        ], [
          {'seat': 'p4', 'card': 0}
        ], broken: false),
        'card',
        card: 40);
    expect(cut['trumpBroken'], true);
  });

  test('a fourth card remains visible then only the winner collects once', () {
    final initial = _playing([
      12
    ], [
      {'seat': 'p2', 'card': 0},
      {'seat': 'p3', 'card': 42},
      {'seat': 'p4', 'card': 26}
    ]);
    final room = _move(initial, 'card', card: 12);
    expect(room['phase'], 'collect');
    expect(room['turn'], 'p3');
    expect(batakTrick(room['trick']).length, 4);
    expect(playBatak(room, 'p1', room['revision'], 'collect'), null);
    final next = _move(room, 'collect');
    expect(next['players']['p3']['taken'], 1);
    expect(next['turn'], 'p3');
    expect(next['phase'], 'play');
    expect(next['trickNumber'], 2);
    expect(batakTrick(next['lastTrick']).length, 4);
    expect(batakTrick(next['trick']).length, 0);
    expect(playBatak(next, 'p3', room['revision'], 'collect'), null);
    expect(initial['players']['p1']['hand'].length, 1);
  });

  test(
      'score applies contract penalties, zero-trick penalties and shared winners',
      () {
    final room = _playing([], []);
    room.addAll({
      'phase': 'collect',
      'round': 4,
      'trickNumber': 13,
      'bidder': 'p2',
      'contract': 5,
      'turn': 'p1'
    });
    room['players']['p1']['taken'] = 3;
    room['players']['p2']['taken'] = 4;
    room['players']['p4']['taken'] = 5;
    room['players']['p4']['score'] = -1;
    final end = _move(room, 'collect');
    expect(end['players']['p1']['score'], 4);
    expect(end['players']['p2']['score'], -5);
    expect(end['players']['p3']['score'], -5);
    expect(end['players']['p4']['score'], 4);
    expect(end['status'], 'finished');
    expect(batakMap(end['winners']).keys.join(','), 'p1,p4');
    expect(end['history']['r4']['taken']['p1'], 4);
    expect(room['players']['p1']['score'], 0);
  });

  test(
      'twenty full four-deal matches consume every card and produce a scorebook',
      () {
    for (var seed = 0; seed < 20; seed++) {
      var room = _waiting();
      for (var round = 1; round <= 4; round++) {
        room = dealBatak(room, 'table', seed * 4 + round)!;
        expect(room['dealer'], batakPlayerSeats[round - 1]);
        room = _move(room, 'bid', bid: 5);
        for (var n = 0; n < 3; n++) {
          room = _move(room, 'pass');
        }
        room = _move(room, 'trump', trump: seed % 4);
        final used = <int>{};
        for (var trick = 1; trick <= 13; trick++) {
          for (var n = 0; n < 4; n++) {
            final cards = batakLegalCards(room, room['turn']);
            expect(cards.isEmpty, false);
            final chosen = cards[(seed + n + trick) % cards.length];
            expect(used.add(chosen), true);
            room = _move(room, 'card', card: chosen);
          }
          room = _move(room, 'collect');
        }
        expect(used.length, 52);
        expect(
            batakPlayerSeats.fold<int>(
                0, (sum, id) => sum + room['players'][id]['taken'] as int),
            13);
        expect(
            batakPlayerSeats
                .every((id) => batakHand(room['players'][id]['hand']).isEmpty),
            true);
        expect(room['status'], round == 4 ? 'finished' : 'playing');
      }
      expect(batakMap(room['history']).length, 4);
      expect(batakMap(room['winners']).isNotEmpty, true);
      expect(dealBatak(room, 'table', seed), null);
    }
  });

  test('QR and app invitation routes preserve the Batak code', () {
    expect(
        parseRoomInvite(Uri.parse('https://azoyun.web.app/join/batak/ABC234'))
            ?.game,
        'batak');
    expect(parseRoomInvite(Uri.parse('azoyun://join/batak/abc234'))?.code,
        'ABC234');
    expect(parseRoomInvite(Uri.parse('https://azoyun.web.app/join/batak/BAD')),
        null);
  });
}
