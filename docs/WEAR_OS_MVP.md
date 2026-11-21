# AZOyun Wear OS MVP

Wear OS is a companion surface for the existing Android app. Firebase and `RoomService` remain the single source of room and game state.

## MVP

- Show the active game's name, room code, coarse status, and player count.
- Give a brief haptic cue when a player joins, a game starts, the turn counter changes, or the match finishes.
- Open AZOyun on the paired phone.
- Mark room data stale after two minutes without a fresh phone update.
- Never send a player's ID, hidden role, hand, target, or private game state. No card/tile move, vote, or second rules engine runs on the watch.
- Keep all room writes and game-action validation in the phone app and Firebase.

## Sync contract

The phone publishes a small Wearable Data Layer item at `/azoyun/room/summary`: room key, game label, public invite code, coarse status, counts, revision/event ID, event type, and publication timestamp. Turn-owner IDs and other player details are not part of the payload. The watch uses the event ID to suppress duplicate haptics and the timestamp to identify stale cached state.

## Still required before release

Build and install both apps on a paired Wear OS emulator. Verify capability discovery, fresh room updates, turn haptics, deduplication, stale state while disconnected, reconnect behavior, and opening the phone. Repeat on a physical watch. Configure the Wear OS listing and test track only after those device checks.
