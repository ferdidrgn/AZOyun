const DATA_URL = "/football/catalog.json";
const CACHE_KEY = "az-football-catalog-v1";
const ROUND_SECONDS = 120;
const normalize = (value) => String(value).normalize("NFD")
  .replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase("tr")
  .replace(/[^a-z0-9]/g, "");

function validCatalog(value) {
  return Array.isArray(value?.players) && value.players.length >= 100 &&
    Array.isArray(value?.grids?.box2box?.current?.rows) &&
    Array.isArray(value?.grids?.box2box?.current?.columns) &&
    value.grids.box2box.current.rows.length === 3 &&
    value.grids.box2box.current.columns.length === 3;
}

async function loadCatalog() {
  let lastError;
  try {
    const response = await fetch(DATA_URL, { cache: "no-store", headers: { Accept: "application/json" } });
    if (!response.ok) throw new Error(`Katalog HTTP ${response.status}`);
    const catalog = await response.json();
    if (!validCatalog(catalog)) throw new Error("Katalog biçimi geçersiz veya günlük tahta eksik.");
    try { localStorage.setItem(CACHE_KEY, JSON.stringify(catalog)); } catch (_) { /* cache optional */ }
    return { catalog, cached: false };
  } catch (error) {
    lastError = error;
  }
  try {
    const cached = JSON.parse(localStorage.getItem(CACHE_KEY) || "null");
    if (validCatalog(cached)) return { catalog: cached, cached: true };
  } catch (_) { /* cache optional */ }
  throw new Error(`Futbol kataloğu yüklenemedi: ${lastError?.message || "kaynak erişilemiyor"}`);
}

