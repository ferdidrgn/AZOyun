import { initializeApp } from 'firebase-admin/app';
import { getDatabase, getDatabaseWithUrl } from 'firebase-admin/database';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';
import { roomPaths, sweepRoom } from './room-cleanup-policy.mjs';
import { buildDailyBox2Box, buildDailyConnections, fetchFootballCatalog } from './football-catalog.mjs';

const app = initializeApp();
const projectId = app.options.projectId ?? process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
const databaseUrl = app.options.databaseURL ?? (projectId === 'azoyun-569b2'
  ? 'https://azoyun-569b2-default-rtdb.firebaseio.com' : undefined);
const batchSize = 50;

async function sweepPath(root, now) {
  let last;
  let deleted = 0;
  let observed = 0;
  for (;;) {
    let query = root.orderByKey().limitToFirst(batchSize);
    if (last !== undefined) query = query.startAfter(last);
    const page = await query.get();
    const candidates = [];
    page.forEach((room) => {
      last = room.key;
      if (sweepRoom(room.val(), now) !== undefined) candidates.push(room.ref);
    });

    for (const candidate of candidates) {
      const result = await candidate.transaction((current) => {
        if (current === null) return null;
        return sweepRoom(current, now);
      });
      if (!result.committed) continue;
      if (result.snapshot.exists()) observed++;
      else deleted++;
    }
    if (page.numChildren() < batchSize) return { deleted, observed };
  }
}

export const sweepLegacyGameRooms = onSchedule(
  { schedule: 'every 5 minutes', region: 'us-central1', timeoutSeconds: 240, maxInstances: 1 },
  async () => {
    const db = databaseUrl ? getDatabaseWithUrl(databaseUrl, app) : getDatabase(app);
    const now = Date.now();
    const result = await Promise.allSettled(roomPaths.map((path) => sweepPath(db.ref(path), now)));
    result.forEach((item, index) => {
      const path = roomPaths[index];
      if (item.status === 'rejected') logger.error('Game room cleanup failed', { path, error: item.reason });
      else if (item.value.deleted || item.value.observed) logger.info('Game room cleanup completed', { path, ...item.value });
    });
    if (result.some((item) => item.status === 'rejected')) throw new Error('One or more room sweeps failed.');
  },
);

export const publishDailyFootballPack = onSchedule(
  { schedule: 'every day 04:20', timeZone: 'UTC', region: 'us-central1', timeoutSeconds: 180, maxInstances: 1 },
  async () => {
    const db = databaseUrl ? getDatabaseWithUrl(databaseUrl, app) : getDatabase(app);
    const catalogRef = db.ref('footballCatalog/current');
    let catalog;
    if (new Date().getUTCDay() === 0) {
      try {
        catalog = await fetchFootballCatalog();
        // A successful complete pull replaces the catalogue atomically. A
        // failed pull keeps the previous release and still permits daily play.
        await catalogRef.set(catalog);
        logger.info('Football catalogue refreshed', {
          datasetVersion: catalog.datasetVersion,
          ...catalog.coverage,
        });
      } catch (error) {
        logger.warn('Football source refresh failed; retaining the last release.', { error });
      }
    }
    if (!catalog) {
      const snapshot = await catalogRef.get();
      catalog = snapshot.val();
    }
    if (!catalog || !catalog.players) {
      throw new Error('Daily football pack cannot publish before an initial catalogue sync.');
    }
    const players = Array.isArray(catalog.players) ? catalog.players : Object.values(catalog.players);
    const date = new Date().toISOString().slice(0, 10);
    const grid = buildDailyBox2Box(players, date);
    const connections = buildDailyConnections(players, date);
    await catalogRef.update({
      'grids/box2box/current': grid,
      'grids/connections/current': connections,
    });
    logger.info('Daily football pack published', {
      gameId: grid.gameId,
      connectionsGameId: connections.gameId,
      datasetVersion: catalog.datasetVersion,
    });
  },
);
