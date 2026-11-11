import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { applyAction, classicWin, meldScore, view } from './game.mjs';
import { familyServer } from './server.mjs';

async function roomClient(t, options) {
  const server = familyServer(options);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const close = () => new Promise((resolve) => server.close(resolve));
  t.after(close);
  const root = 'http://127.0.0.1:' + server.address().port + '/api/family/rooms';
  return {
    close,
    origin: new URL(root).origin,
    async request(path, status, input, bearer) {
      const response = await fetch(root + path, {
        method: input ? 'POST' : 'GET',
        headers: {
          ...(bearer && { Authorization: 'Bearer ' + bearer }),
          ...(input && { 'Content-Type': 'application/json' }),
        },
        body: input && JSON.stringify(input),
      });
      const result = await response.json();
      assert.equal(response.status, status, JSON.stringify(result));
      return result;
    },
  };
}

test('authenticated polling preserves seats within the reconnect grace; TV and spectators do not keep an abandoned game', async (t) => {
  let now = 0;
  const { request } = await roomClient(t, { clock: () => now });
  const host = await request('', 201, { game: 'city' });
  const path = '/' + host.code;
  const first = await request(path + '/join', 201, { name: 'Ada' });
  const second = await request(path + '/join', 201, { name: 'Bora' });
  await request(path + '/action', 200, { type: 'start', revision: 2 }, host.token);
  now = 119_999;
  const restored = await request(path, 200, null, first.token);
  assert.equal(restored.seat, 0);
  assert.equal(restored.players.length, 2);
  now = 120_000;
  await request(path, 200, null, host.token);
  await request(path, 200);
  now = 239_998;
  await request(path, 200, null, host.token);
  await request(path, 200);
  now = 239_999;
  await request(path, 404, null, second.token);
});

test('offline lobby seats are reclaimed while a remaining guest keeps the room', async (t) => {
  let now = 0;
  const { request } = await roomClient(t, { clock: () => now });
  const host = await request('', 201, { game: 'city' });
  const path = '/' + host.code;
  const departed = await request(path + '/join', 201, { name: 'Ada' });
  const staying = await request(path + '/join', 201, { name: 'Bora' });
  now = 60_000;
  await request(path, 200, null, staying.token);
  now = 120_000;
  const current = await request(path, 200, null, host.token);
  assert.deepEqual(current.players.map((player) => player.name), ['Bora']);
  assert.equal(current.revision, 3);
  await request(path, 401, null, departed.token);
  await request(path + '/join', 201, { name: 'Deniz' });
});

test('finished rooms expire despite polling, are removed from storage and cannot reappear after restart', async (t) => {
  const directory = await mkdtemp(join(tmpdir(), 'azoyun-room-state-'));
  const stateFile = join(directory, 'rooms.json');
  t.after(() => rm(directory, { recursive: true }));
  let now = 0;
  const options = { stateFile, clock: () => now };
  const first = await roomClient(t, options);
  const host = await first.request('', 201, { game: 'city' });
  const path = '/' + host.code;
  const guest = await first.request(path + '/join', 201, { name: 'Ada' });
  await first.request(path + '/action', 200, { type: 'close', revision: 1 }, host.token);
  now = 59_999;
  const result = await first.request(path, 200, null, guest.token);
  assert.equal(result.status, 'finished');
  assert.equal(result.completed, false);
  assert.match(result.matchId, /^[a-f0-9-]{36}$/);
  now = 60_000;
  await first.request(path, 404);
  assert.deepEqual(JSON.parse(await readFile(stateFile, 'utf8')), []);
  await first.close();
  const restarted = await roomClient(t, options);
  await restarted.request(path, 404, null, host.token);
});

