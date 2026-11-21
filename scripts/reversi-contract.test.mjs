import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  reversiApplyMove,
  reversiInitialBoard,
  reversiLegalMoves,
  reversiNextSide,
  reversiOutcome,
} from "../web/salon/reversi-rules.mjs";

const contract = JSON.parse(await readFile(
  new URL("../contracts/reversi.vectors.json", import.meta.url), "utf8",
));
const parse = (rows) => rows.join("").split("").map((cell) => ({ ".": 0, B: 1, W: 2 })[cell]);

test("Reversi standard opening and legal moves match the shared vectors", () => {
  assert.deepEqual(reversiInitialBoard(), parse(contract.initial));
  assert.deepEqual(reversiLegalMoves(reversiInitialBoard(), 1), contract.initialMoves.black);
  assert.deepEqual(reversiLegalMoves(reversiInitialBoard(), 2), contract.initialMoves.white);
});

for (const vector of contract.moves) {
  test("Reversi shared move: " + vector.name, () => {
    const result = reversiApplyMove(parse(contract.initial), vector.index, vector.side);
    if (vector.next === null) {
      assert.equal(result, null);
      assert.deepEqual(reversiLegalMoves(parse(contract.initial), vector.side).includes(vector.index), false);
      return;
    }
    assert.deepEqual(result.flips, vector.flips);
    assert.deepEqual(result.board, parse(vector.next));
    assert.equal(reversiNextSide(result.board, vector.side), vector.nextSide);
  });
}

test("Reversi skips a side without legal moves", () => {
  assert.equal(reversiNextSide(parse(contract.pass.board), contract.pass.currentSide), contract.pass.nextSide);
});

test("Reversi scores a terminal board and names the winner", () => {
  assert.deepEqual(reversiOutcome(parse(contract.finished.board)), contract.finished.outcome);
  assert.equal(reversiOutcome(parse(contract.initial)), null);
});
