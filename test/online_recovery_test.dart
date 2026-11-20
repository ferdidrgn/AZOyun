import 'package:AZOyun/core/navigation/room_invite.dart';
import 'package:AZOyun/features/golf/golf_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recognizes app, hosting and family table invites', () {
    expect(parseRoomInvite(Uri.parse('azoyun://join/golf/abc234')),
        (game: 'golf', code: 'ABC234'));
    expect(
        parseRoomInvite(
            Uri.parse('https://azoyun.web.app/join/okey101/ABC234')),
        (game: 'okey101', code: 'ABC234'));
    expect(parseRoomInvite(Uri.parse('https://masam.example/?family=ABC234')),
        (game: 'family', code: 'ABC234'));
    expect(
        parseRoomInvite(
            Uri.parse('https://azoyun.web.app/?join=deck&code=ABC234')),
        (game: 'deck', code: 'ABC234'));
  });

  test('Rejects unrelated URLs, unknown games and invalid room codes', () {
    for (final link in [
      'https://example.test/join/golf/ABC234',
      'https://azoyun.web.app/join/missing/ABC234',
      'https://azoyun.web.app/join/golf/AB%2F234',
      'azoyun://join/golf/ABC234/ignored',
      'https://azoyun.web.app/?family=join',
    ]) {
      expect(parseRoomInvite(Uri.parse(link)), isNull, reason: link);
    }
  });

  test(
      'Golf fills the vacated seat, keeps existing players and rejects late joins',
      () {
    final room = <String, dynamic>{
      'status': 'waiting',
      'players': {
        'p1': {'name': 'Ada'},
        'p3': {'name': 'Deniz'},
      },
    };
    final joined = joinGolfRoom(room, 'Ece')!;
    expect(joined['players']['p2']['name'], 'Ece');
    expect(joined['players']['p3']['name'], 'Deniz');
    expect(room['players']['p2'], isNull);
    expect(joinGolfRoom(startGolfRoom(joined)!, 'Can'), isNull);
  });

  test('Last Golf score advances exactly once and preserves earlier scores',
      () {
    final room = <String, dynamic>{
      'status': 'playing',
      'currentHole': 2,
      'holeCount': 3,
      'holeSeed': 77,
      'players': {
        'p1': {
          'name': 'Ada',
          'totalShots': 3,
          'holeShots': [null, 3]
        },
        'p2': {
          'name': 'Ece',
          'totalShots': 1,
          'holeShots': {'1': 1}
        },
      },
    };
    final first = scoreGolfHole(room, seat: 'p1', hole: 2, shots: 2)!;
    expect(first['currentHole'], 2);
    expect(scoreGolfHole(first, seat: 'p1', hole: 2, shots: 2), isNull);
    final next = scoreGolfHole(first, seat: 'p2', hole: 2, shots: 4)!;
    expect(next['currentHole'], 3);
    expect(next['holeSeed'], 78);
    expect(next['players']['p1']['holeShots'], {'1': 3, '2': 2});
    expect(next['players']['p2']['totalShots'], 5);
    expect(next['players']['p1']['done'], false);
    expect(scoreGolfHole(next, seat: 'p2', hole: 2, shots: 4), isNull);
    final last = scoreGolfHole(next, seat: 'p1', hole: 3, shots: 1)!;
    final finished = scoreGolfHole(last, seat: 'p2', hole: 3, shots: 2)!;
    expect(finished['status'], 'finished');
    expect(finished['currentHole'], 3);
  });
}
