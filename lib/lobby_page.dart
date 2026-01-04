import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'room_service.dart';

class LobbyPage extends StatelessWidget {
  final String roomCode;
  final bool isHost;

  const LobbyPage({
    super.key,
    required this.roomCode,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final service = RoomService();

    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: StreamBuilder<DatabaseEvent>(
        stream: service.roomStream(roomCode),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final guestJoined = data['guestJoined'] == true;
          final status = data['status'];

          if (status == 'playing') {
            return const Center(
              child: Text(
                '🎮 OYUN BAŞLADI',
                style: TextStyle(fontSize: 30),
              ),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ODA KODU: $roomCode',
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 20),
              Text(
                guestJoined
                    ? '✅ Guest katıldı'
                    : '⏳ Guest bekleniyor',
              ),
              const SizedBox(height: 30),
              if (isHost && guestJoined)
                ElevatedButton(
                  onPressed: () {
                    service.startGame(roomCode);
                  },
                  child: const Text('OYUNU BAŞLAT'),
                ),
            ],
          );
        },
      ),
    );
  }
}
