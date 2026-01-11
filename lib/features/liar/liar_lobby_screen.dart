import 'package:AZOyun/features/liar/liar_game.dart';
import 'package:AZOyun/game_lobby_template.dart';
import 'package:AZOyun/generic_room_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:flutter/material.dart';

class LiarLobbyScreen extends StatelessWidget {
  const LiarLobbyScreen({super.key});

  @override
  Widget build(final BuildContext context) => GameLobbyTemplate(
    title: '☕ YALANCILAR KAHVESİ',
    gradient: const LinearGradient(
      colors: [Color(0xFFd66d75), Color(0xFFe29587)],
    ),
    gamePath: GamePaths.liarCafe,
    maxPlayers: 6,
    roomScreen: (final roomId, final playerName, final isHost) =>
        GenericRoomScreen(
          roomId: roomId,
          playerName: playerName,
          isHost: isHost,
          gamePath: GamePaths.liarCafe,
          title: '☕ YALANCILAR KAHVESİ',
          gradient: const LinearGradient(
            colors: [Color(0xFFd66d75), Color(0xFFe29587)],
          ),
          gameScreen: (final roomId, final playerName) => Scaffold(
            body: LiarGame(
              roomId: roomId,
              playerName: playerName,
              onGameEvent: (final msg) {},
              onGameEnd: () {},
            ),
          ),
        ),
  );
}
