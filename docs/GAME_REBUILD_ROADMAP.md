# AZOyun Game Rebuild Roadmap

Status date: 2026-11-24. This is the working project plan derived from the repo inventory, the Android/Web client matrix, the current implementation audit and the linked game-development skill. It does not imply every game is already complete or device-verified.

## Product rule

Android is the primary play surface. Web is a first-class counterpart where the catalog advertises it. Every card must open a playable implementation in the same surface; no dead links, quiz placeholders presented as action games, or Android-to-browser escapes. Build game families in priority order and publish only when their acceptance criteria pass.

## Platform and orientation policy

| Game family | Android | Web | Preferred orientation |
|---|---|---|---|
| Okey / 101 Okey, Pişti, Batak, chess, Reversi, Connect Four, Carrom, Mini Bowling | Native Flutter | Web only when a real browser implementation exists | Landscape for live board/table play; portrait may be used for lobby/setup |
| Family Table / TV board | Flutter TV/tablet host and phone client | Browser TV host and phone client | Host landscape/wide; phone controller adapts to device |
| Football grid, squad chemistry, career/link/connection puzzle | Flutter native screens | Dedicated responsive browser game | Landscape when displaying a multi-row board or squad; portrait quiz only when the board genuinely fits |
| Penalty / free-kick quick play | Flutter in-app gameplay | Browser Canvas/WebGL gameplay | Portrait is allowed for one-thumb shot flow; landscape for full pitch/TV mode |
| Vapur, runner, action 2D/3D arcade | Native Flutter for native modes; packaged local Three.js only for selected 3D modes | Canvas/Three.js browser route | Match camera and controls; usually landscape for field/3D driving, portrait for one-thumb runners |
| Wordle, career quiz, 2048, Snake, reaction and compact word games | Flutter | Web when listed | Portrait/adaptive |

Orientation is owned by the live game route. Setup screens may be portrait; entering a board sets its preferred orientation; leaving the complete nested flow restores the system/default orientation once.

## Work phases and gates

### P0 — Android first: playable tables, football and broken launches

1. Audit every Android catalog tile against its actual Flutter/native route. Repair broken launches first; gameplay must stay in the app. No placeholder quiz may stand in for a football action/board game.
2. Complete Okey/101 table interaction: all 22 rack tiles fit at gameplay sizes; tap and drag reorder work; grouping handles duplicate faces and jokers; auto-sort and best-hand arrangement are clearly labeled and rule-correct; score/open/finish states remain visible in landscape.
3. Ensure every Android table game exposed in the table menu can be hosted on the TV/shared board and joined from phones: Okey, 101, Pişti, Batak, Mahalleler, Word board and hidden-role games. Share a game only when its room contract exists; align the TV selector with actually playable implementations.
4. Put football first among non-table games: Android chemistry squad, career/link path, player quiz/Wordle, connections and Box2Box must use the dynamic sourced catalog, work offline from a cached catalog, and stay in Flutter.
5. Fix arcade entry routes: native 2D games remain Flutter; Vapur stays native; Three.js modes must load packaged assets inside the app, handle touch and resize, and show recovery UI instead of blank screen or external browser.
6. Apply the orientation matrix per gameplay route: table/board/grid/squad games landscape; compact word/quiz/reaction games portrait/adaptive; penalty/free-kick portrait only for one-thumb flow and landscape when showing a full pitch. Restore orientation only after the whole game flow closes.
7. Acceptance: each prioritized Android game starts, takes valid input, shows its state/score, reaches a result and can replay. If a game cannot meet this gate, remove/disable its launch card until it can.

### P1 — All table games on Android + shared TV/web table

1. Android table menu and TV/web host must expose the same table-game list. For each game, TV shows the board/state and phones are player controllers; a phone-only waiting room is not a delivered family-table game.
2. Define a versioned authoritative room/action/result contract. Adapt Pişti and Batak's current separate Firebase room shapes; do not publish public RTDB writes or leak private hands/roles.
3. Server validates seat, turn, legal action, room revision, hidden information and result. Reconnect returns a player to the same seat; stale actions, room full and API unavailable get clear recovery UI.
4. Acceptance per game: TV/browser creates room and displays a join code/QR; Android phone joins; each player completes legal turns; TV and phones see the same result; reconnect and replay work. A game absent from one client must be hidden from both selectors until parity is ready.

### P2 — Complete all remaining board, party and football loops

