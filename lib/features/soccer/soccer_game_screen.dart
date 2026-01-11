import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SoccerGameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;

  const SoccerGameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
  });

  @override
  State<SoccerGameScreen> createState() => _SoccerGameScreenState();
}

class _SoccerGameScreenState extends State<SoccerGameScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;
  final Random _random = Random();

  String? myPlayerKey;
  int currentRound = 1;
  int totalRounds = 5;
  bool isMyTurn = false;
  int myScore = 0;
  Offset? dragStart;
  Offset? dragEnd;

  @override
  void initState() {
    super.initState();
    roomRef = _database.child('soccer_rooms/${widget.roomId}');
    _findMyPlayerKey();
    _listenToRoom();
  }

  Future<void> _findMyPlayerKey() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final players = Map<String, dynamic>.from(snapshot.value as Map);
    players.forEach((key, value) {
      if (value['name'] == widget.playerName) {
        myPlayerKey = key;
      }
    });
  }

  void _listenToRoom() {
    roomRef.onValue.listen((event) {
      if (!mounted || event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        currentRound = data['currentRound'] ?? 1;
        isMyTurn = data['currentPlayer'] == myPlayerKey;
        myScore = data['players']?[myPlayerKey]?['score'] ?? 0;
      });

      if (data['status'] == 'finished') {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _shoot() async {
    if (!isMyTurn || dragStart == null || dragEnd == null ||
        myPlayerKey == null) return;

    final dx = dragEnd!.dx - dragStart!.dx;
    final dy = dragEnd!.dy - dragStart!.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final power = (distance / 100).clamp(0.3, 1.0);

    // Basit gol hesaplaması
    final goalChance = _random.nextDouble();
    final scored = goalChance < power * 0.7; // %70 şans

    if (scored) {
      myScore++;
      await roomRef.update({'players/$myPlayerKey/score': myScore});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚽ GOL! Harika vuruş!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🧤 Kaleci kurtardı!')),
        );
      }
    }

    setState(() {
      dragStart = null;
      dragEnd = null;
    });

    // Sıra değiştir
    await _nextTurn();
  }

  Future<void> _nextTurn() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final players = Map<String, dynamic>.from(snapshot.value as Map);
    final playerKeys = players.keys.toList();
    final currentIndex = playerKeys.indexOf(myPlayerKey!);
    final nextIndex = (currentIndex + 1) % playerKeys.length;

    if (nextIndex == 0) {
      // Yeni round
      if (currentRound >= totalRounds) {
        await roomRef.update({'status': 'finished'});
      } else {
        await roomRef.update({
          'currentRound': currentRound + 1,
          'currentPlayer': playerKeys[nextIndex],
        });
      }
    } else {
      await roomRef.update({'currentPlayer': playerKeys[nextIndex]});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Round $currentRound/$totalRounds',
                      style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    '⚽ $myScore',
                    style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),

            // Oyun Alanı
            Expanded(
              child: GestureDetector(
                onPanStart: isMyTurn ? (details) {
                  setState(() {
                    dragStart = details.localPosition;
                    dragEnd = details.localPosition;
                  });
                } : null,
                onPanUpdate: isMyTurn ? (details) {
                  setState(() {
                    dragEnd = details.localPosition;
                  });
                } : null,
                onPanEnd: isMyTurn ? (details) => _shoot() : null,
                child: CustomPaint(
                  painter: SoccerPainter(
                    dragStart: dragStart,
                    dragEnd: dragEnd,
                  ),
                  child: Container(),
                ),
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isMyTurn ? Colors.green.withOpacity(0.3) : Colors.grey
                    .withOpacity(0.3),
              ),
              child: Text(
                isMyTurn
                    ? '⚽ Senin sıran - Vuruş yap!'
                    : '⏳ Rakip vuruş yapıyor...',
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoccerPainter extends CustomPainter {
  final Offset? dragStart;
  final Offset? dragEnd;

  SoccerPainter({this.dragStart, this.dragEnd});

  @override
  void paint(Canvas canvas, Size size) {
    // Saha
    final grassPaint = Paint()
      ..color = const Color(0xFF4CAF50);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);

    // Kale
    final goalPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final goalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.2),
      width: size.width * 0.5,
      height: size.height * 0.15,
    );
    canvas.drawRect(goalRect, goalPaint);

    // Top
    final ballPaint = Paint()
      ..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.8),
      15,
      ballPaint,
    );

    // Vuruş çizgisi
    if (dragStart != null && dragEnd != null) {
      final linePaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 4;

      canvas.drawLine(dragStart!, dragEnd!, linePaint);

      // Güç göstergesi
      final distance = sqrt(
        pow(dragEnd!.dx - dragStart!.dx, 2) +
            pow(dragEnd!.dy - dragStart!.dy, 2),
      );
      final power = (distance / 100).clamp(0.0, 1.0);

      for (int i = 1; i <= 5; i++) {
        final alpha = power >= i / 5 ? 255 : 60;
        canvas.drawCircle(
          Offset(
            dragStart!.dx + (dragEnd!.dx - dragStart!.dx) * i / 6,
            dragStart!.dy + (dragEnd!.dy - dragStart!.dy) * i / 6,
          ),
          5,
          Paint()
            ..color = Colors.yellow.withAlpha(alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}