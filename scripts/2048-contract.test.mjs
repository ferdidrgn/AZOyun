import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { apply2048Move } from "../web/salon/2048-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/2048.vectors.json", import.meta.url),
  "utf8",
));

for (const testCase of contract.cases) {
  test("2048 shared rule: " + testCase.name, () => {
    const result = apply2048Move(testCase.board, testCase.direction);
    assert.deepEqual(result, {
      board: testCase.nextBoard,
      score: testCase.score,
      changed: testCase.changed,
      gameOver: testCase.gameOver,
      won: testCase.won,
    });
  });
}

