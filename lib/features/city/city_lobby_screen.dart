import 'package:AZOyun/features/city/city_game.dart';
import 'package:AZOyun/game_lobby_template.dart';
import 'package:AZOyun/generic_room_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:flutter/material.dart';

class CityLobbyScreen extends StatelessWidget {
  const CityLobbyScreen({super.key});

  @override
  Widget build(final BuildContext context) => GameLobbyTemplate(
    title: '🏙️ ŞEHİR BULMACA',
    gradient: const LinearGradient(
      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    gamePath: GamePaths.cityPuzzle,
    maxPlayers: 4,
    roomScreen: (final roomId, final playerName, final isHost) =>
        GenericRoomScreen(
          roomId: roomId,
          playerName: playerName,
          isHost: isHost,
          gamePath: GamePaths.cityPuzzle,
          title: '🏙️ ŞEHİR BULMACA',
          gradient: const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          ),
          gameScreen: (final roomId, final playerName) => Scaffold(
            body: CityGame(
              roomId: roomId,
              playerName: playerName,
              onGameEvent: (final msg) {},
              onGameEnd: () {},
            ),
          ),
        ),
  );
}
