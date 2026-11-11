import { cp, mkdir, writeFile } from "node:fs/promises";
import { writePublicPages } from "./web-public-pages.mjs";

const output = new URL("../build/salon/", import.meta.url);
const input = new URL("../web/", import.meta.url);
const arcade = new URL("../assets/arcade3d/", import.meta.url);
const api = process.env.FAMILY_API_URL?.trim() || "";
if (api) {
  const address = new URL(api);
  if (address.protocol !== "https:" || address.username || address.password) {
    throw new Error("FAMILY_API_URL must be an HTTPS address.");
  }
}
await mkdir(output, { recursive: true });
await cp(input, output, { recursive: true });
await cp(arcade, new URL("arcade3d/", output), { recursive: true });
await writePublicPages(input, output);
const team = process.env.APPLE_TEAM_ID?.trim();
if (team && !/^[A-Z0-9]{10}$/.test(team)) throw new Error("Invalid APPLE_TEAM_ID.");
await writeFile(new URL(".well-known/apple-app-site-association", output),
  JSON.stringify({ applinks: { apps: [], details: team ? [
    { appID: team + ".com.ferdidrgn.azgame", paths: ["/join/*"] },
  ] : [] } }, null, 2) + "\n");
await writeFile(
  new URL("salon/config.mjs", output),
  "export const familyApi = " + JSON.stringify(api) + ";\n" +
    "export const adsEnabled = " + (process.env.WEB_ADS_ENABLED === "true") + ";\n",
);
console.log("Web salonu hazır: build/salon");
