---
name: flutter-design-patterns
description: >-
  Maps Refactoring UI and Material 3 patterns onto AZ Oyun Flutter theme
  tokens. Use when styling widgets, choosing colors, type, spacing, shadows,
  cards, or inputs, or when tempted to hardcode Colors.* or a TextStyle.
---

# Flutter design patterns

Check the project theme before any new style. This app already has the tokens. Do not add a parallel `AppColors` or `AppTextStyles`.

## Priority

1. `FeltColors`, `FeltPalette`, `feltDisplay`, `feltUi` for the shell, splash, onboarding, and the card table
2. `AZColors`, `AZSpacing`, `AZRadius`, `AZShadow`, `AZTheme` for game screens that already use them
3. `Theme.of(context).colorScheme` and `textTheme` for Material surfaces such as settings
4. A raw hex only inside those token files

`MaterialApp` already uses Material 3 via `AZTheme`. Seed colors follow the user's theme preference. Do not replace that with a single blue seed.

## Color roles

Use `colorScheme` roles on Material screens:

- `primary` / `onPrimary` for a filled action when the screen is not the felt table
- `surface` / `onSurface` for cards and body text
- `outline` for borders
- `error` for a failed action

On the felt table, brass is the active turn, clay is the play button and red suits, ivory is card faces and text on felt. Those are `FeltColors`, not `Colors.white` scattered through the tree.

## Type

Felt screens: Fraunces only for the wordmark and one title. Figtree for everything else, through `feltUi`.

Other screens: `Theme.of(context).textTheme` (Figtree is already the app text theme). Do not set `TextStyle(fontSize: 16)` with no theme color.

Approximate scale when a felt size is needed: 36–40 title, 28 page title, 16–18 section, 14–15 body, 12–13 secondary. Stay on that ladder.

## Spacing and shape

`AZSpacing`: xs 4, sm 8, md 16, lg 24, xl 32, xxl 48. All are on a 4dp grid.

`AZRadius`: sm 8, md 12, lg 18, xl 24. Cards on the felt shell use 16–18. Pills that are seats use a full stadium radius.

Symmetric padding unless the layout is a row with a 6dp accent bar. A one-off `EdgeInsets.only(top: 20, left: 8)` is a mistake.

## Surfaces

Flat card: surface color, 1px line from `FeltPalette.line` or `outline` at low alpha, radius from `AZRadius`. Elevation is for the physical table oval, not for every list row.

Shadows: `AZShadow.soft`, `medium`, or `deep`. Do not stack a colored glow on every tile.

Inputs: the existing `inputDecorationTheme` in `AZTheme`. Room codes use `AZCodeField`.

## Do not

- `Colors.blue`, `Colors.white` as a brand color, or `withOpacity` on a color that already has a token
- A second spacing scale (`AppSpacing`) beside `AZSpacing`
- Asymmetric spacing that is not a hairline accent
- All-caps tracked labels and a middle dot between every meta string
