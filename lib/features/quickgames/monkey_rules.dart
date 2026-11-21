const int monkeySessionSeconds = 20;
const int monkeyMoveIntervalMs = 700;
const int monkeyScore = 1;

class MonkeyTapResult {
  const MonkeyTapResult({required this.score, required this.hit});

  final int score;
  final bool hit;
}

class MonkeyTickResult {
  const MonkeyTickResult({required this.secondsLeft, required this.running});

  final int secondsLeft;
  final bool running;
}

MonkeyTapResult tapMonkey({
  required int score,
  required int targetIndex,
  required int tappedIndex,
  required bool running,
}) {
  if (score < 0 || targetIndex < 0 || targetIndex >= 9 ||
      tappedIndex < 0 || tappedIndex >= 9) {
    throw ArgumentError('Invalid monkey target state');
  }
  final hit = running && targetIndex == tappedIndex;
  return MonkeyTapResult(score: score + (hit ? monkeyScore : 0), hit: hit);
}

MonkeyTickResult tickMonkeySession(int secondsLeft) {
  if (secondsLeft < 0) throw ArgumentError.value(secondsLeft, 'secondsLeft');
  final nextSeconds = secondsLeft > 0 ? secondsLeft - 1 : 0;
  return MonkeyTickResult(
    secondsLeft: nextSeconds,
    running: nextSeconds > 0,
  );
}

