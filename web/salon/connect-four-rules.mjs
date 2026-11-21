export const CONNECT_FOUR_ROWS = 6;
export const CONNECT_FOUR_COLUMNS = 7;
export const CONNECT_FOUR_LENGTH = CONNECT_FOUR_ROWS * CONNECT_FOUR_COLUMNS;

function validateBoard(board) {
  if (!Array.isArray(board) || board.length !== CONNECT_FOUR_LENGTH) {
    throw new TypeError(`Connect Four board must contain ${CONNECT_FOUR_LENGTH} cells.`);
  }
}

export function connectFourDropRow(board, column) {
  validateBoard(board);
  if (!Number.isInteger(column) || column < 0 || column >= CONNECT_FOUR_COLUMNS) {
    throw new RangeError("Connect Four column is out of range.");
  }
  for (let row = CONNECT_FOUR_ROWS - 1; row >= 0; row--) {
    if (board[row * CONNECT_FOUR_COLUMNS + column] == null) return row;
  }
  return null;
}

export function connectFourOutcome(board) {
  validateBoard(board);
  const directions = [[0, 1], [1, 0], [1, 1], [1, -1]];
  for (let row = 0; row < CONNECT_FOUR_ROWS; row++) {
    for (let column = 0; column < CONNECT_FOUR_COLUMNS; column++) {
      const mark = board[row * CONNECT_FOUR_COLUMNS + column];
      if (mark == null || mark === "") continue;
      for (const [rowStep, columnStep] of directions) {
        const endRow = row + rowStep * 3;
        const endColumn = column + columnStep * 3;
        if (endRow < 0 || endRow >= CONNECT_FOUR_ROWS ||
            endColumn < 0 || endColumn >= CONNECT_FOUR_COLUMNS) continue;
        const line = Array.from({ length: 4 }, (_, step) =>
          (row + rowStep * step) * CONNECT_FOUR_COLUMNS + column + columnStep * step);
        if (line.every((index) => board[index] === mark)) {
          return { winner: mark, winningLine: line, draw: false };
        }
      }
    }
  }
  return {
    winner: null,
    winningLine: null,
    draw: board.every((cell) => cell != null && cell !== ""),
  };
}
