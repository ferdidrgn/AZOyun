import { classics } from "./classic-catalog.mjs";

const shuffle = (items) => {
  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
};
const range = (count) => Array.from({ length: count }, (_, i) => i);
const random = (limit) => Math.floor(Math.random() * limit);
const btn = (text, action, extra = "") =>
  `<button type="button" class="button outline" data-move="${action}" ${extra}>${text}</button>`;
const grid = (count, content, type = "") =>
  `<div class="classic-grid ${type}" style="--columns:${count}">${content}</div>`;
const formatWord = (text) => text.trim().toLocaleUpperCase("tr");
const directions = [-1, 0, 1].flatMap((row) =>
  [-1, 0, 1].filter((column) => row || column).map((column) => [row, column]),
);

export function openClassic(main, id) {
  const [name, description, mode] = classics[id];
  document.title = name + " · AZ Oyun";
  main.className = "shell room-page";
  main.innerHTML = `<div class="room-title"><div><h1>${name}</h1><p>${mode} · ${description}</p></div>
    <a class="button outline" href="/#oyunlar">Oyun salonu</a></div>
    <section class="surface classic-stage"><p class="classic-status" role="status"></p><div class="classic-play"></div>
    <div class="actions"><button type="button" class="button outline" id="classic-reset">Yeni oyun</button></div></section>`;
  const surface = main.querySelector(".classic-play");
  const status = main.querySelector(".classic-status");
  const restart = main.querySelector("#classic-reset");
  let dispose;
  function start() {
    dispose?.();
    surface.replaceChildren();
    status.textContent = "";
    const paint = (html, message) => {
      const active = document.activeElement?.dataset.move;
      surface.innerHTML = html;
      if (message !== undefined) status.textContent = message;
      if (active !== undefined)
        [...surface.querySelectorAll("[data-move]")]
          .find((el) => el.dataset.move === active && !el.disabled)
          ?.focus({ preventScroll: true });
    };
    dispose = implementations[id]({
      paint,
      surface,
      say: (message) => {
        status.textContent = message;
      },
    });
  }
  restart.addEventListener("click", start);
  window.addEventListener("pagehide", () => dispose?.(), { once: true });
  start();
}
function click(surface, handler) {
  surface.onclick = (event) => {
    const target = event.target.closest("[data-move]");
    if (target) handler(target.dataset.move);
  };
  return () => {
    surface.onclick = null;
  };
}
function lineGame({ paint, surface }, connect) {
  const width = connect ? 7 : 3;
  const height = connect ? 6 : 3;
  const board = Array(width * height).fill("");
  let turn = 0;
  let done = false;
  const marks = connect ? ["●", "○"] : ["X", "O"];
  const render = (message = "Sıra " + marks[turn]) =>
    paint(
      (connect
        ? grid(
            width,
            range(width)
              .map((column) =>
                btn("↓", column, `aria-label="${column + 1}. sütuna bırak"`),
              )
              .join(""),
          )
        : "") +
        grid(
          width,
          board
            .map((mark, index) =>
              connect
                ? `<span class="classic-cell">${mark}</span>`
                : btn(
                    mark || "·",
                    index,
                    `aria-label="${index + 1}. hücre ${mark || "boş"}" ${mark || done ? "disabled" : ""}`,
                  ),
            )
            .join(""),
        ),
      message,
    );
  render();
  return click(surface, (move) => {
    if (done) return;
    let index = Number(move);
    if (connect) {
      for (let row = height - 1; row >= 0; row--) {
        if (!board[row * width + index]) {
          index += row * width;
          break;
        }
      }
    }
    if (board[index]) return;
    const mark = (board[index] = marks[turn]);
    const row = Math.floor(index / width);
    const column = index % width;
    const run = (dr, dc) => {
      let length = 0;
      for (
        let r = row + dr, c = column + dc;
        r >= 0 &&
        r < height &&
        c >= 0 &&
        c < width &&
        board[r * width + c] === mark;
        r += dr, c += dc
      )
        length++;
      return length;
    };
    if (
      [
        [1, 0],
        [0, 1],
        [1, 1],
        [1, -1],
      ].some(([dr, dc]) => 1 + run(dr, dc) + run(-dr, -dc) >= (connect ? 4 : 3))
    ) {
      done = true;
      return render(mark + " kazandı.");
    }
    if (board.every(Boolean)) {
      done = true;
      return render("Berabere.");
    }
    turn ^= 1;
    render();
  });
}
function nim({ paint, surface }) {
  const rows = [3, 5, 7];
  let turn = 1;
  const render = (message = "Sıra " + turn + ". oyuncuda") =>
    paint(
      rows
        .map(
          (count, i) =>
            `<div class="actions"><strong>${i + 1}. sıra (${count})</strong>${range(
              count,
            )
              .map((n) => btn(n + 1 + " al", i + ":" + (n + 1)))
              .join("")}</div>`,
        )
        .join(""),
      message,
    );
  render();
  return click(surface, (move) => {
    const [row, count] = move.split(":").map(Number);
    rows[row] -= count;
    if (rows.every((n) => !n)) return render(turn + ". oyuncu kazandı.");
    turn = 3 - turn;
    render();
  });
}
function reversi({ paint, surface }) {
  const board = Array(64).fill(0);
  board[27] = board[36] = 2;
  board[28] = board[35] = 1;
  let turn = 1;
  const flips = (index, side) => {
    if (board[index]) return [];
    const row = index >> 3,
      column = index % 8;
    return directions.flatMap(([dr, dc]) => {
      let r = row + dr,
        c = column + dc;
      const line = [];
      while (
        r >= 0 &&
        r < 8 &&
        c >= 0 &&
        c < 8 &&
        board[r * 8 + c] === 3 - side
      ) {
        line.push(r * 8 + c);
        r += dr;
        c += dc;
      }
      return r >= 0 && r < 8 && c >= 0 && c < 8 && board[r * 8 + c] === side
        ? line
        : [];
    });
  };
  const render = (message = "Sıra " + (turn === 1 ? "siyah" : "beyaz")) =>
    paint(
      grid(
        8,
        board
          .map((side, index) =>
            btn(
              ["·", "●", "○"][side],
              index,
              `aria-label="${index + 1}. hücre" ${turn && flips(index, turn).length ? "" : "disabled"}`,
            ),
          )
          .join(""),
      ),
      message,
    );
  render();
  return click(surface, (value) => {
    const index = Number(value);
    const captured = flips(index, turn);
    if (!captured.length) return;
    for (const cell of [index, ...captured]) board[cell] = turn;
    if (board.some((_, n) => flips(n, 3 - turn).length)) turn = 3 - turn;
    else if (!board.some((_, n) => flips(n, turn).length)) {
      const dark = board.filter((cell) => cell === 1).length;
      const light = board.filter((cell) => cell === 2).length;
      turn = 0;
      return render(
        `Siyah ${dark}, beyaz ${light}. ${dark === light ? "Berabere." : dark > light ? "Siyah kazandı." : "Beyaz kazandı."}`,
      );
    }
    render();
  });
}
function boxes({ paint, surface }) {
  const used = new Set();
  const owners = Array(9).fill(0);
  let turn = 1;
  const edges = (row, col) => [
    `h${row}${col}`,
    `h${row + 1}${col}`,
    `v${row}${col}`,
    `v${row}${col + 1}`,
  ];
  const render = () => {
    const score = [1, 2].map(
      (side) => owners.filter((owner) => owner === side).length,
    );
    const cells = range(49).map((n) => {
      const r = Math.floor(n / 7),
        c = n % 7;
      if (!(r % 2) && !(c % 2)) return '<span class="classic-dot">•</span>';
      if (r % 2 && c % 2)
        return `<span class="classic-cell">${owners[(r >> 1) * 3 + (c >> 1)] || ""}</span>`;
      const key = (r % 2 ? "v" : "h") + (r >> 1) + (c >> 1);
      return btn(
        r % 2 ? "│" : "─",
        key,
        `aria-label="${r % 2 ? "Dikey" : "Yatay"} çizgi ${r + 1}, ${c + 1}" ${used.has(key) ? 'disabled data-claimed="true"' : ""}`,
      );
    });
    paint(
      grid(7, cells.join(""), "boxes"),
      `Oyuncu 1: ${score[0]} · Oyuncu 2: ${score[1]} · ${owners.every(Boolean) ? "Oyun bitti." : "Sıra " + turn}`,
    );
  };
  render();
  return click(surface, (edge) => {
    used.add(edge);
    let captured = false;
    for (let n = 0; n < 9; n++)
      if (
        !owners[n] &&
        edges(Math.floor(n / 3), n % 3).every((key) => used.has(key))
      ) {
        owners[n] = turn;
        captured = true;
      }
    if (!captured) turn = 3 - turn;
    render();
  });
}
function rps({ paint, surface }) {
  const choices = ["Taş", "Kağıt", "Makas"];
  const score = [0, 0];
  paint(choices.map((choice, i) => btn(choice, i)).join(" "), "Hamleni seç.");
  return click(surface, (move) => {
    const player = Number(move),
      bot = random(3);
    const result = (player - bot + 3) % 3;
    if (result) score[result - 1]++;
    const done = score.includes(3);
    paint(
      done ? "" : choices.map((choice, i) => btn(choice, i)).join(" "),
      `Rakip ${choices[bot]} seçti. ${score[0]}–${score[1]}${done ? (score[0] === 3 ? " · Kazandın." : " · Rakip kazandı.") : ""}`,
    );
  });
}
function dice({ paint, surface }) {
  let turn = 0,
    pot = 0;
  const score = [0, 0];
  const render = (message = "") =>
    paint(
      score.some((n) => n >= 40)
        ? ""
        : btn("Zar at", "roll") +
            " " +
            btn("Puanı kasaya al", "hold", pot ? "" : "disabled"),
      `1. oyuncu ${score[0]} · 2. oyuncu ${score[1]} · ${message || "Sıra " + (turn + 1) + ", eldeki puan " + pot}`,
    );
  render();
  return click(surface, (move) => {
    if (move === "hold") {
      score[turn] += pot;
      if (score[turn] >= 40) return render(turn + 1 + ". oyuncu kazandı.");
      pot = 0;
      turn ^= 1;
      return render();
    }
    const roll = 1 + random(6);
    if (roll === 1) {
      pot = 0;
      turn ^= 1;
      return render("Bir geldi. Sıra " + (turn + 1));
    }
    pot += roll;
    render("Zar " + roll + " · Elde " + pot);
  });
}
function memory({ paint, surface }, triple = false) {
  const symbols = ["◆", "✿", "●", "▲", "✚", "☀", "◈", "♣"];
  const copies = triple ? 3 : 2;
  const deck = shuffle(symbols.flatMap((symbol) => Array(copies).fill(symbol)));
  const removed = new Set();
  let active = [];
  let timer;
  let busy = false;
  let moves = 0;
  const render = (message = "Hamle " + moves) =>
    paint(
      grid(
        triple ? 6 : 4,
        deck
          .map((symbol, index) =>
            btn(
              removed.has(index)
                ? " "
                : triple || active.includes(index)
                  ? symbol
                  : "?",
              index,
              `aria-label="${index + 1}. kart${triple || active.includes(index) ? " " + symbol : ""}" ${removed.has(index) || active.includes(index) ? "disabled" : ""}`,
            ),
          )
          .join(""),
      ) +
        (triple
          ? `<p>Tepsi (${active.length}/7) ${active.map((index) => deck[index]).join(" ")}</p>`
          : ""),
      message,
    );
  render();
  const clear = click(surface, (value) => {
    if (busy) return;
    const index = Number(value);
    if (active.includes(index) || removed.has(index)) return;
    active.push(index);
    moves++;
    if (triple) {
      const matches = active.filter((cell) => deck[cell] === deck[index]);
      if (matches.length === 3) {
        for (const cell of matches) removed.add(cell);
        active = active.filter((cell) => !removed.has(cell));
      }
      if (active.length === 7) {
        busy = true;
        return render("Tepsi doldu.");
      }
      return render(
        removed.size === deck.length ? "Hepsini eşledin!" : undefined,
      );
    }
    if (active.length === 2) {
      busy = true;
      render();
      timer = setTimeout(() => {
        if (deck[active[0]] === deck[active[1]])
          for (const cell of active) removed.add(cell);
        active = [];
        busy = false;
        render(removed.size === deck.length ? "Hepsini eşledin!" : undefined);
      }, 650);
    } else render();
  });
  return () => {
    clear();
    clearTimeout(timer);
  };
}
function puzzle({ paint, surface }, numbers = false) {
  const board = numbers
    ? shuffle(range(25).map((n) => n + 1))
    : [...range(15).map((n) => n + 1), 0];
  const width = numbers ? 5 : 4;
  let next = 1,
    moves = 0;
  const adjacent = (i, j) =>
    Math.abs(Math.floor(i / width) - Math.floor(j / width)) +
      Math.abs((i % width) - (j % width)) ===
    1;
  if (!numbers)
    for (let n = 0; n < 90; n++) {
      const empty = board.indexOf(0),
        candidates = range(16).filter((i) => adjacent(i, empty));
      const target = candidates[random(candidates.length)];
      [board[empty], board[target]] = [board[target], board[empty]];
    }
  const render = (
    message = numbers ? "Sıradaki sayı " + next : "Hamle " + moves,
  ) =>
    paint(
      grid(
        width,
        board
          .map((n, i) =>
            n
              ? btn(n, i, numbers && n < next ? "disabled" : "")
              : '<span class="classic-cell"></span>',
          )
          .join(""),
      ),
      message,
    );
  render();
  return click(surface, (value) => {
    const i = Number(value),
      empty = board.indexOf(0);
    if (numbers) {
      if (board[i] !== next) return render("Şimdi " + next + " sayısını bul.");
      next++;
      return render(next === 26 ? "25 sayının hepsini buldun!" : undefined);
    }
    if (!adjacent(i, empty)) return;
    [board[i], board[empty]] = [board[empty], board[i]];
    moves++;
    render(
      board.slice(0, 15).every((n, j) => n === j + 1)
        ? moves + " hamlede çözdün!"
        : undefined,
    );
  });
}
function merge2048({ paint, surface }) {
  const board = Array(16).fill(0);
  let score = 0;
  function spawn() {
    const spaces = range(16).filter((i) => !board[i]);
    if (spaces.length)
      board[spaces[random(spaces.length)]] = random(10) ? 2 : 4;
  }
  function render(message = "Puan " + score) {
    paint(
      grid(
        4,
        board
          .map(
            (n) =>
              `<span class="classic-cell" data-number="${n}">${n || ""}</span>`,
          )
          .join(""),
      ) + moveButtons,
      message,
    );
  }
  function move(direction) {
    let changed = false;
    for (let line = 0; line < 4; line++) {
      const indices = range(4).map((n) =>
        direction < 2 ? line * 4 + n : n * 4 + line,
      );
      if (direction % 2) indices.reverse();
      const values = indices.map((i) => board[i]).filter(Boolean);
      const merged = [];
      for (let n = 0; n < values.length; n++) {
        if (values[n] === values[n + 1]) {
          const value = values[n++] * 2;
          score += value;
          merged.push(value);
        } else merged.push(values[n]);
      }
      for (const [n, index] of indices.entries()) {
        const value = merged[n] || 0;
        if (board[index] !== value) changed = true;
        board[index] = value;
      }
    }
    if (changed) spawn();
    const stuck =
      board.every(Boolean) &&
      !board.some(
        (value, i) =>
          (i % 4 < 3 && board[i + 1] === value) ||
          (i < 12 && board[i + 4] === value),
      );
    render(
      stuck
        ? "Hamle kalmadı. Puan " + score
        : board.includes(2048)
          ? "2048’e ulaştın! Puan " + score
          : undefined,
    );
  }
  const clear = click(surface, (value) => move(Number(value)));
  const removeKeys = arrowKeys(move);
  spawn();
  spawn();
  render();
  return () => {
    clear();
    removeKeys();
  };
}
const arrowNames = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"];
const moveButtons =
  '<div class="actions classic-arrows">' +
  ["Sol", "Sağ", "Yukarı", "Aşağı"].map((label, i) => btn(label, i)).join("") +
  "</div>";
