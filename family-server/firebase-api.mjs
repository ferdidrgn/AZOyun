import { createHash, randomBytes, randomInt, randomUUID } from 'node:crypto';
import { applyAction, games, view } from './game.mjs';
import { partyLimits } from './party-games.mjs';

const rootPath = 'family_api';
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const token = () => randomBytes(24).toString('base64url');
const digest = (value) => createHash('sha256').update(value).digest('hex');
const now = () => Date.now();
const badgeGoals = [
  { id: 'first-table', name: 'İlk Masa', target: 1, stat: 'played' },
  { id: 'first-win', name: 'İlk Galibiyet', target: 1, stat: 'wins' },
  { id: 'five-tables', name: 'Masa Müdavimi', target: 5, stat: 'played' },
  { id: 'five-wins', name: 'Usta Oyuncu', target: 5, stat: 'wins' },
  { id: 'variety', name: 'Masa Gezgini', target: 3, stat: 'variety' },
];

class ApiError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

function publicProfile(profile) {
  return {
    name: profile.name, xp: profile.xp, level: 1 + Math.floor(profile.xp / 20),
    played: profile.played, wins: profile.wins, badges: profile.badges,
  };
}

function randomSource(seed) {
  let state = seed >>> 0;
  return (max) => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return state % max;
  };
}

