import 'package:AZOyun/core/services/ad_manager.dart';
import 'package:AZOyun/core/theme/app_colors.dart';
import 'package:AZOyun/core/theme/app_text_styles.dart';
import 'package:AZOyun/core/widgets/game_button.dart';
import 'package:AZOyun/room_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MathLobbyScreen extends StatefulWidget {
  const MathLobbyScreen({super.key});

  @override
  State<MathLobbyScreen> createState() => _MathLobbyScreenState();
}

class _MathLobbyScreenState extends State<MathLobbyScreen> {
  final RoomService _roomService = RoomService();
  final TextEditingController _codeController = TextEditingController();
  String? playerName;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('player_name');
    if (savedName != null && savedName.isNotEmpty) {
      setState(() => playerName = savedName);
    } else {
      _showNameDialog();
    }
  }

  Future<void> _savePlayerName(final String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', name);
    setState(() => playerName = name);
  }

  Future<void> _showNameDialog() async {
    final nameCtrl = TextEditingController(text: playerName ?? '');
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('👤 İsminiz'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'İsim',
            border: OutlineInputBorder(),
          ),
          maxLength: 15,
        ),
        actions: [
          GameButton(
            text: 'KAYDET',
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              _savePlayerName(name);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom() async {
    if (playerName == null || playerName!.isEmpty) {
      await _showNameDialog();
      if (playerName == null) return;
    }

    setState(() => isLoading = true);

    try {
      final roomCode = _roomService.generateRoomCode();
      final roomId = await _roomService.createRoom(
        gamePath: GamePaths.math,
        roomData: {
          'roomCode': roomCode,
          'status': 'waiting',
          'currentQuestion': 1,
          'totalQuestions': 10,
          'createdAt': ServerValue.timestamp,
          'players': {
            'player1': {'name': playerName, 'isHost': true, 'score': 0},
          },
        },
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (final context) => MathRoomScreen(
              roomId: roomId,
              playerName: playerName!,
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    if (playerName == null || playerName!.isEmpty) {
      await _showNameDialog();
      if (playerName == null) return;
    }

    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli kod girin')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final room = await _roomService.findRoomByCode(
        gamePath: GamePaths.math,
        roomCode: code,
      );
      if (room == null) throw 'Oda bulunamadı';
      if (room['status'] != 'waiting') throw 'Oyun başlamış';

      final players = Map<String, dynamic>.from(room['players'] ?? {});
      if (players.length >= 4) throw 'Oda dolu';

      String? playerKey;
      for (int i = 1; i <= 4; i++) {
        if (!players.containsKey('player$i')) {
          playerKey = 'player$i';
          break;
        }
      }

      if (playerKey == null) throw 'Oda dolu';

      await _roomService.addPlayer(
        gamePath: GamePaths.math,
        roomId: room['id'],
        playerKey: playerKey,
        playerData: {'name': playerName, 'isHost': false, 'score': 0},
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (final context) => MathRoomScreen(
              roomId: room['id'],
              playerName: playerName!,
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        AdManager().onGameEnd();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        '🧮 HIZLI MATEMATİK',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (playerName != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  playerName!,
                                  style: AppTextStyles.h5.white.bold,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _showNameDialog,
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 40),

                        GameButton(
                          text: 'YENİ ODA OLUŞTUR',
                          icon: Icons.add_circle,
                          onPressed: isLoading ? null : _createRoom,
                          isLoading: isLoading,
                          color: Colors.purple,
                          width: 300,
                          height: 60,
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'VEYA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'ODA KODU',
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white24,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[A-Z0-9]'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GameButton(
                                text: 'ODAYA KATIL',
                                icon: Icons.login,
                                onPressed: isLoading ? null : _joinRoom,
                                color: Colors.deepPurple,
                                width: double.infinity,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