function arrowKeys(move) {
  function key(event) {
    const direction = arrowNames.indexOf(event.key);
    if (
      direction < 0 ||
      ["INPUT", "SELECT", "TEXTAREA"].includes(event.target.tagName)
    )
      return;
    event.preventDefault();
    move(direction);
  }
  document.addEventListener("keydown", key);
  return () => document.removeEventListener("keydown", key);
}
const words = [
  "MARTI",
  "VAPUR",
  "BULUT",
  "ZEYTİN",
  "FENER",
  "KİRAZ",
  "ŞEMSİYE",
  "ORMAN",
  "KÖPRÜ",
  "KARTAL",
];
const alphabet = [..."ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ"];
function hangman({ paint, surface }) {
  const answer = words[random(words.length)];
  const picked = new Set();
  let errors = 0;
  const masked = () =>
    [...answer].map((letter) => (picked.has(letter) ? letter : "_"));
  const render = (message = "Kalan hata hakkı " + (6 - errors)) => {
    const end = errors >= 6 || !masked().includes("_");
    paint(
      `<p class="word-slots">${end ? answer : masked().join(" ")}</p>` +
        grid(
          7,
          alphabet
            .map((letter) =>
              btn(letter, letter, end || picked.has(letter) ? "disabled" : ""),
            )
            .join(""),
        ),
      message,
    );
  };
  render();
  return click(surface, (letter) => {
    picked.add(letter);
    if (!answer.includes(letter)) errors++;
    render(
      errors >= 6
        ? "Hata hakkın bitti."
        : !masked().includes("_")
          ? "Kelimeyi buldun!"
          : undefined,
    );
  });
}
const cityQuestions = [
  ["Peribacaları ve Göreme hangi ilimizde?", "NEVŞEHİR"],
  ["Anıtkabir hangi şehirdedir?", "ANKARA"],
  ["Uzungöl hangi ilimizdedir?", "TRABZON"],
  ["Balıklıgöl hangi ilimizdedir?", "ŞANLIURFA"],
  ["Kordon ve Saat Kulesi hangi ilimizdedir?", "İZMİR"],
  ["Pamukkale travertenleri hangi ilimizdedir?", "DENİZLİ"],
];
function inputGame({ paint, surface, say }, type) {
  const answer = type === "sayi-tahmin" ? 1 + random(100) : null;
  const questions =
    type === "sehir"
      ? shuffle(cityQuestions)
      : type === "kelime"
        ? shuffle(words)
            .slice(0, 5)
            .map((word) => {
              let scrambled = shuffle([...word]).join("");
              if (scrambled === word) scrambled = word.slice(1) + word[0];
              return [scrambled, word];
            })
        : range(10).map((_, index) => {
            const a = 2 + random(12),
              b = 2 + random(12);
            return index % 2 ? [`${a} × ${b}`, a * b] : [`${a} + ${b}`, a + b];
          });
  let index = 0,
    attempts = 0;
  const numeric = type === "sayi-tahmin" || type === "matematik";
  const render = (message) => {
    const prompt =
      answer !== null
        ? "1 ile 100 arasındaki sayıyı bul."
        : questions[index][0];
    paint(
      `<form class="stack"><label class="control">${prompt}<input name="answer" required ${numeric ? 'type="number" inputmode="numeric"' : 'autocomplete="off"'}></label><button class="button primary">Cevapla</button></form>`,
      message || "",
    );
  };
  render();
  surface.onsubmit = (event) => {
    event.preventDefault();
    const input = event.target.elements.answer;
    const value = numeric ? Number(input.value) : formatWord(input.value);
    attempts++;
    if (answer !== null) {
      if (value === answer) return paint("", attempts + " tahminde buldun!");
      say(
        value > answer
          ? "Daha küçük bir sayı dene."
          : "Daha büyük bir sayı dene.",
      );
      input.select();
      return;
    }
    if (value !== questions[index][1]) {
      say("Bir daha dene.");
      input.select();
      return;
    }
    index++;
    if (index === questions.length)
      return paint("", "Tüm soruları tamamladın!");
    render("Doğru. " + index + "/" + questions.length);
    surface.querySelector("input").focus();
  };
  return () => {
    surface.onsubmit = null;
  };
}
const general = [
  ["Dünya’nın doğal uydusu hangisi?", "Ay", "Mars", "Venüs"],
  ["Suyun kimyasal formülü hangisi?", "H₂O", "CO₂", "NaCl"],
  ["Türkiye’nin başkenti neresidir?", "Ankara", "İstanbul", "İzmir"],
  ["Satranç tahtasında kaç kare vardır?", "64", "48", "81"],
  ["Bir saatte kaç dakika vardır?", "60", "90", "100"],
  [
    "Kürk Mantolu Madonna’nın yazarı kim?",
    "Sabahattin Ali",
    "Yaşar Kemal",
    "Orhan Veli",
  ],
];
const sport = [
  ["Bir takım sahaya en çok kaç oyuncuyla çıkar?", "11", "10", "12"],
  [
    "Penaltı noktası kale çizgisine yaklaşık kaç metre uzaktadır?",
    "11",
    "9",
    "16",
  ],
  ["Standart maçın iki devresi kaç dakika sürer?", "90", "80", "120"],
  [
    "Bir futbolcunun bir maçta üç gol atmasına ne denir?",
    "Hat-trick",
    "Ofsayt",
    "Asist",
  ],
  [
    "Kaleci kendi ceza alanı dışında topa elle müdahale edebilir mi?",
    "Hayır",
    "Evet",
    "Sadece uzatmada",
  ],
  [
    "Kale direkleri arasında bir golü geçerli yapan nedir?",
    "Topun tamamının çizgiyi geçmesi",
    "Topun çizgiye değmesi",
    "Topun yarısının geçmesi",
  ],
];
function quiz({ paint, surface }, football = false) {
  const questions = shuffle(football ? sport : general);
  let index = 0,
    points = 0,
    answered = false,
    previous = "";
  const render = () => {
    if (index === questions.length)
      return paint("", "Sonuç " + points + "/" + questions.length);
    const [prompt, ...choices] = questions[index];
    paint(
      `<p class="quiz-question">${prompt}</p><div class="stack">${
        answered
          ? btn("Sonraki soru", "next")
          : shuffle(choices.map((choice, i) => [choice, i]))
              .map(([choice, i]) => btn(choice, i))
              .join("")
      }</div>`,
      answered ? previous : "Soru " + (index + 1) + "/" + questions.length,
    );
  };
  render();
  return click(surface, (value) => {
    if (value === "next") {
      index++;
      answered = false;
    } else {
      if (value === "0") points++;
      previous =
        value === "0" ? "Doğru!" : "Doğru cevap " + questions[index][1];
      answered = true;
    }
    render();
  });
}
function reflex({ paint, surface }) {
  let phase = "idle",
    timer,
    start;
  const render = (message) =>
    paint(
      btn(
        phase === "idle" ? "Hazırım" : phase === "go" ? "Şimdi!" : "Bekle…",
        "tap",
      ),
      message,
    );
  render("Işık yanınca düğmeye bas.");
  const clear = click(surface, () => {
    if (phase === "idle") {
      phase = "wait";
      render("Yeşil ışığı bekle.");
      timer = setTimeout(
        () => {
          phase = "go";
          start = performance.now();
          render("Şimdi dokun!");
        },
        1100 + random(2500),
      );
      return;
    }
    clearTimeout(timer);
    const result =
      phase === "go"
        ? Math.round(performance.now() - start) + " ms"
        : "Çok erken bastın.";
    phase = "idle";
    render(result);
  });
  return () => {
    clear();
    clearTimeout(timer);
  };
}
function targets({ paint, surface }, mode = "balon") {
  let target = random(16),
    points = 0,
    remaining = 20,
    timer;
  const symbols = { balon: "◉", maymun: "♧", scuba: "♻" };
  const render = () =>
    paint(
      timer
        ? grid(
            4,
            range(16)
              .map((i) =>
                btn(
                  i === target ? symbols[mode] : "·",
                  i,
                  `aria-label="${i === target ? "Hedef" : "Boş"} ${i + 1}"`,
                ),
              )
              .join(""),
          )
        : remaining
          ? btn("Başla", "start")
          : "",
      "Puan " + points + " · " + remaining + " sn",
    );
  render();
  const clear = click(surface, (value) => {
    if (value === "start") {
      timer = setInterval(() => {
        remaining--;
        if (!remaining) {
          clearInterval(timer);
          timer = undefined;
        }
        render();
      }, 1000);
    } else if (Number(value) === target) {
      points++;
      target = (target + 1 + random(15)) % 16;
    }
    render();
  });
  return () => {
    clear();
    clearInterval(timer);
  };
}
function snake({ paint, surface, say }) {
  const size = 15,
    deltas = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
  const snake = [
    [7, 7],
    [6, 7],
    [5, 7],
  ];
  const equals = ([x, y], [xx, yy]) => x === xx && y === yy;
  let direction = 1,
    pending = 1,
    timer,
    score = 0;
  const food = () => {
    const empty = range(size * size)
      .map((i) => [i % size, Math.floor(i / size)])
      .filter((cell) => !snake.some((part) => equals(cell, part)));
    return empty[random(empty.length)];
  };
  let apple = food();
  paint(
    '<canvas class="classic-canvas" width="300" height="300" aria-label="Yılan oyun alanı"></canvas>' +
      btn("Başla", "start") +
      moveButtons,
    "Puan 0",
  );
  const ctx = surface.querySelector("canvas").getContext("2d");
  const draw = () => {
    ctx.fillStyle = "#1d3036";
    ctx.fillRect(0, 0, 300, 300);
    for (const [i, [x, y]] of snake.entries()) {
      ctx.fillStyle = i ? "#68a993" : "#a2efd0";
      ctx.fillRect(x * 20 + 1, y * 20 + 1, 18, 18);
    }
    if (apple) {
      ctx.fillStyle = "#ffbe74";
      ctx.fillRect(apple[0] * 20 + 3, apple[1] * 20 + 3, 14, 14);
    }
  };
  const steer = (next) => {
    if ((next ^ 1) !== direction) pending = next;
  };
  function tick() {
    direction = pending;
    const [dx, dy] = deltas[direction],
      [x, y] = snake[0];
    const head = [x + dx, y + dy],
      eats = equals(head, apple);
    if (
      head.some((n) => n < 0 || n >= size) ||
      (eats ? snake : snake.slice(0, -1)).some((cell) => equals(cell, head))
    ) {
      clearInterval(timer);
      return say("Oyun bitti. Puan " + score);
    }
    snake.unshift(head);
    if (!eats) snake.pop();
    else {
      apple = food();
      score++;
      say("Puan " + score);
      if (!apple) {
        clearInterval(timer);
        say("Tahtayı doldurdun!");
      }
    }
    draw();
  }
  draw();
  const clear = click(surface, (value) => {
    if (value !== "start") return steer(Number(value));
    if (!timer) {
      surface.querySelector('[data-move="start"]').hidden = true;
      timer = setInterval(tick, 145);
    }
  });
  const keys = arrowKeys(steer);
  return () => {
    clear();
    keys();
    clearInterval(timer);
  };
}
function nails({ paint, surface, say }) {
  const palette = [
    "#d86a91",
    "#80d1bd",
    "#ffbb6a",
    "#ad98e9",
    "#efefdd",
    "#a83c51",
  ];
  const nails = Array(5)
    .fill(null)
    .map(() => ({ color: 0, pattern: 0 }));
  let color = 0,
    pattern = 0;
  const render = () =>
    paint(`<div class="nails">${nails
      .map((nail, i) =>
        btn(
          ["", "✦", "●"][nail.pattern],
          "n" + i,
          `aria-label="${i + 1}. tırnağı boya" style="--polish:${palette[nail.color]}"`,
        ),
      )
      .join("")}</div>
    <div class="actions">${palette.map((shade, i) => btn(" ", "c" + i, `aria-label="${i + 1}. renk" aria-pressed="${color === i}" style="background:${shade}"`)).join("")}</div>
    <div class="actions">${["Düz", "Yıldız", "Nokta"].map((name, i) => btn(name, "p" + i, `aria-pressed="${pattern === i}"`)).join("")}</div>`);
  render();
  say("Bir renk ve desen seç, sonra tırnağa dokun.");
  return click(surface, (move) => {
    const index = Number(move[1]);
    if (move[0] === "c") color = index;
    else if (move[0] === "p") pattern = index;
    else nails[index] = { color, pattern };
    render();
  });
}
function drawGame({ paint, surface, say }) {
  const word = words[random(words.length)];
  paint(`<p>Çizilecek kelimeyi sadece çizen oyuncu görsün.</p>${btn("Kelimeyi göster", "show")}
    <canvas class="classic-canvas drawing" width="560" height="320" aria-label="Çizim alanı"></canvas>
    <div class="actions">${btn("Sil", "clear")} ${btn("Tahmin edildi", "done")}</div>`);
  const canvas = surface.querySelector("canvas"),
    ctx = canvas.getContext("2d");
  let running = false,
    remaining = 45,
    timer;
  let last;
  function position(event) {
    const box = canvas.getBoundingClientRect();
    return [
      ((event.clientX - box.left) * canvas.width) / box.width,
      ((event.clientY - box.top) * canvas.height) / box.height,
    ];
  }
  canvas.onpointerdown = (event) => {
    if (!running) return;
    last = position(event);
    canvas.setPointerCapture(event.pointerId);
  };
  canvas.onpointermove = (event) => {
    if (!last || !running) return;
    const current = position(event);
    ctx.strokeStyle = "#242032";
    ctx.lineWidth = 5;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(...last);
    ctx.lineTo(...current);
    ctx.stroke();
    last = current;
  };
  canvas.onpointerup = canvas.onpointercancel = () => {
    last = undefined;
  };
  const clear = click(surface, (move) => {
    if (move === "clear")
      return ctx.clearRect(0, 0, canvas.width, canvas.height);
    if (move === "done" && running) {
      running = false;
      clearInterval(timer);
      return say("Doğru tahmin. Kelime " + word);
    }
    if (move === "show" && !timer) {
      const reveal = surface.querySelector('[data-move="show"]');
      if (reveal.textContent !== word) {
        reveal.textContent = word;
        return;
      }
      reveal.hidden = true;
      running = true;
      say("45 saniye");
      timer = setInterval(() => {
        if (--remaining) return say(remaining + " saniye");
        clearInterval(timer);
        running = false;
        say("Süre bitti. Kelime " + word);
      }, 1000);
    }
  });
  return () => {
    clear();
    clearInterval(timer);
  };
}
const implementations = {
  xox: (game) => lineGame(game, false),
  dortlu: (game) => lineGame(game, true),
  nim,
  reversi,
  noktalar: boxes,
  tkm: rps,
  zar: dice,
  hafiza: (game) => memory(game),
  uclu: (game) => memory(game, true),
  2048: merge2048,
  yapboz: (game) => puzzle(game),
  sayi: (game) => puzzle(game, true),
  matematik: (game) => inputGame(game, "matematik"),
  "sayi-tahmin": (game) => inputGame(game, "sayi-tahmin"),
  asmaca: hangman,
  sehir: (game) => inputGame(game, "sehir"),
  kelime: (game) => inputGame(game, "kelime"),
  bilgi: (game) => quiz(game),
  futbol: (game) => quiz(game, true),
  refleks: reflex,
  balon: targets,
  maymun: (game) => targets(game, "maymun"),
  scuba: (game) => targets(game, "scuba"),
  yilan: snake,
  oje: nails,
  ciz: drawGame,
};
function runner({ paint, surface, say }, mode) {
  const racing = mode === "serit";
  const tiger = mode === "kaplan";
  paint(
    '<canvas class="classic-canvas drawing-game" width="540" height="280" aria-label="Oyun pisti"></canvas>' +
      btn("Başla", "start") +
      (racing
        ? moveButtons
        : '<div class="actions">' + btn("Zıpla", "jump") + "</div>"),
    "Hazır.",
  );
  const ctx = surface.querySelector("canvas").getContext("2d");
  let lane = 1,
    altitude = 0,
    speed = 0,
    frame,
    last,
    elapsed = 0,
    score = 0,
    countdown = 1;
  const items = [];
  const step = (value) => {
    if (!frame) return;
    if (racing) {
      if (value === 0 || value === 1)
        lane = Math.max(0, Math.min(2, lane + (value === 0 ? -1 : 1)));
    } else if (altitude === 0) speed = 365;
  };
  const draw = () => {
    ctx.fillStyle = racing ? "#292b41" : tiger ? "#294d41" : "#293c55";
    ctx.fillRect(0, 0, 540, 280);
    ctx.fillStyle = "#131d2d";
    ctx.fillRect(0, 223, 540, 57);
    if (racing) {
      ctx.strokeStyle = "#dbd1c3";
      ctx.setLineDash([13, 10]);
      for (const x of [180, 360]) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, 280);
        ctx.stroke();
      }
      ctx.setLineDash([]);
    }
    ctx.fillStyle = tiger ? "#eaa04b" : "#94e3cc";
    ctx.fillRect(
      racing ? lane * 180 + 72 : 62,
      racing ? 211 : 195 - altitude,
      36,
      28,
    );
    for (const item of items) {
      ctx.fillStyle = item.coin ? "#ffcb59" : "#e57787";
      if (racing) ctx.fillRect(item.lane * 180 + 68, item.offset, 44, 31);
      else
        ctx.fillRect(
          item.offset,
          item.coin ? 141 : 195,
          item.coin ? 21 : 34,
          item.coin ? 21 : 28,
        );
    }
  };
  const tick = (now) => {
    const dt = last ? Math.min((now - last) / 1000, 0.04) : 0;
    last = now;
    elapsed += dt;
    countdown -= dt;
    if (countdown <= 0) {
      countdown = 0.85 + Math.random() * 0.45;
      items.push({
        lane: random(3),
        offset: racing ? -35 : 540,
        coin: tiger && random(2) === 0,
      });
    }
    altitude = Math.max(0, altitude + speed * dt);
    speed = altitude ? speed - 950 * dt : 0;
    for (const item of items) {
      item.offset += (racing ? 1 : -1) * (190 + elapsed * 3) * dt;
      const nearby = racing
        ? item.lane === lane && item.offset >= 183 && item.offset <= 235
        : item.offset >= 32 && item.offset <= 96;
      if (!item.collected && nearby) {
        if (item.coin && altitude >= 33 && altitude <= 82) {
          item.collected = true;
          score += 5;
        } else if (!item.coin && (racing || altitude < 28)) {
          frame = undefined;
          draw();
          return say("Oyun bitti. Puan " + (score + Math.floor(elapsed)));
        }
      }
    }
    while (
      items.length &&
      (racing ? items[0].offset > 280 : items[0].offset < -40)
    )
      items.shift();
    for (let i = items.length - 1; i >= 0; i--)
      if (items[i].collected) items.splice(i, 1);
    draw();
    frame = requestAnimationFrame(tick);
  };
  draw();
  const clear = click(surface, (value) => {
    if (value !== "start") return step(Number(value));
    if (frame) return;
    surface.querySelector('[data-move="start"]').hidden = true;
    say(racing ? "Engellerden kaç." : "Engellerin üzerinden atla.");
    frame = requestAnimationFrame(tick);
  });
  const keys = arrowKeys(step);
  return () => {
    clear();
    keys();
    cancelAnimationFrame(frame);
  };
}
function aim({ paint, surface }, mode) {
  const bowling = mode === "bovling",
    freeKick = mode === "frikik";
  const limit = bowling ? 10 : 5;
  let turn = 0,
    points = 0,
    target = random(5);
  const render = (message) =>
    paint(
      turn === limit
        ? ""
        : `<p class="quiz-question">${bowling ? "Okların gösterdiği hattı seç." : freeKick ? "Baraj ve kalecinin kapatmadığı köşeyi bul." : "Kalecinin hareketini izle, boş noktaya vur."}</p>
    ${grid(
      5,
      range(5)
        .map((i) =>
          btn(
            bowling
              ? i === target
                ? "▼"
                : "·"
              : i === target
                ? "◆"
                : freeKick && (i + 4) % 5 === target
                  ? "▥"
                  : "·",
            i,
            `aria-label="${i + 1}. bölge"`,
          ),
        )
        .join(""),
    )}`,
      (message ? message + " · " : "") +
        "Puan " +
        points +
        " · " +
        turn +
        "/" +
        limit,
    );
  render();
  return click(surface, (value) => {
    const choice = Number(value),
      distance = Math.abs(choice - target);
    const scored = bowling
      ? Math.max(0, 10 - distance * 3)
      : Number(choice !== target && (!freeKick || (choice + 4) % 5 !== target));
    points += scored;
    turn++;
    target = random(5);
    render(bowling ? scored + " kuka" : scored ? "Gol!" : "Kurtarıldı.");
  });
}
Object.assign(implementations, {
  zipla: (game) => runner(game, "zipla"),
  kaplan: (game) => runner(game, "kaplan"),
  serit: (game) => runner(game, "serit"),
  bovling: (game) => aim(game, "bovling"),
  penalti: (game) => aim(game, "penalti"),
  frikik: (game) => aim(game, "frikik"),
});
