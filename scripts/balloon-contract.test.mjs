import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  BALLOON_LIFETIME_MS,
  BALLOON_SCORE,
  BALLOON_SESSION_SECONDS,
  popBalloon,
  tickBalloonSession,
} from "../web/salon/balloon-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/balloon.vectors.json", import.meta.url), "utf8",
));

assert.equal(contract.sessionSeconds, BALLOON_SESSION_SECONDS);
assert.equal(contract.balloonLifetimeMs, BALLOON_LIFETIME_MS);
assert.equal(contract.scorePerPop, BALLOON_SCORE);

for (const testCase of contract.popCases) {
  test("Balloon shared pop: " + testCase.name, () => {
    assert.deepEqual(popBalloon(testCase), {
      score: testCase.nextScore,
      popped: testCase.popped,
    });
  });
}

for (const testCase of contract.tickCases) {
  test("Balloon shared countdown: " + testCase.secondsLeft, () => {
    assert.deepEqual(tickBalloonSession(testCase.secondsLeft), {
      secondsLeft: testCase.nextSeconds,
      running: testCase.running,
    });
  });
}

