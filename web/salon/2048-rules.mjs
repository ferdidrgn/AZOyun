export const SIZE_2048 = 4;

export function is2048GameOver(board) {
  if (!Array.isArray(board) || board.length !== SIZE_2048 ** 2 ||
      board.some((value) => !Number.isInteger(value) || value < 0)) {
    throw new TypeError("2048 board must contain 16 non-negative integers");
  }
  return board.every(Boolean) && !board.some((value, index) =>
    (index % SIZE_2048 < SIZE_2048 - 1 && board[index + 1] === value) ||
    (index < SIZE_2048 * (SIZE_2048 - 1) && board[index + SIZE_2048] === value),
  );
}

export function apply2048Move(board, direction) {
  if (!Array.isArray(board) || board.length !== SIZE_2048 ** 2 ||
      board.some((value) => !Number.isInteger(value) || value < 0)) {
    throw new TypeError("2048 board must contain 16 non-negative integers");
  }
  if (!["left", "right", "up", "down"].includes(direction)) {
    throw new TypeError("Unknown 2048 direction");
  }

  const next = [...board];
  let score = 0;
  for (let line = 0; line < SIZE_2048; line++) {
    const indices = Array.from({ length: SIZE_2048 }, (_, offset) =>
      direction === "left" || direction === "right"
        ? line * SIZE_2048 + offset
        : offset * SIZE_2048 + line,
    );
    if (direction === "right" || direction === "down") indices.reverse();
    const values = indices.map((index) => board[index]).filter(Boolean);
    const merged = [];
    for (let i = 0; i < values.length; i++) {
      if (values[i] === values[i + 1]) {
        const value = values[i] * 2;
        merged.push(value);
        score += value;
        i++;
      } else {
        merged.push(values[i]);
      }
    }
    for (let i = 0; i < indices.length; i++) next[indices[i]] = merged[i] || 0;
  }

  const changed = next.some((value, index) => value !== board[index]);
  const gameOver = is2048GameOver(next);
  return { board: next, score, changed, gameOver, won: next.includes(2048) };
}

