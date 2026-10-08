---
name: flutter-mobile-design
description: >-
  Mobile-first Flutter decisions for AZ Oyun on Android, iOS, web, and large
  screens. Use when laying out touch targets, navigation, lists, motion
  performance, deep links, offline failure, or phone versus TV and desktop.
---

# Flutter mobile design

Mobile is not a small desktop. Design for one hand, a bad network, and a bright room.

## Known answers

Do not stop to ask these. The project already decided:

- Platform: Android, iOS, and web. Web includes a laptop and a TV browser used as the table.
- Framework: Flutter. Business logic is shared. Navigation chrome can differ by width, not by a second codebase.
- Navigation: phone uses a bottom bar (Hızlı, Online, Masa). Width at or above 840 uses a rail and hides the bottom bar. Games are a stack on `MaterialPageRoute`.
- State: `StatefulWidget` plus the existing services (`RoomService`, `StorageService`, feature repositories). No new global store for a screen.
- Offline: quick games run on device. Online rooms need Firebase. Failure leaves the form filled and says what to retry.
- Devices: phone, tablet, and large screens. A wide window defaults to the table role in Pişti and can switch to a hand.

## Checkpoint before UI code

1. Primary action is in the bottom thumb zone on a phone. Back and settings may sit at the top.
2. Targets are at least 48, with at least 8 between them.
3. Loading and error exist. Error names the failure and the retry.
4. Long lists use `ListView.builder` with a stable id when items can be reordered.
5. Deep link is planned: `https://azoyun.web.app/?join=<oyun>&code=<KOD>` and `azoyun://join/<oyun>/<KOD>`, parsed by `DeepLinkService` and opened by `openGameInvite`.

## Phone versus table

A phone is a hand: private cards, play button at the bottom. A tap selects a card. A button plays it. Do not use a gesture as the only way to act.

A wide window shows the public table, seats, and a QR code while the room is waiting. QR tiles stay white with dark ink so they scan.

## Performance

`const` constructors. Do not call `setState` on the whole table when one card is selected if a local flag on the hand is enough.

GPU motion is transform and opacity. Honor reduced motion.

`dispose` cancels controllers, timers, and Firebase subscriptions.

Do not log room codes, names, or tokens.

## Platform feel

Shared: rules, Firebase writes, copy, tokens.

Diverge only where the framework already does: system back on Android, edge back on iOS, both through `AZLeaveGuard` so the seat is removed. Use Material icons. Dialogs stay Material. Do not fake a second SF Symbols set.

## Failure

A deleted room pops back. A rejected move says why, for example "Sıra sende değil". A create or join that throws says the connection failed and keeps the code in the field.
