---
name: flutter-frontend-design
description: >-
  Distinctive Flutter UI for AZ Oyun. Use when building or restyling screens,
  widgets, motion, typography, color, or responsive layout in this Flutter
  game app. Applies a felt-table identity and rejects generic generated UI.
---

# Flutter frontend design

Also follow `flutter-ui-ux` for composition and motion, `flutter-design-patterns` for tokens, and `flutter-mobile-design` for touch and layout. This file is the visual identity.

Design for a game night, not a SaaS dashboard. The subject is a shared table: cards, felt, brass, and a screen that can sit in the middle of a room.

## Identity

Spend boldness in one place: the felt ring (an oval stroke and four suits). Everything else stays quiet.

Palette:

- Ink `#141C16` for text on ivory
- Felt `#1B4332` and deep `#101610` for night surfaces and the card table
- Ivory `#F3EFE6` for light canvases and card faces
- Brass `#D7B56D` for the ring, the active turn, and one accent
- Clay `#C4563A` for hearts, diamonds, and the destructive or losing state
- Mist `#8FA396` for secondary text on felt

Type:

- Fraunces for the wordmark and a screen title, used rarely
- Figtree for every other label, button, and sentence
- Do not set all-caps tracked eyebrows, and do not italicize a single word in a title

Light theme uses an ivory page. Dark theme uses felt. The playing surface of a card game stays green in both themes, because it is a table, not chrome.

## Layout

Left-align reading text. Center only the felt mark and the card table.

Breakpoints: under 720 one column and two game tiles; from 720 three tiles; from 840 a side rail instead of a bottom bar; from 1100 four tiles. Cap forms at about 480 wide so a TV does not stretch inputs.

Game rows are quiet surfaces with a short color bar taken from the game's existing gradient. Do not paint every row as a full neon or pastel gradient card.

## Motion

One entrance: the felt ring draws itself when a felt screen opens. Respect `MediaQuery.disableAnimations`. Press feedback is a transform scale, not a shadow animation. Do not fade-and-slide every section.

Animate `transform` and opacity. Do not animate width, height, or padding.

## Copy

Sentence case. A button names the action: "Eli dağıt", "Karta oyna", "Masaya geç". An empty table says what to do next. Errors say what failed and how to retry.

## Quality floor

Responsive from a phone to a TV browser. Touch targets at least 48. Text contrast holds on both ivory and felt. Keyboard focus stays visible on web. Remove one decoration before finishing.
