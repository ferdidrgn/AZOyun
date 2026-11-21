import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { nimApplyMove } from "../web/salon/nim-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/nim.vectors.json", import.meta.url),
  "utf8",
));

assert.deepEqual(contract.initialPiles, [3, 5, 7, 9]);
for (const testCase of contract.cases) {
  test("Nim shared rule: " + testCase.name, () => {
    assert.deepEqual(
      nimApplyMove(testCase.piles, testCase.pileIndex, testCase.remove),
      { piles: testCase.nextPiles, finished: testCase.finished },
    );
  });
}

for (const [index, testCase] of contract.invalidCases.entries()) {
  test("Nim rejects illegal move " + (index + 1), () => {
    assert.throws(() => nimApplyMove(
      testCase.piles,
      testCase.pileIndex,
      testCase.remove,
    ));
  });
}
