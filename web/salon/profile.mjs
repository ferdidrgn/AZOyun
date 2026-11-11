import { familyApi } from "./config.mjs";

export function profileEndpoint() {
  return new URL(familyApi || location.origin).origin;
}

function keyName(server) {
  return "az-family-profile:" + new URL(server).origin;
}
export function profileKey(server) {
  try { return localStorage.getItem(keyName(server)); } catch { return null; }
}
function storeKey(server, key) {
  try {
    if (key) localStorage.setItem(keyName(server), key);
    else localStorage.removeItem(keyName(server));
  } catch {}
}
const text = (tag, value) => {
  const element = document.createElement(tag);
  element.textContent = value;
  return element;
};

export function openProfile(main) {
  const server = profileEndpoint();
  document.title = "Oyuncu profili · AZ Oyun";
  main.className = "shell room-page";
  main.innerHTML = `<div class="room-title"><h1>Oyuncu profili</h1><a class="button outline" href="/#oyunlar">Oyun salonu</a></div>
    <div class="room-layout profile-layout"><section class="surface stack" id="player-profile"></section>
    <section class="surface stack"><h2>Aile Masası sıralaması</h2><ol id="player-ranks" class="profile-ranks"></ol><p class="quiet" id="ranking-status"></p></section></div>`;
  const personal = main.querySelector("#player-profile");
  const ranks = main.querySelector("#player-ranks");
  const rankingStatus = main.querySelector("#ranking-status");
  async function request(route, { name, key } = {}) {
    const response = await fetch(server + "/api/progression/" + route, {
      method: name === undefined ? "GET" : "POST",
      headers: { ...(key && { Authorization: "Bearer " + key }),
        ...(name !== undefined && { "Content-Type": "application/json" }) },
      body: name === undefined ? undefined : JSON.stringify({ name }),
      signal: globalThis.AbortSignal?.timeout?.(7000),
    });
    if (!response.headers.get("content-type")?.includes("application/json"))
      throw new Error("Aile Masası profil sunucusuna ulaşılamadı.");
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Profil açılamadı.");
    return data;
  }
  function showLogin(error = "") {
    personal.innerHTML = `<h2>Aile Masası profili</h2><p>Bitirdiğin masalardan XP kazan. Oyuncu anahtarını saklayarak aynı profili başka cihazda açabilirsin.</p>
      <form class="stack" data-create><label class="control">Oyuncu adı<input name="name" maxlength="24" autocomplete="nickname" required></label>
      <button class="button primary">Profil oluştur</button></form>
      <form class="stack" data-restore><label class="control">Oyuncu anahtarı<input name="key" type="password" autocomplete="off" required></label>
      <button class="button outline">Profilimi aç</button></form><p class="status" role="status"></p>`;
    personal.querySelector(".status").textContent = error;
  }
  function showProfile(profile, key) {
    personal.innerHTML = `<div class="profile-metrics"></div><h2>Rozet vitrini</h2><ul class="profile-goals"></ul>
      <details><summary>Başka cihazda aç</summary><p>Bu anahtar hesabını açar. Yalnızca kendin için güvenli bir yerde sakla.</p>
      <label class="control">Oyuncu anahtarı<input name="profile-key" type="password" readonly autocomplete="off"></label>
      <div class="actions"><button type="button" class="button outline" data-reveal>Anahtarı göster</button></div></details>
      <button type="button" class="button outline" data-logout>Bu cihazdan çık</button>`;
    personal.prepend(text("h2", profile.name));
    const metrics = personal.querySelector(".profile-metrics");
    for (const [label, value] of [["Seviye", profile.level], ["XP", profile.xp], ["Oyun", profile.played], ["Galibiyet", profile.wins]]) {
      const item = document.createElement("div");
      item.append(text("strong", value), text("span", label));
      metrics.append(item);
    }
    const goals = personal.querySelector(".profile-goals");
    for (const goal of profile.goals) {
      const row = document.createElement("li");
      const requirement = goal.stat === "wins" ? "galibiyet" :
        goal.stat === "variety" ? "farklı masa oyunu" : "tamamlanan maç";
      row.append(text("strong", goal.name), text("span",
        Math.min(goal.count, goal.target) + "/" + goal.target + " " + requirement +
        (profile.badges.includes(goal.id) ? " · Kazanıldı" : "")));
      goals.append(row);
    }
    personal.querySelector('[name="profile-key"]').value = key;
  }
  async function load(key) {
    const profile = await request("profile", { key });
    storeKey(server, key);
    showProfile(profile, key);
  }
  personal.addEventListener("submit", async (event) => {
    event.preventDefault();
    const form = event.target;
    const button = event.submitter;
    button.disabled = true;
    const fields = new FormData(form);
    try {
      const key = form.hasAttribute("data-create")
        ? (await request("profile", { name: String(fields.get("name")).trim() })).key
        : String(fields.get("key")).trim();
      await load(key);
    } catch (error) {
      personal.querySelector(".status").textContent = error.message;
    } finally { button.disabled = false; }
  });
  personal.addEventListener("click", (event) => {
    if (event.target.closest("[data-logout]")) { storeKey(server, null); showLogin(); }
    const reveal = event.target.closest("[data-reveal]");
    if (reveal) {
      const input = personal.querySelector('[name="profile-key"]');
      input.type = input.type === "password" ? "text" : "password";
      reveal.textContent = input.type === "text" ? "Anahtarı gizle" : "Anahtarı göster";
    }
  });
  showLogin();
  const key = profileKey(server);
  if (key) load(key).catch((error) => showLogin(error.message));
  request("leaderboard").then(({ players }) => {
    if (!players.length) rankingStatus.textContent = "Henüz sonuç kaydedilmedi.";
    for (const player of players) {
      const row = document.createElement("li");
      row.append(text("strong", player.name), text("span", player.xp + " XP · " + player.wins + " galibiyet"));
      ranks.append(row);
    }
  }).catch((error) => { rankingStatus.textContent = error.message; });
}