1. Chess: legal moves including castling, en passant and promotion; check/mate/stalemate/draw states; landscape board, pass-and-play, then online room only after the room contract is available.
2. Pişti and Batak: complete rules/score/round/end flows; valid-card affordances, hand privacy, landscape, rematch and shared-table adapters.
3. Mahalleler: dice/turns, property purchase/auction/rent/development/trade, bankruptcy and win condition; original visuals and rules with landscape board.
4. Football: grow the free, sourced, versioned player-career dataset and dynamic refresh pipeline; retain cached data and retry cleanly. No paid API key should be required for ordinary play.
5. Other existing catalog games (2D, 3D, word, party, racing, strategy and children’s games): classify each by real core loop and complete one family at a time; do not leave a card that only opens a shell.
6. Acceptance: rule references and shared scenario vectors cover legal/illegal/terminal states; every mode can be completed and replayed. Dynamic football questions resolve against sourced career facts.

### P3 — Web parity and release quality

1. Mirror completed Android gameplay on web using the same versioned rules/data/room contracts. Keep HTML/CSS/JS salon architecture; no Flutter Web migration.
2. Check browser touch/mouse, viewport/orientation, resize, asset failure, visibility pause/resume, audio unlock and console errors.
3. Profile lower-end Android and representative mobile browsers before visual expansion.
4. Publish only modes that pass the same playable-loop gate; keep unready modes out of both catalogs.

## Audit findings that shape the order

- Android currently uses Flutter while the website uses a separate static HTML/CSS/JS salon. The client inventory is documented in [GAME_CLIENT_MATRIX.md](GAME_CLIENT_MATRIX.md); similar names do not prove rule parity.
- Family Table exposes different game sets across Android and the web API. Pişti and Batak currently have separate room shapes, so selector parity requires server/client integration work.
- Okey auto-arrangement was identified as greedy and incomplete for jokers and duplicate tiles; do not label it optimal until the objective handles both and is demonstrably bounded.
- Chess is pass-and-play locally; online room play is a separate scope.
- 3D Android uses local WebView assets for some modes; a successful build does not prove runtime assets/WebGL work on a device.
- Football catalog/play modes exist across multiple screens; source freshness and offline behavior need the versioned catalog gate above.
- Previous work added route/landscape/native arcade fixes, six Flutter football screens and a web Box2Box route, but this is an implementation start—not completion of all table, arcade, football or cross-platform requirements above.

## 30-role delivery office (Ruflo)

The registered office is hierarchical-mesh: project manager, CTO/architecture, Android release, Okey rules/UI/solver, chess rules/UI/network, Pişti rules/UI, Batak rules/UI, Mahalleler rules/UI, Family API/web/Android, football data/gameplay/web, arcade runtime/native/web, orientation, mobile UI, game AI, catalog routes, cloud CI, and rules research.

Ruflo lists 30 registered agent records and 30 pending tasks. Its swarm summary simultaneously reports `taskCount: 0`, so the task-list count and swarm counter are inconsistent. The governing rebuild mission is now revision 2 (`planned`) with eight Android-first work packages and acceptance gates; all eight remain pending. The mission records a one-cent USD ceiling as the minimum positive bookkeeping value required by Ruflo, with zero estimated/reserved/settled spend. These are assignments in the persistent board, not 30 running model workers: `agent_execute` returned that no LLM provider is configured. Native collaboration audits were completed for CTO, orientation, Family Table and project planning; their findings are reflected above. Keep tasks pending until a provider is configured or an available worker actually completes them.

## Research and design sources

- [Game Development skill](https://www.aitmpl.com/component/skills/creative-design/game-development) — platform-aware workflow, playable core loop, logic/input/render separation, fixed-step simulation, input actions, profiling, collision and game feel.
- [LobeHub fixed-timestep game loop](https://lobehub.com/skills/dadbodgeoff-drift-game-loop) — apply fixed simulation, frame-gap clamping and interpolation to continuous action games; turn-based board games do not need an always-running loop.
- [LobeHub game design](https://lobehub.com/skills/sickn33-antigravity-awesome-skills-game-design) — use a compact living brief per game, the 30-second test, and explicit difficulty/progression choices.
- [LobeHub game theory link](https://lobehub.com/skills/openclaw-skills-game-theory) — the linked page returned HTTP 403; the indexed game-theory summary indicates player/action/payoff/information analysis for crypto protocols. Apply only that general fairness lens to multiplayer rules; do not import tokenomics or scripts into casual game code.
- [FIDE Laws of Chess](https://handbook.fide.com/chapter/e012023) — chess rule reference.
- [Pagat: Pişti](https://www.pagat.com/fishing/pishti.html) — Pişti rule reference.
- [OkeyEvi rules](https://www.okeyevi.com.tr/OyunKurallari.aspx) — Turkish Okey/101 rule reference.
- [Zipi Batak rules](https://zipi.games/tr/kurallar/batak/) — Batak rule reference.
- [Hasbro Monopoly instructions](https://www.hasbro.com/common/instruct/Monopoly.pdf) — board-game turn/property-loop reference for the original rules; AZOyun's Mahalleler must use its own name, assets and documented adaptation.

Use competitor pages for interaction research only. Do not copy proprietary code, artwork, branding or datasets; implement original visuals and independently sourced rules/data.
