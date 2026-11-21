import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { familyServer } from "../family-server/server.mjs";

test("built web salon serves canonical games, ad verification and app associations", async (t) => {
  const origin = "https://azoyun.web.app";
  let local = process.env.WEB_TEST_ORIGIN;
  if (!local) {
    const server = familyServer();
    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    t.after(() => new Promise((resolve) => server.close(resolve)));
    local = "http://127.0.0.1:" + server.address().port;
  }
  async function read(path, status = 200) {
    const result = await fetch(local + path);
    assert.equal(result.status, status, path);
    return { headers: result.headers, body: await result.text() };
  }
  const { body: sitemap } = await read("/sitemap.xml");
  const urls = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((entry) => new URL(entry[1]));
  assert.equal(urls.filter((url) => url.pathname.startsWith("/oyun/")).length, 43);
  assert.equal(new Set(urls.map(String)).size, urls.length);
  const { body: home } = await read("/");
  assert.match(home, /href="\/salon\/style\.css"/);
  assert.match(home, /src="\/salon\/app\.mjs"/);
  assert.doesNotMatch(home, /flutter_bootstrap\.js|flutter\.js/);
  const legacyArcadeAliases = new Set(["/oyun/penalti/", "/oyun/frikik/"]);
  for (const url of urls) {
    assert.equal(url.origin, origin);
    const { body: page } = await read(url.pathname);
    assert.ok(page.includes('href="' + url.href + '"'), url.pathname);
    if (url.pathname.startsWith("/oyun/")) {
      if (!legacyArcadeAliases.has(url.pathname)) {
        assert.ok(home.includes('href="' + url.pathname + '"'), url.pathname);
      }
      assert.match(page, /"@type":"VideoGame"/);
    }
  }
  for (const [slug, mode] of Object.entries({
    "neon-pist": "runway",
    "sinyal-avi": "drones",
    "yorunge-pilotu": "orbit",
    "kristal-labirent": "maze",
    "mini-bovling": "bowling",
    "frikik-ustasi": "freeKick",
    "penalti-antrenmani": "penalty",
  })) {
    const { body: page } = await read("/oyun/" + slug + "/");
    assert.ok(page.includes('data-arcade="' + mode + '"'), slug);
    assert.match(page, /class="surface arcade-shell"/);
  }
  const flutterArcade = await readFile(new URL(
    "../lib/features/arcade3d/three_arcade_screen.dart", import.meta.url,
  ), "utf8");
  for (const mode of ["runway", "drones", "orbit", "maze", "bowling", "freeKick", "penalty"]) {
    assert.match(flutterArcade, new RegExp("\\w+\\('[^']+', '" + mode + "'\\)"), mode);
  }
  const { body: arcadeShell } = await read("/salon/arcade-shell.mjs");
  assert.match(arcadeShell, /\/arcade3d\/index\.html\?game=/);
  await read("/arcade3d/arcade.js");
  for (const [legacy, canonical] of Object.entries({
    penalti: "penalti-antrenmani",
    frikik: "frikik-ustasi",
  })) {
    const { body: page } = await read("/oyun/" + legacy + "/");
    assert.ok(page.includes('href="/oyun/' + canonical + '/"'));
    assert.doesNotMatch(page, /data-play=/);
  }
  assert.match(home, /name="google-site-verification"/);
  const publisher = home.match(/name="google-adsense-account" content="ca-(pub-\d+)"/)[1];
  for (const path of ["/ads.txt", "/app-ads.txt"]) {
    const { headers, body } = await read(path);
    assert.match(headers.get("content-type"), /^text\/plain/);
    assert.ok(body.includes("google.com, " + publisher + ", DIRECT"));
  }
  assert.match((await read("/google5afbd46fec1b3ba7.html")).body, /^google-site-verification:/);
  assert.ok((await read("/robots.txt")).body.includes("Sitemap: " + origin + "/sitemap.xml"));
  for (const path of ["/.well-known/assetlinks.json", "/.well-known/apple-app-site-association"]) {
    const { headers, body } = await read(path);
    assert.match(headers.get("content-type"), /^application\/json(?:;|$)/);
    assert.ok(JSON.parse(body));
  }
  const invite = await read("/join/deck/AB12CD");
  assert.equal(invite.headers.get("x-robots-tag"), "noindex");
  assert.match(invite.body, /content="noindex"/);
  await read("/oyun/olmayan-oyun/", 404);
});
