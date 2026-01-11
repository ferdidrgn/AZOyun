import 'package:AZOyun/features/golf/golf_game.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/ad_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/banner_ad.dart';
import '../../core/widgets/game_button.dart';

class GolfGameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isPlayer1;

  const GolfGameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isPlayer1,
  });

  @override
  State<GolfGameScreen> createState() => _GolfGameScreenState();
}

class _GolfGameScreenState extends State<GolfGameScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? _roomData;
  String _gameStatus = 'waiting';
  String _gameMessage = '';
  bool _hasShownFinalDialog = false;

  @override
  void initState() {
    super.initState();
    _listenToRoom();
    AdManager().onGameEnter();
  }

  void _listenToRoom() {
    _database.child('golf_rooms/${widget.roomId}').onValue.listen((
      final event,
    ) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _roomData = data;
          _gameStatus = data['status'] ?? 'waiting';
        });

        if (_gameStatus == 'finished' && !_hasShownFinalDialog) {
          _hasShownFinalDialog = true;
          _showFinalScoresDialog();
        }
      }
    });
  }

  void _handleGameEvent(final String message) {
    setState(() {
      _gameMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _gameMessage = '';
        });
      }
    });
  }

  void _handleGameEnd() {
    if (_hasShownFinalDialog) return;
    _hasShownFinalDialog = true;
    _showFinalScoresDialog();
  }

  Future<void> _showFinalScoresDialog() async {
    if (_roomData == null) return;

    await AdManager().onGameEnd();

    final players = Map<String, dynamic>.from(_roomData!['players'] as Map);
    final scores = <Map<String, dynamic>>[];

    players.forEach((final key, final value) {
      int totalScore = 0;
      final holeScores = value['holeScores'];

      if (holeScores != null) {
        final holeScoresMap = Map<String, dynamic>.from(holeScores as Map);
        holeScoresMap.forEach((final hole, final score) {
          totalScore += (score as num).toInt();
        });
      }

      scores.add({
        'name': value['name'],
        'score': totalScore,
        'isMe': value['name'] == widget.playerName,
      });
    });

    scores.sort(
      (final a, final b) => (a['score'] as int).compareTo(b['score'] as int),
    );
    final winner = scores.first;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('🏆 Oyun Bitti!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.golfPrimary.withOpacity(0.2),
                      AppColors.golfSecondary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.golfPrimary, width: 2),
                ),
                child: Column(
                  children: [
                    const Text('👑 KAZANAN', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Text(
                      winner['name'],
                      style: AppTextStyles.h4.withColor(AppColors.golfPrimary),
                    ),
                    Text(
                      '${winner['score']} atış',
                      style: AppTextStyles.bodyLarge.bold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text('Final Skorları:', style: AppTextStyles.label),
              const SizedBox(height: 12),
              ...scores.asMap().entries.map((final entry) {
                final index = entry.key;
                final player = entry.value;
                final medal = index == 0
                    ? '🥇'
                    : index == 1
                    ? '🥈'
                    : index == 2
                    ? '🥉'
                    : '${index + 1}.';
                final isMe = player['isMe'] as bool;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.golfPrimary.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(medal, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player['name'] + (isMe ? ' (SEN)' : ''),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${player['score']} atış',
                        style: AppTextStyles.bodyLarge.bold,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          GameButton(
            text: 'ANA MENÜYE DÖN',
            onPressed: () {
              Navigator.of(context).popUntil((final route) => route.isFirst);
            },
            color: AppColors.golfPrimary,
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    if (_roomData == null) return const SizedBox();

    final players = Map<String, dynamic>.from(_roomData!['players'] as Map);
    final currentHole = _roomData!['currentHole'] ?? 1;
    final totalHoles = _roomData!['totalHoles'] ?? 9;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.golf_course, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Delik $currentHole/$totalHoles',
                  style: AppTextStyles.h5.white,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: players.entries.map((final entry) {
                final player = entry.value;
                final shots = player['shots'] ?? 0;
                final isMe = player['name'] == widget.playerName;
                final isFinished = player['isFinished'] ?? false;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isFinished
                          ? Colors.green.withOpacity(0.3)
                          : isMe
                          ? AppColors.golfPrimary.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFinished
                            ? Colors.green
                            : isMe
                            ? AppColors.golfPrimary
                            : Colors.white30,
                        width: isMe || isFinished ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          player['name'],
                          style: AppTextStyles.bodySmall.white,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFinished ? '✓ $shots' : '$shots atış',
                          style: AppTextStyles.bodyLarge.white.bold,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_gameMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _gameMessage,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    if (_gameStatus == 'waiting') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('⛳ Mini Golf'),
          backgroundColor: AppColors.golfPrimary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.golfPrimary),
              const SizedBox(height: 20),
              Text('Oyuncular bekleniyor...', style: AppTextStyles.h5),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Oyun
          GolfGame(
            roomId: widget.roomId,
            playerName: widget.playerName,
            onGameEvent: _handleGameEvent,
            onGameEnd: _handleGameEnd,
          ),

          // Skor çubuğu
          Positioned(top: 0, left: 0, right: 0, child: _buildScoreBar()),

          // Çıkış butonu
          Positioned(
            top: MediaQuery.of(context).padding.top + 120,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.red.withOpacity(0.8),
              child: const Icon(Icons.close),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (final context) => AlertDialog(
                    title: const Text('Oyundan Çık?'),
                    content: const Text('Emin misin? İlerlemen kaybolacak.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İPTAL'),
                      ),
                      GameButton(
                        text: 'ÇIK',
                        onPressed: () => Navigator.pop(context, true),
                        color: Colors.red,
                        width: 80,
                        height: 36,
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),

          // Reklam trigger reklam ekelyeceğiz

          // Alt banner reklam
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BannerAdWidget(),
          ),
        ],
      ),
    );
  }
}
