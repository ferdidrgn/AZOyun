import assert from 'node:assert/strict';
import test from 'node:test';
import { familyServer } from './server.mjs';

test('shared family room API covers join, private state, reconnect, result and rematch', async (t) => {
  let now = 0;
  const server = familyServer({ clock: () => now });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const root = 'http://127.0.0.1:' + server.address().port + '/api/family/rooms';

  async function request(path, expected, input, bearer) {
    const response = await fetch(root + path, {
      method: input ? 'POST' : 'GET',
      headers: {
        ...(input && { 'Content-Type': 'application/json' }),
        ...(bearer && { Authorization: 'Bearer ' + bearer }),
      },
      body: input && JSON.stringify(input),
    });
    const data = await response.json();
    assert.equal(response.status, expected, JSON.stringify(data));
    return data;
  }

  const host = await request('', 201, { game: 'roles' });
  const path = '/' + host.code;
  const players = [];
  for (let seat = 0; seat < 6; seat++) {
    players.push(await request(path + '/join', 201, { name: 'Oyuncu ' + seat }));
  }
  const lobby = await request(path, 200, null, host.token);
  assert.equal(lobby.revision, 6);
  assert.equal(lobby.private, undefined);
  const started = await request(path + '/action', 200,
    { type: 'start', revision: lobby.revision }, host.token);
  assert.equal(started.status, 'playing');
  assert.equal(started.phase, 'night');

  const seats = await Promise.all(players.map(({ token }) => request(path, 200, null, token)));
  assert.deepEqual(seats.map(({ seat }) => seat), [0, 1, 2, 3, 4, 5]);
  assert.equal(new Set(seats.map(({ private: data }) => data.role)).size, 4);
  assert.ok(seats.every(({ players: roster }) =>
    roster.every((player) => !('role' in player) && !('token' in player))));
  const enemy = seats.findIndex(({ private: data }) => data.role === 'enemy');
  assert.notEqual(enemy, -1);

  // A phone returning before the reconnect grace keeps its seat and role.
  now = 119_999;
  const restored = await request(path, 200, null, players[enemy].token);
  assert.equal(restored.seat, enemy);
  assert.equal(restored.private.role, 'enemy');
  assert.equal(restored.phase, 'night');

  // All six participants submit through the same revisioned API used by both clients.
  let revision = restored.revision;
  const victim = seats.findIndex(({ private: data }) =>
    data.role !== 'enemy' && data.role !== 'guardian');
  for (let seat = 0; seat < players.length; seat++) {
    const role = seats[seat].private.role;
    const target = role === 'enemy' || role === 'seer' ? victim
      : role === 'guardian' ? seat : null;
    const result = await request(path + '/action', 200,
      { type: 'nightChoice', target, revision }, players[seat].token);
    revision = result.revision;
  }
  const discussion = await request(path, 200, null, players[0].token);
  assert.equal(discussion.phase, 'discussion');
  assert.equal(discussion.players[victim].out, true);
  assert.equal(discussion.events.at(-1).eliminated, victim);
  assert.equal(discussion.nightActions, undefined);

  const vote = await request(path + '/action', 200,
    { type: 'openVote', revision: discussion.revision }, host.token);
  revision = vote.revision;
  let finished;
  for (let seat = 0; seat < players.length; seat++) {
    if (seat === victim) continue;
    const result = await request(path + '/action', 200,
      { type: 'roleVote', target: seat === enemy ? null : enemy, revision }, players[seat].token);
    revision = result.revision;
    finished = result;
  }
  assert.equal(finished.status, 'finished');
  assert.equal(finished.teamWinner, 'village');
  assert.equal(finished.revealedRoles[enemy], 'enemy');
  assert.equal(finished.winner, null);

  const oldMatchId = finished.matchId;
  await request(path + '/action', 200,
    { type: 'rematch', revision: finished.revision }, host.token);
  const rematch = await request(path, 200, null, players[0].token);
  assert.equal(rematch.status, 'playing');
  assert.equal(rematch.phase, 'night');
  assert.notEqual(rematch.matchId, oldMatchId);
  assert.ok(rematch.players.every((player) => player.out === false));

  // A retried action from the previous screen revision is rejected, not double-applied.
  await request(path + '/action', 409,
    { type: 'openVote', revision: finished.revision }, host.token);
});
