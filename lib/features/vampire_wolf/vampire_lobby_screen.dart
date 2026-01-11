import 'package:AZOyun/features/vampire_wolf/vampire_game.dart';
import 'package:AZOyun/game_lobby_template.dart';
import 'package:AZOyun/generic_room_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:flutter/material.dart';

class VampireLobbyScreen extends StatelessWidget {
  const VampireLobbyScreen({super.key});

  @override
  Widget build(final BuildContext context) => GameLobbyTemplate(
    title: '🧛 VAMPİR KÖYLÜ',
    gradient: const LinearGradient(
      colors: [Color(0xFF434343), Color(0xFF000000)],
    ),
    gamePath: GamePaths.vampire,
    maxPlayers: 8,
    roomScreen: (final roomId, final playerName, final isHost) =>
        GenericRoomScreen(
          roomId: roomId,
          playerName: playerName,
          isHost: isHost,
          gamePath: GamePaths.vampire,
          title: '🧛 VAMPİR KÖYLÜ',
          gradient: const LinearGradient(
            colors: [Color(0xFF434343), Color(0xFF000000)],
          ),
          gameScreen: (final roomId, final playerName) => Scaffold(
            body: VampireGame(
              roomId: roomId,
              playerName: playerName,
              onGameEvent: (final msg) {},
              onGameEnd: () {},
            ),
          ),
        ),
  );
}
