export const MONKEY_SESSION_SECONDS = 20;
export const MONKEY_MOVE_INTERVAL_MS = 700;
export const MONKEY_SCORE = 1;

export function tapMonkey({ score, targetIndex, tappedIndex, running }) {
  if (!Number.isInteger(score) || score < 0 ||
      !Number.isInteger(targetIndex) || targetIndex < 0 || targetIndex >= 9 ||
      !Number.isInteger(tappedIndex) || tappedIndex < 0 || tappedIndex >= 9) {
    throw new TypeError("Invalid monkey target state");
  }
  const hit = running && targetIndex === tappedIndex;
  return { score: score + (hit ? MONKEY_SCORE : 0), hit };
}

export function tickMonkeySession(secondsLeft) {
  if (!Number.isInteger(secondsLeft) || secondsLeft < 0) {
    throw new TypeError("Invalid monkey countdown");
  }
  const nextSeconds = Math.max(0, secondsLeft - 1);
  return { secondsLeft: nextSeconds, running: nextSeconds > 0 };
}

