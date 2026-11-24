import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getDatabase, getDatabaseWithUrl } from 'firebase-admin/database';
import { mkdir, rename, rm, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  buildDailyFootballPublication,
  fetchFootballCatalog,
  validateFootballCatalog,
} from './football-catalog.mjs';

/**
 * One-shot dynamic catalogue publisher for environments where Firebase
 * Functions cannot be deployed yet. Run from the functions directory with
 * GOOGLE_APPLICATION_CREDENTIALS (or another ADC source) configured.
 *
 * This writes only after a complete Wikidata fetch and validation succeeds;
 * the existing catalogue remains intact on source or network failures.
 */
export async function seedFootballCatalog({
  now = new Date(),
  projectId = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT,
  databaseUrl = process.env.FIREBASE_DATABASE_URL ??
    (projectId === 'azoyun-569b2' ? 'https://azoyun-569b2-default-rtdb.firebaseio.com' : undefined),
  fetchCatalog = fetchFootballCatalog,
} = {}) {
  if (!projectId) throw new Error('Set GCLOUD_PROJECT or GOOGLE_CLOUD_PROJECT.');
  const app = initializeApp({
    credential: applicationDefault(),
    projectId,
    ...(databaseUrl && { databaseURL: databaseUrl }),
  });
  try {
    const db = databaseUrl
      ? getDatabaseWithUrl(databaseUrl, app)
      : getDatabase(app);

    const date = now.toISOString().slice(0, 10);
    const catalog = await fetchCatalog({ now });
    validateFootballCatalog(catalog);
    const publication = buildDailyFootballPublication(catalog, date);
    const box2box = publication.grids.box2box.current;
    const connections = publication.grids.connections.current;

    // The static web build consumes the same validated release as Android.
    // Stage a complete temporary file, then commit RTDB first and atomically
    // replace the Hosting artifact only after the database accepts the release.
    const outputPath = process.env.FOOTBALL_CATALOG_OUTPUT_PATH;
    let temporary;
    if (outputPath) {
      const target = resolve(outputPath);
      await mkdir(dirname(target), { recursive: true });
      temporary = `${target}.${process.pid}.tmp`;
      await writeFile(temporary, `${JSON.stringify(publication)}\n`, 'utf8');
    }

    try {
      await db.ref('footballCatalog/current').set(publication);
      if (temporary) await rename(temporary, resolve(outputPath));
    } catch (error) {
      if (temporary) await rm(temporary, { force: true }).catch(() => {});
      throw error;
    }
    return {
      datasetVersion: publication.datasetVersion,
      generatedAt: publication.generatedAt,
      players: publication.coverage.players,
      clubs: publication.coverage.clubs,
      countries: publication.coverage.countries,
      box2boxGameId: box2box.gameId,
      connectionsGameId: connections.gameId,
    };
  } finally {
    await app.delete();
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const result = await seedFootballCatalog();
    console.log(JSON.stringify({ ok: true, ...result }, null, 2));
  } catch (error) {
    console.error(`Football catalogue was not published: ${error.message}`);
    process.exitCode = 1;
  }
}
