import 'package:AZOyun/core/services/ad_manager.dart';
import 'package:AZOyun/core/theme/app_colors.dart';
import 'package:AZOyun/core/theme/app_text_styles.dart';
import 'package:AZOyun/core/widgets/banner_ad.dart';
import 'package:AZOyun/core/widgets/game_button.dart';
import 'package:AZOyun/features/soccer/soccer_game_screen.dart';
import 'package:AZOyun/room_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SoccerRoomScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const SoccerRoomScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<SoccerRoomScreen> createState() => _SoccerRoomScreenState();
}

class _SoccerRoomScreenState extends State<SoccerRoomScreen>
    with WidgetsBindingObserver {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final RoomService _roomService = RoomService();
  late DatabaseReference roomRef;

  String roomCode = '';
  String gameStatus = 'waiting';
  Map<String, dynamic> players = {};
  bool isDisconnected = false;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    roomRef = _database.child('soccer_rooms/${widget.roomId}');
    _listenToRoom();
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

  Future<void> _handleDisconnect() async {
    if (isDisconnected) return;
    isDisconnected = true;

    try {
      if (widget.isHost || gameStatus == 'finished') {
        await _roomService.deleteRoom(
          gamePath: GamePaths.soccer,
          roomId: widget.roomId,
        );
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

      if (gameStatus == 'playing' && mounted && !_gameStarted) {
        _gameStarted = true;
        _startGame();
      }

      if (gameStatus == 'finished' && mounted) {
        _showResults();
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
        content: const Text('Oda sahibi odayı kapattı.'),
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (final context) => SoccerGameScreen(
          roomId: widget.roomId,
          playerName: widget.playerName,
        ),
      ),
    );
    _gameStarted = false;
  }

  void _showResults() {
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
                    child: Text(score.key, style: const TextStyle(fontSize: 18)),
                  ),
                  Text('${score.value} gol', style: const TextStyle(fontSize: 16)),
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
                gamePath: GamePaths.soccer,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2 oyuncu gerekli!')),
      );
      return;
    }

    await _roomService.setGameStatus(
      gamePath: GamePaths.soccer,
      roomId: widget.roomId,
      status: 'playing',
    );
  }

  @override
  Widget build(final BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (final didPop) async {
        if (didPop) return;
        await _handleDisconnect();
        if (mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.freeKickGradient),
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
                          '⚽ SERBEST VURUŞ',
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'ODA KODU',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: roomCode),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
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
                                Text(
                                  'Oyuncular (${players.length}/2)',
                                  style: AppTextStyles.h5.white.bold,
                                ),
                                const SizedBox(height: 16),
                                ...players.entries.map((final entry) {
                                  final player = entry.value;
                                  final isPlayerHost = player['isHost'] == true;
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
                                          isPlayerHost
                                              ? Icons.star
                                              : Icons.person,
                                          color: Colors.yellow,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          player['name'] ?? 'Oyuncu',
                                          style: AppTextStyles.bodyLarge.white,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (widget.isHost && gameStatus == 'waiting')
                            GameButton(
                              text: 'OYUNU BAŞLAT',
                              icon: Icons.play_arrow,
                              onPressed: _startGameAsHost,
                              color: Colors.green,
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
