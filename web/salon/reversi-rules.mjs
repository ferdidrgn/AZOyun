export const REVERSI_EMPTY = 0;
export const REVERSI_BLACK = 1;
export const REVERSI_WHITE = 2;
export const REVERSI_BOARD_SIZE = 8;

const DIRECTIONS = [
  [-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1],
  [1, -1], [1, 0], [1, 1],
];

export function reversiInitialBoard() {
  const board = Array(64).fill(REVERSI_EMPTY);
  board[27] = board[36] = REVERSI_WHITE;
  board[28] = board[35] = REVERSI_BLACK;
  return board;
}

export function reversiFlips(board, index, side) {
  if (!Array.isArray(board) || board.length !== 64 ||
      !Number.isInteger(index) || index < 0 || index >= 64 ||
      ![REVERSI_BLACK, REVERSI_WHITE].includes(side) || board[index] !== REVERSI_EMPTY) return [];
  const row = Math.floor(index / 8), col = index % 8, opponent = 3 - side;
  const flips = [];
  for (const [dr, dc] of DIRECTIONS) {
    let r = row + dr, c = col + dc;
    const line = [];
    while (r >= 0 && r < 8 && c >= 0 && c < 8 && board[r * 8 + c] === opponent) {
      line.push(r * 8 + c); r += dr; c += dc;
    }
    if (line.length && r >= 0 && r < 8 && c >= 0 && c < 8 && board[r * 8 + c] === side) flips.push(...line);
  }
  return flips;
}

export function reversiLegalMoves(board, side) {
  return Array.from({ length: 64 }, (_, index) => index)
    .filter((index) => reversiFlips(board, index, side).length > 0);
}

export function reversiApplyMove(board, index, side) {
  const flips = reversiFlips(board, index, side);
  if (!flips.length) return null;
  const next = [...board]; next[index] = side;
  for (const cell of flips) next[cell] = side;
  return { board: next, flips };
}

export function reversiNextSide(board, currentSide) {
  const opponent = 3 - currentSide;
  if (reversiLegalMoves(board, opponent).length) return opponent;
  if (reversiLegalMoves(board, currentSide).length) return currentSide;
  return REVERSI_EMPTY;
}

export function reversiOutcome(board) {
  if (!Array.isArray(board) || board.length !== 64 ||
      reversiLegalMoves(board, REVERSI_BLACK).length || reversiLegalMoves(board, REVERSI_WHITE).length) return null;
  const black = board.filter((cell) => cell === REVERSI_BLACK).length;
  const white = board.filter((cell) => cell === REVERSI_WHITE).length;
  return { black, white, winner: black === white ? REVERSI_EMPTY : black > white ? REVERSI_BLACK : REVERSI_WHITE };
}
