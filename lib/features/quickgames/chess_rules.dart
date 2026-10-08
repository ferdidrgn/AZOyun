class ChessState {
  ChessState({
    required this.squares,
    required this.whiteTurn,
    this.enPassant,
    this.castle = '',
  });

  final List<String?> squares;
  final bool whiteTurn;
  final int? enPassant;
  final String castle;

  factory ChessState.initial() {
    const back = 'rnbqkbnr';
    final squares = List<String?>.filled(64, null);
    for (var i = 0; i < 8; i++) {
      squares[i] = back[i];
      squares[8 + i] = 'p';
      squares[48 + i] = 'P';
      squares[56 + i] = back[i].toUpperCase();
    }
    return ChessState(squares: squares, whiteTurn: true, castle: 'KQkq');
  }
}

bool chessIsWhite(String piece) => piece == piece.toUpperCase();

int chessFile(int index) => index % 8;

int chessRank(int index) => index ~/ 8;

int? chessSquare(int file, int rank) {
  if (file < 0 || file > 7 || rank < 0 || rank > 7) {
    return null;
  }
  return rank * 8 + file;
}

enum ChessEnd { playing, checkmate, stalemate }

bool chessInCheck(ChessState state, bool whiteKing) {
  final king = whiteKing ? 'K' : 'k';
  final at = state.squares.indexOf(king);
  if (at < 0) {
    return false;
  }
  return chessAttacks(state, !whiteKing, at);
}

bool chessAttacks(ChessState state, bool byWhite, int target) {
  for (var i = 0; i < 64; i++) {
    final piece = state.squares[i];
    if (piece == null || chessIsWhite(piece) != byWhite) {
      continue;
    }
    if (_attacksFrom(state, i, target)) {
      return true;
    }
  }
  return false;
}

bool _attacksFrom(ChessState state, int from, int target) {
  final piece = state.squares[from]!;
  final white = chessIsWhite(piece);
  final file = chessFile(from);
  final rank = chessRank(from);
  final df = chessFile(target) - file;
  final dr = chessRank(target) - rank;
  switch (piece.toUpperCase()) {
    case 'P':
      return dr == (white ? -1 : 1) && df.abs() == 1;
    case 'N':
      return (df.abs() == 1 && dr.abs() == 2) || (df.abs() == 2 && dr.abs() == 1);
    case 'K':
      return df.abs() <= 1 && dr.abs() <= 1 && (df != 0 || dr != 0);
    case 'B':
      return df.abs() == dr.abs() && df != 0 && _clear(state, from, target);
    case 'R':
      return (df == 0) != (dr == 0) && _clear(state, from, target);
    case 'Q':
      final diagonal = df.abs() == dr.abs() && df != 0;
      final straight = (df == 0) != (dr == 0);
      return (diagonal || straight) && _clear(state, from, target);
    default:
      return false;
  }
}

bool _clear(ChessState state, int from, int target) {
  final stepFile = chessFile(target) == chessFile(from)
      ? 0
      : (chessFile(target) > chessFile(from) ? 1 : -1);
  final stepRank = chessRank(target) == chessRank(from)
      ? 0
      : (chessRank(target) > chessRank(from) ? 1 : -1);
  var file = chessFile(from) + stepFile;
  var rank = chessRank(from) + stepRank;
  while (file != chessFile(target) || rank != chessRank(target)) {
    final square = chessSquare(file, rank);
    if (square == null || state.squares[square] != null) {
      return false;
    }
    file += stepFile;
    rank += stepRank;
  }
  return true;
}

List<(int, int)> chessLegalMoves(ChessState state) {
  final pseudo = _pseudo(state);
  return [
    for (final move in pseudo)
      if (!chessInCheck(chessPlay(state, move.$1, move.$2), state.whiteTurn)) move,
  ];
}

ChessEnd chessEnd(ChessState state) {
  if (chessLegalMoves(state).isNotEmpty) {
    return ChessEnd.playing;
  }
  if (chessInCheck(state, state.whiteTurn)) {
    return ChessEnd.checkmate;
  }
  return ChessEnd.stalemate;
}

ChessState chessPlay(ChessState state, int from, int to) {
  final squares = List<String?>.of(state.squares);
  final piece = squares[from]!;
  final white = chessIsWhite(piece);
  final kind = piece.toUpperCase();
  squares[to] = piece;
  squares[from] = null;
  if (kind == 'P' && to == state.enPassant && state.squares[to] == null) {
    squares[white ? to + 8 : to - 8] = null;
  }
  if (piece == 'P' && chessRank(to) == 0) {
    squares[to] = 'Q';
  }
  if (piece == 'p' && chessRank(to) == 7) {
    squares[to] = 'q';
  }
  if (kind == 'K' && (to - from).abs() == 2) {
    if (to == 62) {
      squares[63] = null;
      squares[61] = 'R';
    } else if (to == 58) {
      squares[56] = null;
      squares[59] = 'R';
    } else if (to == 6) {
      squares[7] = null;
      squares[5] = 'r';
    } else if (to == 2) {
      squares[0] = null;
      squares[3] = 'r';
    }
  }
  var castle = state.castle;
  void drop(String right) => castle = castle.replaceAll(right, '');
  if (piece == 'K') {
    drop('K');
    drop('Q');
  }
  if (piece == 'k') {
    drop('k');
    drop('q');
  }
  if (from == 63 || to == 63) drop('K');
  if (from == 56 || to == 56) drop('Q');
  if (from == 7 || to == 7) drop('k');
  if (from == 0 || to == 0) drop('q');
  int? enPassant;
  if (kind == 'P' && (from - to).abs() == 16) {
    enPassant = white ? from - 8 : from + 8;
  }
  return ChessState(
    squares: squares,
    whiteTurn: !state.whiteTurn,
    enPassant: enPassant,
    castle: castle,
  );
}

