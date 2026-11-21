const int balloonSessionSeconds = 20;
const int balloonLifetimeMs = 1100;
const int balloonScore = 1;

class BalloonPopResult {
  const BalloonPopResult({required this.score, required this.popped});

  final int score;
  final bool popped;
}

class BalloonTickResult {
  const BalloonTickResult({required this.secondsLeft, required this.running});

  final int secondsLeft;
  final bool running;
}

BalloonPopResult popBalloon({
  required int score,
  required bool visible,
  required bool running,
}) {
  if (score < 0) throw ArgumentError.value(score, 'score');
  final popped = visible && running;
  return BalloonPopResult(
    score: score + (popped ? balloonScore : 0),
    popped: popped,
  );
}

BalloonTickResult tickBalloonSession(int secondsLeft) {
  if (secondsLeft < 0) throw ArgumentError.value(secondsLeft, 'secondsLeft');
  final nextSeconds = secondsLeft > 0 ? secondsLeft - 1 : 0;
  return BalloonTickResult(
    secondsLeft: nextSeconds,
    running: nextSeconds > 0,
  );
}

