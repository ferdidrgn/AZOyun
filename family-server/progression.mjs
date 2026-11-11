import { createHash, randomBytes } from 'node:crypto';
import { existsSync, readFileSync, renameSync, writeFileSync } from 'node:fs';

export const badgeGoals = [
  { id: 'first-table', name: 'İlk Masa', target: 1, stat: 'played' },
  { id: 'first-win', name: 'İlk Galibiyet', target: 1, stat: 'wins' },
  { id: 'five-tables', name: 'Masa Müdavimi', target: 5, stat: 'played' },
  { id: 'five-wins', name: 'Usta Oyuncu', target: 5, stat: 'wins' },
  { id: 'variety', name: 'Masa Gezgini', target: 3, stat: 'variety' },
];
const digest = (value) => createHash('sha256').update(value).digest('hex');
const validToken = (value) => typeof value === 'string' && /^[A-Za-z0-9_-]{43}$/.test(value);
const rank = (a, b) => b.xp - a.xp || b.wins - a.wins || a.name.localeCompare(b.name, 'tr');

function publicProfile(profile) {
  return {
    name: profile.name, xp: profile.xp, level: 1 + Math.floor(profile.xp / 20),
    played: profile.played, wins: profile.wins, badges: profile.badges,
  };
}

export function createProgression({ stateFile, now = Date.now } = {}) {
  let state = stateFile && existsSync(stateFile)
    ? JSON.parse(readFileSync(stateFile, 'utf8')) : { players: {}, receipts: {} };
  const creation = new Map();
  function commit(next) {
    if (stateFile) {
      writeFileSync(stateFile + '.tmp', JSON.stringify(next), { mode: 0o600 });
      renameSync(stateFile + '.tmp', stateFile);
    }
    state = next;
  }

  function resolveToken(value) {
    if (!validToken(value)) return undefined;
    const id = digest(value);
    return state.players[id] ? id : undefined;
  }

  function award({ roomCode, room }) {
    const match = room.matchId ?? roomCode + ':' + room.created;
    if (state.receipts[match]) return;
    const players = new Map();
    room.players.forEach((player, index) => {
      if (state.players[player.profileId]) {
        players.set(player.profileId, players.get(player.profileId) || room.winner === index);
      }
    });
    if (!players.size) return;
    const next = structuredClone(state);
    const day = new Date(now()).toISOString().slice(0, 10);
    for (const [id, winner] of players) {
      const profile = next.players[id];
      if (profile.day !== day) {
        profile.day = day;
        profile.daily = 0;
      }
      profile.played++;
      profile.wins += Number(winner);
      if (profile.daily++ < 10) profile.xp += winner ? 3 : 1;
      if (!profile.games.includes(room.game)) profile.games.push(room.game);
      for (const goal of badgeGoals) {
        const count = goal.stat === 'variety' ? profile.games.length : profile[goal.stat];
        if (count >= goal.target && !profile.badges.includes(goal.id)) profile.badges.push(goal.id);
      }
    }
    next.receipts[match] = now();
    // Rooms cannot survive beyond eight hours. Keep receipts for a full week
    // so delayed or retried result writes still cannot award twice.
    const cutoff = now() - 7 * 86400000;
    for (const [id, time] of Object.entries(next.receipts)) {
      if (time < cutoff) delete next.receipts[id];
    }
    commit(next);
  }

  async function handle(request, response, url) {
    const json = (status, data) => response.writeHead(status, {
      'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store',
    }).end(JSON.stringify(data));
    const path = url.pathname;
    if (request.method === 'GET' && path === '/api/progression/leaderboard') {
      const players = Object.values(state.players).filter((profile) => profile.played > 0);
      return json(200, { players: players.sort(rank).slice(0, 25).map(publicProfile) });
    }
    if (request.method === 'GET' && path === '/api/progression/profile') {
      const id = resolveToken(request.headers.authorization?.match(/^Bearer (.+)$/)?.[1]);
      if (!id) return json(401, { error: 'Oyuncu anahtarı geçersiz.' });
      const profile = state.players[id];
      return json(200, { ...publicProfile(profile), games: profile.games,
        goals: badgeGoals.map((goal) => ({ ...goal, count: goal.stat === 'variety' ? profile.games.length : profile[goal.stat] })) });
    }
    if (request.method === 'POST' && path === '/api/progression/profile') {
      try {
        const address = request.socket.remoteAddress;
        const time = now();
        for (const [key, entry] of creation) if (entry.until <= time) creation.delete(key);
        const entry = creation.get(address) ?? { until: time + 60000, count: 0 };
        if (++entry.count > 12) return json(429, { error: 'Bir dakika sonra tekrar dene.' });
        creation.set(address, entry);
        if (Object.keys(state.players).length >= 5000) return json(503, { error: 'Profil kapasitesi dolu.' });
        let payload = '';
        for await (const chunk of request) {
          payload += chunk;
          if (payload.length > 1024) return json(413, { error: 'İstek çok büyük.' });
        }
        const input = JSON.parse(payload);
        const name = typeof input?.name === 'string' ? input.name.trim().slice(0, 24) : '';
        if (!name || /[\p{C}]/u.test(name)) return json(400, { error: 'Geçerli bir oyuncu adı gir.' });
        const key = randomBytes(32).toString('base64url');
        commit({ ...state, players: { ...state.players, [digest(key)]: {
          name, xp: 0, wins: 0, played: 0, games: [], badges: [],
        } } });
        return json(201, { key });
      } catch (error) {
        if (error instanceof SyntaxError) return json(400, { error: 'Geçersiz profil isteği.' });
        return json(503, { error: 'Profil şu anda kaydedilemedi.' });
      }
    }
    return json(404, { error: 'Profil işlemi bulunamadı.' });
  }

  return { handle, resolveToken, award };
}
