import { createServer } from 'node:http';
import { randomBytes, randomInt } from 'node:crypto';
import { createReadStream, existsSync, readFileSync, renameSync, statSync, writeFileSync } from 'node:fs';
import { extname, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';

import { applyAction, games, view } from './game.mjs';

const lifetime = 8 * 60 * 60 * 1000;
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const token = () => randomBytes(24).toString('base64url');
const media = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css',
  '.png': 'image/png', '.svg': 'image/svg+xml', '.woff2': 'font/woff2',
};

async function body(request) {
  let buffer = '';
  for await (const chunk of request) {
    buffer += chunk;
    if (buffer.length > 8192) throw new Error('İstek çok büyük.');
  }
  return JSON.parse(buffer || '{}');
}

export function familyServer({ webRoot = 'build/web', stateFile, origins = [] } = {}) {
  const root = resolve(webRoot);
  const rooms = new Map(stateFile && existsSync(stateFile)
    ? JSON.parse(readFileSync(stateFile, 'utf8')) : []);
  const attempts = new Map();
  function save(code, room) {
    if (stateFile) {
      const snapshot = new Map(rooms);
      snapshot.set(code, room);
      writeFileSync(stateFile + '.tmp', JSON.stringify([...snapshot]), { mode: 0o600 });
      renameSync(stateFile + '.tmp', stateFile);
    }
    rooms.set(code, room);
  }
  function purge() {
    const cutoff = Date.now() - lifetime;
    for (const [code, room] of rooms) if (room.updated < cutoff) rooms.delete(code);
    for (const [address, entry] of attempts) if (entry.until < Date.now()) attempts.delete(address);
  }
  const timer = setInterval(purge, 60_000);
  timer.unref();

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

    if (url.pathname.startsWith('/api/family/')) {
      try {
        if (url.pathname === '/api/family/health' && request.method === 'GET') return json(200, { ok: true });
        const match = url.pathname.match(/^\/api\/family\/rooms(?:\/([A-Z2-9]{6}))?(?:\/(join|action))?$/);
        if (!match) return json(404, { error: 'İstek bulunamadı.' });
        const [, code, operation] = match;
        const method = request.method;
        const input = method === 'POST' ? await body(request) : {};
        if (method === 'POST' && (!code || operation === 'join')) {
          const address = request.socket.remoteAddress ?? '';
          const entry = attempts.get(address) ?? { until: Date.now() + 60_000, count: 0 };
          if (entry.until < Date.now()) {
            entry.until = Date.now() + 60_000;
            entry.count = 0;
          }
          if (++entry.count > 120) return json(429, { error: 'Bir dakika sonra tekrar dene.' });
          attempts.set(address, entry);
        }
        if (!code && method === 'POST') {
          purge();
          if (!games.includes(input.game)) return json(400, { error: 'Oyun seç.' });
          if (rooms.size >= 300) return json(503, { error: 'Şu an masa kapasitesi dolu.' });
          let newCode;
          do {
            newCode = Array.from({ length: 6 }, () => alphabet[randomInt(alphabet.length)]).join('');
          } while (rooms.has(newCode));
          const host = token();
          save(newCode, { game: input.game, status: 'lobby', revision: 0, players: [],
            host, updated: Date.now() });
          return json(201, { code: newCode, token: host });
        }
        const room = rooms.get(code);
        if (!room || room.updated < Date.now() - lifetime) return json(404, { error: 'Masa bulunamadı.' });
        const bearer = request.headers.authorization?.match(/^Bearer ([A-Za-z0-9_-]{32})$/)?.[1];
        const seat = bearer === room.host ? -1 : room.players.findIndex((player) => player.token === bearer);
        const authenticated = bearer === room.host || seat >= 0;
        if (operation === 'join' && method === 'POST') {
          if (room.status !== 'lobby' || room.players.length >= 4) {
            return json(409, { error: 'Masa dolu veya oyun başlamış.' });
          }
          const name = typeof input.name === 'string' ? input.name.trim().slice(0, 24) : '';
          if (!name) return json(400, { error: 'Oyuncu adını gir.' });
          const playerToken = token();
          const next = structuredClone(room);
          next.players.push({ name, token: playerToken });
          next.revision++;
          next.updated = Date.now();
          save(code, next);
          return json(201, { code, token: playerToken });
        }
        if (!operation && method === 'GET') {
          if (request.headers.authorization && !authenticated) return json(401, { error: 'Oturum geçersiz.' });
          return json(200, { code, ...view(room, authenticated ? seat : -2),
            ...(authenticated && { seat }) });
        }
        if (operation === 'action' && method === 'POST') {
          if (!authenticated) return json(401, { error: 'Oyuncu oturumu gerekiyor.' });
          if (input.revision !== room.revision) return json(409, { error: 'Masa değişti. Tekrar dene.' });
          const next = structuredClone(room);
          if (input.type === 'leave' && seat >= 0 && room.status === 'lobby') {
            next.players.splice(seat, 1);
          } else {
            applyAction(next, seat, input);
          }
          next.revision++;
          next.updated = Date.now();
          save(code, next);
          return json(200, { code, ...view(next, input.type === 'leave' ? -2 : seat), seat });
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
      if (!existsSync(file) || !statSync(file).isFile()) {
        if (extname(pathname)) return response.writeHead(404).end();
        file = resolve(root, 'index.html');
      }
      if (!existsSync(file)) return response.writeHead(404).end('Flutter web çıktısı bulunamadı.');
      response.writeHead(200, {
        'Content-Type': media[extname(file)] ?? 'application/octet-stream',
        'Cache-Control': 'no-cache',
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
    origins: (process.env.FAMILY_ORIGINS || '').split(',').filter(Boolean),
  }).listen(port, process.env.HOST || '0.0.0.0', () => console.log('Aile Masası portu: ' + port));
}
