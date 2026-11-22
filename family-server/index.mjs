import { initializeApp } from 'firebase-admin/app';
import { getDatabaseWithUrl } from 'firebase-admin/database';
import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { cleanupFirebaseFamilyRooms, createFirebaseFamilyApi } from './firebase-api.mjs';

const app = initializeApp();
const projectId = app.options.projectId ?? process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
const databaseUrl = app.options.databaseURL ?? process.env.FIREBASE_DATABASE_URL ??
  (projectId === 'azoyun-569b2' ? 'https://azoyun-569b2-default-rtdb.firebaseio.com' : undefined);
if (!databaseUrl) throw new Error('Firebase Realtime Database URL is missing.');

const database = getDatabaseWithUrl(databaseUrl, app);
const api = createFirebaseFamilyApi(database);

export const familyApi = onRequest(
  { region: 'us-central1', timeoutSeconds: 30, memory: '256MiB', maxInstances: 10 },
  api,
);

export const cleanupFamilyRooms = onSchedule(
  { schedule: 'every 5 minutes', region: 'us-central1', timeoutSeconds: 240, maxInstances: 1 },
  async () => cleanupFirebaseFamilyRooms(database),
);
