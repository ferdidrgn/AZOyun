import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  connectFourDropRow,
  connectFourOutcome,
} from "../web/salon/connect-four-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/connect4.vectors.json", import.meta.url),
  "utf8",
));
const decode = (rows) => rows.flatMap((row) =>
  [...row].map((cell) => cell === "." ? null : cell));

for (const testCase of contract.cases) {
  test("Connect Four shared rule: " + testCase.name, () => {
    const outcome = connectFourOutcome(decode(testCase.board));
    assert.deepEqual(outcome, {
      winner: testCase.winner,
      winningLine: testCase.winningLine,
      draw: testCase.draw,
    });
  });
}

for (const testCase of contract.dropCases) {
  test("Connect Four shared drop: " + testCase.name, () => {
    assert.equal(connectFourDropRow(decode(testCase.board), testCase.column),
      testCase.row);
  });
}
