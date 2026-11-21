const int reversiEmpty = 0;
const int reversiBlack = 1;
const int reversiWhite = 2;
const int reversiBoardSize = 8;

const List<List<int>> _reversiDirections = [
  [-1, -1],
  [-1, 0],
  [-1, 1],
  [0, -1],
  [0, 1],
  [1, -1],
  [1, 0],
  [1, 1],
];

List<int> reversiInitialBoard() {
  final board = List<int>.filled(reversiBoardSize * reversiBoardSize, 0);
  board[27] = reversiWhite;
  board[28] = reversiBlack;
  board[35] = reversiBlack;
  board[36] = reversiWhite;
  return board;
}

List<int> reversiFlips(List<int> board, int index, int side) {
  if (board.length != 64 ||
      index < 0 ||
      index >= 64 ||
      (side != reversiBlack && side != reversiWhite) ||
      board[index] != 0) {
    return const [];
  }
  final row = index ~/ reversiBoardSize;
  final col = index % reversiBoardSize;
  final opponent = 3 - side;
  final flips = <int>[];
  for (final direction in _reversiDirections) {
    var r = row + direction[0];
    var c = col + direction[1];
    final line = <int>[];
    while (r >= 0 &&
        r < reversiBoardSize &&
        c >= 0 &&
        c < reversiBoardSize &&
        board[r * reversiBoardSize + c] == opponent) {
      line.add(r * reversiBoardSize + c);
      r += direction[0];
      c += direction[1];
    }
    if (line.isNotEmpty &&
        r >= 0 &&
        r < reversiBoardSize &&
        c >= 0 &&
        c < reversiBoardSize &&
        board[r * reversiBoardSize + c] == side) {
      flips.addAll(line);
    }
  }
  return flips;
}

List<int> reversiLegalMoves(List<int> board, int side) => [
      for (var index = 0; index < board.length; index++)
        if (reversiFlips(board, index, side).isNotEmpty) index,
    ];

List<int>? reversiApplyMove(List<int> board, int index, int side) {
  final flips = reversiFlips(board, index, side);
  if (flips.isEmpty) return null;
  final next = List<int>.of(board)..[index] = side;
  for (final cell in flips) {
    next[cell] = side;
  }
  return next;
}

/// Returns the next side, keeps the current side for a forced pass, or 0 at end.
int reversiNextSide(List<int> board, int currentSide) {
  final opponent = 3 - currentSide;
  if (reversiLegalMoves(board, opponent).isNotEmpty) return opponent;
  if (reversiLegalMoves(board, currentSide).isNotEmpty) return currentSide;
  return reversiEmpty;
}

Map<String, int>? reversiOutcome(List<int> board) {
  if (board.length != 64 ||
      reversiLegalMoves(board, reversiBlack).isNotEmpty ||
      reversiLegalMoves(board, reversiWhite).isNotEmpty) {
    return null;
  }
  final black = board.where((cell) => cell == reversiBlack).length;
  final white = board.where((cell) => cell == reversiWhite).length;
  return {
    'black': black,
    'white': white,
    'winner': black == white ? 0 : (black > white ? reversiBlack : reversiWhite)
  };
}
