import 'dart:math';

enum SprintMode {
  bluff('Son Kart', 'Blöf yap, rakiplerin kart iddiasını sorgula.', 'sonkart',
      3, 6),
  station(
      'İstasyon 90', 'Terminalleri onar, sabotajcıyı bul.', 'istasyon90', 4, 8),
  penalty(
      'Penaltı Düellosu',
      'Şut ve kurtarış kararını rakibinden önce kilitle.',
      'penaltiduello',
      2,
      2);

  const SprintMode(
      this.title, this.description, this.invite, this.minimum, this.maximum);
  final String title;
  final String description;
  final String invite;
  final int minimum;
  final int maximum;
}

typedef SprintData = Map<String, dynamic>;
typedef SprintAction = ({String type, int? choice});

const sprintSymbols = ['Ay', 'Güneş', 'Yıldız'];
const penaltyZones = ['Sol üst', 'Sağ üst', 'Orta', 'Sol alt', 'Sağ alt'];
const stationNames = ['Enerji', 'İletişim', 'Soğutma'];
const stationPuzzles = [
  (prompt: '2, 4, 8, ?', choices: ['12', '16', '18'], answer: 1),
  (prompt: '3, 6, 9, ?', choices: ['12', '15', '18'], answer: 0),
  (prompt: '20, 17, 14, ?', choices: ['12', '13', '11'], answer: 2),
  (prompt: '1, 4, 9, ?', choices: ['16', '18', '20'], answer: 0),
  (prompt: '1, 1, 2, 3, ?', choices: ['4', '5', '6'], answer: 1),
  (prompt: '6, 12, 18, ?', choices: ['20', '21', '24'], answer: 2),
  (prompt: '4, 7, 10, ?', choices: ['12', '13', '14'], answer: 1),
  (prompt: '2, 6, 18, ?', choices: ['36', '48', '54'], answer: 2),
  (prompt: '25, 20, 15, ?', choices: ['10', '11', '12'], answer: 0),
];

Map<String, dynamic> sprintMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

List<String> sprintPlayers(SprintData state) =>
    sprintMap(state['players']).keys.toList()..sort();

List<String> sprintActive(SprintData state) => sprintPlayers(state)
    .where((id) => !sprintMap(state['out']).containsKey(id))
    .toList();

String sprintActor(SprintData state) {
  final players = sprintPlayers(state);
  return players[((state['round'] as int) - 1) % players.length];
}

int stationPuzzleIndex(SprintData state, int sector) =>
    ((state['seed'] as int) + ((state['round'] as int) - 1) * 3 + sector) %
    stationPuzzles.length;

List<int> bluffHand(SprintData state) {
  final random = Random((state['seed'] as int) + state['round'] as int);
  return List.generate(3, (_) => random.nextInt(sprintSymbols.length));
}

int bluffTarget(SprintData state) =>
    ((state['seed'] as int) + state['round'] as int) % sprintSymbols.length;

SprintData sprintRoom(
        SprintMode mode, String host, String name, int seed, int now) =>
    {
      'mode': mode.name,
      'phase': 'lobby',
      'epoch': 0,
      'round': 0,
      'host': host,
      'seed': seed,
      'createdAt': now,
      'players': {host: name},
    };

SprintData? joinSprint(
    SprintMode mode, SprintData state, String player, String name, int now) {
  if (state['mode'] != mode.name ||
      state['phase'] != 'lobby' ||
      now - (state['createdAt'] as int) >
          const Duration(hours: 2).inMilliseconds) {
    return null;
  }
  final players = sprintMap(state['players']);
  if (!players.containsKey(player) && players.length >= mode.maximum)
    return null;
  return {
    ...state,
    'players': {...players, player: name}
  };
}

