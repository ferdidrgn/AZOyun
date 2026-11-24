const WIKIDATA_ENDPOINT = 'https://query-next.wikidata.org/sparql';
const USER_AGENT = 'AZOyun/1.0 (https://azoyun.web.app/; football-catalog-sync)';
<<<<<<< Updated upstream
=======
const MAX_SPARQL_ROWS = 12000;
const MIN_PLAYERS = 100;
const MIN_DATED_CAREER_PLAYERS = 20;

function compareText(a, b) {
  return a < b ? -1 : a > b ? 1 : 0;
}
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
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
=======
  const byTag = [...groups.values()]
    .map((group) => ({ ...group, playerIds: [...new Set(group.playerIds)].sort(compareText) }))
    .filter((group) => group.playerIds.length >= 4)
    .sort((a, b) => compareText(a.tag, b.tag));
  const seededOrder = new Map(
    seededShuffle(byTag, seed).map((group, index) => [group.tag, index]),
  );
  const candidates = byTag.sort((a, b) =>
    a.playerIds.length - b.playerIds.length || seededOrder.get(a.tag) - seededOrder.get(b.tag),
  );

  // Greedily taking the first four players can consume the only players that
  // make later categories possible. Search for a disjoint pack with a strict
  // node/branch budget so a bad source snapshot cannot stall a scheduled job.
  const MAX_SEARCH_NODES = 50000;
  const MAX_PLAYER_SETS_PER_GROUP = 64;
  let searchNodes = 0;
  const selected = [];
  const usedPlayers = new Set();

  function playerSets(group, available) {
    const shuffled = seededShuffle(
      available,
      dailySeed(`${date}:connections:${group.tag}`),
    );
    const result = [];
    const seen = new Set();
    const add = (ids) => {
      if (ids.length !== 4) return;
      const key = [...ids].sort(compareText).join('|');
      if (seen.has(key)) return;
      seen.add(key);
      result.push([...ids]);
    };

    // Exhaust the small groups; for large clubs/countries use deterministic
    // overlapping windows and seeded samples rather than combinatorial C(n,4).
    if (shuffled.length <= 10) {
      for (const ids of combinations(shuffled, 4)) add(ids);
    } else {
      const maxStart = Math.min(shuffled.length - 4, MAX_PLAYER_SETS_PER_GROUP - 1);
      for (let start = 0; start <= maxStart; start++) add(shuffled.slice(start, start + 4));
      for (let attempt = 0; result.length < MAX_PLAYER_SETS_PER_GROUP && attempt < 256; attempt++) {
        const sample = seededShuffle(shuffled, dailySeed(`${date}:${group.tag}:${attempt}`));
        add(sample.slice(0, 4));
      }
    }
    return result.slice(0, MAX_PLAYER_SETS_PER_GROUP);
  }

  function search(start) {
    if (selected.length === 4) return true;
    const needed = 4 - selected.length;
    if (candidates.length - start < needed) return false;

    for (let index = start; index <= candidates.length - needed; index++) {
      if (++searchNodes > MAX_SEARCH_NODES) return false;
      const candidate = candidates[index];
      const available = candidate.playerIds.filter((id) => !usedPlayers.has(id));
      if (available.length < 4) continue;

      for (const playerIds of playerSets(candidate, available)) {
        if (++searchNodes > MAX_SEARCH_NODES) return false;
        playerIds.forEach((id) => usedPlayers.add(id));
        selected.push({ id: candidate.tag, label: candidate.label, playerIds });
        if (search(index + 1)) return true;
        selected.pop();
        playerIds.forEach((id) => usedPlayers.delete(id));
      }
    }
    return false;
  }

  if (!search(0)) {
    throw new Error(
      `Wikidata result could not produce four disjoint Connections groups within ${MAX_SEARCH_NODES} search steps.`,
    );
  }
  const chosenGroups = selected;
  const uniquePlayerIds = chosenGroups.flatMap((group) => group.playerIds);
  if (new Set(uniquePlayerIds).size !== 16) {
    throw new Error('Connections pack validation failed: expected 16 distinct players.');
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
      return totalB - totalA || a.localeCompare(b);
=======
      return totalB - totalA || compareText(a, b);
>>>>>>> Stashed changes
    })
    .slice(0, 12);
  const topCountries = [...countries.keys()]
    .sort((a, b) => {
      const totalA = [...counts.entries()].filter(([key]) => key.endsWith(`|${a}`)).reduce((n, [, v]) => n + v, 0);
      const totalB = [...counts.entries()].filter(([key]) => key.endsWith(`|${b}`)).reduce((n, [, v]) => n + v, 0);
<<<<<<< Updated upstream
      return totalB - totalA || a.localeCompare(b);
=======
      return totalB - totalA || compareText(a, b);
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
=======
/** Rejects partial or structurally unsafe source snapshots before publication. */
export function validateFootballCatalog(catalog) {
  if (!catalog || typeof catalog !== 'object' || Array.isArray(catalog)) {
    throw new Error('Football catalogue must be an object.');
  }
  if (typeof catalog.datasetVersion !== 'string' || !catalog.datasetVersion.trim()) {
    throw new Error('Football catalogue is missing datasetVersion.');
  }
  if (!Array.isArray(catalog.players) || catalog.players.length < MIN_PLAYERS) {
    throw new Error(`Football catalogue must contain at least ${MIN_PLAYERS} players.`);
  }

  const ids = new Set();
  let datedCareerPlayers = 0;
  for (const player of catalog.players) {
    if (!player || typeof player.id !== 'string' || !/^Q\d+$/.test(player.id) ||
        typeof player.name !== 'string' || !player.name.trim()) {
      throw new Error('Football catalogue contains a player without a valid Wikidata ID/name.');
    }
    if (ids.has(player.id)) throw new Error(`Football catalogue contains duplicate player ${player.id}.`);
    ids.add(player.id);
    if (!Array.isArray(player.careers) || !Array.isArray(player.countries) ||
        !Array.isArray(player.positions)) {
      throw new Error(`Football catalogue player ${player.id} has an invalid career/country/position shape.`);
    }

    const datedClubs = new Set();
    for (const career of player.careers) {
      if (!career || typeof career.id !== 'string' || !/^Q\d+$/.test(career.id) ||
          typeof career.label !== 'string' || !career.label.trim()) {
        throw new Error(`Football catalogue player ${player.id} has an invalid club membership.`);
      }
      if (career.startYear != null && (!Number.isInteger(career.startYear) || career.startYear < 1850)) {
        throw new Error(`Football catalogue player ${player.id} has an invalid career start year.`);
      }
      if (career.endYear != null && (!Number.isInteger(career.endYear) || career.endYear < 1850)) {
        throw new Error(`Football catalogue player ${player.id} has an invalid career end year.`);
      }
      if (career.startYear && career.endYear && career.endYear < career.startYear) {
        throw new Error(`Football catalogue player ${player.id} has a career end before its start.`);
      }
      if (career.startYear) datedClubs.add(career.id);
    }
    if (datedClubs.size >= 3) datedCareerPlayers++;
  }

  if (datedCareerPlayers < MIN_DATED_CAREER_PLAYERS) {
    throw new Error(
      `Football catalogue has only ${datedCareerPlayers} players with three dated clubs; ` +
      `at least ${MIN_DATED_CAREER_PLAYERS} are needed for Career Path.`,
    );
  }
  return { players: ids.size, datedCareerPlayers };
}

/** Builds and validates the complete daily release before any publisher writes. */
export function buildDailyFootballPublication(catalog, date = new Date().toISOString().slice(0, 10)) {
  validateFootballCatalog(catalog);
  const box2box = buildDailyBox2Box(catalog.players, date);
  const connections = buildDailyConnections(catalog.players, date);
  if (box2box.rows.length !== 3 || box2box.columns.length !== 3 ||
      connections.groups.length !== 4 ||
      new Set(connections.groups.flatMap((group) => group.playerIds)).size !== 16) {
    throw new Error('Generated daily football packs failed completeness validation.');
  }
  return {
    ...catalog,
    grids: {
      ...catalog.grids,
      box2box: { current: box2box },
      connections: { current: connections },
    },
  };
}

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    LIMIT 12000
=======
    ORDER BY STR(?player) STR(?club) STR(?citizenship) STR(?start) STR(?end) STR(?position)
    LIMIT ${MAX_SPARQL_ROWS + 1}
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
  const playerMap = new Map();
  const clubLabels = new Map();
  const countryLabels = new Map();
  for (const binding of payload.results?.bindings ?? []) {
=======
  const bindings = payload.results?.bindings;
  if (!Array.isArray(bindings)) throw new Error('Wikidata response did not contain a result binding list.');
  if (bindings.length > MAX_SPARQL_ROWS) {
    throw new Error(
      `Wikidata returned more than ${MAX_SPARQL_ROWS} rows; refusing a truncated/non-complete catalogue.`,
    );
  }
  const playerMap = new Map();
  const clubLabels = new Map();
  const countryLabels = new Map();
  for (const binding of bindings) {
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
      sportNationalityId: player.sportNationalities.keys().next().value ?? null,
      careers,
    };
  }).sort((a, b) => a.name.localeCompare(b.name) || a.id.localeCompare(b.id));
  if (players.length < 100) throw new Error(`Wikidata returned only ${players.length} usable players; preserving previous release.`);

  const date = now.toISOString().slice(0, 10);
  const grid = buildDailyBox2Box(players, date);
  return {
=======
      positionIds: [...player.positions.keys()].sort(compareText),
      sportNationalityId: player.sportNationalities.keys().next().value ?? null,
      careers,
    };
  }).sort((a, b) => compareText(a.name, b.name) || compareText(a.id, b.id));

  const date = now.toISOString().slice(0, 10);
  const catalog = {
>>>>>>> Stashed changes
    datasetVersion: `wikidata-${date}`,
    generatedAt: now.toISOString(),
    source: 'Wikidata Query Service (CC0 structured data)',
    coverage: { players: players.length, clubs: clubLabels.size, countries: countryLabels.size },
    players,
<<<<<<< Updated upstream
    grids: { box2box: { current: grid } },
  };
=======
    grids: {},
  };
  validateFootballCatalog(catalog);
  // Preflight both games before returning this candidate to any publisher.
  return buildDailyFootballPublication(catalog, date);
>>>>>>> Stashed changes
}
