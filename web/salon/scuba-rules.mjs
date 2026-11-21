export const SCUBA_STEP_SECONDS = 0.03;
export const SCUBA_BOOST_PACE = 0.82;
export const SCUBA_DIVER_HOME_Y = 0.72;
export const SCUBA_TRASH_SPAWN_SECONDS = 1.2;
export const SCUBA_ENEMY_SPAWN_SECONDS = 2.3;
export const SCUBA_PEARL_SPAWN_SECONDS = 10;
export const SCUBA_PEARL_SHIELD_SECONDS = 4;
export const SCUBA_LEVEL_PACES = [0.19, 0.31, 0.38, 0.50, 0.62, 0.82, 0.94, 1.0];

export function scubaPace(level, shielded = false) {
  const pace = SCUBA_LEVEL_PACES[Math.max(0, Math.min(SCUBA_LEVEL_PACES.length - 1, level - 1))];
  return shielded && pace < SCUBA_BOOST_PACE ? SCUBA_BOOST_PACE : pace;
}

export const scubaMoveDriftY = (y, pace, dt = SCUBA_STEP_SECONDS) => y + pace * dt;
export const scubaMoveDriftX = (x, vx, dt = SCUBA_STEP_SECONDS) =>
  Math.max(0.06, Math.min(0.94, x + vx * dt));

export function scubaSpawnTick(elapsed, dt, interval) {
  const next = elapsed + dt;
  return next >= interval ? { elapsed: 0, spawn: true } : { elapsed: next, spawn: false };
}

export function scubaCollisionReach(kind, scale = 1) {
  return ({ shark: 0.09, puffer: 0.045 * scale, jelly: 0.055, pearl: 0.05 })[kind] ?? 0.045;
}

export function scubaOverlap(ax, ay, bx, by, reach) {
  const dx = ax - bx;
  const dy = ay - by;
  return dx * dx + dy * dy <= reach * reach;
}

export function scubaResolveContact({ kind, score, level, shieldSeconds }) {
  if (kind === "pearl") {
    return { score, level, shieldSeconds: SCUBA_PEARL_SHIELD_SECONDS, gameOver: false };
  }
  if (["shark", "puffer", "jelly"].includes(kind)) {
    return { score, level, shieldSeconds, gameOver: shieldSeconds <= 0 };
  }
  const nextScore = score + 1;
  return {
    score: nextScore,
    level: nextScore % 10 === 0 ? level + 1 : level,
    shieldSeconds,
    gameOver: false,
  };
}
