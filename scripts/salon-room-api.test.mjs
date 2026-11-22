import assert from 'node:assert/strict';
import test from 'node:test';
import { apiCandidates, discoverApiOrigin, requestRoomApi } from '../web/salon/room-api.mjs';

test('room API candidates prefer configured/discovered Firebase origin and keep hosting fallback', () => {
  assert.deepEqual(apiCandidates({
    pageOrigin: 'https://azoyun.web.app',
    configuredOrigin: 'https://api.example.test',
    discoveredOrigin: 'https://api.example.test',
  }), ['https://api.example.test', 'https://azoyun.web.app']);
});

test('room API discovers the build-time family-api.json origin', async () => {
  const origin = await discoverApiOrigin(async () => ({
    ok: true,
    headers: new Headers({ 'content-type': 'application/json; charset=utf-8' }),
    async json() { return { origin: 'https://firebase.example.test' }; },
  }), 'https://azoyun.web.app');
  assert.equal(origin, 'https://firebase.example.test');
});

test('room API retries a static-hosting HTML response on the Firebase candidate', async () => {
  const calls = [];
  const response = (type, body, ok = true, status = 200) => ({
    ok, status, headers: new Headers({ 'content-type': type }), async json() { return body; },
  });
  const { result, origin } = await requestRoomApi({
    fetchImpl: async (url) => {
      calls.push(url);
      return calls.length === 1
        ? response('text/html', '<!doctype html>')
        : response('application/json', { code: 'ABCD23', token: 'host-token' }, true, 201);
    },
    origins: ['https://azoyun.web.app', 'https://firebase.example.test'],
    path: '', data: { game: 'city' },
  });
  assert.equal(origin, 'https://firebase.example.test');
  assert.equal(result.code, 'ABCD23');
  assert.deepEqual(calls, [
    'https://azoyun.web.app/api/family/rooms',
    'https://firebase.example.test/api/family/rooms',
  ]);
});
