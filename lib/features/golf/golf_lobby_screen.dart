import 'package:AZOyun/core/services/ad_manager.dart';
import 'package:AZOyun/core/services/secure_local_storage.dart';
import 'package:AZOyun/core/theme/app_colors.dart';
import 'package:AZOyun/core/theme/app_text_styles.dart';
import 'package:AZOyun/core/widgets/game_button.dart';
import 'package:AZOyun/features/golf/golf_room_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ⛳ Golf Lobi Ekranı - İsim Kontrolü Eklendi
class GolfLobbyScreen extends StatefulWidget {
  const GolfLobbyScreen({super.key});

  @override
  State<GolfLobbyScreen> createState() => _GolfLobbyScreenState();
}

class _GolfLobbyScreenState extends State<GolfLobbyScreen> {
  final RoomService _roomService = RoomService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? playerName;
  bool isLoading = false;

  static const _secureStore = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  // OKUMA: Artık çok daha kolay
  Future<void> _loadPlayerName() async {
    final savedName = await _secureStore.read(key: 'player_name');
    if (savedName != null) {
      setState(() {
        playerName = savedName;
        _nameController.text = savedName;
      });
    } else {
      _showNameDialog();
    }
  }

  // YAZMA: Tek satır
  Future<void> _savePlayerName(final String name) async {
    await _secureStore.write(key: 'player_name', value: name);
    setState(() => playerName = name);
  }

  Future<void> _showNameDialog() async {
    final nameCtrl = TextEditingController(text: playerName ?? '');

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('👤 İsminiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lütfen oyunda görünecek isminizi girin:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'İsim',
                border: OutlineInputBorder(),
                hintText: 'Örn: Ali',
              ),
              maxLength: 15,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          GameButton(
            text: 'KAYDET',
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İsim boş olamaz!')),
                );
                return;
              }
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
      if (playerName == null || playerName!.isEmpty) return;
    }

    setState(() => isLoading = true);
    await SecureLocalStorage().incrementGameEnterCount();
    try {
      final roomCode = _roomService.generateRoomCode();
      final roomId = await _roomService.createRoom(
        gamePath: GamePaths.golf,
        roomData: {
          'roomCode': roomCode,
          'status': 'waiting',
          'currentHole': 1,
          'maxPlayers': 4,
          'createdAt': ServerValue.timestamp,
          'players': {
            'player1': {
              'name': playerName,
              'isHost': true,
              'isFinished': false,
              'shots': 0,
              'holeScores': {},
            },
          },
        },
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (final context) => GolfRoomScreen(
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
      if (playerName == null || playerName!.isEmpty) return;
    }

    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir kod girin (6 karakter)')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final room = await _roomService.findRoomByCode(
        gamePath: GamePaths.golf,
        roomCode: code,
      );

      if (room == null) {
        throw 'Oda bulunamadı';
      }

      if (room['status'] != 'waiting') {
        throw 'Oyun başlamış';
      }

      final players = Map<String, dynamic>.from(room['players'] ?? {});
      final maxPlayers = room['maxPlayers'] ?? 4;

      if (players.length >= maxPlayers) {
        throw 'Oda dolu';
      }

      // Boş oyuncu slotu bul
      String? playerKey;
      for (int i = 1; i <= maxPlayers; i++) {
        if (!players.containsKey('player$i')) {
          playerKey = 'player$i';
          break;
        }
      }

      if (playerKey == null) throw 'Oda dolu';

      await _roomService.addPlayer(
        gamePath: GamePaths.golf,
        roomId: room['id'],
        playerKey: playerKey,
        playerData: {
          'name': playerName,
          'isHost': false,
          'isFinished': false,
          'shots': 0,
          'holeScores': {},
        },
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (final context) => GolfRoomScreen(
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
        decoration: const BoxDecoration(gradient: AppColors.golfGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        AdManager().onGameEnd(); // Reklam göster
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        '⛳ MİNİ GOLF',
                        style: TextStyle(
                          fontSize: 28,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İsim kartı
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

                        // Oda oluştur
                        GameButton(
                          text: 'YENİ ODA OLUŞTUR',
                          icon: Icons.add_circle,
                          onPressed: isLoading ? null : _createRoom,
                          isLoading: isLoading,
                          color: Colors.green,
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

                        // Koda katıl
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
                                  hintText: '6 haneli kod',
                                  hintStyle: TextStyle(color: Colors.white54),
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
                                color: Colors.orange,
                                width: double.infinity,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Bilgi
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '9 delik golf parkuru\n2-4 oyuncu\nEn az vuruşla bitiren kazanır!',
                                style: AppTextStyles.bodyMedium.white,
                                textAlign: TextAlign.center,
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

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
