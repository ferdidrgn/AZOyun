import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CityGame extends StatefulWidget {
  final String roomId;
  final String playerName;
  final Function(String) onGameEvent;
  final VoidCallback onGameEnd;

  const CityGame({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.onGameEvent,
    required this.onGameEnd,
  });

  @override
  State<CityGame> createState() => _CityGameState();
}

class _CityGameState extends State<CityGame> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;
  final Random _random = Random();

  final Map<String, List<String>> cities = {
    'İSTANBUL': [
      'Türkiye\'nin en kalabalık şehri',
      'Boğaz\'ı var',
      'Eski adı Bizans',
    ],
    'ANKARA': ['Başkent', 'İç Anadolu\'da', 'Anıtkabir burada'],
    'İZMİR': ['Ege\'de', 'Deniz kıyısında', 'Saat kulesi ünlü'],
    'ANTALYA': ['Turizm cenneti', 'Akdeniz\'de', 'Plajları ünlü'],
    'BURSA': ['Yeşil Bursa', 'Uludağ\'ı var', 'İlk Osmanlı başkenti'],
  };

  String? myPlayerKey;
  String currentCity = '';
  List<String> hints = [];
  int hintIndex = 0;
  int myScore = 0;
  int currentRound = 1;

  @override
  void initState() {
    super.initState();
    roomRef = _database.child('city_puzzle_rooms/${widget.roomId}');
    _findMyPlayerKey();
    _listenToRoom();
    _generateCity();
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
        currentRound = data['currentRound'] ?? 1;
        myScore = data['players']?[myPlayerKey]?['score'] ?? 0;
      });
      if (data['status'] == 'finished') widget.onGameEnd();
    });
  }

  void _generateCity() {
    final cityNames = cities.keys.toList();
    currentCity = cityNames[_random.nextInt(cityNames.length)];
    hints = cities[currentCity]!;
    hintIndex = 0;
    setState(() {});
  }

  Future<void> _checkAnswer(final String answer) async {
    if (myPlayerKey == null) return;

    if (answer.toUpperCase() == currentCity) {
      final points = 10 - (hintIndex * 3);
      myScore += points;
      widget.onGameEvent('✅ Doğru! +$points puan');
      await roomRef.update({'players/$myPlayerKey/score': myScore});

      if (currentRound >= 5) {
        await roomRef.update({'status': 'finished'});
      } else {
        await roomRef.update({'currentRound': currentRound + 1});
        _generateCity();
      }
    } else {
      widget.onGameEvent('❌ Yanlış tahmin!');
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Round $currentRound/5',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Puan: $myScore',
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'İPUCU:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  hintIndex < hints.length
                      ? hints[hintIndex]
                      : 'Tüm ipuçları kullanıldı',
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (hintIndex < hints.length - 1)
            ElevatedButton(
              onPressed: () => setState(() => hintIndex++),
              child: const Text('Yeni İpucu (−3 puan)'),
            ),

          const SizedBox(height: 40),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Şehir Adı',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: _checkAnswer,
          ),
        ],
      ),
    );
  }
}

