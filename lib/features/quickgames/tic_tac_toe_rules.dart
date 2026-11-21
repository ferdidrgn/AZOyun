class TicTacToeOutcome {
  const TicTacToeOutcome({
    required this.winner,
    required this.winningLine,
    required this.draw,
  });

  final String? winner;
  final List<int>? winningLine;
  final bool draw;
}

const ticTacToeWinningLines = <List<int>>[
  [0, 1, 2],
  [3, 4, 5],
  [6, 7, 8],
  [0, 3, 6],
  [1, 4, 7],
  [2, 5, 8],
  [0, 4, 8],
  [2, 4, 6],
];

TicTacToeOutcome ticTacToeOutcome(List<String?> board) {
  if (board.length != 9) {
    throw ArgumentError.value(
      board.length,
      'board.length',
      'XOX board has 9 cells',
    );
  }
  for (final line in ticTacToeWinningLines) {
    final mark = board[line.first];
    if (mark != null && line.every((cell) => board[cell] == mark)) {
      return TicTacToeOutcome(
        winner: mark,
        winningLine: line,
        draw: false,
      );
    }
  }
  final draw = board.every((cell) => cell != null);
  return TicTacToeOutcome(
    winner: null,
    winningLine: null,
    draw: draw,
  );
}
