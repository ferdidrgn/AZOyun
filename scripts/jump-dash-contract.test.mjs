import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import * as rules from "../web/salon/jump-dash-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/jump-dash.vectors.json", import.meta.url), "utf8",
));
const constants = contract.constants;
assert.equal(rules.JUMP_DASH_GRAVITY, constants.gravity);
assert.equal(rules.JUMP_DASH_IMPULSE, constants.jumpImpulse);
assert.equal(rules.JUMP_DASH_PIPE_SPEED, constants.pipeSpeed);
assert.equal(rules.JUMP_DASH_PIPE_WIDTH, constants.pipeWidth);
assert.equal(rules.JUMP_DASH_GAP_HALF, constants.gapHalf);
assert.equal(rules.JUMP_DASH_BIRD_X, constants.birdX);
assert.equal(rules.JUMP_DASH_BIRD_RADIUS, constants.birdRadius);
assert.equal(rules.JUMP_DASH_SPAWN_THRESHOLD, constants.spawnThreshold);

for (const vector of contract.cases) {
  test("Jump Dash shared rule: " + vector.name, () => {
    if ("nextVelocity" in vector) assert.ok(Math.abs(rules.jumpDashNextVelocity(vector.velocity) - vector.nextVelocity) < 1e-12);
    if ("nextBirdY" in vector) assert.ok(Math.abs(rules.jumpDashNextBirdY(vector.birdY, vector.velocity) - vector.nextBirdY) < 1e-12);
    if ("nextPipeX" in vector) assert.ok(Math.abs(rules.jumpDashNextPipeX(vector.pipeX) - vector.nextPipeX) < 1e-12);
    if ("shouldSpawn" in vector) assert.equal(rules.jumpDashShouldSpawn(vector.spawnTimer), vector.shouldSpawn);
    if ("passed" in vector) assert.equal(rules.jumpDashPipePassed(vector.pipeX), vector.passed);
    if ("collision" in vector) assert.equal(rules.jumpDashCollision(vector.birdY, vector.pipeX, vector.gapCenter), vector.collision);
  });
}

