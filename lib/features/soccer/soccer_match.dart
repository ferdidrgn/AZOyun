typedef SoccerRoom = Map<String, dynamic>;
typedef SoccerTurn = ({String player, int round, int sequence});

String? soccerLineResult({
  required double fromX,
  required double fromY,
  required double toX,
  required double toY,
  required double goalLine,
  required double leftPost,
  required double rightPost,
  required double radius,
}) {
  final line = goalLine - radius;
  if (fromY < line || toY >= line) return null;
  final crossing = (fromY - line) / (fromY - toY);
  final x = fromX + (toX - fromX) * crossing;
  return x > leftPost + radius && x < rightPost - radius ? 'goal' : 'miss';
}

SoccerTurn? soccerTurn(SoccerRoom room) {
  final player = room['currentPlayer'];
  final round = room['currentRound'];
  if (room['status'] != 'playing' || player is! String || round is! int) {
    return null;
  }
  return (
    player: player,
    round: round,
    sequence: room['resultSeq'] as int? ?? 0
  );
}

SoccerRoom? joinSoccerRoom(SoccerRoom room, String name) {
  final players = _players(room);
  if (room['status'] != 'waiting' ||
      players.length != 1 ||
      !players.containsKey('p1')) return null;
  return {
    ...room,
    'players': {
      ...players,
      'p2': {'name': name, 'isHost': false, 'score': 0}
    },
  };
}

SoccerRoom? startSoccerRoom(SoccerRoom room) {
  final players = _players(room);
  if (room['status'] != 'waiting' ||
      !players.containsKey('p1') ||
      !players.containsKey('p2')) return null;
  return {...room, 'status': 'playing'};
}

SoccerRoom? finishSoccerShot(SoccerRoom room, SoccerTurn shot, String result) {
  if (soccerTurn(room) != shot ||
      !{'goal', 'blocked', 'miss'}.contains(result)) {
    return null;
  }
  final players = _players(room);
  final active = players[shot.player];
  if (players.length != 2 || active is! Map) return null;
  final finished =
      shot.player == 'p2' && shot.round >= (room['totalRounds'] as int? ?? 5);
  return {
    ...room,
    if (result == 'goal')
      'players': {
        ...players,
        shot.player: {...active, 'score': (active['score'] as int? ?? 0) + 1}
      },
    'status': finished ? 'finished' : 'playing',
    'currentPlayer':
        finished ? shot.player : (shot.player == 'p1' ? 'p2' : 'p1'),
    'currentRound':
        finished || shot.player == 'p1' ? shot.round : shot.round + 1,
    'result': result,
    'resultSeq': shot.sequence + 1,
    'ball': null,
  };
}

SoccerRoom? closeSoccerMatch(SoccerRoom room, String player) {
  if (room['status'] != 'playing' || !_players(room).containsKey(player))
    return null;
  return {...room, 'status': 'finished', 'leftPlayer': player, 'ball': null};
}

SoccerRoom _players(SoccerRoom room) =>
    Map<String, dynamic>.from((room['players'] as Map?) ?? {});
