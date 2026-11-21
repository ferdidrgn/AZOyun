export function canTurnSnake(current, next) {
  const delta = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };
  if (!delta[current] || !delta[next]) throw new TypeError("Unknown snake direction");
  return delta[current][0] + delta[next][0] !== 0 ||
    delta[current][1] + delta[next][1] !== 0;
}

export function stepSnake(snake, direction, food, size = 14) {
  if (!Array.isArray(snake) || snake.length === 0 ||
      snake.some((cell) => !Array.isArray(cell) || cell.length !== 2 ||
        cell.some((value) => !Number.isInteger(value)))) {
    throw new TypeError("Snake must contain coordinate pairs");
  }
  if (!Number.isInteger(size) || size <= 0) throw new TypeError("Invalid board size");
  const delta = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] }[direction];
  if (!delta) throw new TypeError("Unknown snake direction");
  const head = [snake[0][0] + delta[0], snake[0][1] + delta[1]];
  const ate = food !== null && head[0] === food[0] && head[1] === food[1];
  const body = ate ? snake : snake.slice(0, -1);
  const collided = head.some((value) => value < 0 || value >= size) ||
    body.some((cell) => cell[0] === head[0] && cell[1] === head[1]);
  if (collided) return { snake: [...snake], ate: false, collided: true, score: 0 };
  return {
    snake: [head, ...(ate ? snake : snake.slice(0, -1))],
    ate,
    collided: false,
    score: ate ? 10 : 0,
  };
}

