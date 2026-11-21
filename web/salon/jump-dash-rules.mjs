export const JUMP_DASH_GRAVITY = 0.0018;
export const JUMP_DASH_IMPULSE = -0.034;
export const JUMP_DASH_PIPE_SPEED = 0.011;
export const JUMP_DASH_PIPE_WIDTH = 0.14;
export const JUMP_DASH_GAP_HALF = 0.16;
export const JUMP_DASH_BIRD_X = 0.22;
export const JUMP_DASH_BIRD_RADIUS = 0.035;
export const JUMP_DASH_SPAWN_THRESHOLD = 0.42;

export const jumpDashNextVelocity = (velocity) => velocity + JUMP_DASH_GRAVITY;
export const jumpDashNextBirdY = (birdY, velocity) => birdY + velocity;
export const jumpDashNextPipeX = (pipeX) => pipeX - JUMP_DASH_PIPE_SPEED;
export const jumpDashShouldSpawn = (spawnTimer) =>
  spawnTimer + JUMP_DASH_PIPE_SPEED >= JUMP_DASH_SPAWN_THRESHOLD;
export const jumpDashPipePassed = (pipeX) =>
  pipeX + JUMP_DASH_PIPE_WIDTH < JUMP_DASH_BIRD_X;
export const jumpDashHitBoundary = (birdY) =>
  birdY - JUMP_DASH_BIRD_RADIUS < 0 || birdY + JUMP_DASH_BIRD_RADIUS > 1;

export function jumpDashPipeCollision(birdY, pipeX, gapCenter) {
  const overlapsPipe = JUMP_DASH_BIRD_X + JUMP_DASH_BIRD_RADIUS > pipeX &&
    JUMP_DASH_BIRD_X - JUMP_DASH_BIRD_RADIUS < pipeX + JUMP_DASH_PIPE_WIDTH;
  if (!overlapsPipe) return false;
  return !(birdY - JUMP_DASH_BIRD_RADIUS > gapCenter - JUMP_DASH_GAP_HALF &&
    birdY + JUMP_DASH_BIRD_RADIUS < gapCenter + JUMP_DASH_GAP_HALF);
}

export const jumpDashCollision = (birdY, pipeX, gapCenter) =>
  jumpDashHitBoundary(birdY) || jumpDashPipeCollision(birdY, pipeX, gapCenter);

