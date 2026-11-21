import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { ticTacToeOutcome } from "../web/salon/tic-tac-toe-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/xox.vectors.json", import.meta.url),
  "utf8",
));

for (const testCase of contract.cases) {
  test("XOX shared rule: " + testCase.name, () => {
    assert.deepEqual(ticTacToeOutcome(testCase.board), {
      winner: testCase.winner,
      winningLine: testCase.winningLine,
      draw: testCase.draw,
    });
  });
}
