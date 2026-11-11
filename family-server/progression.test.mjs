import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { createProgression } from './progression.mjs';

test('profiles grant small capped XP once, persist medals and redact their key', async (t) => {
  const directory = await mkdtemp(join(tmpdir(), 'az-progression-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const stateFile = join(directory, 'profiles.json');
  let clock = Date.UTC(2026, 10, 11);
  let progression = createProgression({ stateFile, now: () => clock });
  const server = createServer((req, res) => progression.handle(req, res, new URL(req.url, 'http://localhost')));
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const root = 'http://127.0.0.1:' + server.address().port + '/api/progression';
  async function get(route, key) {
    return fetch(root + route, { headers: key ? { Authorization: 'Bearer ' + key } : {} });
  }
  const created = await fetch(root + '/profile', { method: 'POST', body: JSON.stringify({ name: 'Ada' }) });
  assert.equal(created.status, 201);
  const { key } = await created.json();
  const profileId = progression.resolveToken(key);
  assert.ok(profileId);
  assert.equal((await get('/profile', 'wrong')).status, 401);

  const award = (matchId, winner) => progression.award({
    roomCode: 'ABC234', room: { matchId, winner, game: 'city', players: [{ profileId }] },
  });
  award('m1', 0);
  award('m1', 0);
  let profile = await (await get('/profile', key)).json();
  assert.deepEqual([profile.xp, profile.played, profile.wins], [3, 1, 1]);
  assert.deepEqual(profile.badges, ['first-table', 'first-win']);
  for (let n = 2; n <= 12; n++) award('m' + n, null);
  profile = await (await get('/profile', key)).json();
  assert.deepEqual([profile.xp, profile.played, profile.wins], [12, 12, 1]);
  assert.ok(profile.badges.includes('five-tables'));

  progression = createProgression({ stateFile, now: () => clock });
  award('m1', 0);
  clock += 86400000;
  award('tomorrow', 0);
  const board = await (await get('/leaderboard')).json();
  assert.deepEqual(board.players.map(({ name, xp, played }) => ({ name, xp, played })), [
    { name: 'Ada', xp: 15, played: 13 },
  ]);
  assert.equal(JSON.stringify(board).includes(key), false);
  assert.equal(JSON.stringify(board).includes(profileId), false);
  assert.equal((await readFile(stateFile, 'utf8')).includes(key), false);
});
