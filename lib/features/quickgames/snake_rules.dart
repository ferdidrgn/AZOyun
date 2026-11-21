enum SnakeDirection { up, down, left, right }

class SnakeStepResult {
  const SnakeStepResult({
    required this.snake,
    required this.ate,
    required this.collided,
    required this.score,
  });

  final List<({int x, int y})> snake;
  final bool ate;
  final bool collided;
  final int score;
}

bool canTurnSnake(SnakeDirection current, SnakeDirection next) {
  final delta = _snakeDelta(current);
  final nextDelta = _snakeDelta(next);
  return delta.$1 + nextDelta.$1 != 0 || delta.$2 + nextDelta.$2 != 0;
}

SnakeStepResult stepSnake({
  required List<({int x, int y})> snake,
  required SnakeDirection direction,
  required ({int x, int y})? food,
  int size = 14,
}) {
  if (snake.isEmpty || size <= 0) {
    throw ArgumentError('Snake and board size must be valid');
  }
  final delta = _snakeDelta(direction);
  final head = (x: snake.first.x + delta.$1, y: snake.first.y + delta.$2);
  final ate = food != null && head == food;
  final body = ate ? snake : snake.take(snake.length - 1);
  final collided = head.x < 0 || head.x >= size || head.y < 0 || head.y >= size ||
      body.contains(head);
  if (collided) {
    return SnakeStepResult(
      snake: List.of(snake),
      ate: false,
      collided: true,
      score: 0,
    );
  }
  return SnakeStepResult(
    snake: [head, ...body],
    ate: ate,
    collided: false,
    score: ate ? 10 : 0,
  );
}

(int, int) _snakeDelta(SnakeDirection direction) => switch (direction) {
      SnakeDirection.up => (0, -1),
      SnakeDirection.down => (0, 1),
      SnakeDirection.left => (-1, 0),
      SnakeDirection.right => (1, 0),
    };

