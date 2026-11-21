const double jumpDashGravity = 0.0018;
const double jumpDashImpulse = -0.034;
const double jumpDashPipeSpeed = 0.011;
const double jumpDashPipeWidth = 0.14;
const double jumpDashGapHalf = 0.16;
const double jumpDashBirdX = 0.22;
const double jumpDashBirdRadius = 0.035;
const double jumpDashSpawnThreshold = 0.42;

double jumpDashNextVelocity(double velocity) => velocity + jumpDashGravity;
double jumpDashNextBirdY(double birdY, double velocity) => birdY + velocity;
double jumpDashNextPipeX(double pipeX) => pipeX - jumpDashPipeSpeed;
bool jumpDashShouldSpawn(double spawnTimer) =>
    spawnTimer + jumpDashPipeSpeed >= jumpDashSpawnThreshold;
bool jumpDashPipePassed(double pipeX) =>
    pipeX + jumpDashPipeWidth < jumpDashBirdX;

bool jumpDashHitBoundary(double birdY) =>
    birdY - jumpDashBirdRadius < 0 || birdY + jumpDashBirdRadius > 1;

bool jumpDashPipeCollision(double birdY, double pipeX, double gapCenter) {
  final overlapsPipe = jumpDashBirdX + jumpDashBirdRadius > pipeX &&
      jumpDashBirdX - jumpDashBirdRadius < pipeX + jumpDashPipeWidth;
  if (!overlapsPipe) return false;
  return !(birdY - jumpDashBirdRadius > gapCenter - jumpDashGapHalf &&
      birdY + jumpDashBirdRadius < gapCenter + jumpDashGapHalf);
}

bool jumpDashCollision(double birdY, double pipeX, double gapCenter) =>
    jumpDashHitBoundary(birdY) ||
    jumpDashPipeCollision(birdY, pipeX, gapCenter);