function make(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

export async function openFootballGrid(main) {
  document.title = "Futbol Box2Box · AZ Oyun";
  main.className = "shell room-page football-grid-page";
  main.innerHTML = `<div class="room-title"><div><h1>Futbol Box2Box</h1><p>Gerçek kariyer geçmişinden kulüp × ülke 3×3</p></div><a class="button outline" href="/#oyunlar">Oyun salonu</a></div>
    <section class="surface football-grid-shell" aria-label="Futbol Box2Box oyunu"><p class="football-grid-status" role="status">Günlük futbol kataloğu yükleniyor…</p></section>`;
  const shell = main.querySelector(".football-grid-shell");
  try {
    const { catalog, cached } = await loadCatalog();
    renderGame(shell, catalog, cached);
  } catch (error) {
    const status = shell.querySelector(".football-grid-status");
    status.textContent = error.message;
    status.classList.add("is-error");
    const retry = make("button", "button primary", "Yeniden dene");
    retry.type = "button";
    retry.addEventListener("click", () => openFootballGrid(main));
    shell.append(retry);
    const dataHint = make("p", "football-grid-help", "Bu oyun statik soru listesi kullanmaz; yayınlanan Wikidata kataloğu ve günlük 3×3 tahtası gerekir.");
    shell.append(dataHint);
  }
}

function renderGame(shell, catalog, cached) {
  const board = catalog.grids.box2box.current;
  const players = catalog.players.map((player) => ({
    ...player,
    normalizedName: normalize(player.name),
    tags: new Set(player.tags || []),
  })).filter((player) => player.id && player.name && player.tags.size);
  const intersections = board.rows.flatMap((row) => board.columns.map((column) => {
    const matches = players.filter((player) => player.tags.has(row.tag) && player.tags.has(column.tag));
    return { row, column, matches };
  }));
  if (intersections.some((cell) => cell.matches.length === 0)) {
    throw new Error("Günlük tahtada boş kesişim var. Veri paketi yenilenmeli.");
  }

  shell.replaceChildren();
  shell.classList.add("football-grid-game");
  const top = make("div", "football-grid-top");
  const intro = make("p", "football-grid-copy", "Bir kutu seç, iki koşulu da sağlayan futbolcuyu yaz. Aynı oyuncu tahtada bir kez kullanılabilir.");
  const stats = make("div", "football-grid-stats");
  const scoreNode = make("strong", "", "0");
  const timeNode = make("strong", "", String(ROUND_SECONDS));
  const mistakesNode = make("strong", "", "0/3");
  stats.append(stat("PUAN", scoreNode), stat("SÜRE", timeNode), stat("HATA", mistakesNode));
  top.append(intro, stats);

  const boardWrap = make("div", "football-board-wrap");
  const grid = make("div", "football-board");
  grid.setAttribute("role", "grid");
  grid.setAttribute("aria-label", "Futbolcu kategori kesişimleri");
  grid.append(make("div", "football-corner", "KULÜP × ÜLKE"));
  for (const column of board.columns) grid.append(make("div", "football-column", column.label));
  const cells = [];
  const filled = new Set();
  const usedPlayers = new Set();
  const selected = { index: 0 };
  let mistakes = 0;
  let score = 0;
  let seconds = ROUND_SECONDS;
  let finished = false;

  board.rows.forEach((row, rowIndex) => {
    grid.append(make("div", "football-row", row.label));
    board.columns.forEach((column, columnIndex) => {
      const index = rowIndex * 3 + columnIndex;
      const cell = make("button", "football-cell");
      cell.type = "button";
      cell.setAttribute("role", "gridcell");
      cell.dataset.index = String(index);
      cell.setAttribute("aria-label", `${row.label} ve ${column.label}: futbolcu seç`);
      const value = make("span", "football-cell-value", "＋");
      const label = make("span", "football-cell-hint", `${row.label} · ${column.label}`);
      cell.append(value, label);
      cell.addEventListener("click", () => {
        if (finished || filled.has(index)) return;
        selected.index = index;
        cells.forEach((item, itemIndex) => item.button.classList.toggle("is-selected", itemIndex === index));
        selectedLabel.textContent = `${row.label} + ${column.label}`;
        input.focus();
      });
      cells[index] = { button: cell, value, label, row, column, matches: intersections[index].matches };
      grid.append(cell);
    });
  });
  boardWrap.append(grid);

  const entry = make("form", "football-entry");
  entry.autocomplete = "off";
  const selectedLabel = make("label", "football-selected", `${board.rows[0].label} + ${board.columns[0].label}`);
  selectedLabel.htmlFor = "football-player-entry";
  const inputRow = make("div", "football-entry-row");
  const input = make("input");
  input.id = "football-player-entry";
  input.type = "search";
  input.placeholder = "Futbolcu adı yaz";
  input.autocomplete = "off";
  input.enterKeyHint = "send";
  const submit = make("button", "button primary", "Yerleştir");
  submit.type = "submit";
  inputRow.append(input, submit);
  const suggestions = make("div", "football-suggestions");
  suggestions.setAttribute("role", "listbox");
  const message = make("p", "football-grid-message");
  message.setAttribute("role", "status");
  entry.append(selectedLabel, inputRow, suggestions, message);

  const footer = make("div", "football-grid-footer");
  footer.append(make("span", "football-version", `${catalog.datasetVersion || "Wikidata"} · ${players.length.toLocaleString("tr-TR")} futbolcu${cached ? " · çevrimdışı önbellek" : ""}`));
  const restart = make("button", "button outline", "Yeni tahta");
  restart.type = "button";
  restart.addEventListener("click", () => location.reload());
  footer.append(restart);
  shell.append(top, boardWrap, entry, footer);
  cells.forEach((cell, index) => cell.button.classList.toggle("is-selected", index === 0));

  function finish(text) {
    if (finished) return;
    finished = true;
    input.disabled = true;
    submit.disabled = true;
    suggestions.replaceChildren();
    message.textContent = text;
    shell.classList.add("is-finished");
  }

  function updateSuggestionList() {
    suggestions.replaceChildren();
    const query = normalize(input.value.trim());
    if (query.length < 2 || finished) return;
    const options = players.filter((player) => player.normalizedName.includes(query) && !usedPlayers.has(player.id)).slice(0, 8);
    for (const player of options) {
      const option = make("button", "football-suggestion", player.name);
      option.type = "button";
      option.setAttribute("role", "option");
      option.addEventListener("click", () => { input.value = player.name; suggestions.replaceChildren(); input.focus(); });
      suggestions.append(option);
    }
  }

  function submitPlayer(event) {
    event.preventDefault();
    if (finished) return;
    const name = normalize(input.value.trim());
    if (!name) return;
    if (filled.has(selected.index)) {
      message.textContent = "Önce boş bir kutu seç.";
      return;
    }
    const cell = cells[selected.index];
    const candidate = cell.matches.find((player) => player.normalizedName === name && !usedPlayers.has(player.id));
    if (!candidate) {
      const already = players.find((player) => player.normalizedName === name && usedPlayers.has(player.id));
      mistakes++;
      mistakesNode.textContent = `${mistakes}/3`;
      message.textContent = already ? "Bu futbolcuyu tahtada zaten kullandın." : "Bu futbolcu bu kulüp ve ülke kesişimini karşılamıyor.";
      input.select();
      if (mistakes >= 3) finish(`Üç hata hakkın doldu · ${filled.size}/9 kutu · ${score} puan`);
      return;
    }
    const rarity = Math.max(1, Math.round(1000 / cell.matches.length));
    usedPlayers.add(candidate.id);
    filled.add(selected.index);
    score += rarity;
    scoreNode.textContent = String(score);
    cell.button.classList.remove("is-selected");
    cell.button.classList.add("is-filled");
    cell.button.setAttribute("aria-label", `${candidate.name}, ${cell.row.label} ve ${cell.column.label}`);
    cell.value.textContent = candidate.name;
    cell.label.textContent = `NADİRLİK +${rarity}`;
    message.textContent = `${candidate.name} doğru · ${rarity} puan`;
    input.value = "";
    suggestions.replaceChildren();
    const next = cells.findIndex((item, index) => !filled.has(index));
    if (filled.size === 9) finish(`Tahta tamamlandı · ${score} puan`);
    else if (next >= 0) cells[next].button.click();
  }

  input.addEventListener("input", updateSuggestionList);
  entry.addEventListener("submit", submitPlayer);
  let timer = setInterval(() => {
    if (finished) { clearInterval(timer); return; }
    seconds--;
    timeNode.textContent = String(seconds);
    if (seconds <= 0) {
      clearInterval(timer);
      finish(`Süre doldu · ${filled.size}/9 kutu · ${score} puan`);
    }
  }, 1000);
  window.addEventListener("pagehide", () => clearInterval(timer), { once: true });
}

function stat(label, value) {
  const item = make("div", "football-stat");
  item.append(value, make("span", "", label));
  return item;
}
