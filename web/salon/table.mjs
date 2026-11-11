import { qrcode } from "./qrcode.mjs";
import { familyApi } from "./config.mjs";
import { profileKey } from "./profile.mjs";

const games = { okey: "Klasik Okey", okey101: "101 Okey", city: "Mahalleler" };
const gameDetails = {
  city: "2–4 oyuncu · Mülk al, kira topla ve özel takas yap.",
  okey: "4 oyuncu · Serileri veya yedi çifti tamamla.",
  okey101: "4 oyuncu · 101 puanla ya da beş çiftle aç.",
};
const seats = ["#ffd288", "#a9e6df", "#f8a5aa", "#d3b4f6"];
const colors = ["#24252e", "#a71c37", "#145c89", "#82570d"];
const path = [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12];
const codePattern = /^[A-Z2-9]{6}$/;
const escape = (value) =>
  String(value ?? "").replace(
    /[&<>"']/g,
    (char) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        char
      ],
  );
const button = (type, label, value = "", primary = false) =>
  `<button type="button" class="button ${primary ? "primary" : "outline"}" data-action="${type}" data-value="${escape(value)}">${escape(label)}</button>`;
const playerName = (room, index) => escape(room.players[index]?.name);
const delay = 950;

function endpoint(value) {
  let url;
  try {
    url = new URL(value);
  } catch {
    throw new Error("Masa sunucusunun adresini kontrol et.");
  }
  if (
    !["http:", "https:"].includes(url.protocol) ||
    url.username ||
    url.password ||
    (location.protocol === "https:" && url.protocol !== "https:")
  ) {
    throw new Error("Geçerli bir HTTPS sunucu adresi gir.");
  }
  return url.origin;
}

function tileMarkup(tile, interactive = false, selected = false) {
  if (!tile) return '<span class="quiet">Boş</span>';
  const text = tile.wild ? "★" : escape(tile.value);
  if (!interactive)
    return `<span class="tile" style="color:${colors[tile.color]}">${text}</span>`;
  return `<button type="button" class="tile" style="color:${colors[tile.color]}" data-action="select"
    data-value="${escape(tile.id)}" aria-pressed="${selected}" aria-label="${tile.wild ? "Okey" : ["Siyah", "Kırmızı", "Mavi", "Sarı"][tile.color] + " " + tile.value}">${text}</button>`;
}