test('natural tie is completed and exposes stable match identity only to the signed-in seat', async (t) => {
  const directory = await mkdtemp(join(tmpdir(), 'azoyun-room-result-'));
  const stateFile = join(directory, 'rooms.json');
  const progressionStateFile = join(directory, 'profiles.json');
  t.after(() => rm(directory, { recursive: true }));
  const playerToken = 'a'.repeat(32);
  const profileToken = 'p'.repeat(43);
  const profileId = createHash('sha256').update(profileToken).digest('hex');
  const room = {
    game: 'okey', matchId: 'result-one', status: 'playing', revision: 3, turn: 0,
    phase: 'draw', stock: [], created: 0, updated: 0, host: 'b'.repeat(32),
    players: [{ name: 'Ada', token: playerToken, hand: [], profileId }],
  };
  await writeFile(stateFile, JSON.stringify([['ABC234', room]]));
  await writeFile(progressionStateFile, JSON.stringify({ players: {
    [profileId]: { name: 'Ada', xp: 0, wins: 0, played: 0, games: [], badges: [] },
  }, receipts: {} }));
  const { request, origin } = await roomClient(t, { stateFile, progressionStateFile, clock: () => 0 });
  const result = await request('/ABC234/action', 200, { type: 'draw', revision: 3 }, playerToken);
  assert.equal(result.status, 'finished');
  assert.equal(result.winner, null);
  assert.equal(result.completed, true);
  assert.equal(result.matchId, 'result-one');
  const publicRoom = await request('/ABC234', 200);
  assert.equal(publicRoom.matchId, undefined);
  assert.equal(publicRoom.completed, undefined);
  assert.equal(JSON.stringify(publicRoom).includes(profileId), false);
  const profile = await fetch(origin + '/api/progression/profile', {
    headers: { Authorization: 'Bearer ' + profileToken },
  }).then((response) => response.json());
  assert.deepEqual([profile.xp, profile.played, profile.wins], [1, 1, 0]);
});

test('static hosting keeps TV and phone query routes and resolves arcade and module files', async (t) => {
  const root = await mkdtemp(join(tmpdir(), 'azoyun-web-'));
  await mkdir(join(root, 'arcade3d'));
  await Promise.all([
    writeFile(join(root, 'index.html'), '<title>Oyun Salonu</title>'),
    writeFile(join(root, 'arcade3d', 'index.html'), '<title>AZ Oyun 3D</title>'),
    writeFile(join(root, 'table.mjs'), 'export {};'),
  ]);
  const server = familyServer({ webRoot: root });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => {
    await new Promise((resolve) => server.close(resolve));
    await rm(root, { recursive: true });
  });
  const url = 'http://127.0.0.1:' + server.address().port;
  for (const route of ['/?family=tv', '/?family=ABC234']) {
    const response = await fetch(url + route);
    assert.equal(await response.text(), '<title>Oyun Salonu</title>');
  }
  const arcade = await fetch(url + '/arcade3d/?game=maze');
  assert.equal(await arcade.text(), '<title>AZ Oyun 3D</title>');
  const module = await fetch(url + '/table.mjs');
  assert.equal(module.headers.get('content-type'), 'application/javascript');
  assert.equal(await module.text(), 'export {};');
});

test('four phones join, receive separate hands and submit versioned turns', async (t) => {
  const server = familyServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const root = 'http://127.0.0.1:' + server.address().port + '/api/family/rooms';
  async function request(path, expected, input, token) {
    const response = await fetch(root + path, {
      method: input ? 'POST' : 'GET',
      headers: { ...(token && { Authorization: 'Bearer ' + token }),
        ...(input && { 'Content-Type': 'application/json' }) },
      body: input && JSON.stringify(input),
    });
    const result = await response.json();
    assert.equal(response.status, expected, JSON.stringify(result));
    return result;
  }
  const host = await request('', 201, { game: 'okey' });
  const path = '/' + host.code;
  const tokens = [];
  for (const name of ['Ece', 'Ada', 'Bora', 'Deniz']) {
    tokens.push((await request(path + '/join', 201, { name })).token);
  }
  await request(path + '/join', 409, { name: 'Beşinci' });
  const lobby = await request(path, 200);
  const start = { type: 'start', revision: lobby.revision };
  await request(path + '/action', 401, start);
  await request(path + '/action', 400, start, tokens[0]);
  const table = await request(path + '/action', 200, start, host.token);
  const phones = await Promise.all(tokens.map((token) => request(path, 200, null, token)));
  assert.deepEqual(phones.map((phone) => phone.private.hand.length), [15, 14, 14, 14]);
  assert.equal(new Set(phones.flatMap((phone) => phone.private.hand.map((tile) => tile.id))).size, 57);
  const publicTable = await request(path, 200);
  for (const projection of [table, publicTable]) {
    assert.equal(projection.private, undefined);
    assert.equal(projection.stock, undefined);
    assert.ok(projection.players.every((player) => !player.hand && !player.token));
  }
  const tile = phones[0].private.hand[0].id;
  const discard = { type: 'discard', tile, revision: table.revision };
  await request(path + '/action', 400, discard, tokens[1]);
  const after = await request(path + '/action', 200, discard, tokens[0]);
  await request(path + '/action', 409, discard, tokens[0]);
  const drawn = await request(path + '/action', 200,
    { type: 'draw', source: 'discard', revision: after.revision }, tokens[1]);
  assert.equal(drawn.private.hand.at(-1).id, tile);
  assert.equal(drawn.discards[0], null);
  await request(path + '/join', 409, { name: 'Geç Gelen' });
  const restored = await request(path, 200, null, tokens[1]);
  assert.deepEqual(restored.private, drawn.private);
});