export function createFirebaseFamilyApi(database, { clock = now } = {}) {
  const rooms = database.ref(`${rootPath}/rooms`);
  const progression = database.ref(`${rootPath}/progression`);
  const rateLimits = database.ref(`${rootPath}/rateLimits`);

  async function resolveProfileKey(key) {
    if (typeof key !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(key)) return null;
    const id = digest(key);
    const snapshot = await progression.child(`players/${id}`).get();
    return snapshot.exists() ? id : null;
  }

  async function rateLimit(request, limit = 120) {
    const address = String(request.ip || request.headers['x-forwarded-for'] || 'unknown').split(',')[0].trim();
    const ref = rateLimits.child(digest(address));
    const result = await ref.transaction((entry) => {
      const current = entry && entry.until > clock() ? entry : { until: clock() + 60_000, count: 0 };
      if (current.count >= limit) return;
      current.count++;
      return current;
    });
    if (!result.committed) throw new ApiError(429, 'Bir dakika sonra tekrar dene.');
  }

  function roomProjection(code, room, seat, authenticated) {
    return {
      code,
      ...view(room, authenticated ? seat : -2),
      ...(authenticated && { seat, completed: room.completed === true }),
      ...(seat >= 0 && authenticated && { matchId: room.matchId, completed: room.completed === true }),
    };
  }

  async function notePresence(roomRef, bearer) {
    await roomRef.child(`_presence/${digest(bearer)}`).set(clock());
  }

  async function awardProfiles(code, room) {
    const match = room.matchId ?? `${code}:${room.created}`;
    await progression.transaction((current) => {
      const state = current ?? { players: {}, receipts: {} };
      if (state.receipts?.[match]) return;
      const next = structuredClone(state);
      next.players ??= {};
      next.receipts ??= {};
      const winners = new Map();
      room.players.forEach((player, seat) => {
        if (!next.players[player.profileId]) return;
        const winner = room.winner === seat || room.winners?.includes(seat) === true;
        winners.set(player.profileId, winners.get(player.profileId) === true || winner);
      });
      if (!winners.size) return;
      const day = new Date(clock()).toISOString().slice(0, 10);
      for (const [id, winner] of winners) {
        const profile = next.players[id];
        if (profile.day !== day) { profile.day = day; profile.daily = 0; }
        profile.played++;
        profile.wins += Number(winner);
        if (profile.daily++ < 10) profile.xp += winner ? 3 : 1;
        if (!profile.games.includes(room.game)) profile.games.push(room.game);
        for (const goal of badgeGoals) {
          const count = goal.stat === 'variety' ? profile.games.length : profile[goal.stat];
          if (count >= goal.target && !profile.badges.includes(goal.id)) profile.badges.push(goal.id);
        }
      }
      next.receipts[match] = clock();
      const cutoff = clock() - 7 * 86_400_000;
      for (const [id, time] of Object.entries(next.receipts)) if (time < cutoff) delete next.receipts[id];
      return next;
    });
    await rooms.child(`${code}/rewardPending`).remove();
  }

  async function createRoom(game) {
    if (!games.includes(game)) throw new ApiError(400, 'Oyun seç.');
    const capacity = await rooms.limitToFirst(300).get();
    if (capacity.numChildren() >= 300) throw new ApiError(503, 'Şu an masa kapasitesi dolu.');
    const host = token();
    for (let attempt = 0; attempt < 12; attempt++) {
      const code = Array.from({ length: 6 }, () => alphabet[randomInt(alphabet.length)]).join('');
      const timestamp = clock();
      const room = {
        game, status: 'lobby', revision: 0, players: [], host,
        matchId: randomUUID(), created: timestamp, updated: timestamp,
      };
      const result = await rooms.child(code).transaction((current) => current == null ? room : undefined);
      if (result.committed) {
        await notePresence(rooms.child(code), host);
        return { code, token: host };
      }
    }
    throw new ApiError(503, 'Masa açılamadı. Tekrar dene.');
  }

  async function joinRoom(code, input) {
    const name = typeof input.name === 'string' ? input.name.trim().slice(0, 24) : '';
    if (!name || /[\p{C}]/u.test(name)) throw new ApiError(400, 'Geçerli bir oyuncu adı gir.');
    const profileId = input.profileToken ? await resolveProfileKey(input.profileToken) : null;
    if (input.profileToken && !profileId) throw new ApiError(401, 'Oyuncu profili oturumu geçersiz.');
    const playerToken = token();
    let failure = null;
    const result = await rooms.child(code).transaction((current) => {
      if (!current) { failure = new ApiError(404, 'Masa bulunamadı.'); return; }
      const limit = partyLimits[current.game]?.[1] ?? 4;
      if (current.status !== 'lobby' || current.players.length >= limit) {
        failure = new ApiError(409, 'Masa dolu veya oyun başlamış.'); return;
      }
      if (profileId && current.players.some((player) => player.profileId === profileId)) {
        failure = new ApiError(409, 'Bu profil zaten masada oturuyor.'); return;
      }
      current.players.push({ name, token: playerToken, ...(profileId && { profileId }) });
      current.hadPlayers = true;
      current.revision++;
      current.updated = clock();
      return current;
    });
    if (!result.committed) throw failure ?? new ApiError(409, 'Masa değişti. Tekrar dene.');
    await notePresence(rooms.child(code), playerToken);
    return { code, token: playerToken };
  }

  async function readRoom(code, authorization) {
    const ref = rooms.child(code);
    const snapshot = await ref.get();
    if (!snapshot.exists()) throw new ApiError(404, 'Masa bulunamadı.');
    const room = snapshot.val();
    const bearer = authorization.match(/^Bearer ([A-Za-z0-9_-]{32})$/)?.[1];
    const seat = bearer === room.host ? -1 : room.players.findIndex((player) => player.token === bearer);
    const authenticated = bearer === room.host || seat >= 0;
    if (authorization && !authenticated) throw new ApiError(401, 'Oturum geçersiz.');
    if (authenticated && room.status !== 'finished') await notePresence(ref, bearer);
    if (room.rewardPending) await awardProfiles(code, room);
    return roomProjection(code, room, seat, authenticated);
  }

  async function actOnRoom(code, authorization, input) {
    const bearer = authorization.match(/^Bearer ([A-Za-z0-9_-]{32})$/)?.[1];
    if (!bearer) throw new ApiError(401, 'Oyuncu oturumu gerekiyor.');
    const seed = randomBytes(4).readUInt32BE(0);
    let failure = null;
    const result = await rooms.child(code).transaction((current) => {
      if (!current) { failure = new ApiError(404, 'Masa bulunamadı.'); return; }
      const isHost = bearer === current.host;
      const seat = isHost ? -1 : current.players.findIndex((player) => player.token === bearer);
      if (!isHost && seat < 0) { failure = new ApiError(401, 'Oyuncu oturumu geçersiz.'); return; }
      if (input.revision !== current.revision) { failure = new ApiError(409, 'Masa değişti. Tekrar dene.'); return; }
      try {
        const previousStatus = current.status;
        const next = structuredClone(current);
        next.matchId ??= randomUUID();
        if (input.type === 'leave' && seat >= 0 && current.status === 'lobby') {
          next.players.splice(seat, 1);
        } else {
          applyAction(next, seat, input, randomSource(seed));
        }
        if (previousStatus === 'finished' && next.status === 'playing') next.matchId = randomUUID();
        if (previousStatus !== 'finished' && next.status === 'finished') {
          next.finishedAt = clock();
          next.completed = input.type !== 'close';
          if (next.completed && next.players.some((player) => player.profileId)) next.rewardPending = true;
        }
        next.revision++;
        next.updated = clock();
        return next;
      } catch (error) {
        failure = new ApiError(400, error.message);
        return;
      }
    });
    if (!result.committed) throw failure ?? new ApiError(409, 'Masa değişti. Tekrar dene.');
    const room = result.snapshot.val();
    await notePresence(rooms.child(code), bearer);
    if (room.rewardPending) await awardProfiles(code, room);
    const seat = bearer === room.host ? -1 : room.players.findIndex((player) => player.token === bearer);
    return roomProjection(code, room, seat, input.type !== 'leave');
  }

  async function progressionRequest(request, response, path, authorization, input) {
    const stateRef = progression;
    if (request.method === 'GET' && path === '/api/progression/leaderboard') {
      const snapshot = await stateRef.child('players').get();
      const players = Object.values(snapshot.val() ?? {}).filter((profile) => profile.played > 0);
      players.sort((a, b) => b.xp - a.xp || b.wins - a.wins || a.name.localeCompare(b.name, 'tr'));
      return send(response, 200, { players: players.slice(0, 25).map(publicProfile) });
    }
    if (request.method === 'GET' && path === '/api/progression/profile') {
      const id = await resolveProfileKey(authorization.match(/^Bearer (.+)$/)?.[1]);
      if (!id) throw new ApiError(401, 'Oyuncu anahtarı geçersiz.');
      const profile = (await stateRef.child(`players/${id}`).get()).val();
      return send(response, 200, { ...publicProfile(profile), games: profile.games,
        goals: badgeGoals.map((goal) => ({ ...goal, count: goal.stat === 'variety' ? profile.games.length : profile[goal.stat] })) });
    }
    if (request.method === 'POST' && path === '/api/progression/profile') {
      await rateLimit(request, 12);
      const name = typeof input.name === 'string' ? input.name.trim().slice(0, 24) : '';
      if (!name || /[\p{C}]/u.test(name)) throw new ApiError(400, 'Geçerli bir oyuncu adı gir.');
      const key = randomBytes(32).toString('base64url');
      const id = digest(key);
      const result = await stateRef.child('players').transaction((current) => {
        current ??= {};
        if (Object.keys(current).length >= 5000) return;
        current[id] = { name, xp: 0, wins: 0, played: 0, games: [], badges: [] };
        return current;
      });
      if (!result.committed) throw new ApiError(503, 'Profil kapasitesi dolu.');
      return send(response, 201, { key });
    }
    throw new ApiError(404, 'Profil işlemi bulunamadı.');
  }

  async function handle(request, response) {
    const origin = request.headers.origin;
    if (origin === 'https://azoyun.web.app' || origin === 'https://azoyun-569b2.web.app') {
      response.set('Access-Control-Allow-Origin', origin);
      response.set('Vary', 'Origin');
      response.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    }
    if (request.method === 'OPTIONS') return response.status(204).end();
    const path = request.path ?? new URL(request.url, 'https://azoyun.web.app').pathname;
    const authorization = String(request.headers.authorization ?? '');
    const input = request.body && typeof request.body === 'object' ? request.body : {};
    try {
      if (path.startsWith('/api/progression/')) return await progressionRequest(request, response, path, authorization, input);
      if (!path.startsWith('/api/family/')) throw new ApiError(404, 'İstek bulunamadı.');
      if (path === '/api/family/health' && request.method === 'GET') return send(response, 200, { ok: true });
      const match = path.match(/^\/api\/family\/rooms(?:\/([A-Z2-9]{6}))?(?:\/(join|action))?$/);
      if (!match) throw new ApiError(404, 'İstek bulunamadı.');
      const [, code, operation] = match;
      if (request.method === 'POST' && (!code || operation === 'join')) await rateLimit(request);
      if (!code && request.method === 'POST') return send(response, 201, await createRoom(input.game));
      if (!code) throw new ApiError(405, 'İstek desteklenmiyor.');
      if (operation === 'join' && request.method === 'POST') return send(response, 201, await joinRoom(code, input));
      if (!operation && request.method === 'GET') return send(response, 200, await readRoom(code, authorization));
      if (operation === 'action' && request.method === 'POST') return send(response, 200, await actOnRoom(code, authorization, input));
      throw new ApiError(405, 'İstek desteklenmiyor.');
    } catch (error) {
      if (response.headersSent) return;
      send(response, error.status ?? 503, { error: error.message || 'İstek şu anda tamamlanamadı.' });
    }
  }
  return handle;
}

