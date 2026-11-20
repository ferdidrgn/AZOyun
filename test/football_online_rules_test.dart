import 'package:AZOyun/features/soccer/soccer_match.dart';
import 'package:AZOyun/features/sprint/penalty_rules.dart';
import 'package:AZOyun/features/sprint/sprint_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('penalty aim, curve, power and keeper dive affect the same result', () {
    expect(penaltyFlight(encodePenaltyKick(0, 65, 0), 0).result, 'save');
    expect(penaltyFlight(encodePenaltyKick(0, 90, 0), 1).result, 'goal');
    expect(penaltyFlight(encodePenaltyKick(0, 65, -1), 2).result, 'miss');
    expect(penaltyFlight(encodePenaltyKick(0, 10, 0), 1).result, 'miss');
    expect(penaltyFlight(encodePenaltyKick(4, 100, 1), 2).x > 1, true);
    expect(penaltyFlight(null, 2).result, 'timeout');
  });

  test(
      'penalty locks inputs, publishes a replay and restarts by mutual consent',
      () {
    const mode = SprintMode.penalty;
    var room = sprintRoom(mode, 'a', 'Ada', 14, 0, penaltyV2: true);
    room = joinSprint(mode, room, 'b', 'Can', 0)!;
    SprintData? act(String player, String type, [int? choice, int now = 0]) =>
        updateSprint(mode, room, player, room['epoch'] as int,
            (type: type, choice: choice), now);

    room = act('a', 'start')!;
    final shot = encodePenaltyKick(0, 90, 0);
    expect(act('b', 'kick', shot), isNull);
    room = act('a', 'kick', shot)!;
    expect(act('a', 'kick', 1), isNull);
    room = act('b', 'kick', 1)!;
    expect(room['phase'], 'reveal');
    expect(room['score']['a'], 1);
    expect(room['penaltyReplay']['kick'], shot);
    room = {...room, 'phase': 'finished', 'winner': 'a'};
    room = act('a', 'rematch')!;
    expect(room['phase'], 'finished');
    room = act('b', 'rematch')!;
    expect(room['phase'], 'kick');
    expect(room['score']['a'], 0);
    expect(room['round'], 1);
    expect(room['matchNumber'], 1);
    expect(room['penaltyReplay'], isNull);
  });

  test('free kick assigns one guest and applies each shot once', () {
    final lobby = {
      'status': 'waiting',
      'currentPlayer': 'p1',
      'currentRound': 1,
      'totalRounds': 1,
      'players': {
        'p1': {'score': 0}
      },
    };
    expect(startSoccerRoom(lobby), isNull);
    final joined = joinSoccerRoom(lobby, 'Can')!;
    expect(joinSoccerRoom(joined, 'Deniz'), isNull);
    final first = startSoccerRoom(joined)!;
    final firstTurn = soccerTurn(first)!;
    final second = finishSoccerShot(first, firstTurn, 'goal')!;
    expect(second['players']['p1']['score'], 1);
    expect(second['currentPlayer'], 'p2');
    expect(second['ball'], isNull);
    expect(finishSoccerShot(second, firstTurn, 'goal'), isNull);
    final finished = finishSoccerShot(second, soccerTurn(second)!, 'blocked')!;
    expect(finished['status'], 'finished');
    expect(finished['resultSeq'], 2);
    expect(soccerTurn(finished), isNull);
  });

  test('free kick requires the whole ball to cross between both posts', () {
    String? shot(double x, double y, {double fromY = .2}) => soccerLineResult(
          fromX: x,
          fromY: fromY,
          toX: x,
          toY: y,
          goalLine: .18,
          leftPost: .20,
          rightPost: .80,
          radius: .048,
        );
    expect(shot(.5, .14), isNull);
    expect(shot(.5, .12), 'goal');
    expect(shot(.21, .12), 'miss');
    expect(shot(.5, .20, fromY: .12), isNull);
  });
}