export function openTable(main, params) {
  const route = params.get("family");
  const host = route === "tv";
  const firstCode = route?.toUpperCase() ?? "";
  let server = location.origin;
  try {
    server = endpoint(params.get("server") || familyApi || location.origin);
  } catch {}
  let code = codePattern.test(firstCode) ? firstCode : "";
  let token;
  let room;
  let busy = false;
  let timer;
  let error = "";
  let currentGame = Object.keys(games).includes(params.get("game"))
    ? params.get("game")
    : "city";
  let rack = [];
  let selected = [];
  let groups = [];
  let pairs = false;
  let diceChanged = false;
  const storage = {
    get(key) {
      try {
        return localStorage.getItem(key);
      } catch {
        return null;
      }
    },
    set(key, value) {
      try {
        localStorage.setItem(key, value);
      } catch {}
    },
    drop(key) {
      try {
        localStorage.removeItem(key);
      } catch {}
    },
  };
  const hostKey = () => "az-salon-host-" + server;
  const seatKey = () => "az-salon-seat-" + server + "/" + code;
  const inviteUrl = () => {
    const url = new URL("/", location.origin);
    url.searchParams.set("family", code);
    if (server !== (familyApi || location.origin))
      url.searchParams.set("server", server);
    return url.href;
  };
  const keepRoomAddress = () => {
    const url = new URL(inviteUrl());
    if (host) url.searchParams.set("family", "tv");
    history.replaceState(null, "", url);
  };
  main.className = host ? "shell room-page host-page" : "shell room-page";
  main.innerHTML = `<div class="room-title"><div><h1>${host ? "TV Masası" : "Masaya katıl"}</h1>
    <p>${host ? "TV veya bilgisayar için ortak ekran" : "Oyuncu kumandası"}</p></div>
    <div class="actions">${host && document.fullscreenEnabled ? '<button class="button outline" id="full-table">Tam ekran</button>' : ""}
    <a class="button outline" href="/">Oyun salonu</a></div></div>
    <p class="status" role="status"></p><div id="table-view"></div>`;
  const status = main.querySelector(".status");
  const view = main.querySelector("#table-view");
  const setError = (message) => {
    error = message;
    status.textContent = message;
  };
  const full = main.querySelector("#full-table");
  if (full) {
    full.addEventListener("click", async () => {
      try {
        if (document.fullscreenElement) await document.exitFullscreen();
        else await document.documentElement.requestFullscreen();
      } catch {
        setError("Bu tarayıcı tam ekranı açamadı.");
      }
    });
    document.addEventListener("fullscreenchange", () => {
      full.textContent = document.fullscreenElement
        ? "Tam ekrandan çık"
        : "Tam ekran";
    });
  }
  const showSetup = () => {
    const serverField = `<details><summary>Sunucu ayarı</summary><label class="control">Masa sunucusu
      <input name="server" type="url" inputmode="url" value="${escape(server)}" autocapitalize="off"></label></details>`;
    view.innerHTML = `<div class="room-layout solo-layout"><form class="surface stack" data-form="setup">
      <h2>${host ? "Oyunu seç" : "Koltuğunu al"}</h2>
      ${
        host
          ? `<label class="control">Oyun<select name="game">${Object.entries(
              games,
            )
              .map(
                ([id, name]) =>
                  `<option value="${id}" ${currentGame === id ? "selected" : ""}>${name}</option>`,
              )
              .join("")}</select></label>
        <div class="setup-preview" data-game="${currentGame}">
          <p>${gameDetails[currentGame]}</p>
        </div>
        <p class="quiet">Bu ekran tahtayı gösterir. Oyuncular QR ile telefonlarından bağlanır.</p>`
          : `<label class="control">Oyuncu adı<input name="name" autocomplete="nickname" maxlength="24" required></label>
        <label class="control">Masa kodu<input name="code" class="join-code" value="${escape(code)}" maxlength="6" spellcheck="false" autocapitalize="characters" required></label>
        <p class="quiet"><a href="/?profil" target="_blank" rel="noopener">Profil oluştur veya aç</a> · Tamamlanan masalardan XP kazan.</p>`
      }
      <button class="button primary" type="submit">${host ? "Masa aç" : "Katıl"}</button>${serverField}
    </form></div>`;
  };
  const request = async (suffix, data, auth = token) => {
    const response = await fetch(server + "/api/family/rooms" + suffix, {
      method: data ? "POST" : "GET",
      headers: {
        ...(auth && { Authorization: "Bearer " + auth }),
        ...(data && { "Content-Type": "application/json" }),
      },
      body: data ? JSON.stringify(data) : undefined,
      cache: "no-store",
      signal: globalThis.AbortSignal?.timeout?.(7000),
    }).catch(() => {
      throw new Error(
        "Sunucuya bağlanılamadı. Ağ bağlantısını ve sunucu adresini kontrol et.",
      );
    });
    if (!response.headers.get("content-type")?.includes("application/json")) {
      throw new Error(
        "Aile Masası sunucusuna ulaşılamadı. Sunucu ayarını kontrol et.",
      );
    }
    const result = await response.json();
    if (!response.ok)
      throw Object.assign(new Error(result.error || "Masa açılamadı."), {
        status: response.status,
      });
    return result;
  };
  const accept = (next) => {
    if (room && next.revision <= room.revision) return;
    diceChanged = Boolean(
      next.dice &&
        (!room?.dice || (room.phase === "roll" && next.phase !== "roll")),
    );
    room = next;
    const ids = (room.private?.hand || []).map((tile) => tile.id);
    rack = [
      ...rack.filter((id) => ids.includes(id)),
      ...ids.filter((id) => !rack.includes(id)),
    ];
    selected = selected.filter((id) => ids.includes(id));
    groups = groups.filter((group) => group.every((id) => ids.includes(id)));
    render();
  };
  const refresh = () => request("/" + code).then(accept);
  const poll = () => {
    clearTimeout(timer);
    timer = setTimeout(async () => {
      if (!busy) {
        try {
          await refresh();
          if (error.startsWith("Bağlantı")) setError("");
        } catch (failure) {
          if (failure.status === 404 || failure.status === 401) {
            reset();
            setError("Masa kapandı veya oturumun süresi doldu.");
            return;
          }
          setError("Bağlantı: " + failure.message);
        }
      }
      if (token) poll();
    }, delay);
  };
  const reset = () => {
    clearTimeout(timer);
    storage.drop(host ? hostKey() : seatKey());
    room = token = undefined;
    code = "";
    rack = [];
    selected = [];
    groups = [];
    pairs = false;
    if (!host) {
      const url = new URL(inviteUrl());
      url.searchParams.set("family", "join");
      history.replaceState(null, "", url);
    }
    setError("");
    showSetup();
    view.querySelector("button").focus();
  };
  async function connect(form) {
    server = endpoint(form.get("server"));
    if (host) {
      currentGame = form.get("game");
      const created = await request("", { game: currentGame }, null);
      code = created.code;
      token = created.token;
      storage.set(hostKey(), JSON.stringify({ code, token }));
      keepRoomAddress();
    } else {
      code = String(form.get("code")).trim().toUpperCase();
      if (!codePattern.test(code))
        throw new Error("Altı karakterli oda kodunu kontrol et.");
      token = storage.get(seatKey());
      if (token) {
        try {
          await refresh();
          keepRoomAddress();
          poll();
          return;
        } catch (failure) {
          if (failure.status !== 401) throw failure;
        }
      }
      const joined = await request(
        "/" + code + "/join",
        { name: String(form.get("name")).trim(), profileToken: profileKey(server) },
        null,
      );
      token = joined.token;
      storage.set(seatKey(), token);
      keepRoomAddress();
    }
    await refresh();
    poll();
    view.querySelector("button, a")?.focus();
  }

  function render() {
    const active = document.activeElement;
    const focus =
      view.contains(active) && active.dataset.action
        ? [active.dataset.action, active.dataset.value]
        : null;
    const formActive =
      view.contains(active) && active.closest('form[data-form="trade"]');
    const oldTrade = view.querySelector('form[data-form="trade"]');
    const lobby = room.status === "lobby";
    const city = room.game === "city";
    const playing = room.status === "playing";
    const privateView = !host && playing && room.private;
    const invite = host && lobby ? inviteUrl() : "";
    const message = playing
      ? `<p class="turn">Sıra ${playerName(room, room.turn)} oyuncusunda</p>`
      : "";
    const roster = `<ul class="roster" aria-label="Oyuncular">${room.players
      .map(
        (player, index) =>
          `<li class="${room.turn === index ? "active" : ""}">${index + 1}. ${escape(player.name)}${index === room.seat ? " (sen)" : ""}${player.count != null ? " · " + escape(player.count) + " taş" : ""}</li>`,
      )
      .join("")}</ul>`;
    const controls = privateView
      ? `<section class="surface stack">${city ? cityControls(room) : rackControls(room)}</section>`
      : "";
    view.innerHTML = `<div class="room-layout ${privateView ? "phone-controls" : !invite ? "room-full" : ""}">
      <section class="surface"><h2>${games[room.game]}</h2>${message}
      ${room.status === "finished" && room.winner != null ? '<p class="turn">' + playerName(room, room.winner) + " kazandı</p>" : ""}
      <p class="quiet">${escape(room.message || (lobby ? "Oyuncular bekleniyor." : ""))}</p>${roster}
      ${city ? cityBoard(room) : lobby ? "" : tileBoard(room)}
      ${room.status === "finished" ? '<div class="actions">' + button("reset", "Masa seçimine dön") +
        (!host && profileKey(server) ? '<a class="button outline" href="/?profil">XP ve rozetlerini gör</a>' : "") + "</div>" : ""}
      ${host && playing ? '<div class="actions">' + button("close", "Masayı kapat") + "</div>" : ""}
      ${!host && lobby ? '<p class="quiet">TV’de oyunun başlamasını bekle.</p><div class="actions">' + button("leave", "Masadan ayrıl") + "</div>" : ""}
      </section>
      ${
        invite
          ? `<aside class="surface qr-panel stack"><div id="table-qr"></div><p class="code">${code}</p>
        <a class="button outline" href="${escape(invite)}" target="_blank" rel="noopener">Katılım bağlantısı</a>
        <button class="button primary" data-action="start" ${room.players.length < (city ? 2 : 4) ? "disabled" : ""}>Başlat · ${escape(room.players.length)}/4</button>
        ${button("close", "Masayı kapat")}</aside>`
          : ""
      }
      ${controls}</div>`;
    if (invite) {
      const qr = qrcode(0, "M");
      qr.addData(invite);
      qr.make();
      const svg = qr
        .createSvgTag(5, 20)
        .replace(
          "<svg ",
          '<svg class="qr" role="img" aria-label="Masaya katılım QR kodu" ',
        );
      view.querySelector("#table-qr").innerHTML = svg;
    }
    if (diceChanged) {
      view.querySelector(".dice")?.classList.add("dice-arrival");
      diceChanged = false;
    }
    if (
      formActive &&
      oldTrade &&
      view.querySelector('form[data-form="trade"]')
    ) {
      view.querySelector('form[data-form="trade"]').replaceWith(oldTrade);
      active.focus({ preventScroll: true });
    } else if (focus) {
      [...view.querySelectorAll("[data-action]")]
        .find(
          (element) =>
            element.dataset.action === focus[0] &&
            element.dataset.value === focus[1],
        )
        ?.focus({ preventScroll: true });
    }
  }

  function rackControls(state) {
    const hand = state.private.hand || [];
    const mine = state.turn === state.seat;
    const previous =
      (state.seat + state.players.length - 1) % state.players.length;
    const single = selected.length === 1 ? selected[0] : "";
    const ids = new Set(groups.flat());
    return `<h2>Istakan</h2><p class="quiet">${mine ? "Sıra sende." : "Sıranı bekle."}</p>
      <div class="rack tile-row">${rack
        .filter((id) => !ids.has(id))
        .map((id) =>
          tileMarkup(
            hand.find((tile) => tile.id === id),
            true,
            selected.includes(id),
          ),
        )
        .join("")}</div>
      ${groups
        .map(
          (group, index) =>
            `<div class="tile-row">${group
              .map((id) => tileMarkup(hand.find((tile) => tile.id === id)))
              .join("")}${button("ungroup", "Grubu geri al", index)}</div>`,
        )
        .join("")}
      <div class="actions">${single !== "" ? button("reorder", "Sola kaydır", -1) + button("reorder", "Sağa kaydır", 1) : ""}
      ${
        mine && state.phase === "draw"
          ? button("draw", "Desteden çek", "stock", true) +
            (state.discards?.[previous]
              ? button("draw", "Atılan taşı al", "discard")
              : "")
          : ""
      }
      ${
        mine && state.phase === "discard"
          ? [
              state.private.requiredTile != null
                ? button("returnDiscard", "Taşı geri bırak")
                : "",
              single !== "" ? button("discard", "Taşı at", single, true) : "",
              single !== "" && state.game === "okey"
                ? button("win", "Eli bitir", single)
                : "",
              state.game === "okey101" && selected.length >= 2
                ? button("group", "Grup ayır")
                : "",
              state.game === "okey101" && groups.length
                ? button(
                    "meld",
                    pairs ? "Çiftleri işle" : "Perleri işle",
                    "",
                    true,
                  ) + button("pairs", pairs ? "Seriye geç" : "Çift olarak aç")
                : "",
            ].join("")
          : ""
      }</div>
      ${
        mine &&
        state.game === "okey101" &&
        state.phase === "discard" &&
        state.players[state.seat]?.opened &&
        single !== ""
          ? (state.melds || [])
              .map((meld, index) =>
                !meld.pair
                  ? button("extend", index + 1 + ". gruba işle", index)
                  : "",
              )
              .join(" ")
          : ""
      }`;
  }

  function cityControls(state) {
    const mine = state.turn === state.seat;
    const money = state.private.money;
    const trade = state.private.trade;
    const offers = state.board
      .map((square, index) => ({ ...square, index }))
      .filter((square) => square.owner === state.seat);
    const offerChoices = state.players
      .map((player, index) =>
        index !== state.seat && !player.out
          ? `<option value="${index}">${escape(player.name)}</option>`
          : "",
      )
      .join("");
    const canManage =
      mine && ["roll", "end"].includes(state.phase) && offers.length;
    return `<h2>Cüzdanın</h2><p class="turn">${escape(money)} para</p>
      ${state.private.card ? "<p>" + escape(state.private.card) + "</p>" : ""}
      ${
        trade
          ? `<p>${escape(state.board[trade.square].name)} · ${escape(trade.price)} para</p><div class="actions">
      ${
        trade.to === state.seat
          ? button("tradeReply", "Kabul et", "yes", true) +
            button("tradeReply", "Reddet", "no")
          : mine && state.phase !== "auction"
            ? button("cancelTrade", "Teklifi geri çek")
            : ""
      }</div>`
          : ""
      }
      <div class="actions">
      ${mine && state.phase === "roll" ? button("roll", "Zar at", "", true) : ""}
      ${mine && state.phase === "property" ? button("buy", "Mülkü al", "", true) + button("auction", "Açık artır") : ""}
      ${state.auction?.bidder === state.seat ? button("bid", state.auction.bid + 10 + " para teklif et", "", true) + button("passBid", "Pas") : ""}
      ${mine && state.phase === "end" ? button("end", "Sırayı bitir", "", true) : ""}
      </div>
      ${
        canManage
          ? offers
              .filter(
                (square) =>
                  square.level < 3 &&
                  state.board.every(
                    (peer) =>
                      peer.group !== square.group || peer.owner === state.seat,
                  ),
              )
              .map((square) =>
                button(
                  "build",
                  square.name + " geliştir · 60 para",
                  square.index,
                ),
              )
              .join(" ")
          : ""
      }
      ${
        canManage && !trade && offerChoices
          ? `<form class="stack" data-form="trade">
        <label class="control">Tapu<select name="square">${offers
          .map(
            (square) =>
              `<option value="${square.index}">${escape(square.name)}</option>`,
          )
          .join("")}</select></label>
        <label class="control">Alıcı<select name="to">${offerChoices}</select></label>
        <label class="control">Fiyat<input name="price" type="number" min="0" max="2000" value="100" required></label>
        <button class="button outline">Özel teklif gönder</button></form>`
          : ""
      }`;
  }

  function cityBoard(state) {
    return `${state.dice ? `<p class="turn dice" role="status"><span aria-hidden="true">⚄</span> Zarlar ${escape(state.dice.join(" + "))} · Tur ${escape(state.round)}/10</p>` : ""}
      ${
        state.wealth
          ? `<ol class="wealth" aria-label="Oyun sonu sıralaması">${state.wealth
              .map((total, seat) => ({ total, seat }))
              .sort((a, b) => b.total - a.total)
              .map(
                ({ seat, total }) =>
                  "<li>" +
                  playerName(state, seat) +
                  " · " +
                  total +
                  " para</li>",
              )
              .join("")}</ol>`
          : ""
      }
      ${state.auction ? `<p class="quiet">Açık artırma · ${escape(state.board[state.auction.square].name)} · ${escape(state.auction.bid)} para</p>` : ""}
      <div class="city-board" aria-label="Mahalleler tahtası">${path
        .map((index) => {
          const square = state.board[index];
          const pawns = state.players.flatMap((player, seat) =>
            player.position === index && !player.out
              ? [
                  `<span class="pawn" style="--pawn:${seats[seat]}" title="${escape(player.name)}">${seat + 1}</span>`,
                ]
              : [],
          );
          return `<div class="square" data-group="${Number(square.group) || 0}"><strong>${escape(square.name)}</strong>
          ${
            square.price
              ? `<small>${
                  square.owner == null
                    ? escape(square.price) + " para"
                    : playerName(state, square.owner) +
                      (square.level ? " · Seviye " + escape(square.level) : "")
                }</small>`
              : ""
          }<div class="pawns">${pawns.join("")}</div></div>`;
        })
        .join("")}</div>`;
  }

  function tileBoard(state) {
    if (!state.indicator) return "";
    return `<div class="tile-row"><strong>Gösterge</strong> ${tileMarkup(state.indicator)}
      <span class="quiet">Deste ${escape(state.stockCount)} taş</span></div>
      <div class="tile-row">${state.players
        .map(
          (player, index) =>
            `<div class="tile-row"><small>${escape(player.name)}</small>${tileMarkup(state.discards[index])}</div>`,
        )
        .join("")}</div>
      ${state.melds
        .map(
          (
            meld,
            index,
          ) => `<div class="tile-row"><small>${index + 1}. grup</small>
        ${meld.tiles.map((tile) => tileMarkup(tile)).join("")}</div>`,
        )
        .join("")}`;
  }

  async function run(action, control) {
    if (busy) return;
    busy = true;
    if (control) control.disabled = true;
    setError("");
    try {
      await action();
    } catch (failure) {
      setError(failure.message || "Masa sunucusuna bağlanılamadı.");
    } finally {
      busy = false;
      if (control?.isConnected) control.disabled = false;
    }
  }
  async function submitAction(type, details = {}) {
    const next = await request("/" + code + "/action", {
      type,
      revision: room.revision,
      ...details,
    });
    if (type === "leave") reset();
    else accept(next);
  }
  view.addEventListener("submit", (event) => {
    event.preventDefault();
    const form = new FormData(event.target);
    if (event.target.dataset.form === "setup")
      run(() => connect(form), event.submitter);
    else
      run(
        () =>
          submitAction("trade", {
            square: Number(form.get("square")),
            to: Number(form.get("to")),
            price: Number(form.get("price")),
          }),
        event.submitter,
      );
  });
  view.addEventListener("change", (event) => {
    if (event.target.name !== "game") return;
    currentGame = event.target.value;
    const preview = view.querySelector(".setup-preview");
    preview.dataset.game = currentGame;
    preview.querySelector("p").textContent = gameDetails[currentGame];
  });
  view.addEventListener("click", (event) => {
    const control = event.target.closest("[data-action]");
    if (!control || busy) return;
    const { action, value } = control.dataset;
    const number = Number(value);
    if (action === "reset") return reset();
    if (action === "select") {
      if (selected.includes(number))
        selected = selected.filter((id) => id !== number);
      else if (room.game === "okey") selected = [number];
      else selected.push(number);
      return render();
    }
    if (action === "group") {
      groups.push(selected);
      selected = [];
      return render();
    }
    if (action === "ungroup") {
      groups.splice(number, 1);
      return render();
    }
    if (action === "pairs") {
      pairs = !pairs;
      return render();
    }
    if (action === "reorder") {
      const from = rack.indexOf(selected[0]);
      const to = from + number;
      if (to >= 0 && to < rack.length)
        [rack[from], rack[to]] = [rack[to], rack[from]];
      return render();
    }
    const details = {
      draw: { source: value },
      discard: { tile: number },
      win: { tile: number },
      extend: { index: number, tile: selected[0] },
      meld: { groups, pairs },
      build: { square: number },
      tradeReply: { accept: value === "yes" },
    };
    run(() => submitAction(action, details[action]), control);
  });
  if (host)
    main.addEventListener("keydown", (event) => {
      if (
        !["ArrowDown", "ArrowUp", "ArrowLeft", "ArrowRight"].includes(
          event.key,
        ) ||
        ["INPUT", "SELECT"].includes(event.target.tagName)
      )
        return;
      const items = [
        ...main.querySelectorAll(
          "button:not([disabled]), a, input, select, summary",
        ),
      ].filter((item) => item.getClientRects().length > 0);
      const step = ["ArrowDown", "ArrowRight"].includes(event.key) ? 1 : -1;
      const index = items.indexOf(document.activeElement);
      const target = items[index < 0 ? 0 : index + step];
      if (target) {
        event.preventDefault();
        target.focus();
      }
    });
  showSetup();
  if (host) view.querySelector("select").focus({ preventScroll: true });
  if (host) {
    try {
      const saved = JSON.parse(storage.get(hostKey()));
      if (saved && codePattern.test(saved.code) && !params.has("game"))
        ({ code, token } = saved);
    } catch {}
  } else if (code) token = storage.get(seatKey());
  if (token)
    refresh()
      .then(poll)
      .catch((failure) => {
        setError(failure.message);
        token = undefined;
      });
}
