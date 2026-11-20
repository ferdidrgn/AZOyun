import 'package:flutter/material.dart';

import '../batak/batak_screen.dart';

import '../deck/deck_lobby_screen.dart';
import '../mahalleler/mahalle_screen.dart';
import '../okey/okey_screens.dart';
import 'family_screen.dart';

class FirebaseTableMenu extends StatelessWidget {
  const FirebaseTableMenu({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Aile Masası')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                      'Ortak ekran için oyun seç. Oyuncular QR kodunu telefonlarından okutabilir.'),
                  const SizedBox(height: 18),
                  for (final (index, (title, screen)) in const [
                    ('101 Okey', OkeyLobbyScreen(mode: '101', table: true)),
                    ('Klasik Okey', OkeyLobbyScreen(table: true)),
                    ('Pişti', DeckLobbyScreen(table: true)),
                    ('Batak', BatakLobbyScreen(table: true)),
                    ('Mahalleler', MahalleLobbyScreen(table: true)),
                    ('Kelime Tahtası', FamilyScreen(host: true, initialGame: 'words')),
                    ('Gizli Rol', FamilyScreen(host: true, initialGame: 'roles')),
                  ].indexed) ...[
                    FilledButton.icon(
                      autofocus: index == 0,
                      onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(builder: (_) => screen)),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(title),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
