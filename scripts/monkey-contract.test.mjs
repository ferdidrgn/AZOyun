import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  MONKEY_MOVE_INTERVAL_MS,
  MONKEY_SCORE,
  MONKEY_SESSION_SECONDS,
  tapMonkey,
  tickMonkeySession,
} from "../web/salon/monkey-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/monkey.vectors.json", import.meta.url), "utf8",
));

assert.equal(contract.sessionSeconds, MONKEY_SESSION_SECONDS);
assert.equal(contract.moveIntervalMs, MONKEY_MOVE_INTERVAL_MS);
assert.equal(contract.scorePerHit, MONKEY_SCORE);

for (const testCase of contract.tapCases) {
  test("Monkey shared tap: " + testCase.name, () => {
    assert.deepEqual(tapMonkey(testCase), {
      score: testCase.nextScore,
      hit: testCase.hit,
    });
  });
}

for (const testCase of contract.tickCases) {
  test("Monkey shared countdown: " + testCase.secondsLeft, () => {
    assert.deepEqual(tickMonkeySession(testCase.secondsLeft), {
      secondsLeft: testCase.nextSeconds,
      running: testCase.running,
    });
  });
}

