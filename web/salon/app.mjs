import { classics } from "./classic-catalog.mjs";
import { adsEnabled } from "./config.mjs";

const params = new URLSearchParams(location.search);
const main = document.querySelector("main");
const roomRoute = params.get("family");
const play = main.dataset.play || params.get("play");
const joinPath = location.pathname.split("/").filter(Boolean);
const invite = joinPath[0] === "join" || params.has("join") ||
  (params.has("game") && params.has("code"));

if (roomRoute !== null) {
  markPrivate();
  import("./table.mjs").then(({ openTable }) => openTable(main, params));
} else if (invite) {
  markPrivate();
  const game = params.get("join") || params.get("game") || joinPath[1];
  const code = (params.get("code") || joinPath[2] || "").toUpperCase();
  if (game === "family" && /^[A-Z2-9]{6}$/.test(code)) {
    params.set("family", code);
    import("./table.mjs").then(({ openTable }) => openTable(main, params));
  } else {
    showAppInvite(game, code);
  }
} else if (params.has("profil")) {
  markPrivate();
  import("./profile.mjs").then(({ openProfile }) => openProfile(main));
} else if (play === "ayna") {
  openMirror();
} else if (Object.keys(classics).includes(play)) {
  import("./classic-games.mjs").then(({ openClassic }) =>
    openClassic(main, play),
  );
} else if (document.querySelector(".catalog-grid")) {
  const search = document.querySelector("#game-search");
  const results = document.querySelector("#game-results");
  let filter = "all";
  function updateCatalog() {
    const query = search.value.trim().toLocaleLowerCase("tr");
    let visible = 0;
    for (const game of document.querySelectorAll("[data-kind]")) {
      game.hidden =
        (filter !== "all" && filter !== game.dataset.kind) ||
        !game
          .querySelector("h3")
          .textContent.toLocaleLowerCase("tr")
          .includes(query);
      if (!game.hidden) visible++;
    }
    results.textContent = visible
      ? visible + " oyun"
      : "Eşleşen oyun bulunamadı.";
  }
  document.querySelector(".filters").addEventListener("click", (event) => {
    const button = event.target.closest("[data-filter]");
    if (!button) return;
    for (const option of document.querySelectorAll("[data-filter]")) {
      option.setAttribute("aria-pressed", String(option === button));
    }
    filter = button.dataset.filter;
    updateCatalog();
  });
  search.addEventListener("input", updateCatalog);
  updateCatalog();
}

if (play && !main.dataset.play) {
  const canonical = document.querySelector('link[rel="canonical"]');
  if (canonical && (play === "ayna" || Object.keys(classics).includes(play))) {
    canonical.href = new URL("/oyun/" + play + "/", canonical.href);
  }
}
if (adsEnabled && location.hostname === "azoyun.web.app" && !invite &&
    roomRoute === null && !location.search) {
  const publisher = document.querySelector('meta[name="google-adsense-account"]').content;
  const script = document.createElement("script");
  script.async = true;
  script.crossOrigin = "anonymous";
  script.src = "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=" + publisher;
  document.head.append(script);
}

function markPrivate() {
  let robots = document.querySelector('meta[name="robots"]');
  if (!robots) {
    robots = document.createElement("meta");
    robots.name = "robots";
    document.head.append(robots);
  }
  robots.content = "noindex";
}

function showAppInvite(game, code) {
  const supported = /^(golf|soccer|hangman|city|word|vampire|liar|okey|okey101|fighter|racing|dama|impostor|deck|sonkart|istasyon90|penaltiduello)$/.test(game);
  document.title = "Oda Daveti · AZ Oyun";
  main.className = "shell room-page";
  main.innerHTML = `<div class="room-title"><h1>Oda daveti</h1></div>
    <section class="surface stack classic-stage">${supported && /^[A-Z0-9]{4,12}$/.test(code)
      ? `<p>Oda kodu <strong>${code}</strong></p><a class="button primary" href="azoyun://join/${game}/${code}">Uygulamada aç</a>
         <a class="button outline" href="https://play.google.com/store/apps/details?id=com.ferdidrgn.azgame">Google Play</a>`
      : '<p>Bu davet bağlantısı geçersiz.</p>'}
    <a href="/#oyunlar">Oyun salonuna dön</a></section>`;
}

function openMirror() {
  document.title = "Ayna Odası · AZ Oyun";
  main.className = "shell room-page";
  main.innerHTML = `<div class="room-title"><h1>Ayna Odası</h1><a class="button outline" href="/#oyunlar">Oyun salonu</a></div>
    <section class="surface stack"><p>Işıklara bak, sonra işaretlere aynı sırayla dokun.</p>
    <p id="mirror-status" role="status">Başlamak için hazır ol.</p>
    <div class="illusion-board" aria-label="Ayna işaretleri">
      <button data-sign="0" aria-label="Yıldız">✦</button><button data-sign="1" aria-label="Daire">●</button>
      <button data-sign="2" aria-label="Üçgen">▲</button><button data-sign="3" aria-label="Elmas">◆</button>
    </div><div><button class="button primary" id="mirror-start">Başla</button></div></section>`;
  const tiles = [...main.querySelectorAll("[data-sign]")];
  const status = main.querySelector("#mirror-status");
  const start = main.querySelector("#mirror-start");
  const sequence = [];
  let cursor = 0;
  let phase = "idle";
  const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  async function nextRound() {
    phase = "show";
    cursor = 0;
    sequence.push(Math.floor(Math.random() * tiles.length));
    status.textContent = "Tur " + sequence.length + ". İşaretleri izle.";
    await delay(460);
    for (const index of sequence) {
      tiles[index].classList.add("lit");
      status.textContent = tiles[index].getAttribute("aria-label");
      await delay(550);
      tiles[index].classList.remove("lit");
      status.textContent = " ";
      await delay(210);
    }
    phase = "input";
    status.textContent = "Tur " + sequence.length + ". Şimdi sıra sende.";
  }
  start.addEventListener("click", () => {
    sequence.length = 0;
    start.disabled = true;
    nextRound();
  });
  for (const tile of tiles)
    tile.addEventListener("click", async () => {
      if (phase !== "input") return;
      if (Number(tile.dataset.sign) !== sequence[cursor]) {
        phase = "idle";
        status.textContent = "Tamamlanan tur: " + (sequence.length - 1);
        start.disabled = false;
        start.textContent = "Yeniden oyna";
        return;
      }
      cursor++;
      tile.classList.add("lit");
      if (cursor === sequence.length) nextRound();
      await delay(160);
      tile.classList.remove("lit");
    });
}
