const double scubaStepSeconds = 0.03;
const double scubaBoostPace = 0.82;
const double scubaDiverHomeY = 0.72;
const double scubaTrashSpawnSeconds = 1.2;
const double scubaEnemySpawnSeconds = 2.3;
const double scubaPearlSpawnSeconds = 10;
const double scubaPearlShieldSeconds = 4;

const List<double> scubaLevelPaces = [0.19, 0.31, 0.38, 0.50, 0.62, 0.82, 0.94, 1.0];

class ScubaContactResult {
  const ScubaContactResult({
    required this.score,
    required this.level,
    required this.shieldSeconds,
    required this.gameOver,
  });

  final int score;
  final int level;
  final double shieldSeconds;
  final bool gameOver;
}

class ScubaSpawnResult {
  const ScubaSpawnResult({required this.elapsed, required this.spawn});

  final double elapsed;
  final bool spawn;
}

double scubaPace(int level, {required bool shielded}) {
  final pace = scubaLevelPaces[(level - 1).clamp(0, scubaLevelPaces.length - 1)];
  return shielded && pace < scubaBoostPace ? scubaBoostPace : pace;
}

double scubaMoveDriftY(double y, double pace, [double dt = scubaStepSeconds]) =>
    y + pace * dt;

double scubaMoveDriftX(double x, double vx, [double dt = scubaStepSeconds]) =>
    (x + vx * dt).clamp(0.06, 0.94);

ScubaSpawnResult scubaSpawnTick(double elapsed, double dt, double interval) {
  final next = elapsed + dt;
  return next >= interval
      ? ScubaSpawnResult(elapsed: 0, spawn: true)
      : ScubaSpawnResult(elapsed: next, spawn: false);
}

double scubaCollisionReach(String kind, double scale) => switch (kind) {
      'shark' => 0.09,
      'puffer' => 0.045 * scale,
      'jelly' => 0.055,
      'pearl' => 0.05,
      _ => 0.045,
    };

bool scubaOverlap(double ax, double ay, double bx, double by, double reach) {
  final dx = ax - bx;
  final dy = ay - by;
  return dx * dx + dy * dy <= reach * reach;
}

ScubaContactResult scubaResolveContact({
  required String kind,
  required int score,
  required int level,
  required double shieldSeconds,
}) {
  if (kind == 'pearl') {
    return ScubaContactResult(
      score: score,
      level: level,
      shieldSeconds: scubaPearlShieldSeconds,
      gameOver: false,
    );
  }
  if (const {'shark', 'puffer', 'jelly'}.contains(kind)) {
    return ScubaContactResult(
      score: score,
      level: level,
      shieldSeconds: shieldSeconds,
      gameOver: shieldSeconds <= 0,
    );
  }
  final nextScore = score + 1;
  return ScubaContactResult(
    score: nextScore,
    level: nextScore % 10 == 0 ? level + 1 : level,
    shieldSeconds: shieldSeconds,
    gameOver: false,
  );
}
