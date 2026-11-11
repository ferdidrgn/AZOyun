import 'package:AZOyun/features/sprint/sprint_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a room cannot start early or accept late joiners', () {
    final room = sprintRoom(SprintMode.penalty, 'a', 'Ada', 5, 0);
    expect(
        updateSprint(
            SprintMode.penalty, room, 'a', 0, (type: 'start', choice: null), 0),
        isNull);
    final match = _Match(SprintMode.penalty, ['a', 'b']);
    expect(joinSprint(SprintMode.penalty, match.state, 'c', 'Cem', 0), isNull);
    expect(match.tryAction('b', 'start', null), isNull);
    expect(match.tryAction('a', 'kick', 3, epoch: 0), isNull);
  });

  test(
      'penalty locks picks, expires a missing kick, and ends after a full deciding pair',
      () {
    final match = _Match(SprintMode.penalty, ['a', 'b']);
    match.act('a', 'kick', 0);
    expect(match.tryAction('a', 'kick', 1), isNull);
    match.act('b', 'kick', 1);
    expect(sprintMap(match.state['score'])['a'], 1);
    match.expire();
    match.expire(); // Second striker did not select a shot.
    expect(sprintMap(match.state['score'])['b'], 0);
    expect(match.state['result'], startsWith('Süre doldu'));
    match.expire();

    for (var i = 3; i <= 10; i++) {
      match.act('a', 'kick', 2);
      match.act('b', 'kick', 2);
      match.expire();
    }
    expect(match.state['winner'], 'a');

    final tie = _Match(SprintMode.penalty, ['a', 'b']);
    for (var i = 1; i <= 16; i++) {
      tie.act('a', 'kick', 2);
      tie.act('b', 'kick', 2);
      tie.expire();
      if (i < 16) expect(tie.state['phase'], 'kick');
    }
    expect(tie.state['winner'], 'draw');
  });

  test(
      'bluff rotates the declarer and scores correct votes without mutating old snapshots',
      () {
    final match = _Match(SprintMode.bluff, ['a', 'b', 'c']);
    final oldState = match.state;
    final chosen =
        bluffHand(oldState).indexWhere((card) => card != bluffTarget(oldState));
    expect(chosen, isNonNegative);
    match.act('a', 'declare', chosen);
    expect(match.tryAction('a', 'bluffVote', 1), isNull);
    match.act('b', 'bluffVote', 1);
    match.act('c', 'bluffVote', 1);
    expect(sprintMap(match.state['score']), {'a': 0, 'b': 1, 'c': 1});
    expect(sprintMap(oldState['score']), {'a': 0, 'b': 0, 'c': 0});
    match.expire();
    expect(sprintActor(match.state), 'b');
  });

  test('sabotage blocks one repair and a tied vote does not eject a player',
      () {
    final match = _Match(SprintMode.station, ['a', 'b', 'c', 'd']);
    final spy = match.state['saboteur'] as String;
    final crew = sprintPlayers(match.state).where((id) => id != spy).toList();
    match.act(spy, 'work', 0);
    for (final (sector, id) in crew.indexed) {
      final answer =
          stationPuzzles[stationPuzzleIndex(match.state, sector)].answer;
      match.act(id, 'work', sector * 3 + answer);
    }
    expect(match.state['repairs'], 2);
    final spyIndex = sprintPlayers(match.state).indexOf(spy);
    final firstIndex = sprintPlayers(match.state).indexOf(crew.first);
    match.act(spy, 'stationVote', firstIndex);
    match.act(crew.first, 'stationVote', spyIndex);
    match.act(crew[1], 'stationVote', spyIndex);
    match.act(crew[2], 'stationVote', firstIndex);
    expect(match.state['phase'], 'reveal');
    expect(sprintMap(match.state['out']), isEmpty);
    match.expire();
    for (final id in sprintPlayers(match.state)) {
      match.act(id, 'work', 0);
    }
    for (final id in crew) {
      match.act(id, 'stationVote', spyIndex);
    }
    match.act(spy, 'stationVote', 4);
    expect(match.state['winner'], 'crew');
  });
}

class _Match {
  _Match(this.mode, List<String> ids) {
    state = sprintRoom(mode, ids.first, ids.first, 5, 0);
    for (final id in ids.skip(1)) {
      state = joinSprint(mode, state, id, id, 0)!;
    }
    act(ids.first, 'start', null);
  }

  final SprintMode mode;
  late SprintData state;
  int now = 0;

  SprintData? tryAction(String player, String type, int? choice,
          {int? epoch}) =>
      updateSprint(mode, state, player, epoch ?? state['epoch'] as int,
          (type: type, choice: choice), now);

  void act(String player, String type, int? choice) =>
      state = tryAction(player, type, choice)!;

  void expire() {
    now = state['deadline'] as int;
    act(sprintPlayers(state).first, 'tick', null);
  }
}