test('Okey validates pairs and 101 opening, extension and required discard use', () => {
  const indicator = { id: 90, color: 3, value: 13 };
  const tile = (id, color, value) => ({ id, color, value });
  const pairs = Array.from({ length: 14 }, (_, i) => tile(i, 0, 1 + Math.floor(i / 2)));
  assert.ok(classicWin(pairs, indicator));
  assert.equal(classicWin(pairs.slice(1), indicator), false);
  assert.equal(meldScore([tile(70, 1, 12), tile(71, 1, 13), tile(72, 1, 1)], indicator), 26);
  const room = { game: 'okey101', status: 'lobby',
    players: ['Ece', 'Ada', 'Bora', 'Deniz'].map((name) => ({ name })) };
  applyAction(room, -1, { type: 'start' }, () => 0);
  assert.deepEqual(room.players.map((player) => player.hand.length), [22, 21, 21, 21]);
  room.indicator = indicator;
  room.players[0].hand = [
    ...[10, 11, 12].map((value, i) => tile(i, 0, value)),
    ...[11, 12, 13].map((value, i) => tile(i + 3, 1, value)),
    ...[0, 1, 2].map((color, i) => tile(i + 6, color, 12)),
    tile(9, 0, 13), tile(10, 1, 2),
  ];
  assert.throws(() => applyAction(room, 0, { type: 'meld', groups: [[0, 1, 2]] }), /101/);
  applyAction(room, 0, { type: 'meld', groups: [[0, 1, 2], [3, 4, 5], [6, 7, 8]] });
  applyAction(room, 0, { type: 'extend', tile: 9, index: 0 });
  applyAction(room, 0, { type: 'discard', tile: 10 });
  assert.equal(room.winner, 0);
  assert.equal(view(room, -1).melds[0].tiles.length, 4);
  room.status = 'playing';
  room.turn = 1;
  room.phase = 'draw';
  applyAction(room, 1, { type: 'draw', source: 'discard' });
  assert.throws(() => applyAction(room, 1, { type: 'discard', tile: 10 }), /grupta/);
  applyAction(room, 1, { type: 'returnDiscard' });
  assert.equal(room.discards[0].id, 10);
});

test('Mahalleler validates auctions, private sales, building, rent and bankruptcy', () => {
  const room = { game: 'city', status: 'lobby', players: ['Ada', 'Bora', 'Deniz'].map((name) => ({ name })) };
  const move = (seat, type, details) => applyAction(room, seat, { type, ...details });
  move(-1, 'start');
  const dice = [0, 1];
  applyAction(room, 0, { type: 'roll' }, () => dice.shift());
  move(0, 'auction');
  assert.throws(() => move(1, 'bid'), /sırası/);
  move(0, 'bid');
  move(1, 'passBid');
  move(2, 'passBid');
  assert.deepEqual(room.deeds[3], { owner: 0, level: 0 });
  move(0, 'trade', { square: 3, to: 1, price: 25 });
  assert.equal(view(room, -1).private, undefined);
  assert.equal(view(room, 2).private.trade, undefined);
  assert.equal(view(room, 1).private.trade.price, 25);
  assert.throws(() => move(2, 'tradeReply', { accept: true }), /ait değil/);
  move(1, 'tradeReply', { accept: true });
  assert.deepEqual(room.players.map((player) => player.money), [515, 475, 500]);
  move(0, 'end');
  assert.throws(() => move(1, 'build', { square: 3 }), /iki mülkü/);
  room.deeds[1] = { owner: 1, level: 0 };
  move(1, 'build', { square: 3 });
  assert.equal(room.deeds[3].level, 1);
  room.turn = 2;
  room.players[2].money = 5;
  const rentDice = [0, 1];
  applyAction(room, 2, { type: 'roll' }, () => rentDice.shift());
  assert.equal(room.players[2].out, true);
  assert.equal(room.players[1].money, 420);
});
