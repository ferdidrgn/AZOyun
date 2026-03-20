import 'package:AZOyun/core/services/ad_manager.dart';
import 'package:AZOyun/core/widgets/banner_ad.dart';
import 'package:AZOyun/core/widgets/game_button.dart';
import 'package:AZOyun/room_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenericRoomScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;
  final String gamePath;
  final String title;
  final Gradient gradient;
  final Widget Function(String roomId, String playerName) gameScreen;

  const GenericRoomScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
    required this.gamePath,
    required this.title,
    required this.gradient,
    required this.gameScreen,
  });

  @override
  State<GenericRoomScreen> createState() => _GenericRoomScreenState();
}

class _GenericRoomScreenState extends State<GenericRoomScreen>
    with WidgetsBindingObserver {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final RoomService _roomService = RoomService();
  late DatabaseReference roomRef;

  String roomCode = '';
  String gameStatus = 'waiting';
  Map<String, dynamic> players = {};
  bool isDisconnected = false;
  bool _gameStarted = false; // FIX: çift navigasyon önlenir

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    roomRef = _database.child('${widget.gamePath}/${widget.roomId}');
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
          gamePath: widget.gamePath,
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
        builder: (final context) =>
            widget.gameScreen(widget.roomId, widget.playerName),
      ),
    );
    // Geri dönünce tekrar başlatılabilsin
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
            final medals = ['🥇', '🥈', '🥉'];
            final medal = index < 3 ? medals[index] : '  ';

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
                gamePath: widget.gamePath,
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
        const SnackBar(content: Text('En az 2 oyuncu gerekli!')),
      );
      return;
    }

    await _roomService.setGameStatus(
      gamePath: widget.gamePath,
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
        body: Container(
          decoration: BoxDecoration(gradient: widget.gradient),
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
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
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
                                Text(
                                  'Oyuncular (${players.length})',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...players.entries.map((final entry) {
                                  final player = entry.value;
                                  // FIX: player['isHost'] kontrol edilmeli, widget.isHost değil
                                  final isPlayerHost =
                                      player['isHost'] == true;
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
                                          color: isPlayerHost
                                              ? Colors.yellow
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            player['name'] ?? 'Oyuncu',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (isPlayerHost)
                                          Container(
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
                                                color: Colors.black87,
                                              ),
                                            ),
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
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Host oyunu başlatacak...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
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