export async function cleanupFirebaseFamilyRooms(database, { clock = now } = {}) {
  const root = database.ref(`${rootPath}/rooms`);
  const snapshot = await root.get();
  const timestamp = clock();
  for (const child of snapshot.children) {
    const ref = root.child(child.key);
    await ref.transaction((room) => {
      if (!room || typeof room !== 'object') return;
      const presence = room._presence ?? {};
      const active = (bearer) => timestamp - (presence[digest(bearer)] ?? room.updated ?? room.created ?? timestamp);
      const livingPlayers = (room.players ?? []).filter((player) => active(player.token) < 120_000);
      const isFinished = room.status === 'finished';
      const allAbsent = active(room.host) >= 120_000 && livingPlayers.length === 0;
      const emptyLobbyExpired = room.status === 'lobby' && (room.players ?? []).length === 0 &&
        timestamp - (room.created ?? timestamp) >= 15 * 60_000 && active(room.host) >= 120_000;
      const abandonedRoomExpired = room.status !== 'lobby' && !isFinished && allAbsent;
      const finishedExpired = isFinished && !room.rewardPending &&
        timestamp - (room.finishedAt ?? room.updated ?? timestamp) >= 60_000;
      const lifetimeExpired = timestamp - (room.created ?? timestamp) >= 8 * 60 * 60_000;
      if (emptyLobbyExpired || abandonedRoomExpired || finishedExpired || lifetimeExpired) return null;
      if (room.status === 'lobby' && livingPlayers.length !== (room.players ?? []).length) {
        room.players = livingPlayers;
        room.revision = (room.revision ?? 0) + 1;
        room.updated = timestamp;
        return room;
      }
      return;
    });
  }
}

function send(response, status, data) {
  response.status(status).set('Content-Type', 'application/json; charset=utf-8')
    .set('Cache-Control', 'no-store').send(data);
}
