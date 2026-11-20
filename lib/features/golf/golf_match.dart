typedef GolfRoom = Map<String, dynamic>;

GolfRoom? joinGolfRoom(GolfRoom room, String name) {
  if (room['status'] != 'waiting') return null;
  final players = _players(room);
  for (var number = 2; number <= 4; number++) {
    final seat = 'p$number';
    if (players.containsKey(seat)) continue;
    players[seat] = {
      'name': name,
      'isHost': false,
      'totalShots': 0,
      'done': false
    };
    return {...room, 'players': players};
  }
  return null;
}

GolfRoom? startGolfRoom(GolfRoom room) {
  if (room['status'] != 'waiting' || _players(room).length < 2) return null;
  return {...room, 'status': 'playing', 'currentHole': 1};
}

GolfRoom? scoreGolfHole(
  GolfRoom room, {
  required String seat,
  required int hole,
  required int shots,
}) {
  if (room['status'] != 'playing' || room['currentHole'] != hole || shots < 1) {
    return null;
  }
  final players = _players(room);
  final player = players[seat] as Map?;
  if (player == null || player['done'] == true) return null;
  final scores = player['holeShots'];
  // Firebase may decode numeric keys as lists on existing rooms.
  final holeShots = <String, dynamic>{
    if (scores is Map) ...scores.map((key, value) => MapEntry('$key', value)),
    if (scores is List)
      for (var index = 0; index < scores.length; index++)
        if (scores[index] != null) '$index': scores[index],
  };
  if (holeShots.containsKey('$hole')) return null;
  players[seat] = {
    ...player,
    'done': true,
    'totalShots': ((player['totalShots'] as num?) ?? 0).toInt() + shots,
    'holeShots': {...holeShots, '$hole': shots},
  };
  final scored = {...room, 'players': players};
  return advanceGolfRoom(scored, hole) ?? scored;
}

GolfRoom? advanceGolfRoom(GolfRoom room, int hole) {
  if (room['status'] != 'playing' || room['currentHole'] != hole) return null;
  final players = _players(room);
  if (players.isEmpty ||
      players.values.any((player) => player['done'] != true)) {
    return null;
  }
  if (hole >= ((room['holeCount'] as num?) ?? 5)) {
    return {...room, 'status': 'finished'};
  }
  return {
    ...room,
    'currentHole': hole + 1,
    'holeSeed': ((room['holeSeed'] as num?) ?? 0).toInt() + 1,
    'players': players
        .map((seat, player) => MapEntry(seat, {...player, 'done': false})),
  };
}

GolfRoom _players(GolfRoom room) =>
    Map<String, dynamic>.from((room['players'] as Map?) ?? {});
