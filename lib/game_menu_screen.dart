import 'package:a_z_oyun/hangman_lobby_screen.dart';
import 'package:flutter/material.dart';

class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade900, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Başlık
              const Text(
                '🎮 MULTIPLAYER GAMES',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Oyun Butonları
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildGameCard(
                      context,
                      title: 'HANGMAN',
                      subtitle: 'Adam Asmaca - 2 Oyuncu',
                      icon: '🎯',
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HangmanLobbyScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildGameCard(
                      context,
                      title: 'GOLF',
                      subtitle: 'Mini Golf - 4 Oyuncu',
                      icon: '⛳',
                      color: Colors.green,
                      onTap: () {
                        // Yakında eklenecek
                        _showComingSoon(context, 'Golf');
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildGameCard(
                      context,
                      title: 'FREE KICK',
                      subtitle: 'Serbest Vuruş - 2 Oyuncu',
                      icon: '⚽',
                      color: Colors.orange,
                      onTap: () {
                        _showComingSoon(context, 'Free Kick');
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildGameCard(
                      context,
                      title: 'RACING',
                      subtitle: 'Yarış - 4 Oyuncu',
                      icon: '🏎️',
                      color: Colors.blue,
                      onTap: () {
                        _showComingSoon(context, 'Racing');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String gameName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$gameName 🎮'),
        content: const Text('Bu oyun yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }
}
