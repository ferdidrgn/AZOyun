import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const root = fileURLToPath(new URL("../", import.meta.url));
const read = (relative) => readFile(join(root, relative), "utf8");
const exists = (relative) => access(join(root, relative));

const contracts = [
  ["2048", "2048.vectors.json"],
  ["balloon", "balloon.vectors.json"],
  ["connect-four", "connect4.vectors.json"],
  ["jump-dash", "jump-dash.vectors.json"],
  ["monkey", "monkey.vectors.json"],
  ["nim", "nim.vectors.json"],
  ["reversi", "reversi.vectors.json"],
  ["scuba", "scuba.vectors.json"],
  ["snake", "snake.vectors.json"],
  ["tic-tac-toe", "xox.vectors.json"],
];
const dartTests = new Map([
  ["2048", "game_2048_rules_test.dart"],
  ["connect-four", "connect_four_rules_test.dart"],
  ["tic-tac-toe", "tic_tac_toe_rules_test.dart"],
]);
const dartTestFor = (name) => dartTests.get(name) ?? `${name.replaceAll("-", "_")}_rules_test.dart`;

test("QA-01: all shared contract vectors are present and non-empty", async () => {
  for (const [, file] of contracts) {
    const vector = JSON.parse(await read(`contracts/${file}`));
    assert.ok(Object.keys(vector).length > 0, file);
  }
});

test("QA-02: every shared contract has a Flutter test", async () => {
  for (const [name] of contracts) {
    await exists(`test/${dartTestFor(name)}`);
  }
});

test("QA-03: every shared contract has a Node contract test", async () => {
  for (const [name] of contracts) await exists(`scripts/${name}-contract.test.mjs`);
});

test("QA-04: every Node contract test uses the built-in test runner", async () => {
  for (const [name] of contracts) {
    const source = await read(`scripts/${name}-contract.test.mjs`);
    assert.match(source, /from ["']node:test["']/u, name);
    assert.match(source, /assert\./u, name);
  }
});

test("QA-05: contract vectors are referenced by both test layers", async () => {
  for (const [name, file] of contracts) {
    const dart = dartTestFor(name);
    assert.match(await read(`test/${dart}`), new RegExp(file.replace(".", "\\."), "u"), dart);
    assert.match(await read(`scripts/${name}-contract.test.mjs`), new RegExp(file.replace(".", "\\."), "u"), name);
  }
});

test("QA-06: hosting CI runs every shared contract test", async () => {
  const workflow = await read(".github/workflows/firebase-hosting-deploy.yml");
  for (const [name] of contracts) assert.ok(workflow.includes(`scripts/${name}-contract.test.mjs`), name);
});

test("QA-07: hosting CI keeps publishing checks in the test job", async () => {
  const workflow = await read(".github/workflows/firebase-hosting-deploy.yml");
  assert.match(workflow, /node --test scripts\/web-publishing\.test\.mjs/u);
  assert.match(workflow, /deploy:\s*\n\s*needs: test/u);
});

test("QA-08: Android CI runs Flutter tests before producing an AAB", async () => {
  const workflow = await read(".github/workflows/play-store-deploy.yml");
  assert.match(workflow, /run: flutter test/u);
  assert.ok(workflow.indexOf("run: flutter test") < workflow.indexOf("flutter build appbundle"));
});

test("QA-09: release docs distinguish static checks from device checks", async () => {
  const docs = await read("docs/RELEASE_CHECKLIST.md");
  assert.match(docs, /gerçek cihazda çalışma testi yerine geçmez/u);
  assert.match(docs, /iki cihazda Saved Games/u);
});

test("QA-10: Android bundle validation is shipped and documented", async () => {
  await exists("scripts/check-android-bundle.py");
  const docs = await read("docs/RELEASE_CHECKLIST.md");
  assert.match(docs, /scripts\/check-android-bundle\.py/u);
});
