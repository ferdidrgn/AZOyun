import { classics } from "./classic-catalog.mjs";
import { connectFourDropRow, connectFourOutcome } from "./connect-four-rules.mjs";
import { apply2048Move, is2048GameOver } from "./2048-rules.mjs";
import { canTurnSnake, stepSnake } from "./snake-rules.mjs";
import {
  BALLOON_LIFETIME_MS,
  BALLOON_SESSION_SECONDS,
  popBalloon,
  tickBalloonSession,
} from "./balloon-rules.mjs";
import {
  MONKEY_MOVE_INTERVAL_MS,
  MONKEY_SESSION_SECONDS,
  tapMonkey,
  tickMonkeySession,
} from "./monkey-rules.mjs";
import {
  JUMP_DASH_BIRD_RADIUS,
  JUMP_DASH_BIRD_X,
  JUMP_DASH_GAP_HALF,
  JUMP_DASH_IMPULSE,
  JUMP_DASH_PIPE_SPEED,
  JUMP_DASH_PIPE_WIDTH,
  jumpDashHitBoundary,
  jumpDashNextBirdY,
  jumpDashNextPipeX,
  jumpDashNextVelocity,
  jumpDashPipeCollision,
  jumpDashPipePassed,
  jumpDashShouldSpawn,
} from "./jump-dash-rules.mjs";
import { nimApplyMove } from "./nim-rules.mjs";
import {
  REVERSI_BLACK,
  REVERSI_EMPTY,
  reversiApplyMove,
  reversiInitialBoard,
  reversiLegalMoves,
  reversiNextSide,
  reversiOutcome,
} from "./reversi-rules.mjs";
import {
  SCUBA_BOOST_PACE,
  SCUBA_DIVER_HOME_Y,
  SCUBA_ENEMY_SPAWN_SECONDS,
  SCUBA_PEARL_SPAWN_SECONDS,
  SCUBA_STEP_SECONDS,
  SCUBA_TRASH_SPAWN_SECONDS,
  scubaCollisionReach,
  scubaMoveDriftX,
  scubaMoveDriftY,
  scubaOverlap,
  scubaPace,
  scubaResolveContact,
  scubaSpawnTick,
} from "./scuba-rules.mjs";
import { ticTacToeOutcome } from "./tic-tac-toe-rules.mjs";

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
  const render = (message = "Sıra " + marks[turn]) => {
    const winCells = new Set();
    if (done) {
      if (!connect) {
        const outcome = ticTacToeOutcome(board);
        for (const cell of outcome.winningLine ?? []) winCells.add(cell);
      } else {
        const outcome = connectFourOutcome(board);
        for (const cell of outcome.winningLine ?? []) winCells.add(cell);
      }
    }
    const piece = (mark, index) => {
      if (!mark) return "";
      const first = marks.indexOf(mark) === 0;
      const shades = connect
        ? first ? ["#ffd1c5", "#ea514b", "#822f38"] : ["#fff1bd", "#e9b94a", "#86521d"]
        : mark === "X" ? ["#d2fff4", "#35bfa5", "#176858"] : ["#fffdf1", "#ede6d4", "#8b816d"];
      const won = winCells.has(index);
      const glow = connect ? (first ? "255,91,75" : "255,208,93") : "126,255,219";
      return `<span aria-hidden="true" style="display:grid;place-items:center;width:74%;aspect-ratio:1;border:1px solid rgba(255,255,255,.52);border-radius:50%;background:radial-gradient(circle at 30% 22%,${shades[0]} 0%,${shades[1]} 45%,${shades[2]} 100%);box-shadow:inset 0 2px 2px rgba(255,255,255,.5),inset 0 -4px 6px rgba(0,0,0,.25),0 3px 0 ${shades[2]},0 7px 10px rgba(0,0,0,.38)${won ? `,0 0 0 3px rgba(${glow},.55),0 0 18px 7px rgba(${glow},.72)` : ""};color:#fff;font-size:clamp(1.25rem,5vw,2.35rem);font-weight:900;text-shadow:0 2px 5px rgba(0,0,0,.4)">${mark}</span>`;
    };
    const dropRow = connect
      ? `<div class="classic-grid" aria-label="Sütun seç" style="--columns:${width};width:100%;aspect-ratio:7 / 1;grid-auto-rows:minmax(0,1fr);gap:clamp(2px,.7vw,5px);margin:0 0 3px">${range(width).map((column) => btn("↓", column, `aria-label="${column + 1}. sütuna bırak" style="min-height:0;padding:0;aspect-ratio:1;border:1px solid rgba(255,255,255,.35);border-radius:clamp(4px,1vw,9px);background:linear-gradient(145deg,#e9c575,#946332 65%,#58391f);box-shadow:inset 0 2px 0 rgba(255,255,255,.45),0 3px 0 #4c301d,0 5px 8px rgba(0,0,0,.3);color:#fff2cc;text-shadow:0 2px 3px rgba(0,0,0,.6)`)).join("")}</div>`
      : "";
    const cells = board.map((mark, index) => {
      const won = winCells.has(index);
      if (connect) {
        const glow = marks.indexOf(mark) === 0 ? "255,91,75" : "255,208,93";
        const pieceView = mark
          ? piece(mark, index)
          : '<span aria-hidden="true" style="display:block;width:76%;aspect-ratio:1;border:1px solid rgba(255,255,255,.05);border-radius:50%;background:radial-gradient(circle at 35% 25%,#071d28,#0a2530 60%,#102f36);box-shadow:inset 0 4px 7px rgba(0,0,0,.6),inset 0 -1px 0 rgba(255,255,255,.05)"></span>';
        return `<span class="classic-cell" aria-label="${mark ? `Taş ${mark}` : "Boş"}" style="min-height:0;padding:0;display:grid;place-items:center;aspect-ratio:1;border:1px solid rgba(190,229,193,.28);border-radius:clamp(4px,1vw,9px);background:${won ? `radial-gradient(circle,#39896d,#125b45 68%,#0b4137)` : "linear-gradient(145deg,#176448,#0c503e 58%,#073b32)"};box-shadow:inset 0 2px 0 rgba(255,255,255,.12),inset 0 -3px 0 rgba(0,0,0,.28)${won ? `,0 0 15px 4px rgba(${glow},.4)` : ""}">${pieceView}</span>`;
      }
      return btn(
        mark ? piece(mark, index) : '<span aria-hidden="true" style="display:block;width:28%;aspect-ratio:1;border:1px solid rgba(208,242,223,.24);border-radius:50%;background:rgba(7,38,32,.32);box-shadow:inset 0 2px 5px rgba(0,0,0,.32)"></span>',
        index,
        `aria-label="${index + 1}. hücre ${mark || "boş"}" ${mark || done ? "disabled" : ""} style="min-height:0;padding:0;aspect-ratio:1;display:grid;place-items:center;border:1px solid rgba(198,230,202,.34);border-radius:clamp(5px,1.3vw,11px);background:${won ? "linear-gradient(145deg,#1e8062,#125d49 64%,#0a4338)" : "linear-gradient(145deg,#176448,#0c503e 58%,#073b32)"};box-shadow:inset 0 2px 0 rgba(255,255,255,.15),inset 0 -3px 0 rgba(0,0,0,.26),0 3px 0 #082f29,0 6px 9px rgba(0,0,0,.27)${won ? ";outline:2px solid #ffe18c;outline-offset:1px;box-shadow:0 0 17px 5px rgba(255,225,140,.72),inset 0 2px 0 rgba(255,255,255,.25)" : ""}`,
      );
    }).join("");
    const cellBoard = `<div class="classic-grid" role="grid" aria-label="${connect ? "Dörtlü Diz" : "XOX"} tahtası" style="--columns:${width};width:100%;aspect-ratio:${width} / ${height};grid-auto-rows:minmax(0,1fr);gap:clamp(2px,.7vw,5px);padding:clamp(5px,1.2vw,9px);border:1px solid rgba(10,38,30,.8);border-radius:clamp(6px,1.3vw,11px);background:${connect ? "radial-gradient(ellipse at 38% 20%,#1b7050,#0c4b38 70%,#073729)" : "radial-gradient(ellipse at 38% 20%,#1c7452,#0b4b39 70%,#07382c)"};box-shadow:inset 0 3px 8px rgba(0,0,0,.46),inset 0 0 0 1px rgba(164,214,162,.18)">${cells}</div>`;
    const boardView = `<div style="width:min(100%,510px);margin:0 auto;padding:clamp(8px,2vw,14px);border:1px solid rgba(255,224,174,.52);border-radius:clamp(12px,2vw,20px);background:linear-gradient(135deg,#a87543 0%,#684324 25%,#bd8955 52%,#56361f 78%,#8a5932 100%);box-shadow:inset 0 2px 0 rgba(255,241,214,.62),inset 0 -5px 8px rgba(36,20,12,.55),0 10px 20px rgba(0,0,0,.38);perspective:950px"><div style="transform:rotateX(6deg);transform-origin:center top">${dropRow}${cellBoard}</div></div>`;
    paint(boardView, message);
  };
  render();
  return click(surface, (move) => {
    if (done) return;
    let index = Number(move);
    if (connect) {
      const row = connectFourDropRow(board, index);
      if (row === null) return;
      index += row * width;
    }
    if (board[index]) return;
    const mark = (board[index] = marks[turn]);
    if (!connect) {
      const outcome = ticTacToeOutcome(board);
      if (outcome.winner) {
        done = true;
        return render(mark + " kazandı.");
      }
      if (outcome.draw) {
        done = true;
        return render("Berabere.");
      }
      turn ^= 1;
      return render();
    }
    const outcome = connectFourOutcome(board);
    if (outcome.winner) {
      done = true;
      return render(mark + " kazandı.");
    }
    if (outcome.draw) {
      done = true;
      return render("Berabere.");
    }
    turn ^= 1;
    render();
  });
}
function nim({ paint, surface }) {
  let rows = [3, 5, 7, 9];
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
    const outcome = nimApplyMove(rows, row, count);
    rows = outcome.piles;
    if (outcome.finished) return render(turn + ". oyuncu kazandı.");
    turn = 3 - turn;
    render();
  });
}
function reversi({ paint, surface }) {
  let board = reversiInitialBoard();
  let turn = 1;
  const render = (message = "Sıra " + (turn === 1 ? "siyah" : "beyaz")) => {
    const legalMoves = turn === REVERSI_EMPTY ? [] : reversiLegalMoves(board, turn);
    const cells = board.map((side, index) => {
      const legal = side === REVERSI_EMPTY && legalMoves.includes(index);
      const disk = side
        ? `<span aria-hidden="true" style="display:block;width:73%;aspect-ratio:1;border-radius:50%;position:relative;background:${side === 1 ? "radial-gradient(circle at 30% 22%,#59616a 0%,#272d33 34%,#0b0f13 78%,#030507 100%)" : "radial-gradient(circle at 30% 22%,#ffffff 0%,#f4eedc 34%,#c9c0a9 78%,#908875 100%)"};border:1px solid ${side === 1 ? "rgba(255,255,255,.24)" : "rgba(68,57,36,.5)"};box-shadow:inset 0 2px 2px rgba(255,255,255,.36),inset 0 -4px 5px rgba(0,0,0,.28),0 3px 0 ${side === 1 ? "#05080a" : "#827b6b"},0 6px 8px rgba(0,0,0,.42);transform:translateY(-2px)"><span style="position:absolute;left:21%;top:15%;width:22%;height:12%;border-radius:50%;background:rgba(255,255,255,.62);filter:blur(1px)"></span></span>`
        : legal
          ? '<span aria-hidden="true" style="display:block;width:23%;aspect-ratio:1;border:2px solid rgba(255,226,151,.95);border-radius:50%;background:rgba(255,226,151,.24);box-shadow:0 0 10px rgba(255,219,132,.78),inset 0 0 5px rgba(255,255,255,.5)"></span>'
          : "";
      return btn(
        disk,
        index,
        `aria-label="${index + 1}. hücre${legal ? ', yasal hamle' : ''}" ${legal ? 'data-legal="true"' : ''} ${legal ? '' : 'disabled'} style="min-height:0;padding:0;display:grid;place-items:center;aspect-ratio:1;border:1px solid rgba(210,244,206,.22);border-radius:clamp(3px,1vw,8px);background:linear-gradient(145deg,#176448,#0c503e 58%,#073b32);box-shadow:inset 0 1px 0 rgba(255,255,255,.12),inset 0 -2px 0 rgba(0,0,0,.22)"`,
      );
    }).join("");
    const boardView = `<div style="width:min(100%,510px);margin:0 auto;padding:clamp(8px,2vw,15px);border:1px solid rgba(255,224,174,.52);border-radius:clamp(12px,2vw,20px);background:linear-gradient(135deg,#a87543 0%,#684324 25%,#bd8955 52%,#56361f 78%,#8a5932 100%);box-shadow:inset 0 2px 0 rgba(255,241,214,.62),inset 0 -5px 8px rgba(36,20,12,.55),0 10px 20px rgba(0,0,0,.38)"><div class="classic-grid" role="grid" aria-label="Reversi tahtası" style="--columns:8;width:100%;aspect-ratio:1;grid-auto-rows:minmax(0,1fr);gap:2px;padding:clamp(5px,1.2vw,9px);border:1px solid rgba(10,38,30,.8);border-radius:clamp(6px,1.3vw,11px);background:radial-gradient(ellipse at 38% 20%,#1b7050,#0c4b38 70%,#073729);box-shadow:inset 0 3px 8px rgba(0,0,0,.46),inset 0 0 0 1px rgba(164,214,162,.18)">${cells}</div></div>`;
    paint(boardView, message);
  };
  render();
  return click(surface, (value) => {
    const index = Number(value);
    const side = turn;
    const result = reversiApplyMove(board, index, side);
    if (!result) return;
    board = result.board;
    turn = reversiNextSide(board, side);
    if (turn === REVERSI_EMPTY) {
      const outcome = reversiOutcome(board);
      return render(
        `Siyah ${outcome.black}, beyaz ${outcome.white}. ${outcome.winner === REVERSI_EMPTY ? "Berabere." : outcome.winner === REVERSI_BLACK ? "Siyah kazandı." : "Beyaz kazandı."}`,
      );
    }
    if (turn === side) {
      return render(`${side === REVERSI_BLACK ? "Beyaz" : "Siyah"} hamle yapamıyor; ${side === REVERSI_BLACK ? "siyah" : "beyaz"} devam ediyor.`);
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
      if (!(r % 2) && !(c % 2))
        return '<span class="classic-dot" aria-hidden="true" style="z-index:2;display:grid;place-items:center;min-height:0;padding:0;border:1px solid rgba(255,240,207,.78);border-radius:50%;background:radial-gradient(circle at 30% 25%,#fff0bb,#d49a4c 48%,#805027 100%);box-shadow:inset 0 2px 2px rgba(255,255,255,.72),inset 0 -2px 3px rgba(68,38,14,.42),0 2px 0 #59391e,0 5px 8px rgba(0,0,0,.38)"><span style="width:35%;aspect-ratio:1;border-radius:50%;background:radial-gradient(circle at 35% 30%,#fff8de,#e2b45e 80%);box-shadow:0 0 5px rgba(255,226,146,.72)"></span></span>';
      if (r % 2 && c % 2) {
        const owner = owners[(r >> 1) * 3 + (c >> 1)];
        const colors = owner === 1
          ? ["#c5e6dc", "#438d75", "#204d43"]
          : ["#f7d9c9", "#bb6256", "#652f34"];
        return owner
          ? `<span class="classic-cell" aria-label="Oyuncu ${owner} kutusu" style="min-height:0;padding:0;display:grid;place-items:center;border:1px solid rgba(255,255,255,.32);border-radius:clamp(4px,1vw,9px);background:radial-gradient(circle at 35% 28%,${colors[0]},${colors[1]} 48%,${colors[2]} 100%);box-shadow:inset 0 2px 0 rgba(255,255,255,.3),inset 0 -3px 5px rgba(0,0,0,.25),0 0 14px ${colors[1]}66;color:#fff7e9;font-size:clamp(1rem,3.6vw,1.8rem);font-weight:900;text-shadow:0 2px 4px rgba(0,0,0,.55)">${owner}</span>`
          : '<span class="classic-cell" aria-hidden="true" style="min-height:0;padding:0;border:1px solid rgba(183,219,195,.08);border-radius:clamp(4px,1vw,9px);background:rgba(9,39,32,.23);box-shadow:inset 0 3px 7px rgba(0,0,0,.2)"></span>';
      }
      const key = (r % 2 ? "v" : "h") + (r >> 1) + (c >> 1);
      const horizontal = !(r % 2);
      const claimed = used.has(key);
      const line = `<span aria-hidden="true" style="display:block;position:relative;width:${horizontal ? "132%" : "18%"};height:${horizontal ? "18%" : "132%"};border-radius:999px;background:${claimed
        ? "linear-gradient(180deg,#fff0b0 0%,#e3b65c 36%,#97602e 100%)"
        : "linear-gradient(180deg,rgba(191,208,166,.42),rgba(89,127,102,.25))"};box-shadow:${claimed
          ? "inset 0 1px 0 rgba(255,255,255,.8),0 2px 0 #694421,0 4px 8px rgba(0,0,0,.34),0 0 10px rgba(255,212,120,.48)"
          : "inset 0 1px 0 rgba(255,255,255,.16),0 1px 2px rgba(0,0,0,.25)"};transform:${claimed ? "translateZ(5px)" : "translateZ(1px)"}"></span>`;
      return btn(
        line,
        key,
        `aria-label="${horizontal ? "Yatay" : "Dikey"} çizgi ${r + 1}, ${c + 1}" ${claimed ? 'disabled data-claimed="true"' : ""} style="min-height:0;padding:0;position:relative;z-index:1;display:grid;place-items:center;aspect-ratio:1;border:0;border-radius:4px;background:transparent;box-shadow:none;cursor:${claimed ? "default" : "pointer"};overflow:visible"`,
      );
    }).join("");
    const boardView = `<div style="width:min(100%,510px);margin:0 auto;padding:clamp(8px,2vw,14px);border:1px solid rgba(255,224,174,.52);border-radius:clamp(12px,2vw,20px);background:linear-gradient(135deg,#a87543 0%,#684324 25%,#bd8955 52%,#56361f 78%,#8a5932 100%);box-shadow:inset 0 2px 0 rgba(255,241,214,.62),inset 0 -5px 8px rgba(36,20,12,.55),0 10px 20px rgba(0,0,0,.38);perspective:950px"><div class="classic-grid boxes" role="grid" aria-label="Noktaları birleştir tahtası" style="--columns:7;width:100%;aspect-ratio:1;grid-auto-rows:minmax(0,1fr);gap:clamp(2px,.7vw,5px);padding:clamp(5px,1.2vw,9px);border:1px solid rgba(10,38,30,.8);border-radius:clamp(6px,1.3vw,11px);background:radial-gradient(ellipse at 38% 20%,#1b7050,#0c4b38 70%,#073729);box-shadow:inset 0 3px 8px rgba(0,0,0,.46),inset 0 0 0 1px rgba(164,214,162,.18);transform:rotateX(6deg);transform-origin:center top">${cells}</div></div>`;
    paint(
      boardView,
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
  const icons = ["✊", "✋", "✌️"];
  const score = [0, 0];
  let lastRound;
  const render = (message = "Hamleni seç.", done = false) => {
    const summary = lastRound
      ? `<div style="width:min(100%,510px);margin:0 auto 12px;display:grid;grid-template-columns:1fr auto 1fr;align-items:center;gap:8px"><div style="padding:9px 7px;border:1px solid rgba(255,255,255,.28);border-radius:12px;background:linear-gradient(145deg,#394c5c,#1d2d3c);box-shadow:inset 0 1px 0 rgba(255,255,255,.2),0 5px 10px rgba(0,0,0,.25);text-align:center;color:#fff"><span style="display:block;font-size:1.5rem">${icons[lastRound.player]}</span><strong style="font-size:.78rem">SEN</strong><small style="display:block;opacity:.85">${choices[lastRound.player]}</small></div><strong style="color:#f2d598;text-shadow:0 2px 8px rgba(242,213,152,.4)">VS</strong><div style="padding:9px 7px;border:1px solid rgba(255,255,255,.22);border-radius:12px;background:linear-gradient(145deg,#4a3945,#28242f);box-shadow:inset 0 1px 0 rgba(255,255,255,.14),0 5px 10px rgba(0,0,0,.25);text-align:center;color:#fff"><span style="display:block;font-size:1.5rem">${icons[lastRound.bot]}</span><strong style="font-size:.78rem">RAKİP</strong><small style="display:block;opacity:.85">${choices[lastRound.bot]}</small></div></div>`
      : "";
    const cards = done ? "" : grid(3, choices.map((choice, index) => {
      const selected = lastRound?.player === index;
      const playerWon = selected && lastRound?.result === 1;
      const botWon = lastRound?.bot === index && lastRound?.result === 2;
      const won = playerWon || botWon;
      const tied = selected && lastRound?.result === 0;
      const colors = index === 0
        ? ["#ffe2cf", "#cf684c", "#723c35"]
        : index === 1
          ? ["#d8fff2", "#56b89d", "#286c62"]
          : ["#e5e0ff", "#8177bd", "#403c72"];
      const effect = won
        ? "outline:2px solid #ffe28b;outline-offset:2px;box-shadow:0 0 20px 5px rgba(255,220,117,.7),inset 0 2px 0 rgba(255,255,255,.5),0 5px 0 " + colors[2] + ",0 12px 18px rgba(0,0,0,.35);"
        : tied
          ? "outline:2px solid #f5e2a7;outline-offset:2px;box-shadow:0 0 16px 4px rgba(245,226,167,.45),inset 0 2px 0 rgba(255,255,255,.5),0 5px 0 " + colors[2] + ",0 12px 18px rgba(0,0,0,.35);"
          : "box-shadow:inset 0 2px 0 rgba(255,255,255,.48),inset 0 -4px 7px rgba(0,0,0,.24),0 5px 0 " + colors[2] + ",0 12px 18px rgba(0,0,0,.35);";
      const badge = lastRound?.bot === index
        ? `<small style="position:absolute;top:6px;right:6px;padding:3px 5px;border-radius:99px;background:rgba(17,24,34,.72);color:#fff;font-size:.55rem;letter-spacing:.08em">RAKİP</small>`
        : "";
      const caption = won ? "KAZANDI" : tied ? "BERABERE" : selected ? "SEÇİMİN" : "SEÇ";
      const content = `<span aria-hidden="true" style="position:relative;display:flex;min-height:100%;width:100%;flex-direction:column;align-items:center;justify-content:center;gap:5px;padding:10px 3px;border:1px solid rgba(255,255,255,.58);border-radius:clamp(8px,1.5vw,13px);background:linear-gradient(145deg,${colors[0]} 0%,${colors[1]} 52%,${colors[2]} 100%);${effect}color:#fff;font-size:clamp(.82rem,2.7vw,1.05rem);font-weight:800;text-shadow:0 2px 4px rgba(0,0,0,.38);transform:${selected ? "translateY(-3px) rotateX(3deg)" : "translateY(-1px)"};transition:transform 180ms ease,box-shadow 180ms ease"><span style="font-size:clamp(2rem,8vw,3.6rem);line-height:1.05;filter:drop-shadow(0 4px 3px rgba(0,0,0,.28))">${icons[index]}</span><strong>${choice}</strong><small style="font-size:.58rem;letter-spacing:.14em;opacity:.86">${caption}</small>${badge}</span>`;
      return btn(content, index, `aria-label="${choice} seç" style="min-height:116px;padding:0;position:relative;aspect-ratio:.88;border:0;border-radius:clamp(8px,1.5vw,13px);background:transparent;perspective:800px;box-shadow:none;overflow:visible;cursor:pointer"`);
    }).join(""), "classic-rps-cards");
    const scoreBar = `<div style="width:min(100%,510px);margin:10px auto 0;padding:8px 12px;border:1px solid rgba(255,255,255,.16);border-radius:10px;background:linear-gradient(145deg,#3c4b58,#202a35);box-shadow:inset 0 1px 0 rgba(255,255,255,.14),0 4px 9px rgba(0,0,0,.2);text-align:center;color:#f7ead2;font-variant-numeric:tabular-nums">SEN <strong>${score[0]}</strong><span style="padding:0 12px;color:#c8b78c">—</span><strong>${score[1]}</strong> RAKİP</div>`;
    paint(summary + cards + scoreBar, message);
  };
  render();
  return click(surface, (move) => {
    const player = Number(move),
      bot = random(3);
    const result = (player - bot + 3) % 3;
    if (result) score[result - 1]++;
    const done = score.includes(3);
    lastRound = { player, bot, result };
    render(
      `Rakip ${choices[bot]} seçti. ${score[0]}-${score[1]}${done ? (score[0] === 3 ? " · Kazandın." : " · Rakip kazandı.") : ""}`,
      done,
    );
  });
}
function dice({ paint, surface }) {
  let turn = 0,
    pot = 0;
  const score = [0, 0];
  let lastRoll = null;
  let lastEvent = "Zarını at ve puan biriktir.";
  const faces = [[], [4], [0, 8], [0, 4, 8], [0, 2, 6, 8], [0, 2, 4, 6, 8], [0, 2, 3, 5, 6, 8]];
  const render = (message = "", rolling = false) => {
    const finished = score.some((n) => n >= 40);
    const face = lastRoll ?? 5;
    const pips = range(9)
      .map((position) => `<span class="classic-die-pip${faces[face].includes(position) ? " is-on" : ""}"></span>`)
      .join("");
    const scoreCards = score
      .map((points, player) => `<div class="classic-dice-player${turn === player && !finished ? " is-active" : ""}"><small>OYUNCU ${player + 1}</small><strong>${points}</strong><span>PUAN</span></div>`)
      .join("");
    const die = `<div class="classic-dice-stage"><div class="classic-die${rolling ? " is-rolling" : ""}" role="img" aria-label="Zar sonucu ${lastRoll ?? "henüz atılmadı"}">${pips}</div></div>`;
    const panel = `<style>@keyframes classic-die-roll{0%{transform:rotateX(-18deg) rotateY(22deg) translateY(0) scale(1)}22%{transform:rotateX(115deg) rotateY(176deg) translateY(-16px) scale(1.08)}48%{transform:rotateX(235deg) rotateY(316deg) translateY(2px) scale(.96)}72%{transform:rotateX(335deg) rotateY(428deg) translateY(-7px) scale(1.03)}100%{transform:rotateX(342deg) rotateY(382deg) translateY(0) scale(1)}}.classic-dice-panel{width:min(100%,520px);margin:0 auto 14px;padding:14px;border:1px solid rgba(238,215,166,.25);border-radius:18px;background:radial-gradient(ellipse at 50% 0%,rgba(76,103,121,.58),transparent 70%),linear-gradient(145deg,#253646,#17232f);box-shadow:inset 0 1px 0 rgba(255,255,255,.12),0 12px 24px rgba(0,0,0,.25);color:#fff}.classic-dice-score{display:grid;grid-template-columns:1fr 1fr;gap:10px}.classic-dice-player{display:grid;justify-items:center;gap:3px;padding:8px;border:1px solid rgba(255,255,255,.12);border-radius:12px;background:linear-gradient(145deg,#334655,#22313e);box-shadow:inset 0 1px 0 rgba(255,255,255,.1),0 5px 9px rgba(0,0,0,.2);transition:transform .18s,border-color .18s,box-shadow .18s}.classic-dice-player.is-active{transform:translateY(-2px);border-color:#f0d48f;box-shadow:0 0 15px rgba(240,212,143,.2),inset 0 1px 0 rgba(255,255,255,.15),0 7px 12px rgba(0,0,0,.25)}.classic-dice-player small,.classic-dice-player span{font-size:.63rem;letter-spacing:.12em;opacity:.78}.classic-dice-player strong{font-size:1.6rem;font-variant-numeric:tabular-nums;color:#ffe7ad;text-shadow:0 2px 8px rgba(255,214,122,.22)}.classic-dice-round{display:flex;justify-content:space-between;align-items:center;gap:10px;margin-top:10px;padding:9px 11px;border-radius:10px;background:rgba(7,14,21,.35);font-size:.82rem}.classic-dice-round strong{color:#baf4dd;font-size:1rem;font-variant-numeric:tabular-nums}.classic-dice-stage{display:grid;place-items:center;min-height:126px;padding:8px 0 18px;perspective:600px}.classic-die{position:relative;display:grid;width:clamp(70px,18vw,94px);aspect-ratio:1;grid-template:repeat(3,1fr)/repeat(3,1fr);gap:5px;padding:12px;border:1px solid #fff4db;border-radius:19px;background:linear-gradient(145deg,#fffef9 0%,#f5e9d1 54%,#dac8a7 100%);box-shadow:inset 2px 2px 5px #fff, inset -5px -6px 10px rgba(113,78,35,.2),0 8px 0 #927c5e,0 13px 18px rgba(0,0,0,.42);transform:rotateX(-18deg) rotateY(22deg);transform-style:preserve-3d}.classic-die:before{position:absolute;content:"";inset:0;border-radius:18px;transform:translateZ(-8px) translateY(8px);background:#8a7252;z-index:-1}.classic-die-pip{display:grid;place-items:center}.classic-die-pip.is-on:after{content:"";width:clamp(9px,2.4vw,13px);aspect-ratio:1;border-radius:50%;background:radial-gradient(circle at 35% 28%,#687887,#1b2631 65%);box-shadow:inset 1px 1px 2px rgba(255,255,255,.32),0 1px 2px rgba(0,0,0,.35)}.classic-die.is-rolling{animation:classic-die-roll .56s cubic-bezier(.18,.75,.24,1)}.classic-dice-actions{display:flex;justify-content:center;flex-wrap:wrap;gap:9px}.classic-dice-actions button{min-width:138px;box-shadow:inset 0 1px 0 rgba(255,255,255,.3),0 4px 0 rgba(0,0,0,.22),0 7px 12px rgba(0,0,0,.2)}.classic-dice-actions button:disabled{opacity:.48;filter:saturate(.5);box-shadow:none}@media(prefers-reduced-motion:reduce){.classic-die.is-rolling{animation:none}}</style><section class="classic-dice-panel"><div class="classic-dice-score">${scoreCards}</div>${die}<div class="classic-dice-round"><span>${lastEvent}</span><strong>ELDE <b>${pot}</b></strong></div></section>`;
    const actions = finished
      ? ""
      : `<div class="classic-dice-actions">${btn("Zar at", "roll")} ${btn("Puanı kasaya al", "hold", pot ? "" : "disabled")}</div>`;
    paint(panel + actions, message || `1. oyuncu ${score[0]} · 2. oyuncu ${score[1]} · Sıra ${turn + 1}, eldeki puan ${pot}`);
  };
  render();
  return click(surface, (move) => {
    if (move === "hold") {
      const banked = pot;
      score[turn] += banked;
      pot = 0;
      lastEvent = `${turn + 1}. oyuncu ${banked} puanı kasaya aldı.`;
      if (score[turn] >= 40) return render(turn + 1 + ". oyuncu kazandı.");
      turn ^= 1;
      return render();
    }
    const roll = 1 + random(6);
    lastRoll = roll;
    if (roll === 1) {
      lastEvent = `Bir geldi. Eldeki puan sıfırlandı; sıra ${turn + 2 > 2 ? 1 : turn + 2}. oyuncuda.`;
      pot = 0;
      turn ^= 1;
      return render("Bir geldi. Sıra " + (turn + 1), true);
    }
    pot += roll;
    lastEvent = `Zar ${roll} geldi · eldeki puan ${pot}.`;
    render("Zar " + roll + " · Elde " + pot, true);
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
  const previousFaceUp = new Set();
  const render = (message = "Hamle " + moves) => {
    const cards = deck.map((symbol, index) => {
      const faceUp = triple || active.includes(index);
      const matched = removed.has(index);
      const disabled = matched || active.includes(index);
      const label = matched ? "" : faceUp ? " " + symbol : "";
      const turnStyle = faceUp !== previousFaceUp.has(index)
        ? `animation:classic-memory-${faceUp ? "flip" : "unflip"} 460ms cubic-bezier(.2,.75,.25,1) ${Math.min(index, 5) * 16}ms both;`
        : `transform:rotateY(${faceUp ? 180 : 0}deg);`;
      const card = `<span style="position:absolute;inset:0;display:grid;place-items:center;border:1px solid rgba(255,255,255,.58);border-radius:clamp(7px,1.6vw,14px);backface-visibility:hidden;background:linear-gradient(145deg,#fff8df 0%,#f3dfb8 52%,#cfac7d 100%);box-shadow:inset 0 2px 0 rgba(255,255,255,.9),inset 0 -4px 7px rgba(95,62,34,.18),0 3px 0 #8f6945,0 8px 13px rgba(0,0,0,.3);color:#3b2b45;font-size:clamp(1.4rem,5.2vw,2.65rem);font-weight:800;text-shadow:0 2px 0 rgba(255,255,255,.65)">${matched ? "" : symbol}</span>`;
      const cover = `<span style="position:absolute;inset:0;display:grid;place-items:center;overflow:hidden;border:1px solid rgba(221,238,255,.6);border-radius:clamp(7px,1.6vw,14px);backface-visibility:hidden;background:radial-gradient(circle at 28% 18%,#586f9c 0%,#354b76 35%,#243555 76%,#18243d 100%);box-shadow:inset 0 2px 0 rgba(255,255,255,.35),inset 0 -5px 8px rgba(8,15,31,.5),0 3px 0 #111b30,0 8px 13px rgba(0,0,0,.34);color:#f4d895"><span style="display:grid;place-items:center;width:62%;aspect-ratio:1;border:1px solid rgba(255,228,170,.65);border-radius:50%;box-shadow:0 0 0 4px rgba(255,228,170,.1),inset 0 0 10px rgba(255,228,170,.22);font-size:clamp(1rem,3.5vw,1.55rem)">✦</span><small style="position:absolute;bottom:8%;font-size:.55rem;font-weight:800;letter-spacing:.18em;opacity:.78">AZOYUN</small></span>`;
      const content = `<span aria-hidden="true" style="position:absolute;inset:0;transform-style:preserve-3d;${turnStyle}${matched ? "opacity:.12;" : ""}">${cover}<span style="position:absolute;inset:0;display:grid;place-items:center;transform:rotateY(180deg);backface-visibility:hidden">${card}</span></span>`;
      return btn(
        content,
        index,
        `aria-label="${index + 1}. kart${label}" ${disabled ? "disabled" : ""} style="min-height:0;padding:0;position:relative;aspect-ratio:.84;border:0;border-radius:clamp(7px,1.6vw,14px);background:transparent;perspective:900px;transform-style:preserve-3d;overflow:visible;box-shadow:none;cursor:${disabled ? "default" : "pointer"}"`,
      );
    }).join("");
    previousFaceUp.clear();
    deck.forEach((_, index) => {
      if (triple || active.includes(index)) previousFaceUp.add(index);
    });
    const motion = '<style>@keyframes classic-memory-flip{0%{transform:rotateY(0deg) translateY(5px) scale(.96)}65%{transform:rotateY(195deg) translateY(-2px) scale(1.035)}100%{transform:rotateY(180deg) translateY(0) scale(1)}}@keyframes classic-memory-unflip{0%{transform:rotateY(180deg) translateY(0) scale(1)}55%{transform:rotateY(-15deg) translateY(-2px) scale(1.02)}100%{transform:rotateY(0deg) translateY(4px) scale(.96)}}@media(prefers-reduced-motion:reduce){.classic-memory-cards *{animation-duration:.01ms!important;animation-delay:0ms!important}}</style>';
    paint(
      motion + grid(
        triple ? 6 : 4,
        cards,
        "classic-memory-cards",
      ) +
        (triple
          ? `<p style="text-align:center;margin:4px auto 10px;color:#e9d5ac">Tepsi (${active.length}/7) ${active.map((index) => deck[index]).join(" ")}</p>`
          : ""),
      message,
    );
  };
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
  ) => {
    const cells = board.map((n, index) => {
      if (!n)
        return '<span class="classic-cell" aria-hidden="true" style="min-height:0;padding:0;border:1px solid rgba(204,222,223,.1);border-radius:clamp(5px,1.3vw,11px);background:linear-gradient(145deg,#101d26,#172b35 65%,#20343a);box-shadow:inset 0 4px 8px rgba(0,0,0,.44),inset 0 -1px 0 rgba(255,255,255,.04)"></span>';
      const complete = numbers && n < next;
      const active = numbers && n === next;
      const palettes = complete
        ? ["#9ec5aa", "#416e57", "#244637", "#f1f8e9"]
        : active
          ? ["#fff0b4", "#e3ad4e", "#8f5425", "#fffce6"]
          : ["#fff3d1", ["#d5a36a", "#bd8d5a", "#dfa967", "#c39160"][n % 4], "#765139", "#fff7e8"];
      const [light, face, shadow, ink] = palettes;
      const fontSize = String(n).length > 1 ? "clamp(1rem,4.1vw,1.8rem)" : "clamp(1.2rem,5vw,2.25rem)";
      return btn(
        `<span aria-hidden="true">${n}</span>`,
        index,
        `aria-label="${numbers ? 'Sayı ' : 'Taş '}${n}" ${numbers && n < next ? "disabled" : ""} style="min-height:0;padding:0;aspect-ratio:1;border:1px solid rgba(255,255,255,.52);border-radius:clamp(5px,1.3vw,11px);background:linear-gradient(145deg,${light} 0%,${face} 52%,${shadow} 100%);box-shadow:inset 0 2px 0 rgba(255,255,255,.72),inset 0 -3px 0 rgba(45,27,16,.25),0 3px 0 ${shadow},0 7px 11px rgba(0,0,0,.34);color:${ink};font-size:${fontSize};font-weight:900;text-shadow:0 1px 0 rgba(55,35,22,.2);transform:translateY(-2px);cursor:${complete ? "default" : "pointer"};${active ? "outline:2px solid #fff0b4;outline-offset:1px;" : ""}`,
      );
    }).join("");
    const boardView = `<div style="width:min(100%,510px);margin:0 auto;padding:clamp(8px,2vw,15px);border:1px solid rgba(255,224,174,.5);border-radius:clamp(12px,2vw,20px);background:linear-gradient(135deg,#a87543 0%,#684324 25%,#bd8955 52%,#56361f 78%,#8a5932 100%);box-shadow:inset 0 2px 0 rgba(255,241,214,.6),inset 0 -5px 8px rgba(36,20,12,.55),0 10px 20px rgba(0,0,0,.38)"><div class="classic-grid" role="grid" aria-label="${numbers ? 'Sayı bulmaca tahtası' : 'Kaydırmalı sayı tahtası'}" style="--columns:${width};width:100%;aspect-ratio:1;grid-auto-rows:minmax(0,1fr);gap:clamp(3px,.9vw,7px);padding:clamp(5px,1.2vw,9px);border:1px solid rgba(10,38,30,.8);border-radius:clamp(6px,1.3vw,11px);background:radial-gradient(ellipse at 38% 20%,#354747,#1b2c31 70%,#132329);box-shadow:inset 0 3px 8px rgba(0,0,0,.46),inset 0 0 0 1px rgba(164,214,162,.1)">${cells}</div></div>`;
    paint(boardView, message);
  };
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
  const tileColors = {
    2: ["#fff2cb", "#d7ab70", "#9b643d", "#fffaf0"],
    4: ["#ffe5b3", "#e5a45f", "#a95c35", "#fff5df"],
    8: ["#ffd5a0", "#f28b52", "#a9442d", "#fff8ed"],
    16: ["#ffd2a3", "#ef704b", "#982e31", "#fff2e7"],
    32: ["#ffc3a0", "#df554f", "#852c40", "#fff0ec"],
    64: ["#ffc0a5", "#c83c50", "#6f263d", "#fff1ee"],
    128: ["#fff1aa", "#e4bd42", "#876328", "#fffbe2"],
    256: ["#fff0a3", "#d9a92f", "#805025", "#fff9d7"],
    512: ["#fff0a7", "#c98832", "#6d4021", "#fff8df"],
    1024: ["#fff1ad", "#b97835", "#633725", "#fff9e6"],
    2048: ["#fff6c6", "#e8bd50", "#8c4d24", "#fffdf2"],
  };
  function spawn() {
    const spaces = range(16).filter((i) => !board[i]);
    if (spaces.length)
      board[spaces[random(spaces.length)]] = random(10) ? 2 : 4;
  }
  function render(message = "Puan " + score) {
    const highest = Math.max(...board);
    const tiles = board.map((n, index) => {
      if (!n)
        return `<span class="classic-cell" role="gridcell" aria-label="${Math.floor(index / 4) + 1}. satır, ${index % 4 + 1}. sütun, boş" data-number="0" style="min-height:0;padding:0;border:1px solid rgba(186,220,232,.12);border-radius:clamp(5px,1.4vw,12px);background:linear-gradient(145deg,#213847,#172a37 62%,#12232f);box-shadow:inset 0 3px 7px rgba(0,0,0,.36),inset 0 -1px 0 rgba(177,218,231,.06)"></span>`;
      const [light, face, dark, ink] = tileColors[n] || tileColors[2048];
      const size = n >= 1024 ? "clamp(.86rem,4vw,1.85rem)" : n >= 128 ? "clamp(1rem,4.8vw,2.15rem)" : "clamp(1.2rem,5.4vw,2.45rem)";
      return `<span class="classic-cell" role="gridcell" aria-label="${Math.floor(index / 4) + 1}. satır, ${index % 4 + 1}. sütun, ${n}" data-number="${n}" style="min-height:0;padding:0;border:1px solid rgba(255,255,255,.55);border-radius:clamp(5px,1.4vw,12px);background:linear-gradient(145deg,${light} 0%,${face} 48%,${dark} 100%);box-shadow:inset 0 2px 0 rgba(255,255,255,.68),inset 0 -3px 0 rgba(26,19,28,.28),0 3px 0 ${dark},0 7px 12px rgba(0,0,0,.34);color:${ink};font-size:${size};font-weight:900;text-shadow:0 1px 0 rgba(45,29,26,.28),0 3px 7px rgba(34,19,25,.2);transform:translateY(-2px)">${n}</span>`;
    }).join("");
    const counters = `<div class="classic-2048-counters" style="width:min(100%,510px);display:flex;justify-content:flex-end;gap:8px;margin:0 auto 10px"><div style="min-width:94px;padding:7px 12px;border:1px solid rgba(255,255,255,.16);border-radius:10px;background:linear-gradient(145deg,#435367,#283646);box-shadow:inset 0 1px 0 rgba(255,255,255,.18),0 4px 8px rgba(0,0,0,.24);text-align:center;color:#fff"><small style="display:block;font-size:.65rem;letter-spacing:.12em;opacity:.8">PUAN</small><strong style="font-size:1.1rem;font-variant-numeric:tabular-nums">${score.toLocaleString("tr-TR")}</strong></div><div style="min-width:94px;padding:7px 12px;border:1px solid rgba(255,255,255,.2);border-radius:10px;background:linear-gradient(145deg,#785c38,#40312d);box-shadow:inset 0 1px 0 rgba(255,255,255,.2),0 4px 8px rgba(0,0,0,.24);text-align:center;color:#fff3d5"><small style="display:block;font-size:.65rem;letter-spacing:.12em;opacity:.85">EN BÜYÜK TAŞ</small><strong style="font-size:1.1rem;font-variant-numeric:tabular-nums">${highest}</strong></div></div>`;
    paint(
      counters +
        `<div class="classic-grid classic-2048-board" role="grid" aria-label="2048 oyun tahtası" style="--columns:4;width:min(100%,510px);aspect-ratio:1;grid-auto-rows:minmax(0,1fr);gap:clamp(5px,1.5vw,10px);padding:clamp(7px,2vw,12px);border:1px solid rgba(186,220,232,.2);border-radius:clamp(10px,2vw,18px);background:linear-gradient(145deg,#263e4d,#182b39 58%,#12222f);box-shadow:inset 0 2px 0 rgba(255,255,255,.08),inset 0 -8px 18px rgba(0,0,0,.24),0 12px 26px rgba(0,0,0,.34)">${tiles}</div>` +
        '<p class="classic-hint">Yön tuşlarıyla da oynayabilirsin: ← ↑ → ↓</p>' +
        moveButtons,
      message,
    );
  }
  function move(direction) {
    const result = apply2048Move(board, ["left", "right", "up", "down"][direction]);
    if (result.changed) {
      board.splice(0, board.length, ...result.board);
      score += result.score;
      spawn();
    }
    const stuck = is2048GameOver(board);
    render(
      stuck
        ? "Hamle kalmadı. Puan " + score
        : result.won
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
  if (mode === "balon") return balloonTargets({ paint, surface });
  if (mode === "maymun") return monkeyTargets({ paint, surface });
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
function monkeyTargets({ paint, surface }) {
  let target = 4,
    score = 0,
    remaining = MONKEY_SESSION_SECONDS,
    running = false;
  let countdown, movement;
  const render = () =>
    paint(
      running
        ? grid(3, range(9).map((i) => btn(i === target ? "🐵" : "·", i,
            `aria-label="${i === target ? "Maymun" : "Boş"} ${i + 1}"`)).join(""))
        : remaining
          ? btn("Başla", "start")
          : "",
      `Puan ${score} · ${remaining} sn`,
    );
  const end = () => {
    running = false;
    clearInterval(countdown);
    clearInterval(movement);
    render();
  };
  render();
  const clear = click(surface, (value) => {
    if (value === "start" && !running && remaining === MONKEY_SESSION_SECONDS) {
      running = true;
      movement = setInterval(() => {
        target = random(9);
        render();
      }, MONKEY_MOVE_INTERVAL_MS);
      countdown = setInterval(() => {
        const tick = tickMonkeySession(remaining);
        remaining = tick.secondsLeft;
        if (!tick.running) end();
        else render();
      }, 1000);
      return render();
    }
    const result = tapMonkey({ score, targetIndex: target, tappedIndex: Number(value), running });
    if (!result.hit) return;
    score = result.score;
    target = random(9);
    render();
  });
  return () => {
    clear();
    clearInterval(countdown);
    clearInterval(movement);
  };
}
function scubaDiverGame({ paint, surface, say }) {
  const width = 540, height = 400;
  paint(
    `<canvas class="classic-canvas drawing-game" width="${width}" height="${height}" aria-label="Scuba Sweep dalış alanı"></canvas>` +
      '<div class="actions scuba-controls">' +
      btn("Dalışa başla", "start") + btn("Duraklat", "pause", 'hidden') +
      btn("◀", "left", 'aria-label="Sola yüz"') + btn("▶", "right", 'aria-label="Sağa yüz"') +
      "</div>",
    "Dalgıcı sürükle. Atıkları topla, deniz canlılarından kaç.",
  );
  const canvas = surface.querySelector("canvas");
  const ctx = canvas.getContext("2d");
  const items = [];
  const symbols = { bottle: "🧴", glass: "🍾", bag: "🛍️", straw: "🥤", shark: "🦈", puffer: "🐡", jelly: "🪼", pearl: "🦪" };
  const plasticKinds = ["bottle", "glass", "bag", "straw"];
  let x = .5, diverY = .92, time = 0, trashIn = 0, enemyIn = .8, pearlIn = 4;
  let shield = 0, score = 0, level = 1, collectFlash = 0, running = false, paused = false, timer;
  const lane = () => .12 + Math.random() * .76;
  const spawnPlastic = () => items.push({ kind: plasticKinds[random(plasticKinds.length)], x: lane(), y: -.08, vx: 0, scale: 1 });
  const spawnEnemy = () => {
    const pool = Math.min(level, 3);
    const kind = ["shark", "puffer", "jelly"][random(pool)];
    const at = lane();
    items.push({ kind, x: at, y: -.1, vx: kind === "shark" ? (at < .5 ? .18 : -.18) : 0, scale: 1 });
  };
  const draw = () => {
    const bg = ctx.createLinearGradient(0, 0, 0, height);
    bg.addColorStop(0, "#45b2c9"); bg.addColorStop(.55, "#17627c"); bg.addColorStop(1, "#0a3448");
    ctx.fillStyle = bg; ctx.fillRect(0, 0, width, height);
    for (let i = 0; i < 4; i++) {
      ctx.fillStyle = "rgba(255,255,255,.055)";
      ctx.beginPath(); ctx.moveTo(width * (.12 + i * .24), 0); ctx.lineTo(width * (.17 + i * .24), 0);
      ctx.lineTo(width * (.37 + i * .15), height * .7); ctx.lineTo(width * (.23 + i * .15), height * .7); ctx.fill();
    }
    ctx.fillStyle = "#0e4657";
    ctx.beginPath(); ctx.moveTo(0,height*.72); ctx.quadraticCurveTo(width*.5,height*.62,width,height*.72); ctx.lineTo(width,height); ctx.lineTo(0,height); ctx.fill();
    ctx.fillStyle = "#0c5465"; ctx.fillRect(0,height*.81,width,height*.19);
    for (let i = 0; i < 16; i++) {
      const bx = ((i * 47 + time * 11) % width), by = height - ((i * 29 + time * 17) % height);
      ctx.strokeStyle = "rgba(190,248,245,.38)"; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.arc(bx,by,2+(i%3),0,Math.PI*2); ctx.stroke();
    }
    for (const item of items) {
      const px = item.x * width, py = item.y * height;
      const size = item.kind === "puffer" ? 26 * item.scale : 27;
      ctx.font = `${size}px system-ui, sans-serif`; ctx.textAlign = "center"; ctx.textBaseline = "middle";
      ctx.fillText(symbols[item.kind], px, py);
    }
    const diverX = x * width, diverPixelY = diverY * height;
    if (shield > 0) {
      ctx.strokeStyle = "rgba(123,250,255,.7)"; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(diverX,diverPixelY,34,0,Math.PI*2); ctx.stroke();
    }
    if (collectFlash > 0) {
      ctx.fillStyle = `rgba(255,230,119,${collectFlash*.18})`; ctx.fillRect(0,0,width,height);
    }
    ctx.font = "38px system-ui, sans-serif"; ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.fillText("🤿", diverX, diverPixelY);
    ctx.fillStyle = "rgba(4,27,42,.65)"; ctx.fillRect(10,10,220,38);
    ctx.fillStyle = "#efffff"; ctx.textAlign = "left"; ctx.font = "bold 16px system-ui, sans-serif";
    ctx.fillText(`SEVİYE ${level}   PLASTİK ${score}${shield > 0 ? "   KALKAN" : ""}`,20,34);
    if (paused) {
      ctx.fillStyle = "rgba(2,18,31,.55)"; ctx.fillRect(0,0,width,height);
      ctx.fillStyle = "white"; ctx.textAlign = "center"; ctx.font = "bold 28px system-ui"; ctx.fillText("DURAKLATILDI",width/2,height/2);
    }
  };
  const end = () => {
    clearInterval(timer); timer = undefined; running = false; paused = false;
    draw(); say(`Çarptın. ${score} plastik topladın.`);
  };
  const tick = () => {
    if (!running || paused) return;
    const dt = SCUBA_STEP_SECONDS;
    time += dt; collectFlash = Math.max(0, collectFlash - dt * 2.6);
    if (diverY > SCUBA_DIVER_HOME_Y) diverY = Math.max(SCUBA_DIVER_HOME_Y, diverY - .01);
    const pace = scubaPace(level, shield > 0);
    if (shield > 0) shield -= dt;
    let timerState = scubaSpawnTick(trashIn, dt, SCUBA_TRASH_SPAWN_SECONDS); trashIn = timerState.elapsed;
    if (timerState.spawn) spawnPlastic();
    timerState = scubaSpawnTick(enemyIn, dt, SCUBA_ENEMY_SPAWN_SECONDS); enemyIn = timerState.elapsed;
    if (timerState.spawn) spawnEnemy();
    timerState = scubaSpawnTick(pearlIn, dt, SCUBA_PEARL_SPAWN_SECONDS); pearlIn = timerState.elapsed;
    if (timerState.spawn) { pearlIn = 0; items.push({kind:"pearl",x:lane(),y:-.08,vx:0,scale:1}); }
    for (const item of items) {
      item.y = scubaMoveDriftY(item.y, pace, dt);
      item.x = scubaMoveDriftX(item.x, item.vx, dt);
      if (item.kind === "puffer" && item.scale < 2.4) item.scale += dt * .35;
    }
    for (let i = items.length - 1; i >= 0; i--) if (items[i].y > 1.25) items.splice(i, 1);
    for (let i = items.length - 1; i >= 0; i--) {
      const item = items[i], reach = scubaCollisionReach(item.kind, item.scale);
      if (!scubaOverlap(x, diverY, item.x, item.y, reach)) continue;
      items.splice(i, 1);
      const contact = scubaResolveContact({kind:item.kind,score,level,shieldSeconds:shield});
      if (contact.gameOver) return end();
      score = contact.score; level = contact.level; shield = contact.shieldSeconds;
      if (item.kind !== "pearl") collectFlash = 1;
    }
    draw();
  };
  const start = () => {
    if (running) return;
    running = true; paused = false;
    surface.querySelector('[data-move="start"]').hidden = true;
    surface.querySelector('[data-move="pause"]').hidden = false;
    say("Sürükleyerek yönlendir.");
    timer = setInterval(tick, 30); draw();
  };
  const clear = click(surface, (value) => {
    if (value === "start") return start();
    if (value === "pause" && running) { paused = !paused; surface.querySelector('[data-move="pause"]').textContent = paused ? "Devam et" : "Duraklat"; return draw(); }
    if (value === "left") x = Math.max(.08,x-.08);
    if (value === "right") x = Math.min(.92,x+.08);
    draw();
  });
  let dragging = false, previousX = 0;
  const pointerDown = (event) => { dragging=true; previousX=event.clientX; canvas.setPointerCapture?.(event.pointerId); };
  const pointerMove = (event) => {
    if (!dragging || !running || paused) return;
    const rect=canvas.getBoundingClientRect(); x=Math.max(.08,Math.min(.92,x+(event.clientX-previousX)/rect.width)); previousX=event.clientX; draw();
  };
  const pointerUp = () => { dragging=false; };
  const key = (event) => {
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") { event.preventDefault(); x=Math.max(.08,Math.min(.92,x+(event.key==="ArrowLeft"?-.06:.06))); draw(); }
    if (event.code === "Space" && !running) { event.preventDefault(); start(); }
  };
  canvas.addEventListener("pointerdown",pointerDown); canvas.addEventListener("pointermove",pointerMove);
  canvas.addEventListener("pointerup",pointerUp); canvas.addEventListener("pointercancel",pointerUp);
  document.addEventListener("keydown",key); draw();
  return () => { clear(); clearInterval(timer); canvas.removeEventListener("pointerdown",pointerDown); canvas.removeEventListener("pointermove",pointerMove); canvas.removeEventListener("pointerup",pointerUp); canvas.removeEventListener("pointercancel",pointerUp); document.removeEventListener("keydown",key); };
}
function balloonTargets({ paint, surface }) {
  let target = random(16),
    score = 0,
    remaining = BALLOON_SESSION_SECONDS,
    running = true;
  let countdown, targetTimer, gapTimer;
  const render = () =>
    paint(
      grid(
        4,
        range(16)
          .map((i) => btn(i === target ? "🎈" : "·", i,
            `aria-label="${i === target ? "Balon" : "Boş"} ${i + 1}"`))
          .join(""),
      ),
      `Puan ${score} · ${remaining} sn`,
    );
  const spawn = () => {
    if (!running) return;
    target = random(16);
    render();
    targetTimer = setTimeout(() => {
      target = -1;
      render();
      gapTimer = setTimeout(spawn, 200);
    }, BALLOON_LIFETIME_MS);
  };
  const end = () => {
    running = false;
    target = -1;
    clearInterval(countdown);
    clearTimeout(targetTimer);
    clearTimeout(gapTimer);
    render();
  };
  render();
  spawn();
  countdown = setInterval(() => {
    const tick = tickBalloonSession(remaining);
    remaining = tick.secondsLeft;
    if (!tick.running) end();
    else render();
  }, 1000);
  const clear = click(surface, (value) => {
    const result = popBalloon({ score, visible: Number(value) === target, running });
    if (!result.popped) return;
    score = result.score;
    target = -1;
    clearTimeout(targetTimer);
    render();
    gapTimer = setTimeout(spawn, 150);
  });
  return () => {
    clear();
    clearInterval(countdown);
    clearTimeout(targetTimer);
    clearTimeout(gapTimer);
  };
}
function snake({ paint, surface, say }) {
  const size = 14,
    cellSize = 300 / size,
    directions = ["left", "right", "up", "down"];
  const snake = [
    [6, 7],
    [5, 7],
    [4, 7],
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
      ctx.fillRect(x * cellSize + 1, y * cellSize + 1, cellSize - 2, cellSize - 2);
    }
    if (apple) {
      ctx.fillStyle = "#ffbe74";
      ctx.fillRect(apple[0] * cellSize + 3, apple[1] * cellSize + 3, cellSize - 6, cellSize - 6);
    }
  };
  const steer = (next) => {
    const nextDirection = directions[next];
    if (nextDirection && canTurnSnake(directions[direction], nextDirection)) pending = next;
  };
  function tick() {
    direction = pending;
    const result = stepSnake(snake, directions[direction], apple, size);
    if (result.collided) {
      clearInterval(timer);
      return say("Oyun bitti. Puan " + score);
    }
    snake.splice(0, snake.length, ...result.snake);
    if (result.ate) {
      apple = food();
      score += result.score;
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
  scuba: scubaDiverGame,
  yilan: snake,
  oje: nails,
  ciz: drawGame,
};
function runner({ paint, surface, say }, mode) {
  if (mode === "zipla") return flappyRunner({ paint, surface, say });
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
function flappyRunner({ paint, surface, say }) {
  paint(
    '<canvas class="classic-canvas drawing-game" width="540" height="280" aria-label="Zıpla Geç uçuş alanı"></canvas>' +
      btn("Başla", "start") + '<div class="actions">' + btn("Zıpla", "jump") + "</div>",
    "Boruların arasından geç.",
  );
  const canvas = surface.querySelector("canvas");
  const ctx = canvas.getContext("2d");
  let birdY = 0.5,
    velocity = 0,
    spawnTimer = 0,
    score = 0,
    phase = 0,
    timer;
  const pipes = [];
  const draw = () => {
    const { width, height } = canvas;
    const sky = ctx.createLinearGradient(0, 0, 0, height);
    sky.addColorStop(0, "#6cc6df");
    sky.addColorStop(.56, "#b8e5da");
    sky.addColorStop(1, "#e9f0cb");
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, width, height);
    ctx.fillStyle = "#fff1bd";
    ctx.beginPath();
    ctx.arc(width * .8, height * .16, width * .075, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#77ad75";
    ctx.beginPath();
    ctx.moveTo(0, height * .68);
    for (let x = 0; x <= width; x += 8) {
      ctx.lineTo(x, height * (.66 + Math.sin(x * .018 + phase) * .045));
    }
    ctx.lineTo(width, height); ctx.lineTo(0, height); ctx.fill();
    const birdX = JUMP_DASH_BIRD_X * width;
    for (const pipe of pipes) {
      const px = pipe.x * width;
      const top = (pipe.gap - JUMP_DASH_GAP_HALF) * height;
      const bottom = (pipe.gap + JUMP_DASH_GAP_HALF) * height;
      ctx.fillStyle = "#39875d";
      ctx.fillRect(px, 0, JUMP_DASH_PIPE_WIDTH * width, top);
      ctx.fillRect(px, bottom, JUMP_DASH_PIPE_WIDTH * width, height - bottom);
      ctx.fillStyle = "#9be59b";
      ctx.fillRect(px + 5, 0, 5, top);
      ctx.fillRect(px + 5, bottom, 5, height - bottom);
    }
    ctx.save();
    ctx.translate(birdX, birdY * height);
    ctx.fillStyle = "#ffc94d";
    ctx.beginPath();
    ctx.ellipse(0, 0, JUMP_DASH_BIRD_RADIUS * width, JUMP_DASH_BIRD_RADIUS * width * .78, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#fff";
    ctx.beginPath(); ctx.arc(5, -4, 4, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = "#3c3445";
    ctx.beginPath(); ctx.arc(6, -4, 1.7, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = "#f07857";
    ctx.beginPath(); ctx.moveTo(9, 2); ctx.lineTo(18, 5); ctx.lineTo(9, 8); ctx.fill();
    ctx.restore();
    ctx.fillStyle = "#4d8a55";
    ctx.fillRect(0, height - 10, width, 10);
    ctx.fillStyle = "#fff";
    ctx.font = "bold 22px system-ui";
    ctx.fillText("Puan " + score, 14, 28);
  };
  const tick = () => {
    velocity = jumpDashNextVelocity(velocity);
    birdY = jumpDashNextBirdY(birdY, velocity);
    phase += .03;
    spawnTimer += JUMP_DASH_PIPE_SPEED;
    if (jumpDashShouldSpawn(spawnTimer)) {
      spawnTimer = 0;
      pipes.push({ x: 1.15, gap: .22 + Math.random() * .56, passed: false });
    }
    for (const pipe of pipes) {
      pipe.x = jumpDashNextPipeX(pipe.x);
      if (!pipe.passed && jumpDashPipePassed(pipe.x)) { pipe.passed = true; score++; }
    }
    while (pipes.length && pipes[0].x < -.2) pipes.shift();
    if (jumpDashHitBoundary(birdY) || pipes.some((pipe) => jumpDashPipeCollision(birdY, pipe.x, pipe.gap))) {
      clearInterval(timer);
      timer = undefined;
      draw();
      say("Çarptın! Skor: " + score);
      return;
    }
    draw();
  };
  const jump = () => { if (timer) velocity = JUMP_DASH_IMPULSE; };
  const clear = click(surface, (value) => {
    if (value === "start" && !timer) {
      surface.querySelector('[data-move="start"]').hidden = true;
      timer = setInterval(tick, 30);
    } else if (value === "jump") jump();
  });
  const key = (event) => {
    if (event.code === "Space" && timer) { event.preventDefault(); jump(); }
  };
  document.addEventListener("keydown", key);
  draw();
  return () => { clear(); clearInterval(timer); document.removeEventListener("keydown", key); };
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
