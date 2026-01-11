import 'package:AZOyun/features/word/word_game.dart';
import 'package:AZOyun/game_lobby_template.dart';
import 'package:AZOyun/generic_room_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:flutter/material.dart';

class WordLobbyScreen extends StatelessWidget {
  const WordLobbyScreen({super.key});

  @override
  Widget build(final BuildContext context) => GameLobbyTemplate(
    title: '🔤 KELİME BULMACA',
    gradient: const LinearGradient(
      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    gamePath: GamePaths.wordPuzzle,
    maxPlayers: 4,
    roomScreen: (final roomId, final playerName, final isHost) =>
        GenericRoomScreen(
          roomId: roomId,
          playerName: playerName,
          isHost: isHost,
          gamePath: GamePaths.wordPuzzle,
          title: '🔤 KELİME BULMACA',
          gradient: const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
          gameScreen: (final roomId, final playerName) => Scaffold(
            body: WordGame(
              roomId: roomId,
              playerName: playerName,
              onGameEvent: (final msg) {},
              onGameEnd: () {},
            ),
          ),
        ),
  );
}
