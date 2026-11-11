import test from 'node:test';
import assert from 'node:assert/strict';
import { emptyGrace, finishedRetention, sweepRoom } from './room-cleanup-policy.mjs';

const now = 1_000_000_000;
const tracked = { p1: true, p2: true };
const room = { status: 'playing', createdAt: now - 30_000, players: { p1: {}, p2: {} } };

test('an unknown client in an active legacy room prevents deletion', () => {
  assert.equal(sweepRoom(room, now), undefined);
  assert.equal(sweepRoom({ ...room, _lifecycle: { tracked: { p1: true } } }, now), undefined);
  assert.equal(sweepRoom({ ...room, createdAt: null, _lifecycle: { tracked } }, now), undefined);
});

test('host disconnect does not remove a room with another live connection', () => {
  assert.equal(sweepRoom({ ...room, _lifecycle: { tracked, connections: { session: 'p2' } } }, now), undefined);
});

test('empty tracked rooms get a grace period and a returning connection cancels deletion', () => {
  const marked = sweepRoom({ ...room, _lifecycle: { tracked } }, now);
  assert.equal(marked._lifecycle.emptySince, now);
  assert.equal(sweepRoom(marked, now + emptyGrace - 1), undefined);
  assert.equal(sweepRoom(marked, now + emptyGrace), null);
  const returned = { ...marked, _lifecycle: { ...marked._lifecycle, connections: { back: 'p1' } } };
  assert.equal(sweepRoom(returned, now + emptyGrace)._lifecycle.emptySince, undefined);
});

test('completed rooms retain the result before deletion, even with old creation time', () => {
  const marked = sweepRoom({ ...room, status: 'finished', createdAt: 1 }, now);
  assert.equal(marked._lifecycle.finishedSince, now);
  assert.equal(sweepRoom(marked, now + finishedRetention - 1), undefined);
  assert.equal(sweepRoom(marked, now + finishedRetention), null);
});

test('Sprint uses phase rather than status for completed rooms', () => {
  const sprint = { ...room, mode: 'bluff', phase: 'finished', status: undefined };
  const marked = sweepRoom(sprint, now);
  assert.equal(marked._lifecycle.finishedSince, now);
  assert.equal(sweepRoom(marked, now + finishedRetention), null);
});
