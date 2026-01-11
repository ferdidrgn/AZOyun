import 'package:AZOyun/features/hangman/hangman_game_screen.dart';
import 'package:AZOyun/game_lobby_template.dart';
import 'package:AZOyun/generic_room_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:flutter/material.dart';

class HangmanLobbyScreen extends StatelessWidget {
  const HangmanLobbyScreen({super.key});

  @override
  Widget build(final BuildContext context) => GameLobbyTemplate(
    title: '🎯 ADAM ASMACA',
    gradient: const LinearGradient(
      colors: [Color(0xFF4CAF93), Color(0xFF731818)],
    ),
    gamePath: GamePaths.hangman,
    maxPlayers: 8,
    roomScreen: (final roomId, final playerName, final isHost) =>
        GenericRoomScreen(
          roomId: roomId,
          playerName: playerName,
          isHost: isHost,
          gamePath: GamePaths.vampire,
          title: '🎯 ADAM ASMACA',
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF93), Color(0xFF731818)],
          ),
          gameScreen: (final roomId, final playerName) => Scaffold(
            body: HangmanGameScreen(
              roomId: roomId,
              playerName: playerName,
              isHost: isHost,
              onGameEvent: (final msg) {},
              onGameEnd: () {},
            ),
          ),
        ),
  );
}