const _knight = [
  (-2, -1),
  (-2, 1),
  (-1, -2),
  (-1, 2),
  (1, -2),
  (1, 2),
  (2, -1),
  (2, 1),
];

const _kingSteps = [
  (-1, -1),
  (-1, 0),
  (-1, 1),
  (0, -1),
  (0, 1),
  (1, -1),
  (1, 0),
  (1, 1),
];

const _bishop = [(-1, -1), (-1, 1), (1, -1), (1, 1)];
const _rook = [(-1, 0), (1, 0), (0, -1), (0, 1)];

List<(int, int)> _pseudo(ChessState state) {
  final moves = <(int, int)>[];
  for (var i = 0; i < 64; i++) {
    final piece = state.squares[i];
    if (piece == null || chessIsWhite(piece) != state.whiteTurn) {
      continue;
    }
    final white = chessIsWhite(piece);
    switch (piece.toUpperCase()) {
      case 'P':
        _pawns(state, i, white, moves);
      case 'N':
        _leaps(state, i, white, _knight, moves);
      case 'K':
        _leaps(state, i, white, _kingSteps, moves);
        _castle(state, i, white, moves);
      case 'B':
        _slide(state, i, white, _bishop, moves);
      case 'R':
        _slide(state, i, white, _rook, moves);
      case 'Q':
        _slide(state, i, white, _bishop, moves);
        _slide(state, i, white, _rook, moves);
    }
  }
  return moves;
}

void _pawns(ChessState state, int from, bool white, List<(int, int)> out) {
  final dir = white ? -1 : 1;
  final file = chessFile(from);
  final rank = chessRank(from);
  final one = chessSquare(file, rank + dir);
  if (one != null && state.squares[one] == null) {
    out.add((from, one));
    final start = white ? 6 : 1;
    if (rank == start) {
      final two = chessSquare(file, rank + dir * 2);
      if (two != null && state.squares[two] == null) {
        out.add((from, two));
      }
    }
  }
  for (final df in const [-1, 1]) {
    final cap = chessSquare(file + df, rank + dir);
    if (cap == null) {
      continue;
    }
    final occupied = state.squares[cap];
    if (occupied != null && chessIsWhite(occupied) != white) {
      out.add((from, cap));
    }
    if (cap == state.enPassant) {
      out.add((from, cap));
    }
  }
}

void _leaps(
  ChessState state,
  int from,
  bool white,
  List<(int, int)> deltas,
  List<(int, int)> out,
) {
  final file = chessFile(from);
  final rank = chessRank(from);
  for (final delta in deltas) {
    final square = chessSquare(file + delta.$1, rank + delta.$2);
    if (square == null) {
      continue;
    }
    final occupied = state.squares[square];
    if (occupied == null || chessIsWhite(occupied) != white) {
      out.add((from, square));
    }
  }
}

void _slide(
  ChessState state,
  int from,
  bool white,
  List<(int, int)> dirs,
  List<(int, int)> out,
) {
  final file = chessFile(from);
  final rank = chessRank(from);
  for (final dir in dirs) {
    var nextFile = file + dir.$1;
    var nextRank = rank + dir.$2;
    while (true) {
      final square = chessSquare(nextFile, nextRank);
      if (square == null) {
        break;
      }
      final occupied = state.squares[square];
      if (occupied == null) {
        out.add((from, square));
      } else {
        if (chessIsWhite(occupied) != white) {
          out.add((from, square));
        }
        break;
      }
      nextFile += dir.$1;
      nextRank += dir.$2;
    }
  }
}

void _castle(ChessState state, int from, bool white, List<(int, int)> out) {
  if (white && from == 60 && !chessInCheck(state, true)) {
    if (state.castle.contains('K') &&
        state.squares[61] == null &&
        state.squares[62] == null &&
        state.squares[63] == 'R' &&
        !chessAttacks(state, false, 61) &&
        !chessAttacks(state, false, 62)) {
      out.add((60, 62));
    }
    if (state.castle.contains('Q') &&
        state.squares[57] == null &&
        state.squares[58] == null &&
        state.squares[59] == null &&
        state.squares[56] == 'R' &&
        !chessAttacks(state, false, 58) &&
        !chessAttacks(state, false, 59)) {
      out.add((60, 58));
    }
  }
  if (!white && from == 4 && !chessInCheck(state, false)) {
    if (state.castle.contains('k') &&
        state.squares[5] == null &&
        state.squares[6] == null &&
        state.squares[7] == 'r' &&
        !chessAttacks(state, true, 5) &&
        !chessAttacks(state, true, 6)) {
      out.add((4, 6));
    }
    if (state.castle.contains('q') &&
        state.squares[1] == null &&
        state.squares[2] == null &&
        state.squares[3] == null &&
        state.squares[0] == 'r' &&
        !chessAttacks(state, true, 2) &&
        !chessAttacks(state, true, 3)) {
      out.add((4, 2));
    }
  }
}
