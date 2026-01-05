import 'package:flutter/material.dart';
import 'room_service.dart';
import 'features/hangman/hangman_lobby_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RoomService();
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Lobby Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final code = await service.createRoom();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HangmanLobbyPage(
                      roomCode: code,
                      isHost: true,
                    ),
                  ),
                );
              },
              child: const Text('ODA OLUŞTUR (HOST)'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Oda Kodu',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final ok = await service.joinRoom(controller.text);
                if (!ok) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HangmanLobbyPage(
                      roomCode: controller.text,
                      isHost: false,
                    ),
                  ),
                );
              },
              child: const Text('ODAYA GİR (GUEST)'),
            ),
          ],
        ),
      ),
    );
  }
}
