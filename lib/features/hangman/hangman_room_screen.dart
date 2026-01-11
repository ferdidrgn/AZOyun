import 'package:AZOyun/core/services/ad_manager.dart';
import 'package:AZOyun/core/theme/app_colors.dart';
import 'package:AZOyun/core/theme/app_text_styles.dart';
import 'package:AZOyun/core/widgets/banner_ad.dart';
import 'package:AZOyun/core/widgets/game_button.dart';
import 'package:AZOyun/features/hangman/hangman_game.dart';
import 'package:AZOyun/features/hangman/hangman_game_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🎯 Hangman Oda Ekranı
class HangmanRoomScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const HangmanRoomScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<HangmanRoomScreen> createState() => _HangmanRoomScreenState();
}

class _HangmanRoomScreenState extends State<HangmanRoomScreen>
    with WidgetsBindingObserver {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final RoomService _roomService = RoomService();
  late DatabaseReference roomRef;

  String roomCode = '';
  String gameStatus = 'waiting';
  Map<String, dynamic> players = {};
  String? myPlayerKey;
  bool isDisconnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    roomRef = _database.child('hangman_rooms/${widget.roomId}');
    _listenToRoom();
    _findMyPlayerKey();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _handleDisconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _handleDisconnect();
    }
  }

  Future<void> _findMyPlayerKey() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final playerData = Map<String, dynamic>.from(snapshot.value as Map);

    playerData.forEach((final key, final value) {
      if (value['name'] == widget.playerName) {
        myPlayerKey = key;
      }
    });
  }

  Future<void> _handleDisconnect() async {
    if (isDisconnected) return;
    isDisconnected = true;

    try {
      if (widget.isHost || gameStatus == 'finished') {
        await _roomService.deleteRoom(
          gamePath: GamePaths.hangman,
          roomId: widget.roomId,
        );
      } else if (myPlayerKey != null) {
        await roomRef.child('players/$myPlayerKey').remove();

        final snapshot = await roomRef.child('players').get();
        if (snapshot.exists) {
          final remainingPlayers = Map<String, dynamic>.from(
            snapshot.value as Map,
          );
          if (remainingPlayers.isNotEmpty) {
            final firstPlayerKey = remainingPlayers.keys.first;
            await roomRef.child('players/$firstPlayerKey/isHost').set(true);
          }
        }
      }
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  void _listenToRoom() {
    roomRef.onValue.listen((final event) {
      if (!mounted) return;

      if (event.snapshot.value == null) {
        _showRoomDeletedDialog();
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        roomCode = data['roomCode'] ?? '';
        gameStatus = data['status'] ?? 'waiting';
        players = Map<String, dynamic>.from(data['players'] ?? {});
      });

      if (gameStatus == 'playing' && mounted) {
        _startGame();
      }

      if (gameStatus == 'finished' && mounted) {
        _showGameResults();
      }
    });
  }

  void _showRoomDeletedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('⚠️ Oda Kapandı'),
        content: const Text('Oda sahibi odayı kapattı veya oda silindi.'),
        actions: [
          GameButton(
            text: 'TAMAM',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startGame() async {
    if (gameStatus != 'playing') return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (final context) => Scaffold(
          backgroundColor: AppColors.primary,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.hangmanGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            '🎯 ADAM ASMACA',
                            style: AppTextStyles.h4.white.bold,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Oyun
                  Expanded(
                    child: HangmanGameScreen(
                      roomId: widget.roomId,
                      playerName: widget.playerName,
                      isPlayer1: myPlayerKey == players.keys.first,
                    ),
                  ),

                  // Skorlar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: players.entries.map((final entry) {
                        final player = entry.value;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              player['name'] ?? 'Oyuncu',
                              style: AppTextStyles.bodyMedium.white.bold,
                            ),
                            Text(
                              '${player['score'] ?? 0} puan',
                              style: AppTextStyles.bodySmall.white,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGameResults() {
    final scores = <String, int>{};

    players.forEach((final key, final player) {
      scores[player['name']] = player['score'] ?? 0;
    });

    final sortedScores = scores.entries.toList()
      ..sort((final a, final b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('🏆 Oyun Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sortedScores.asMap().entries.map((final entry) {
            final index = entry.key;
            final score = entry.value;
            final medal = index == 0 ? '🥇' : '🥈';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(medal, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      score.key,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: index == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${score.value} puan',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          GameButton(
            text: 'KAPAT',
            onPressed: () async {
              await _roomService.deleteRoom(
                gamePath: GamePaths.hangman,
                roomId: widget.roomId,
              );

              await AdManager().onGameEnd();

              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startGameAsHost() async {
    if (players.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('2 oyuncu gerekli!')));
      return;
    }

    await _roomService.setGameStatus(
      gamePath: GamePaths.hangman,
      roomId: widget.roomId,
      status: 'playing',
    );
  }

  @override
  Widget build(final BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleDisconnect();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.hangmanGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          await _handleDisconnect();
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          '🎯 HANGMAN ODASI',
                          style: TextStyle(
                            fontSize: 24,
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
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'ODA KODU',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      roomCode,
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 8,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: roomCode),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Kod kopyalandı!'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Oyuncular (${players.length}/2)',
                                      style: AppTextStyles.h5.white.bold,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...players.entries.map((final entry) {
                                  final player = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          player['isHost'] == true
                                              ? Icons.star
                                              : Icons.person,
                                          color: Colors.yellow,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          player['name'] ?? 'Oyuncu',
                                          style: AppTextStyles.bodyLarge.white,
                                        ),
                                        if (player['isHost'] == true)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.yellow,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'HOST',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          if (widget.isHost && gameStatus == 'waiting')
                            GameButton(
                              text: 'OYUNU BAŞLAT',
                              icon: Icons.play_arrow,
                              onPressed: _startGameAsHost,
                              color: Colors.purple,
                              width: 300,
                              height: 60,
                            ),

                          if (!widget.isHost && gameStatus == 'waiting')
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Host oyunu başlatacak...',
                                    style: AppTextStyles.bodyMedium.white,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const AdaptiveBannerAdWidget(padding: EdgeInsets.zero),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
