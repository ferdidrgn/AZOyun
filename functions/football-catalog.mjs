const WIKIDATA_ENDPOINT = 'https://query-next.wikidata.org/sparql';
const USER_AGENT = 'AZOyun/1.0 (https://azoyun.web.app/; football-catalog-sync)';

function wikidataId(uri) {
  return typeof uri === 'string' ? uri.match(/(Q\d+)$/)?.[1] ?? null : null;
}

function year(value) {
  if (!value) return null;
  const parsed = Number(value.slice(0, 4));
  return Number.isInteger(parsed) ? parsed : null;
}

function dailySeed(date) {
  let hash = 2166136261;
  for (const char of date) hash = Math.imul(hash ^ char.charCodeAt(0), 16777619);
  return hash >>> 0;
}

function combinations(items, size) {
  const result = [];
  const visit = (start, chosen) => {
    if (chosen.length === size) {
      result.push(chosen);
      return;
    }
    for (let i = start; i <= items.length - (size - chosen.length); i++) {
      visit(i + 1, [...chosen, items[i]]);
    }
  };
  visit(0, []);
  return result;
}

function seededShuffle(items, seed) {
  let state = seed >>> 0 || 1;
  const random = () => {
    state ^= state << 13;
    state ^= state >>> 17;
    state ^= state << 5;
    return (state >>> 0) / 0x100000000;
  };
  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

/** Builds one stable daily 4x4 Connections board from the versioned catalogue. */
export function buildDailyConnections(players, date = new Date().toISOString().slice(0, 10)) {
  const groups = new Map();
  for (const player of players) {
    const memberships = new Map();
    for (const career of player.careers ?? []) {
      if (career.id && career.label) memberships.set(`club:${career.id}`, career.label);
    }
    for (const country of player.countries ?? []) {
      if (country.id && country.label) memberships.set(`country:${country.id}`, country.label);
    }
    for (const [tag, label] of memberships) {
      const group = groups.get(tag) ?? { tag, label, playerIds: [] };
      group.playerIds.push(player.id);
      groups.set(tag, group);
    }
  }

  const seed = dailySeed(`${date}:connections`);
  const candidates = seededShuffle(
    [...groups.values()].filter((group) => group.playerIds.length >= 4).sort((a, b) => a.tag.localeCompare(b.tag)),
    seed,
  );
  const chosenGroups = [];
  const usedPlayers = new Set();
  for (const candidate of candidates) {
    if (chosenGroups.length === 4) break;
    const available = seededShuffle(
      candidate.playerIds.filter((id) => !usedPlayers.has(id)).sort(),
      dailySeed(`${date}:${candidate.tag}`),
    );
    if (available.length < 4) continue;
    const playerIds = available.slice(0, 4);
    playerIds.forEach((id) => usedPlayers.add(id));
    chosenGroups.push({ id: candidate.tag, label: candidate.label, playerIds });
  }
  if (chosenGroups.length !== 4) {
    throw new Error('Wikidata result cannot produce four disjoint Connections groups.');
  }
  return {
    gameId: `connections-${date}`,
    generatedAt: new Date(`${date}T04:30:00.000Z`).toISOString(),
    groups: chosenGroups,
  };
}

function selectGrid(players, clubLabels, countryLabels, date) {
  const clubs = new Map();
  const countries = new Map();
  const counts = new Map();
  for (const player of players) {
    const playerClubs = new Map(player.careers.map((club) => [club.id, club.label]));
    for (const [id, label] of playerClubs) clubs.set(id, label);
    for (const country of player.countries) countries.set(country.id, country.label);
    for (const clubId of playerClubs.keys()) {
      for (const country of player.countries) {
        const key = `${clubId}|${country.id}`;
        counts.set(key, (counts.get(key) ?? 0) + 1);
      }
    }
  }
  const topClubs = [...clubs.keys()]
    .sort((a, b) => {
      const totalA = [...counts.entries()].filter(([key]) => key.startsWith(`${a}|`)).reduce((n, [, v]) => n + v, 0);
      const totalB = [...counts.entries()].filter(([key]) => key.startsWith(`${b}|`)).reduce((n, [, v]) => n + v, 0);
      return totalB - totalA || a.localeCompare(b);
    })
    .slice(0, 12);
  const topCountries = [...countries.keys()]
    .sort((a, b) => {
      const totalA = [...counts.entries()].filter(([key]) => key.endsWith(`|${a}`)).reduce((n, [, v]) => n + v, 0);
      const totalB = [...counts.entries()].filter(([key]) => key.endsWith(`|${b}`)).reduce((n, [, v]) => n + v, 0);
      return totalB - totalA || a.localeCompare(b);
    })
    .slice(0, 12);
  const validGrids = [];
  for (const rowIds of combinations(topClubs, 3)) {
    for (const columnIds of combinations(topCountries, 3)) {
      const cells = rowIds.flatMap((club) => columnIds.map((country) => counts.get(`${club}|${country}`) ?? 0));
      if (cells.some((count) => count === 0)) continue;
      const score = Math.min(...cells) * 100 + cells.reduce((sum, count) => sum + count, 0);
      validGrids.push({ rowIds, columnIds, score });
    }
  }
  validGrids.sort((a, b) => b.score - a.score);
  const highestScore = validGrids[0]?.score ?? 0;
  const dailyPool = validGrids.filter((grid) => grid.score >= highestScore * 0.9).slice(0, 64);
  const best = dailyPool[dailySeed(date) % Math.max(dailyPool.length, 1)];
  if (!best) throw new Error('Wikidata result does not cover a complete 3x3 club-country grid.');
  return {
    rows: best.rowIds.map((id) => ({ id, label: clubLabels.get(id), tag: `club:${id}` })),
    columns: best.columnIds.map((id) => ({ id, label: countryLabels.get(id), tag: `country:${id}` })),
  };
}

export function buildDailyBox2Box(players, date = new Date().toISOString().slice(0, 10)) {
  const clubLabels = new Map();
  const countryLabels = new Map();
  for (const player of players) {
    for (const club of player.careers ?? []) clubLabels.set(club.id, club.label);
    for (const country of player.countries ?? []) countryLabels.set(country.id, country.label);
  }
  return {
    gameId: `daily-${date}`,
    generatedAt: new Date(`${date}T04:30:00.000Z`).toISOString(),
    ...selectGrid(players, clubLabels, countryLabels, date),
  };
}

/** Fetches a bounded Wikidata slice and produces the app's versioned grid catalogue. */
export async function fetchFootballCatalog({ now = new Date(), fetchImpl = fetch } = {}) {
  const query = `
    SELECT ?player ?playerLabel ?country ?countryLabel ?sportNationality ?club ?clubLabel ?position ?positionLabel ?start ?end WHERE {
      ?player wdt:P106 wd:Q937857 ; wdt:P27 ?citizenship ; p:P54 ?statement .
      ?statement ps:P54 ?club .
      OPTIONAL { ?player wdt:P1532 ?sportNationality . }
      OPTIONAL { ?player wdt:P413 ?position . }
      BIND(COALESCE(?sportNationality, ?citizenship) AS ?country)
      OPTIONAL { ?statement pq:P580 ?start . }
      OPTIONAL { ?statement pq:P582 ?end . }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "tr,en". }
    }
    LIMIT 12000
  `;
  const body = new URLSearchParams({ query, timeout: '50s' });
  const response = await fetchImpl(WIKIDATA_ENDPOINT, {
    method: 'POST',
    headers: {
      accept: 'application/sparql-results+json',
      'content-type': 'application/x-www-form-urlencoded',
      'user-agent': USER_AGENT,
    },
    body,
    signal: AbortSignal.timeout(60000),
  });
  if (!response.ok) throw new Error(`Wikidata returned HTTP ${response.status}.`);
  const payload = await response.json();
  const playerMap = new Map();
  const clubLabels = new Map();
  const countryLabels = new Map();
  for (const binding of payload.results?.bindings ?? []) {
    const id = wikidataId(binding.player?.value);
    const clubId = wikidataId(binding.club?.value);
    const countryId = wikidataId(binding.country?.value);
    const positionId = wikidataId(binding.position?.value);
    const name = binding.playerLabel?.value?.trim();
    const clubLabel = binding.clubLabel?.value?.trim();
    const countryLabel = binding.countryLabel?.value?.trim();
    if (!id || !clubId || !countryId || !name || !clubLabel || !countryLabel) continue;
    clubLabels.set(clubId, clubLabel);
    countryLabels.set(countryId, countryLabel);
    const positionLabel = binding.positionLabel?.value?.trim();
    const sportNationalityId = wikidataId(binding.sportNationality?.value);
    const player = playerMap.get(id) ?? {
      id, name, careers: new Map(), countries: new Map(), positions: new Map(),
      sportNationalities: new Map(),
    };
    const spellKey = `${clubId}:${binding.start?.value ?? ''}:${binding.end?.value ?? ''}`;
    player.careers.set(spellKey, {
      id: clubId,
      label: clubLabel,
      ...(year(binding.start?.value) ? { startYear: year(binding.start.value) } : {}),
      ...(year(binding.end?.value) ? { endYear: year(binding.end.value) } : {}),
    });
    player.countries.set(countryId, { id: countryId, label: countryLabel });
    if (positionId && positionLabel) player.positions.set(positionId, positionLabel);
    if (sportNationalityId) player.sportNationalities.set(sportNationalityId, countryLabel);
    playerMap.set(id, player);
  }

  const players = [...playerMap.values()].map((player) => {
    const careers = [...player.careers.values()];
    const countries = [...player.countries.values()];
    const positions = [...player.positions.values()];
    const tags = [
      ...careers.map((career) => `club:${career.id}`),
      ...countries.map((country) => `country:${country.id}`),
    ];
    return {
      id: player.id,
      name: player.name,
      tags: [...new Set(tags)],
      countries,
      positions,
      sportNationalityId: player.sportNationalities.keys().next().value ?? null,
      careers,
    };
  }).sort((a, b) => a.name.localeCompare(b.name) || a.id.localeCompare(b.id));
  if (players.length < 100) throw new Error(`Wikidata returned only ${players.length} usable players; preserving previous release.`);

  const date = now.toISOString().slice(0, 10);
  const grid = buildDailyBox2Box(players, date);
  return {
    datasetVersion: `wikidata-${date}`,
    generatedAt: now.toISOString(),
    source: 'Wikidata Query Service (CC0 structured data)',
    coverage: { players: players.length, clubs: clubLabels.size, countries: countryLabels.size },
    players,
    grids: { box2box: { current: grid } },
  };
}