/// Computes one atomic room update. An action from a stale phase is ignored.
SprintData? updateSprint(SprintMode mode, SprintData state, String player,
    int epoch, SprintAction action, int now) {
  final players = sprintPlayers(state);
  if (state['mode'] != mode.name || !players.contains(player)) return null;
  final phase = state['phase'];
  if (action.type == 'leave') {
    if (phase == 'lobby') {
      final roster = sprintMap(state['players'])..remove(player);
      final remaining = players.where((id) => id != player).toList();
      return remaining.isEmpty
          ? {}
          : {
              ...state,
              'players': roster,
              'host': state['host'] == player ? remaining.first : state['host']
            };
    }
    if (phase == 'finished') return null;
    return _finish(state, 'left');
  }
  if (epoch != state['epoch'] || phase == 'finished') return null;
  if (phase == 'lobby') {
    if (action.type != 'start' ||
        state['host'] != player ||
        players.length < mode.minimum) {
      return null;
    }
    return _beginRound(
        mode,
        {
          ...state,
          'score': {for (final id in players) id: 0},
          if (mode == SprintMode.station)
            'saboteur':
                players[Random(state['seed'] as int).nextInt(players.length)],
        },
        1,
        now);
  }

  if (now >= (state['deadline'] as int)) return _advance(mode, state, now);
  if (action.type == 'tick') return null;
  if (phase == 'reveal') return null;
  final choice = action.choice;
  if (choice == null || !sprintActive(state).contains(player)) return null;
  final moves = sprintMap(state['moves']);
  if (moves.containsKey(player)) return null;
  final valid = switch (phase) {
    'declare' => player == sprintActor(state) && choice >= 0 && choice < 3,
    'bluffVote' => player != sprintActor(state) && (choice == 0 || choice == 1),
    'work' => choice >= 0 && choice < (player == state['saboteur'] ? 3 : 9),
    'stationVote' => choice >= 0 &&
        choice <= players.length &&
        (choice == players.length ||
            (players[choice] != player &&
                sprintActive(state).contains(players[choice]))),
    'kick' => choice >= 0 && choice < penaltyZones.length,
    _ => false,
  };
  if (!valid || action.type != phase) return null;
  moves[player] = choice;
  final next = {...state, 'moves': moves};
  final expected = phase == 'declare'
      ? 1
      : phase == 'bluffVote'
          ? players.length - 1
          : sprintActive(state).length;
  return moves.length == expected ? _advance(mode, next, now) : next;
}

SprintData _step(SprintData state, String phase, int seconds, int now) => {
      ...state,
      'phase': phase,
      'epoch': (state['epoch'] as int) + 1,
      'deadline': now + seconds * 1000,
      'moves': null,
    };

SprintData _beginRound(SprintMode mode, SprintData state, int round, int now) {
  final (phase, seconds) = switch (mode) {
    SprintMode.bluff => ('declare', 9),
    SprintMode.station => ('work', 15),
    SprintMode.penalty => ('kick', 8),
  };
  return _step({...state, 'round': round, 'result': null}, phase, seconds, now);
}

SprintData _finish(SprintData state, String winner) =>
    {..._step(state, 'finished', 0, 0), 'winner': winner};

