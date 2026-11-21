import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import * as rules from "../web/salon/scuba-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/scuba.vectors.json", import.meta.url), "utf8",
));
const close = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-10, `${actual} != ${expected}`);
const constants = contract.constants;
assert.equal(rules.SCUBA_STEP_SECONDS, constants.stepSeconds);
assert.equal(rules.SCUBA_BOOST_PACE, constants.boostPace);
assert.equal(rules.SCUBA_DIVER_HOME_Y, constants.diverHomeY);
assert.equal(rules.SCUBA_TRASH_SPAWN_SECONDS, constants.trashSpawnSeconds);
assert.equal(rules.SCUBA_ENEMY_SPAWN_SECONDS, constants.enemySpawnSeconds);
assert.equal(rules.SCUBA_PEARL_SPAWN_SECONDS, constants.pearlSpawnSeconds);
assert.equal(rules.SCUBA_PEARL_SHIELD_SECONDS, constants.pearlShieldSeconds);
assert.deepEqual(rules.SCUBA_LEVEL_PACES, constants.levelPaces);

for (const vector of contract.paceCases) test("Scuba pace level " + vector.level, () => {
  close(rules.scubaPace(vector.level, vector.shielded), vector.pace);
});
for (const vector of contract.driftCases) test("Scuba drift", () => {
  close(rules.scubaMoveDriftX(vector.x, vector.vx, vector.dt), vector.nextX);
  close(rules.scubaMoveDriftY(vector.y, vector.pace, vector.dt), vector.nextY);
});
for (const vector of contract.spawnCases) test("Scuba spawn timer", () => {
  const result = rules.scubaSpawnTick(vector.elapsed, vector.dt, vector.interval);
  close(result.elapsed, vector.nextElapsed);
  assert.equal(result.spawn, vector.spawn);
});
for (const vector of contract.reachCases) test("Scuba reach " + vector.kind, () => {
  close(rules.scubaCollisionReach(vector.kind, vector.scale), vector.reach);
});
for (const vector of contract.overlapCases) test("Scuba overlap", () => {
  assert.equal(rules.scubaOverlap(vector.ax,vector.ay,vector.bx,vector.by,vector.reach),vector.overlap);
});
for (const vector of contract.contactCases) test("Scuba contact " + vector.kind, () => {
  assert.deepEqual(rules.scubaResolveContact(vector), {
    score: vector.nextScore,
    level: vector.nextLevel,
    shieldSeconds: vector.nextShield,
    gameOver: vector.gameOver,
  });
});
