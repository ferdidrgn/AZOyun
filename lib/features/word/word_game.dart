// ============================================

import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class WordGame extends StatefulWidget {
  final String roomId;
  final String playerName;
  final Function(String) onGameEvent;
  final VoidCallback onGameEnd;

  const WordGame({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.onGameEvent,
    required this.onGameEnd,
  });

  @override
  State<WordGame> createState() => _WordGameState();
}

class _WordGameState extends State<WordGame> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;
  final Random _random = Random();

  final List<String> words = [
    'ELMA',
    'KALEM',
    'KAPI',
    'MASA',
    'SU',
    'EV',
    'ARABA',
    'KEDI',
    'KÖPEK',
    'KUŞLAR',
  ];

  String? myPlayerKey;
  List<String> availableLetters = [];
  List<String> usedLetters = [];
  Set<String> foundWords = {};
  int myScore = 0;

  @override
  void initState() {
    super.initState();
    roomRef = _database.child('word_puzzle_rooms/${widget.roomId}');
    _findMyPlayerKey();
    _listenToRoom();
    _generateLetters();
  }

  Future<void> _findMyPlayerKey() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;
    final players = Map<String, dynamic>.from(snapshot.value as Map);
    players.forEach((final key, final value) {
      if (value['name'] == widget.playerName) myPlayerKey = key;
    });
  }

  void _listenToRoom() {
    roomRef.onValue.listen((final event) {
      if (!mounted || event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        myScore = data['players']?[myPlayerKey]?['score'] ?? 0;
      });
      if (data['status'] == 'finished') widget.onGameEnd();
    });
  }

  void _generateLetters() {
    const allLetters = 'ABCDEFGHİJKLMNOPRSTUVYZ';
    availableLetters = List.generate(
      12,
      (final i) => allLetters[_random.nextInt(allLetters.length)],
    );
    setState(() {});
  }

  void _addLetter(final String letter) {
    if (usedLetters.length < 6) {
      setState(() => usedLetters.add(letter));
    }
  }

  void _removeLetter() {
    if (usedLetters.isNotEmpty) {
      setState(() => usedLetters.removeLast());
    }
  }

  Future<void> _checkWord() async {
    if (myPlayerKey == null || usedLetters.isEmpty) return;

    final word = usedLetters.join('');

    if (words.contains(word) && !foundWords.contains(word)) {
      foundWords.add(word);
      myScore += word.length * 10;
      widget.onGameEvent('✅ Kelime bulundu! +${word.length * 10} puan');
      await roomRef.update({'players/$myPlayerKey/score': myScore});
      setState(() => usedLetters.clear());
    } else {
      widget.onGameEvent('❌ Geçersiz kelime!');
      setState(() => usedLetters.clear());
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Puan: $myScore',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Kullanılan harfler
          Container(
            height: 60,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                usedLetters.join(' '),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _removeLetter,
                child: const Icon(Icons.backspace),
              ),
              ElevatedButton(
                onPressed: _checkWord,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('KONTROL ET'),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Mevcut harfler
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableLetters.map((final letter) {
              return ElevatedButton(
                onPressed: () => _addLetter(letter),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(60, 60),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  letter,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          Text(
            'Bulunan Kelimeler: ${foundWords.join(', ')}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
