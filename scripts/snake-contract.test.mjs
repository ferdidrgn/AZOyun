import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { canTurnSnake, stepSnake } from "../web/salon/snake-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/snake.vectors.json", import.meta.url), "utf8",
));

for (const testCase of contract.cases) {
  test("Snake shared rule: " + testCase.name, () => {
    const result = stepSnake(testCase.snake, testCase.direction, testCase.food);
    assert.deepEqual(result, {
      snake: testCase.nextSnake,
      ate: testCase.ate,
      collided: testCase.collided,
      score: testCase.score,
    });
  });
}

for (const testCase of contract.turnCases) {
  test("Snake turn rule: " + testCase.current + " to " + testCase.next, () => {
    assert.equal(canTurnSnake(testCase.current, testCase.next), testCase.allowed);
  });
}

