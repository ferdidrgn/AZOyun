self.addEventListener("install", (event) =>
  event.waitUntil(self.skipWaiting()),
);
self.addEventListener("activate", (event) =>
  event.waitUntil(
    (async () => {
      await Promise.all(
        ["flutter-app-cache", "flutter-temp-cache", "flutter-app-manifest"].map(
          (cache) => caches.delete(cache),
        ),
      );
      await self.registration.unregister();
    })(),
  ),
);
