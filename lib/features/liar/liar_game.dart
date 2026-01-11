import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// ☕ YALANCILAR KAHVESİ OYUNU
/// liar_game.dart

class LiarGame extends StatefulWidget {
  final String roomId;
  final String playerName;
  final Function(String) onGameEvent;
  final VoidCallback onGameEnd;

  const LiarGame({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.onGameEvent,
    required this.onGameEnd,
  });

  @override
  State<LiarGame> createState() => _LiarGameState();
}

class _LiarGameState extends State<LiarGame> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;
  final Random _random = Random();

  final List<String> topics = [
    'Tatil',
    'Okul',
    'Ev',
    'Araba',
    'Yemek',
    'Spor',
    'Film',
    'Müzik',
    'Hayvan',
    'Kitap',
  ];

  String? myPlayerKey;
  bool isLiar = false;
  String topic = '';
  String? myAnswer;
  Map<String, dynamic> players = {};
  String gamePhase = 'answer'; // answer, guess

  @override
  void initState() {
    super.initState();
    roomRef = _database.child('liar_cafe_rooms/${widget.roomId}');
    _findMyPlayerKey();
    _listenToRoom();
  }

  Future<void> _findMyPlayerKey() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;
    final playerData = Map<String, dynamic>.from(snapshot.value as Map);
    playerData.forEach((final key, final value) {
      if (value['name'] == widget.playerName) {
        myPlayerKey = key;
        isLiar = value['isLiar'] == true;
        topic = value['topic'] ?? '';
      }
    });
  }

  void _listenToRoom() {
    roomRef.onValue.listen((final event) {
      if (!mounted || event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        gamePhase = data['phase'] ?? 'answer';
        players = Map<String, dynamic>.from(data['players'] ?? {});
      });
      if (data['status'] == 'finished') widget.onGameEnd();
    });
  }

  Future<void> _submitAnswer(final String answer) async {
    if (myPlayerKey == null) return;
    await roomRef.update({'players/$myPlayerKey/answer': answer});
    setState(() => myAnswer = answer);

    // Herkes cevap verdi mi?
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final playerData = Map<String, dynamic>.from(snapshot.value as Map);
    final allAnswered = playerData.values.every(
      (final p) => p['answer'] != null && p['answer'] != '',
    );

    if (allAnswered) {
      await roomRef.update({'phase': 'guess'});
    }
  }

  Future<void> _guessLiar(final String targetKey) async {
    if (myPlayerKey == null) return;
    await roomRef.update({'players/$myPlayerKey/guess': targetKey});

    // Herkes tahmin etti mi?
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final playerData = Map<String, dynamic>.from(snapshot.value as Map);
    final allGuessed = playerData.values.every(
      (final p) => p['guess'] != null && p['guess'] != '',
    );

    if (allGuessed) {
      _checkResult();
    }
  }

  Future<void> _checkResult() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final playerData = Map<String, dynamic>.from(snapshot.value as Map);

    // Yalancıyı bul
    String? liarKey;
    playerData.forEach((final key, final value) {
      if (value['isLiar'] == true) liarKey = key;
    });

    // Tahminleri say
    final guesses = <String, int>{};
    playerData.forEach((final key, final value) {
      final guess = value['guess'] as String?;
      if (guess != null && guess.isNotEmpty) {
        guesses[guess] = (guesses[guess] ?? 0) + 1;
      }
    });

    // En çok tahmin edilen
    String? mostGuessed;
    int maxGuesses = 0;
    guesses.forEach((final key, final count) {
      if (count > maxGuesses) {
        maxGuesses = count;
        mostGuessed = key;
      }
    });

    if (mostGuessed == liarKey) {
      widget.onGameEvent('🎉 Yalancı yakalandı!');
    } else {
      widget.onGameEvent('😈 Yalancı kazandı!');
    }

    await roomRef.update({'status': 'finished'});
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLiar ? Colors.red : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isLiar ? '😈 SEN YALANCISIN!' : '🔍 Konu: $topic',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          if (gamePhase == 'answer' && myAnswer == null)
            Column(
              children: [
                const Text(
                  'Konu hakkında bir cümle söyle:',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Cevabını yaz...',
                  ),
                  onSubmitted: _submitAnswer,
                ),
              ],
            ),

          if (gamePhase == 'answer' && myAnswer != null)
            Text(
              'Cevabın: $myAnswer\n\nDiğer oyuncular cevap veriyor...',
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),

          if (gamePhase == 'guess')
            Column(
              children: [
                const Text(
                  'Kim yalancı?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ...players.entries.map((final entry) {
                  final key = entry.key;
                  final player = entry.value;
                  if (key == myPlayerKey) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () => _guessLiar(key),
                      child: Text(
                        '${player['name']}: ${player['answer'] ?? '...'}',
                      ),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}
