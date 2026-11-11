import { createServer } from 'node:http';
import { randomBytes, randomInt, randomUUID } from 'node:crypto';
import { createReadStream, existsSync, readFileSync, renameSync, statSync, writeFileSync } from 'node:fs';
import { extname, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';

import { applyAction, games, view } from './game.mjs';
import { createProgression } from './progression.mjs';

const lifetime = 8 * 60 * 60 * 1000;
const reconnectGrace = 2 * 60 * 1000;
const finishedRetention = 60 * 1000;
const emptyLobbyLifetime = 15 * 60 * 1000;
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const token = () => randomBytes(24).toString('base64url');
const media = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.mjs': 'application/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css',
  '.txt': 'text/plain; charset=utf-8', '.xml': 'application/xml; charset=utf-8',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.woff2': 'font/woff2',
};

async function body(request) {
  let buffer = '';
  for await (const chunk of request) {
    buffer += chunk;
    if (buffer.length > 8192) throw new Error('İstek çok büyük.');
  }
  return JSON.parse(buffer || '{}');
}

export function familyServer({
  webRoot = 'build/salon', stateFile, progressionStateFile, origins = [], clock = Date.now,
} = {}) {
  const root = resolve(webRoot);
  const rooms = new Map(stateFile && existsSync(stateFile)
    ? JSON.parse(readFileSync(stateFile, 'utf8')) : []);
  const attempts = new Map();
  const presence = new Map();
  const bootedAt = clock();
  const progression = createProgression({ stateFile: progressionStateFile, now: clock });
  function writeSnapshot(snapshot) {
    if (!stateFile) return;
    writeFileSync(stateFile + '.tmp', JSON.stringify([...snapshot]), { mode: 0o600 });
    renameSync(stateFile + '.tmp', stateFile);
  }
  function save(code, room) {
    if (stateFile) {
      const snapshot = new Map(rooms);
      snapshot.set(code, room);
      writeSnapshot(snapshot);
    }
    rooms.set(code, room);
  }
  function seen(code, bearer, now) {
    const activity = presence.get(code) ?? new Map();
    activity.set(bearer, now);
    presence.set(code, activity);
  }
  function settleRewards(code, room) {
    if (!room?.rewardPending) return;
    try {
      progression.award({ roomCode: code, room });
      const next = { ...room };
      delete next.rewardPending;
      save(code, next);
    } catch (error) {
      console.error('Masa ödülleri kaydedilemedi:', error);
    }
  }
  function purge(now, onlyCode) {
    const candidates = onlyCode ? [onlyCode] : [...rooms.keys()];
    if (!onlyCode) for (const code of candidates) settleRewards(code, rooms.get(code));
    const changes = [];
    for (const code of candidates) {
      const room = rooms.get(code);
      if (!room) continue;
      const activity = presence.get(code);
      const lastSeen = (bearer) => activity?.get(bearer) ?? Math.max(room.updated, bootedAt);
      const players = room.players.filter((player) => now - lastSeen(player.token) < reconnectGrace);
      const created = room.created ?? room.updated;
      const hasPlayed = room.hadPlayers || room.players.length > 0;
      const expired = now - created >= lifetime ||
        (room.status === 'finished'
          ? !room.rewardPending && now - (room.finishedAt ?? room.updated) >= finishedRetention
          : hasPlayed
            ? !players.length && (room.players.length > 0 || now - room.updated >= reconnectGrace)
            : now - created >= emptyLobbyLifetime || now - lastSeen(room.host) >= reconnectGrace);
      if (expired) {
        changes.push([code, null]);
      } else if (room.status === 'lobby' && players.length !== room.players.length) {
        const next = { ...room, players, revision: room.revision + 1 };
        changes.push([code, next]);
      }
    }
    if (changes.length && stateFile) {
      const snapshot = new Map(rooms);
      for (const [code, room] of changes) {
        if (room) snapshot.set(code, room);
        else snapshot.delete(code);
      }
      writeSnapshot(snapshot);
    }
    for (const [code, room] of changes) {
      if (!room) {
        rooms.delete(code);
        presence.delete(code);
      } else {
        const activeTokens = new Set([room.host, ...room.players.map((player) => player.token)]);
        const activity = presence.get(code);
        if (activity) for (const bearer of activity.keys()) if (!activeTokens.has(bearer)) activity.delete(bearer);
        rooms.set(code, room);
      }
    }
    if (!onlyCode) for (const [address, entry] of attempts) if (entry.until <= now) attempts.delete(address);
  }
  purge(bootedAt);
  const timer = setInterval(() => {
    try { purge(clock()); }
    catch (error) { console.error('Aile masası temizlenemedi:', error); }
  }, 15_000);
  timer.unref();
  function roomProjection(code, room, seat, authenticated) {
    return {
      code,
      ...view(room, authenticated ? seat : -2),
      ...(authenticated && { seat }),
      ...(seat >= 0 && authenticated && { matchId: room.matchId, completed: room.completed === true }),
    };
  }

  const server = createServer(async (request, response) => {
    const url = new URL(request.url, 'http://localhost');
    const origin = request.headers.origin;
    if (origin && origins.includes(origin)) {
      response.setHeader('Access-Control-Allow-Origin', origin);
      response.setHeader('Vary', 'Origin');
      response.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      response.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    }
    if (request.method === 'OPTIONS') return response.writeHead(204).end();
    const json = (status, data) => response.writeHead(status, {
      'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store',
    }).end(JSON.stringify(data));

    if (url.pathname.startsWith('/api/progression/')) {
      try {
        const handled = await progression.handle(request, response, url);
        if (!handled && !response.writableEnded) return json(404, { error: 'İstek bulunamadı.' });
      } catch (error) {
        if (!response.headersSent) return json(400, { error: error.message });
        response.end();
      }
      return;
    }

    if (url.pathname.startsWith('/api/family/')) {
      try {
        if (url.pathname === '/api/family/health' && request.method === 'GET') return json(200, { ok: true });
        const match = url.pathname.match(/^\/api\/family\/rooms(?:\/([A-Z2-9]{6}))?(?:\/(join|action))?$/);
        if (!match) return json(404, { error: 'İstek bulunamadı.' });
        const [, code, operation] = match;
        const method = request.method;
        const input = method === 'POST' ? await body(request) : {};
        const now = clock();
        if (method === 'POST' && (!code || operation === 'join')) {
          const address = request.socket.remoteAddress ?? '';
          const entry = attempts.get(address) ?? { until: now + 60_000, count: 0 };
          if (entry.until <= now) {
            entry.until = now + 60_000;
            entry.count = 0;
          }
          if (++entry.count > 120) return json(429, { error: 'Bir dakika sonra tekrar dene.' });
          attempts.set(address, entry);
        }
        if (!code && method === 'POST') {
          purge(now);
          if (!games.includes(input.game)) return json(400, { error: 'Oyun seç.' });
          if (rooms.size >= 300) return json(503, { error: 'Şu an masa kapasitesi dolu.' });
          let newCode;
          do {
            newCode = Array.from({ length: 6 }, () => alphabet[randomInt(alphabet.length)]).join('');
          } while (rooms.has(newCode));
          const host = token();
          save(newCode, { game: input.game, status: 'lobby', revision: 0, players: [],
            host, matchId: randomUUID(), created: now, updated: now });
          seen(newCode, host, now);
          return json(201, { code: newCode, token: host });
        }
        if (code) purge(now, code);
        const room = rooms.get(code);
        if (!room) return json(404, { error: 'Masa bulunamadı.' });
        const bearer = request.headers.authorization?.match(/^Bearer ([A-Za-z0-9_-]{32})$/)?.[1];
        const seat = bearer === room.host ? -1 : room.players.findIndex((player) => player.token === bearer);
        const authenticated = bearer === room.host || seat >= 0;
        if (operation === 'join' && method === 'POST') {
          if (room.status !== 'lobby' || room.players.length >= 4) {
            return json(409, { error: 'Masa dolu veya oyun başlamış.' });
          }
          const name = typeof input.name === 'string' ? input.name.trim().slice(0, 24) : '';
          if (!name) return json(400, { error: 'Oyuncu adını gir.' });
          const profileId = input.profileToken ? progression.resolveToken(input.profileToken) : null;
          if (input.profileToken && !profileId) return json(401, { error: 'Oyuncu profili oturumu geçersiz.' });
          if (profileId && room.players.some((player) => player.profileId === profileId)) {
            return json(409, { error: 'Bu profil zaten masada oturuyor.' });
          }
          const playerToken = token();
          const next = structuredClone(room);
          next.players.push({ name, token: playerToken, ...(profileId && { profileId }) });
          next.hadPlayers = true;
          next.revision++;
          next.updated = now;
          save(code, next);
          seen(code, playerToken, now);
          return json(201, { code, token: playerToken });
        }
        if (!operation && method === 'GET') {
          if (request.headers.authorization && !authenticated) return json(401, { error: 'Oturum geçersiz.' });
          if (authenticated && room.status !== 'finished') seen(code, bearer, now);
          return json(200, roomProjection(code, room, seat, authenticated));
        }
        if (operation === 'action' && method === 'POST') {
          if (!authenticated) return json(401, { error: 'Oyuncu oturumu gerekiyor.' });
          if (room.status !== 'finished') seen(code, bearer, now);
          if (input.revision !== room.revision) return json(409, { error: 'Masa değişti. Tekrar dene.' });
          const next = structuredClone(room);
          next.matchId ??= randomUUID();
          if (input.type === 'leave' && seat >= 0 && room.status === 'lobby') {
            next.players.splice(seat, 1);
          } else {
            applyAction(next, seat, input);
          }
          if (room.status !== 'finished' && next.status === 'finished') {
            next.finishedAt = now;
            next.completed = input.type !== 'close';
            if (next.completed && next.players.some((player) => player.profileId)) next.rewardPending = true;
          }
          next.revision++;
          next.updated = now;
          save(code, next);
          settleRewards(code, next);
          if (input.type === 'leave') presence.get(code)?.delete(bearer);
          return json(200, roomProjection(code, next, seat, input.type !== 'leave'));
        }
        return json(405, { error: 'İstek desteklenmiyor.' });
      } catch (error) {
        return json(400, { error: error instanceof SyntaxError ? 'Geçersiz istek.' : error.message });
      }
    }

    if (request.method !== 'GET' && request.method !== 'HEAD') return response.writeHead(405).end();
    let file;
    try {
      const pathname = decodeURIComponent(url.pathname);
      file = resolve(root, '.' + pathname);
      if (file !== root && !file.startsWith(root + sep)) return response.writeHead(404).end();
      if (existsSync(file) && statSync(file).isDirectory()) file = resolve(file, 'index.html');
      let status = 200;
      if (!existsSync(file) || !statSync(file).isFile()) {
        if (pathname.startsWith('/join/')) file = resolve(root, 'join/index.html');
        else {
          file = resolve(root, '404.html');
          status = 404;
        }
      }
      if (!existsSync(file)) return response.writeHead(404).end('Web salonu çıktısı bulunamadı.');
      response.writeHead(status, {
        'Content-Type': pathname === '/.well-known/apple-app-site-association'
          ? 'application/json' : media[extname(file)] ?? 'application/octet-stream',
        'Cache-Control': 'no-cache',
        ...(/^\/(join|arcade3d)(\/|$)/.test(pathname) && { 'X-Robots-Tag': 'noindex' }),
      });
      if (request.method === 'HEAD') return response.end();
      createReadStream(file).pipe(response);
    } catch {
      if (!response.headersSent) response.writeHead(404);
      response.end();
    }
  });
  server.once('close', () => clearInterval(timer));
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT || 8780);
  familyServer({ webRoot: process.env.FAMILY_WEB_ROOT, stateFile: process.env.FAMILY_STATE_FILE,
    progressionStateFile: process.env.PROGRESSION_STATE_FILE,
    origins: (process.env.FAMILY_ORIGINS || '').split(',').filter(Boolean),
  }).listen(port, process.env.HOST || '0.0.0.0', () => console.log('Aile Masası portu: ' + port));
}
