export const BALLOON_SESSION_SECONDS = 20;
export const BALLOON_LIFETIME_MS = 1100;
export const BALLOON_SCORE = 1;

export function popBalloon({ score, visible, running }) {
  if (!Number.isInteger(score) || score < 0) throw new TypeError("Invalid balloon score");
  const popped = visible && running;
  return { score: score + (popped ? BALLOON_SCORE : 0), popped };
}

export function tickBalloonSession(secondsLeft) {
  if (!Number.isInteger(secondsLeft) || secondsLeft < 0) {
    throw new TypeError("Invalid balloon countdown");
  }
  const nextSeconds = Math.max(0, secondsLeft - 1);
  return { secondsLeft: nextSeconds, running: nextSeconds > 0 };
}