SprintData _advance(SprintMode mode, SprintData state, int now) {
  final players = sprintPlayers(state);
  final round = state['round'] as int;
  final score = sprintMap(state['score']);
  final moves = sprintMap(state['moves']);
  switch (state['phase']) {
    case 'declare':
      final card = moves[sprintActor(state)] as int?;
      if (card == null) {
        return _step({...state, 'result': 'Kart seçilmedi. Tur boş geçti.'},
            'reveal', 3, now);
      }
      return _step(
          {...state, 'card': bluffHand(state)[card]}, 'bluffVote', 10, now);
    case 'bluffVote':
      final truthful = state['card'] == bluffTarget(state);
      var fooled = 0;
      for (final entry in moves.entries) {
        if (entry.value == (truthful ? 0 : 1)) {
          score[entry.key] = (score[entry.key] as int) + 1;
        } else {
          fooled++;
        }
      }
      final actor = sprintActor(state);
      if (fooled > (players.length - 1) / 2)
        score[actor] = (score[actor] as int) + 2;
      final symbol = sprintSymbols[state['card'] as int];
      return _step({
        ...state,
        'score': score,
        'result': truthful
            ? 'Doğru iddia. Açılan kart: $symbol.'
            : 'Blöf! Açılan kart: $symbol.',
      }, 'reveal', 4, now);
    case 'work':
      final repairs = [0, 0, 0];
      final jammed = moves[state['saboteur']];
      for (final entry in moves.entries) {
        if (entry.key == state['saboteur']) continue;
        final encoded = entry.value as int;
        final sector = encoded ~/ 3;
        if (encoded % 3 ==
            stationPuzzles[stationPuzzleIndex(state, sector)].answer) {
          repairs[sector]++;
        }
      }
      final fixed = [
        for (var i = 0; i < repairs.length; i++)
          if (repairs[i] >= (i == jammed ? 2 : 1)) stationNames[i]
      ];
      final progress = (state['repairs'] as int? ?? 0) + fixed.length;
      final report = fixed.isEmpty
          ? 'Bu tur onarılan terminal yok.'
          : 'Onarılan: ' + fixed.join(', ');
      if (progress >= 5) {
        return _finish(
            {...state, 'repairs': progress, 'result': report}, 'crew');
      }
      return _step({...state, 'repairs': progress, 'result': report},
          'stationVote', 12, now);
    case 'stationVote':
      final totals = <int, int>{};
      for (final vote in moves.values.cast<int>()) {
        if (vote < players.length)
          totals.update(vote, (n) => n + 1, ifAbsent: () => 1);
      }
      final high = totals.values.fold(0, max);
      final leaders = totals.keys.where((id) => totals[id] == high).toList();
      if (high < 2 || leaders.length != 1) {
        return _step(
            {...state, 'result': 'Yeterli ortak oy yok. Kimse elenmedi.'},
            'reveal',
            4,
            now);
      }
      final ejected = players[leaders.single];
      final name = sprintMap(state['players'])[ejected];
      final result = {...state, 'result': '$name istasyondan çıkarıldı.'};
      if (ejected == state['saboteur']) return _finish(result, 'crew');
      return _step({
        ...result,
        'out': {...sprintMap(state['out']), ejected: true}
      }, 'reveal', 4, now);
    case 'kick':
      final striker = sprintActor(state);
      final keeper = players.firstWhere((id) => id != striker);
      final shot = moves[striker] as int?;
      final dive = moves[keeper] as int? ?? 2;
      final goal = shot != null && shot != dive;
      if (goal) score[striker] = (score[striker] as int) + 1;
      final shotName = shot == null ? 'Şut çekilmedi' : penaltyZones[shot];
      final diveName = penaltyZones[dive];
      final outcome = goal
          ? 'Gol'
          : shot == null
              ? 'Süre doldu'
              : 'Kurtarış';
      return _step({
        ...state,
        'score': score,
        'result': '$outcome · Şut: $shotName · Kaleci: $diveName',
      }, 'reveal', 3, now);
    case 'reveal':
      if (mode == SprintMode.station) {
        if (round >= 3 || sprintActive(state).length <= 2)
          return _finish(state, 'saboteur');
      } else if (mode == SprintMode.bluff) {
        if (round >= players.length) return _finish(state, _scoreWinner(score));
      } else if (round >= 10 && round.isEven) {
        final winner = _scoreWinner(score);
        if (winner != 'draw' || round >= 16) return _finish(state, winner);
      }
      return _beginRound(mode, state, round + 1, now);
  }
  return state;
}

String _scoreWinner(SprintData score) {
  final high = score.values.cast<int>().fold(0, max);
  final leaders = score.keys.where((key) => score[key] == high).toList();
  return leaders.length == 1 ? leaders.single : 'draw';
}
