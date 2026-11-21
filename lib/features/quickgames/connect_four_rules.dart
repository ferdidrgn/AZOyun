const connectFourRows = 6;
const connectFourColumns = 7;
const connectFourLength = connectFourRows * connectFourColumns;

class ConnectFourOutcome {
  const ConnectFourOutcome({
    required this.winner,
    required this.winningLine,
    required this.draw,
  });

  final String? winner;
  final List<int>? winningLine;
  final bool draw;
}

List<String?> flattenConnectFourBoard(List<List<String?>> board) => [
      for (final row in board) ...row,
    ];

int? connectFourDropRow(List<String?> board, int column) {
  _validateConnectFourBoard(board);
  if (column < 0 || column >= connectFourColumns) {
    throw RangeError.range(column, 0, connectFourColumns - 1, 'column');
  }
  for (var row = connectFourRows - 1; row >= 0; row--) {
    if (board[row * connectFourColumns + column] == null) return row;
  }
  return null;
}

ConnectFourOutcome connectFourOutcome(List<String?> board) {
  _validateConnectFourBoard(board);
  const directions = [(0, 1), (1, 0), (1, 1), (1, -1)];
  for (var row = 0; row < connectFourRows; row++) {
    for (var column = 0; column < connectFourColumns; column++) {
      final mark = board[row * connectFourColumns + column];
      if (mark == null) continue;
      for (final (rowStep, columnStep) in directions) {
        final endRow = row + rowStep * 3;
        final endColumn = column + columnStep * 3;
        if (endRow < 0 ||
            endRow >= connectFourRows ||
            endColumn < 0 ||
            endColumn >= connectFourColumns) continue;
        final line = [
          for (var step = 0; step < 4; step++)
            (row + rowStep * step) * connectFourColumns +
                column +
                columnStep * step,
        ];
        if (line.every((index) => board[index] == mark)) {
          return ConnectFourOutcome(
            winner: mark,
            winningLine: line,
            draw: false,
          );
        }
      }
    }
  }
  return ConnectFourOutcome(
    winner: null,
    winningLine: null,
    draw: board.every((cell) => cell != null),
  );
}

void _validateConnectFourBoard(List<String?> board) {
  if (board.length != connectFourLength) {
    throw ArgumentError.value(
      board.length,
      'board.length',
      'Connect Four board has $connectFourLength cells',
    );
  }
}
