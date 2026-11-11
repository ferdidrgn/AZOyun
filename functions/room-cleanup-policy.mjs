export const roomPaths = Object.freeze([
  'hangman_rooms', 'golf_rooms', 'soccer_rooms', 'city_puzzle_rooms',
  'word_puzzle_rooms', 'vampire_rooms', 'liar_cafe_rooms', 'okey_rooms',
  'fighter_rooms', 'racing_rooms', 'dama_rooms', 'impostor_rooms', 'deck_rooms',
]);

const minute = 60_000;
export const emptyGrace = 10 * minute;
export const finishedRetention = 120 * minute;

const asObject = (value) => value && typeof value === 'object' ? value : {};
const validStamp = (value, now) => Number.isFinite(value) && value > 0 && value <= now;

// undefined keeps the current record, null deletes it.
export function sweepRoom(room, now) {
  if (!room || typeof room !== 'object' || Array.isArray(room)) return undefined;
  const lifecycle = asObject(room._lifecycle);
  const sprintFinished = room.phase === 'finished' && ['bluff', 'station', 'penalty'].includes(room.mode);
  if (room.status === 'finished' || sprintFinished) {
    const firstObserved = lifecycle.finishedSince;
    if (!validStamp(firstObserved, now)) {
      return { ...room, _lifecycle: { ...lifecycle, finishedSince: now } };
    }
    return now - firstObserved >= finishedRetention ? null : undefined;
  }

  const players = Object.keys(asObject(room.players));
  const connections = Object.values(asObject(lifecycle.connections));
  const tracked = asObject(lifecycle.tracked);
  const reliablyEmpty = validStamp(room.createdAt, now) &&
    players.every((id) => tracked[id] === true) &&
    !connections.some((id) => players.includes(id));
  if (reliablyEmpty) {
    if (!validStamp(lifecycle.emptySince, now) || lifecycle.finishedSince) {
      const next = { ...lifecycle, emptySince: now };
      delete next.finishedSince;
      return { ...room, _lifecycle: next };
    }
    return now - lifecycle.emptySince >= emptyGrace ? null : undefined;
  }

  if (!lifecycle.finishedSince && !lifecycle.emptySince) return undefined;
  const next = { ...lifecycle };
  delete next.finishedSince;
  delete next.emptySince;
  return { ...room, _lifecycle: next };
}
