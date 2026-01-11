import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 🧮 HIZLI MATEMATİK OYUNU
class MathGame extends StatefulWidget {
  final String roomId;
  final String playerName;
  final Function(String message) onGameEvent;
  final VoidCallback onGameEnd;

  const MathGame({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.onGameEvent,
    required this.onGameEnd,
  });

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;
  final Random _random = Random();

  String? myPlayerKey;
  int currentQuestion = 1;
  int totalQuestions = 10;
  int myScore = 0;
  int timeLeft = 15;
  Timer? _timer;

  String question = '';
  int correctAnswer = 0;
  List<int> options = [];
  bool answered = false;

  @override
  void initState() {
    super.initState();
    roomRef = _database.child('math_rooms/${widget.roomId}');
    _findMyPlayerKey();
    _listenToRoom();
    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      if (event.snapshot.value == null || !mounted) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        currentQuestion = data['currentQuestion'] ?? 1;
        myScore = data['players']?[myPlayerKey]?['score'] ?? 0;
      });

      if (data['status'] == 'finished') {
        widget.onGameEnd();
      }
    });
  }

  void _generateQuestion() {
    final num1 = _random.nextInt(20) + 1;
    final num2 = _random.nextInt(20) + 1;
    final operations = ['+', '-', '×', '÷'];
    final operation = operations[_random.nextInt(4)];

    switch (operation) {
      case '+':
        question = '$num1 + $num2 = ?';
        correctAnswer = num1 + num2;
        break;
      case '-':
        final bigger = max(num1, num2);
        final smaller = min(num1, num2);
        question = '$bigger - $smaller = ?';
        correctAnswer = bigger - smaller;
        break;
      case '×':
        final a = _random.nextInt(12) + 1;
        final b = _random.nextInt(12) + 1;
        question = '$a × $b = ?';
        correctAnswer = a * b;
        break;
      case '÷':
        final b = _random.nextInt(10) + 1;
        final result = _random.nextInt(10) + 1;
        final a = b * result;
        question = '$a ÷ $b = ?';
        correctAnswer = result;
        break;
    }

    // Şıklar oluştur
    options = [correctAnswer];
    while (options.length < 4) {
      final option = correctAnswer + _random.nextInt(21) - 10;
      if (option > 0 && !options.contains(option)) {
        options.add(option);
      }
    }
    options.shuffle();

    setState(() {
      answered = false;
      timeLeft = 15;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        timeLeft--;
      });

      if (timeLeft <= 0) {
        _handleAnswer(-1); // Süre bitti
      }
    });
  }

  Future<void> _handleAnswer(int answer) async {
    if (answered || myPlayerKey == null) return;

    setState(() => answered = true);
    _timer?.cancel();

    final isCorrect = answer == correctAnswer;

    if (isCorrect) {
      final points = timeLeft + 5; // Hızlı cevap = daha fazla puan
      myScore += points;
      widget.onGameEvent('✅ Doğru! +$points puan');

      await roomRef.update({'players/$myPlayerKey/score': myScore});
    } else {
      widget.onGameEvent('❌ Yanlış! Doğru cevap: $correctAnswer');
    }

    await Future.delayed(const Duration(seconds: 2));

    if (currentQuestion >= totalQuestions) {
      // Oyun bitti
      await roomRef.update({'status': 'finished'});
    } else {
      // Sonraki soru
      await roomRef.update({'currentQuestion': currentQuestion + 1});
      _generateQuestion();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // İlerleme
          LinearProgressIndicator(
            value: currentQuestion / totalQuestions,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),

          const SizedBox(height: 20),

          // Soru numarası ve süre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru $currentQuestion/$totalQuestions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: timeLeft <= 5 ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⏰ $timeLeft',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Soru
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Şıklar
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final option = options[index];

                return ElevatedButton(
                  onPressed: answered ? null : () => _handleAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: answered
                        ? (option == correctAnswer
                              ? Colors.green
                              : Colors.red.withOpacity(0.5))
                        : Colors.blue,
                    disabledBackgroundColor: answered
                        ? (option == correctAnswer
                              ? Colors.green
                              : Colors.red.withOpacity(0.5))
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    option.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Skor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 30),
                const SizedBox(width: 8),
                Text(
                  'Puan: $myScore',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
