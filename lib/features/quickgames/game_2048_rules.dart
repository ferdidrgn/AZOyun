const int size2048 = 4;

class Move2048Result {
  const Move2048Result({
    required this.board,
    required this.score,
    required this.changed,
    required this.gameOver,
    required this.won,
  });

  final List<int> board;
  final int score;
  final bool changed;
  final bool gameOver;
  final bool won;
}

Move2048Result apply2048Move(List<int> board, String direction) {
  if (board.length != size2048 * size2048 || board.any((value) => value < 0)) {
    throw ArgumentError('2048 board must contain 16 non-negative integers');
  }
  if (!const {'left', 'right', 'up', 'down'}.contains(direction)) {
    throw ArgumentError.value(direction, 'direction', 'Unknown 2048 direction');
  }

  final next = List<int>.from(board);
  var score = 0;
  for (var line = 0; line < size2048; line++) {
    final indices = [
      for (var offset = 0; offset < size2048; offset++)
        direction == 'left' || direction == 'right'
            ? line * size2048 + offset
            : offset * size2048 + line,
    ];
    if (direction == 'right' || direction == 'down') {
      final reversed = indices.reversed.toList();
      indices
        ..clear()
        ..addAll(reversed);
    }
    final values = indices.map((index) => board[index]).where((value) => value != 0).toList();
    final merged = <int>[];
    for (var i = 0; i < values.length; i++) {
      if (i + 1 < values.length && values[i] == values[i + 1]) {
        final value = values[i] * 2;
        merged.add(value);
        score += value;
        i++;
      } else {
        merged.add(values[i]);
      }
    }
    for (var i = 0; i < indices.length; i++) {
      next[indices[i]] = i < merged.length ? merged[i] : 0;
    }
  }

  return Move2048Result(
    board: next,
    score: score,
    changed: next.asMap().entries.any((entry) => entry.value != board[entry.key]),
    gameOver: is2048GameOver(next),
    won: next.contains(2048),
  );
}

bool is2048GameOver(List<int> board) {
  if (board.length != size2048 * size2048) {
    throw ArgumentError('2048 board must contain 16 cells');
  }
  for (var index = 0; index < board.length; index++) {
    if (board[index] == 0 ||
        (index % size2048 < size2048 - 1 && board[index] == board[index + 1]) ||
        (index < size2048 * (size2048 - 1) && board[index] == board[index + size2048])) {
      return false;
    }
  }
  return true;
}

