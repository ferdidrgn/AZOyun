import 'package:a_z_oyun/core/widgets/ad_trigger_widget.dart';
import 'package:a_z_oyun/core/widgets/banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_button.dart';

class GolfGameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;

  const GolfGameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
  });

  @override
  State<GolfGameScreen> createState() => _GolfGameScreenState();
}

class _GolfGameScreenState extends State<GolfGameScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? _roomData;
  String _gameStatus = 'waiting';
  String? _myPlayerKey;
  bool _isMyTurn = false;

  // Golf ball physics
  Offset _ballPosition = const Offset(100, 400);
  Offset _ballVelocity = Offset.zero;
  Offset _holePosition = const Offset(300, 100);
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;

  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();

    _listenToRoom();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePhysics);
  }

  void _listenToRoom() {
    _database.child('golf_rooms/${widget.roomId}').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _roomData = data;
          _gameStatus = data['status'] ?? 'waiting';

          // Benim player key'imi bul
          if (_myPlayerKey == null) {
            final players = Map<String, dynamic>.from(data['players'] as Map);
            players.forEach((key, value) {
              if (value['name'] == widget.playerName) {
                _myPlayerKey = key;
              }
            });
          }

          // Sıram mı kontrol et
          if (data['currentPlayer'] != null) {
            _isMyTurn = data['currentPlayer'] == _myPlayerKey;
          }

          // Oyun bitti mi kontrol et
          if (data['status'] == 'finished') {
            // Eğer dialog açık değilse final skorları göster
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {}
            });
          }
        });
      }
    });
  }

  void _updatePhysics() {
    if (_ballVelocity.distance < 0.5) {
      _animationController?.stop();
      _ballVelocity = Offset.zero;
      _checkIfInHole();
      return;
    }

    setState(() {
      // Friction
      _ballVelocity *= 0.98;

      // Update position
      _ballPosition += _ballVelocity;

      // Bounce off walls
      if (_ballPosition.dx < 20 ||
          _ballPosition.dx > MediaQuery.of(context).size.width - 20) {
        _ballVelocity = Offset(-_ballVelocity.dx * 0.7, _ballVelocity.dy);
        _ballPosition = Offset(
          _ballPosition.dx.clamp(20, MediaQuery.of(context).size.width - 20),
          _ballPosition.dy,
        );
      }

      if (_ballPosition.dy < 100 || _ballPosition.dy > 500) {
        _ballVelocity = Offset(_ballVelocity.dx, -_ballVelocity.dy * 0.7);
        _ballPosition = Offset(
          _ballPosition.dx,
          _ballPosition.dy.clamp(100, 500),
        );
      }
    });
  }

  void _checkIfInHole() {
    final distance = (_ballPosition - _holePosition).distance;
    if (distance < 25) {
      _showHoleCompletedDialog();
    }
  }

  void _onDragStart(Offset position) {
    if (!_isMyTurn || _gameStatus != 'playing') return;
    setState(() {
      _isDragging = true;
      _dragStart = position;
    });
  }

  void _onDragUpdate(Offset position) {
    if (!_isDragging) return;
    setState(() {});
  }

  void _onDragEnd(Offset position) {
    if (!_isDragging || !_isMyTurn) return;

    final delta = _dragStart - position;
    final power = (delta.distance / 100).clamp(0.0, 5.0);
    final direction = Offset(
      delta.dx / delta.distance,
      delta.dy / delta.distance,
    );

    setState(() {
      _isDragging = false;
      _ballVelocity = direction * power * 3;
    });

    _animationController?.repeat();
    _incrementShots();
  }

  Future<void> _incrementShots() async {
    if (_myPlayerKey == null) return;

    final currentShots = _roomData?['players'][_myPlayerKey]['shots'] ?? 0;
    await _database
        .child('golf_rooms/${widget.roomId}/players/$_myPlayerKey/shots')
        .set(currentShots + 1);

    // Next player
    _nextPlayer();
  }

  Future<void> _nextPlayer() async {
    final players = Map<String, dynamic>.from(_roomData!['players'] as Map);
    final playerKeys = players.keys.toList();
    final currentIndex = playerKeys.indexOf(_roomData!['currentPlayer']);
    final nextIndex = (currentIndex + 1) % playerKeys.length;

    await _database
        .child('golf_rooms/${widget.roomId}/currentPlayer')
        .set(playerKeys[nextIndex]);
  }

  void _showHoleCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Deliğe Girdi!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text('Tebrikler ${widget.playerName}!', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              'Atış sayısı: ${_roomData?['players'][_myPlayerKey]['shots'] ?? 0}',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
        actions: [
          GameButton(
            text: 'DEVAM',
            onPressed: () {
              Navigator.pop(context);
              _nextHole();
            },
            color: AppColors.golfPrimary,
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }

  Future<void> _nextHole() async {
    final currentHole = _roomData?['currentHole'] ?? 1;
    final totalHoles = _roomData?['totalHoles'] ?? 9;

    if (currentHole >= totalHoles) {
      _endGame();
    } else {
      await _database
          .child('golf_rooms/${widget.roomId}/currentHole')
          .set(currentHole + 1);

      // Reset ball position
      setState(() {
        _ballPosition = const Offset(100, 400);
        _ballVelocity = Offset.zero;
        _holePosition = Offset(
          Random().nextDouble() * 300 + 50,
          Random().nextDouble() * 200 + 100,
        );
      });
    }
  }

  void _endGame() {
    // TODO: Show final scores
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _toggleReady() async {
    if (_myPlayerKey == null) return;

    final isReady = _roomData?['players'][_myPlayerKey]['isReady'] ?? false;
    await _database
        .child('golf_rooms/${widget.roomId}/players/$_myPlayerKey/isReady')
        .set(!isReady);

    // Check if all players are ready
    final players = Map<String, dynamic>.from(_roomData!['players'] as Map);
    final allReady = players.values.every(
      (player) => player['isReady'] == true,
    );

    if (allReady && players.length >= 2) {
      await _database.child('golf_rooms/${widget.roomId}').update({
        'status': 'playing',
        'currentPlayer': 'player1',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roomData == null || _gameStatus == 'waiting') {
      return _buildWaitingRoom();
    }

    return _buildGameScreen();
  }

  Widget _buildWaitingRoom() {
    final players = _roomData != null
        ? Map<String, dynamic>.from(_roomData!['players'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('⛳ Mini Golf - Lobi'),
        backgroundColor: AppColors.golfPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text('Oyuncular (${players.length}/4)', style: AppTextStyles.h4),
          const SizedBox(height: 20),

          /// ✅ REKLAM TETİKLEYİCİ (LOGIC BURADA)
          AdTriggerWidget(roomId: widget.roomId),

          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final playerKey = players.keys.elementAt(index);
                final player = players[playerKey];
                final isReady = player['isReady'] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.golfPrimary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      player['name'],
                      style: AppTextStyles.playerName,
                    ),
                    trailing: isReady
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          )
                        : const Icon(Icons.pending, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

          /// ✅ BANNER
          const AdaptiveBannerAdWidget(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: GameButton(
              text: _roomData?['players'][_myPlayerKey]['isReady'] == true
                  ? 'HAZIR DEĞİLİM'
                  : 'HAZIRIM',
              onPressed: _toggleReady,
              color: _roomData?['players'][_myPlayerKey]['isReady'] == true
                  ? AppColors.error
                  : AppColors.golfPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delik ${_roomData?['currentHole']}/${_roomData?['totalHoles']}',
        ),
        backgroundColor: AppColors.golfPrimary,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onPanStart: (details) => _onDragStart(details.localPosition),
        onPanUpdate: (details) => _onDragUpdate(details.localPosition),
        onPanEnd: (details) => _onDragEnd(details.localPosition),
        child: Stack(
          children: [
            // Golf course background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.golfPrimary.withOpacity(0.3),
                    AppColors.golfPrimary.withOpacity(0.1),
                  ],
                ),
              ),
            ),

            // Hole
            Positioned(
              left: _holePosition.dx - 20,
              top: _holePosition.dy - 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.flag, color: Colors.red, size: 24),
                ),
              ),
            ),

            // Golf ball
            Positioned(
              left: _ballPosition.dx - 15,
              top: _ballPosition.dy - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // Aim line
            if (_isDragging)
              CustomPaint(
                painter: AimLinePainter(start: _ballPosition, end: _dragStart),
              ),

            // Turn indicator
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isMyTurn ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isMyTurn ? '✨ SİZİN SIRANIZ!' : '⏳ Rakip oynuyor...',
                  style: AppTextStyles.button.white,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Shots counter
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'Atışlar: ${_roomData?['players'][_myPlayerKey]['shots'] ?? 0}',
                  style: AppTextStyles.label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}

class AimLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  AimLinePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    // Power indicator
    final distance = (start - end).distance;
    final maxDistance = 200.0;
    final power = (distance / maxDistance).clamp(0.0, 1.0);

    // Draw power circles
    for (int i = 1; i <= 5; i++) {
      final alpha = power >= i / 5 ? 255 : 50;
      final circlePaint = Paint()
        ..color = Colors.white.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      final circlePos = Offset.lerp(start, end, i / 6)!;
      canvas.drawCircle(circlePos, 5, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
