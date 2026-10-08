---
name: flutter-ui-ux
description: >-
  Builds responsive, animated Flutter UI for AZ Oyun. Use when adding screens,
  widgets, motion, navigation transitions, accessibility, or when the user
  asks for Flutter UI/UX, micro-interactions, or 60fps layout.
---

# Flutter UI/UX

Mobile-first, animation with a purpose, accessible. Work in this order. Finish a phase before the next.

## 1. Requirements

Read the screen that already exists, `lib/core/theme/az_theme.dart`, `lib/core/theme/felt.dart`, and `lib/core/widgets/az_widgets.dart`.

Note what is shared (phone, tablet, web, TV browser) and what is a playing surface. A card table stays felt green in both themes. Chrome follows `ThemeData` brightness.

Output, in the work notes only: which widgets are new, which existing ones are reused, and which animation is the single entrance.

## 2. Widget architecture

Compose small widgets. A screen owns state. A presentational widget is a `StatelessWidget` with a `const` constructor.

Use `StatefulWidget` when the screen listens, animates, or holds a form. Use `ValueListenableBuilder` or `AnimatedBuilder` when one value changes and the rest of the tree should stay `const`.

Do not add a new state library. Rooms already use `RoomService` and feature repositories.

## 3. Core UI

Reuse before creating: `AZButton`, `AZGameCard`, `AZRoomCode`, `FeltBackdrop`, `FeltMark`, `PlayingCardView`.

Layout:

- `LayoutBuilder` when the widget's own width decides the layout
- `MediaQuery.sizeOf` for phone versus rail (840)
- `Expanded` / `Flexible` instead of fixed heights in a column that must fit
- `AspectRatio` for the felt oval and cards
- `ListView.builder` when the item count is not tiny and fixed

Spacing is `AZSpacing` (4, 8, 16, 24, 32, 48). Radius is `AZRadius`. Do not invent 17 or 20.

Color comes from `Theme.of(context).colorScheme`, `AZColors`, or `FeltColors`. A new hex value is a last resort and belongs in one of those files.

Typography comes from `feltDisplay` / `feltUi` on felt screens, otherwise `Theme.of(context).textTheme`.

## 4. Motion

One entrance per screen. The felt ring is that entrance on felt screens. Do not fade-slide every section.

| Job | Widget | Duration |
| --- | --- | --- |
| Show or hide | `AnimatedOpacity` | 200–300ms |
| Press | `AnimatedScale` on transform | 110–160ms |
| Selection lift | `AnimatedSlide` | 140ms |
| Loading mark | existing `FeltMark` controller | about 1100ms, once |

`AnimatedBuilder` passes a stable `child` so the heavy widget is not rebuilt. Animate transform and opacity. Do not animate width, height, padding, or margin.

`MediaQuery.disableAnimationsOf(context)` uses `Duration.zero` and jumps the controller to the end.

Hero is for a shared element that actually continues on the next route, not for every card.

## 5. Accessibility and performance

`Semantics` on icon-only buttons and on playing cards (`cardLabel`).

Touch targets are at least 48, with at least 8 between them. Primary action sits in the bottom thumb zone on a phone.

`const` widgets. `RepaintBoundary` only around a paint that would otherwise repaint a large static subtree. Cancel `AnimationController` and room subscriptions in `dispose`.

Contrast must hold for ivory text on felt and ink text on ivory. Do not put mist-colored text on a white QR tile.
