import assert from 'node:assert/strict';
import test from 'node:test';
import { applyAction, classicWin, meldScore, view } from './game.mjs';
import { familyServer } from './server.mjs';

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
