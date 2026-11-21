const winningLines = [
  [0, 1, 2],
  [3, 4, 5],
  [6, 7, 8],
  [0, 3, 6],
  [1, 4, 7],
  [2, 5, 8],
  [0, 4, 8],
  [2, 4, 6],
];

export function ticTacToeOutcome(board) {
  if (!Array.isArray(board) || board.length !== 9) {
    throw new TypeError("XOX board must contain exactly 9 cells.");
  }
  for (const line of winningLines) {
    const mark = board[line[0]];
    if (mark && line.every((cell) => board[cell] === mark)) {
      return { winner: mark, winningLine: line, draw: false };
    }
  }
  return {
    winner: null,
    winningLine: null,
    draw: board.every(Boolean),
  };
}
