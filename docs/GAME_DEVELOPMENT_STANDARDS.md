# AZOyun Game Development Standards

Web and Flutter adaptation of the [Game Development skill](https://www.aitmpl.com/component/skills/creative-design/game-development) and its linked platform guidance. These are project rules, not a framework migration proposal.

## Existing project boundaries

- Android gameplay stays in Flutter/Dart. Use Flutter widgets for turn-based boards and menus, `CustomPainter`/`Ticker` for compact 2D action scenes, and the existing packaged Three.js runtime only for scenes that need 3D.
- Browser games stay in the HTML/CSS/JavaScript salon. Use DOM for menus and turn-based boards, Canvas for responsive 2D action, and the existing Three.js runtime for 3D.
- Keep game rules independent from view code. Share JSON rule vectors and versioned data contracts where Dart and JavaScript implement the same game; do not claim parity based on the title alone.
- Do not move a game to a new engine to work around a local bug. First diagnose the current route, renderer, input, and asset-loading path.

## Build the playable loop first

For every game, make its core 30-second loop playable before adding progression or cosmetic polish. Document: player goal, legal actions, turn/state transitions, win/loss/draw, replay, and the first visible response to an action. Use temporary shapes if art is not ready.

Separate three layers:

1. **Rules/state:** deterministic inputs and state transitions, independent from a frame or widget tree.
2. **Input adapter:** named actions such as `select_tile`, `move`, `confirm`, `aim`, `shoot`; map touch, mouse, keyboard, controller, and network messages to those actions.
3. **Presentation:** board/sprites, animation, sound, HUD, accessibility labels and orientation.

Write a small living game brief for each mode: one-line pitch, 30-second loop, mechanics, skill/progression, visual/audio direction, target devices and finish/replay states. Prototype the loop before progression or polish. Let players choose difficulty when a single adaptive curve would be unfair; tune from actual play observations rather than retention tricks.

## Frame loop and performance

- Use a fixed simulation step for physics and time-sensitive collisions; render independently and clamp long frame gaps. Prefer Flutter's `Ticker`/engine timing and the browser's `requestAnimationFrame`; do not run competing loops.
- Target 60 FPS (16.7 ms per frame) on supported devices, with headroom for slower Android hardware. Profile first; optimize the measured bottleneck.
- Avoid per-frame allocations and full-scene rebuilds in hot paths. Reuse buffers/objects, update only changed UI, and pool frequently spawned effects when measurement justifies it.
- Use simple collision shapes beneath detailed art. Use swept checks/raycast for fast moving objects that could pass through thin obstacles.
- Every accepted action should receive immediate visual feedback; haptics/audio are optional and must respect platform settings.

## Web requirements

- Handle pointer and touch input without requiring hover. Keep targets usable on small screens and avoid browser gestures stealing gameplay gestures where safe.
- Fit the viewport with safe-area-aware layout; support resize, orientation change, visibility pause/resume, and reduced-motion preferences.
- Load local assets with explicit failure states. For WebGL/Three.js failure, show a useful recovery/fallback screen rather than a blank canvas; do not escape to an unrelated external page.
- Unlock audio only after a user gesture. Keep canvas rendering separate from DOM controls and accessible status text.
- On resume from a hidden tab, reset/clamp elapsed time so physics does not jump forward.

## Flutter / Android requirements

- All game actions must remain in the Android app; do not open a web page as a substitute for an unimplemented native game. Embedded local Three.js is acceptable only when its assets load offline from the packaged app and it has an in-app failure state.
- Use responsive constraints, safe areas, system text scaling, minimum practical touch targets, and keyboard/controller support where the game is shown on TV/tablet.
- Choose orientation per game interaction and restore the previous/system orientation when leaving. Avoid nested routes that reset orientation while a landscape game is still active.
- Pause or safely suspend timers/simulation when backgrounded; resume without granting hidden-time progress. Respect battery/thermal limits and avoid unnecessary continuous animation on static boards.
- For tactile boards, support tap selection as well as drag where appropriate; never make a gesture the only way to perform a critical action.

## Online and data-driven games

- The server owns room state, legal move validation, turn order, score and match result. Clients submit named actions with room revision/turn identity and render the server's accepted state.
- Keep private hands/roles seat-scoped. Reconnect must restore the same seat without exposing another player's hidden state. Provide loading, offline, retry, room-full, stale-action and finished-game states.
- Dynamic football content must have a versioned schema, source/provenance, update timestamp, validation and cached/offline fallback. Never make an API key or paid dependency necessary for ordinary play when a free static catalog can serve the game.

For competitive/cooperative design, model only the useful parts of game theory: players and goals, available actions, sequential versus simultaneous decisions, visible versus private information, payoffs/scoring, and whether matches repeat. Use this to catch dominant strategies, collusion/kingmaking, runaway leader effects and rules that reward stalling or disconnecting. Prefer transparent scoring, fair rematch/exit rules, and counterplay. Do not import crypto/tokenomics scripts, real-money incentives, or mathematically elaborate equilibrium machinery into casual games without a concrete gameplay need.

## Definition of done

- The game can be opened from its advertised Android/web entry and stays in the expected app/browser surface.
- A player can complete the core loop, understand the result and replay.
- Orientation, touch/keyboard input, viewport changes and background/resume behavior match the game's matrix entry.
- For paired implementations, shared rule vectors cover representative legal, illegal, terminal and edge transitions before parity is claimed.
- For 3D, verify asset initialization, resize, touch controls, renderer failure and a low-end-device frame profile. Compilation alone is not proof of playability.

## Upstream references

- [Skill overview and core principles](https://www.aitmpl.com/component/skills/creative-design/game-development)
- [Web games reference](https://github.com/davila7/claude-code-templates/blob/main/cli-tool/components/skills/creative-design/game-development/references/web-games.md)
- [Mobile games reference](https://github.com/davila7/claude-code-templates/blob/main/cli-tool/components/skills/creative-design/game-development/references/mobile-games.md)
- [2D games reference](https://github.com/davila7/claude-code-templates/blob/main/cli-tool/components/skills/creative-design/game-development/references/2d-games.md)
- [3D games reference](https://github.com/davila7/claude-code-templates/blob/main/cli-tool/components/skills/creative-design/game-development/references/3d-games.md)
- [Multiplayer reference](https://github.com/davila7/claude-code-templates/blob/main/cli-tool/components/skills/creative-design/game-development/references/multiplayer.md)
- [LobeHub fixed-timestep game loop](https://lobehub.com/skills/dadbodgeoff-drift-game-loop) — accumulator, clamped frame gaps, fixed simulation/render separation, interpolation and time-step telemetry; apply only where a game has continuous simulation.
- [LobeHub game design](https://lobehub.com/skills/sickn33-antigravity-awesome-skills-game-design) — small GDD, 30-second loop, player motivations, difficulty and progression review.
- [LobeHub game theory link](https://lobehub.com/skills/openclaw-skills-game-theory) — the page returned HTTP 403 during review. The indexed `game-theory` skill summary describes player/strategy/payoff/information framing, but targets crypto protocols; use only the general fairness lens for multiplayer rules, and keep protocol scripts/token incentives out of AZOyun.

