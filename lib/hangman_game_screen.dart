import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class HangmanGameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isPlayer1;

  const HangmanGameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isPlayer1,
  });

  @override
  State<HangmanGameScreen> createState() => _HangmanGameScreenState();
}

class _HangmanGameScreenState extends State<HangmanGameScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _customWordController = TextEditingController();

  Map<String, dynamic>? _roomData;
  String? _currentWord;
  List<String> _guessedLetters = [];
  int _wrongGuesses = 0;
  bool _isMyTurn = false;
  String _gameStatus = 'waiting';
  bool _needsWordSelection = false;
  bool _isShowingRoundDialog = false;
  int _lastCompletedRound = 0;

  final List<String> _wordList = [
    'FLUTTER', 'FIREBASE', 'KOTLIN', 'ANDROID', 'PYTHON', 'JAVASCRIPT',
    'DATABASE', 'COMPUTER', 'KEYBOARD', 'INTERNET', 'TELEFON', 'OYUN',
    'BILGISAYAR', 'PROGRAMLAMA', 'YAZILIM', 'MOBIL', 'UYGULAMA', 'GITAR',
    'PIYANO', 'FUTBOL', 'BASKETBOL', 'YÜZME', 'KOŞU', 'BİSİKLET',
    'ARABA', 'UÇAK', 'TREN', 'GEMI', 'OTOBÜS', 'METRO'
  ];

  @override
  void initState() {
    super.initState();
    _listenToRoom();
  }

  void _listenToRoom() {
    _database.child('hangman_rooms/${widget.roomId}').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        final oldCurrentGame = _roomData?['currentGame'];
        final newCurrentGame = data['currentGame'];
        final oldRound = _roomData?['currentRound'] ?? 0;
        final newRound = data['currentRound'] ?? 1;

        setState(() {
          _roomData = data;
          _gameStatus = data['status'] ?? 'waiting';

          if (data['currentGame'] != null) {
            final game = Map<String, dynamic>.from(data['currentGame'] as Map);
            _currentWord = game['word'];
            _guessedLetters = List<String>.from(game['guessedLetters'] ?? []);
            _wrongGuesses = game['wrongGuesses'] ?? 0;

            // Sıra mantığı: Kelimeyi seçen bekler, diğeri tahmin eder
            String wordChooser = game['wordChooser'] ?? 'player1';
            String myRole = widget.isPlayer1 ? 'player1' : 'player2';
            _isMyTurn = wordChooser != myRole; // Kelimeyi seçmeyen tahmin eder

            _needsWordSelection = false;
          } else if (_gameStatus == 'playing') {
            // Oyun başladı ama kelime seçilmemiş
            bool shouldShow = _shouldIChooseWord();

            // Round değişti mi ve kelime seçilmesi gerekiyor mu?
            if (newRound > oldRound && shouldShow) {
              _needsWordSelection = true;
            } else if (oldCurrentGame == null && newCurrentGame == null && shouldShow) {
              // İlk kelime seçimi
              _needsWordSelection = true;
            } else {
              _needsWordSelection = false;
            }
          }
        });

        _checkGameEnd();
      }
    });
  }

  bool _shouldIChooseWord() {
    if (_roomData == null) return false;

    final currentRound = _roomData!['currentRound'] ?? 1;

    // Tek roundlarda player1, çift roundlarda player2 seçer
    if (currentRound % 2 == 1) {
      return widget.isPlayer1;
    } else {
      return !widget.isPlayer1;
    }
  }

  void _showWordSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Kelime Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rakibinin tahmin edeceği kelimeyi seç:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showPredefinedWords();
              },
              icon: const Icon(Icons.list),
              label: const Text('LİSTEDEN SEÇ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCustomWordDialog();
              },
              icon: const Icon(Icons.create),
              label: const Text('KENDİ KELİMENİ YAZ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPredefinedWords() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kelime Seç'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _wordList.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(
                    _wordList[index],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pop(context);
                    _startGameWithWord(_wordList[index]);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
        ],
      ),
    );
  }

  void _showCustomWordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kendi Kelimeni Yaz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customWordController,
              decoration: const InputDecoration(
                hintText: 'Kelimeyi gir',
                border: OutlineInputBorder(),
                helperText: 'Sadece harfler (min 3, max 15)',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 15,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '⚠️ Rakibin bu kelimeyi göremez!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () {
              String word = _customWordController.text
                  .toUpperCase()
                  .trim()
                  .replaceAll(RegExp(r'[^A-ZÇĞİÖŞÜ]'), '');

              if (word.length >= 3) {
                Navigator.pop(context);
                _startGameWithWord(word);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kelime en az 3 harf olmalı!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('BAŞLAT'),
          ),
        ],
      ),
    );
  }

  Future<void> _startGameWithWord(String word) async {
    String wordChooser = widget.isPlayer1 ? 'player1' : 'player2';

    await _database.child('hangman_rooms/${widget.roomId}/currentGame').set({
      'word': word,
      'guessedLetters': [],
      'wrongGuesses': 0,
      'wordChooser': wordChooser,
      'roundStartTime': ServerValue.timestamp,
    });
  }

  void _checkGameEnd() {
    if (_currentWord == null || _isShowingRoundDialog) return;

    // Kelime tamamlandı mı?
    bool wordCompleted = _currentWord!.split('').every((letter) =>
    _guessedLetters.contains(letter) || letter == ' '
    );

    final currentRound = _roomData?['currentRound'] ?? 1;

    // Bu round'u daha önce tamamladık mı kontrol et
    if (currentRound > _lastCompletedRound) {
      if (wordCompleted) {
        _lastCompletedRound = currentRound;
        _handleRoundWin(guesserWon: true);
      } else if (_wrongGuesses >= 6) {
        _lastCompletedRound = currentRound;
        _handleRoundWin(guesserWon: false);
      }
    }
  }

  Future<void> _handleRoundWin({required bool guesserWon}) async {
    if (_isShowingRoundDialog) return;

    setState(() {
      _isShowingRoundDialog = true;
    });

    // Tahmin eden kazandı mı yoksa kelimeyi seçen mi?
    final game = Map<String, dynamic>.from(_roomData!['currentGame'] as Map);
    String wordChooser = game['wordChooser'];
    String guesser = wordChooser == 'player1' ? 'player2' : 'player1';

    String winner = guesserWon ? guesser : wordChooser;

    final currentScore = _roomData?[winner]['score'] ?? 0;
    await _database.child('hangman_rooms/${widget.roomId}/$winner/score')
        .set(currentScore + 1);

    final currentRound = _roomData?['currentRound'] ?? 1;

    // Round bitince göster
    if (mounted) {
      await _showRoundEndDialog(winner, currentRound, guesserWon);
    }

    setState(() {
      _isShowingRoundDialog = false;
    });

    // 3 round bitti mi kontrol et
    if (currentRound >= 3) {
      _endGame();
    } else {
      // Yeni round başlat - sadece Player1 günceller
      if (widget.isPlayer1) {
        await _database.child('hangman_rooms/${widget.roomId}').update({
          'currentRound': currentRound + 1,
          'currentGame': null, // Yeni round için sıfırla
        });
      }
    }
  }

  Future<void> _showRoundEndDialog(String winner, int round, bool guesserWon) async {
    String winnerName = winner == 'player1'
        ? _roomData!['player1']['name']
        : _roomData!['player2']['name'];

    String message = guesserWon
        ? '$winnerName kelimeyi buldu! 🎉'
        : 'Kelime bulunamadı! $winnerName kazandı! 🏆';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Round $round Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Kelime: $_currentWord',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text('${_roomData!['player1']['name']}: ${_roomData!['player1']['score']}'),
            Text('${_roomData!['player2']['name']}: ${_roomData!['player2']['score']}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(round >= 3 ? 'SONUÇLARI GÖR' : 'DEVAM ET'),
          ),
        ],
      ),
    );
  }

  void _endGame() {
    _database.child('hangman_rooms/${widget.roomId}/status').set('finished');

    final p1Score = _roomData?['player1']['score'] ?? 0;
    final p2Score = _roomData?['player2']['score'] ?? 0;

    String winner = p1Score > p2Score
        ? _roomData!['player1']['name']
        : _roomData!['player2']['name'];

    if (p1Score == p2Score) {
      winner = 'BERABERE!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎮 Oyun Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winner == 'BERABERE!' ? '🤝 $winner' : '🏆 Kazanan: $winner',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('${_roomData!['player1']['name']}: $p1Score'),
            Text('${_roomData!['player2']['name']}: $p2Score'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('ANA MENÜYE DÖN'),
          ),
        ],
      ),
    );
  }

  Future<void> _guessLetter(String letter) async {
    if (!_isMyTurn || _guessedLetters.contains(letter)) return;

    final newGuessedLetters = [..._guessedLetters, letter];
    final isCorrect = _currentWord!.contains(letter);

    await _database.child('hangman_rooms/${widget.roomId}/currentGame').update({
      'guessedLetters': newGuessedLetters,
      'wrongGuesses': isCorrect ? _wrongGuesses : _wrongGuesses + 1,
    });
  }

  Widget _buildHangman() {
    return CustomPaint(
      size: const Size(200, 250),
      painter: HangmanPainter(_wrongGuesses),
    );
  }

  Widget _buildWord() {
    if (_currentWord == null) return const SizedBox();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _currentWord!.split('').map((letter) {
          if (letter == ' ') {
            return const SizedBox(width: 20);
          }

          bool isGuessed = _guessedLetters.contains(letter);
          return Container(
            width: 40,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Center(
              child: Text(
                isGuessed ? letter : '_',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyboard() {
    const keyboard = [
      ['A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ'],
      ['H', 'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O'],
      ['Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V'],
      ['Y', 'Z'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: keyboard.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((letter) {
                bool isGuessed = _guessedLetters.contains(letter);
                bool isDisabled = !_isMyTurn || isGuessed;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: isDisabled ? null : () => _guessLetter(letter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGuessed ? Colors.grey : Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(32, 40),
                      padding: const EdgeInsets.all(4),
                    ),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_roomData == null || _gameStatus == 'waiting') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Adam Asmaca'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 20),
              Text('Rakip bekleniyor...', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    // Kelime seçim bekleme ekranı veya kelime seçme dialogu
    if (_currentWord == null) {
      bool shouldIChoose = _shouldIChooseWord();

      // Ben kelime seçmeliyim - dialog göster
      if (shouldIChoose && _needsWordSelection) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _needsWordSelection) {
            setState(() {
              _needsWordSelection = false;
            });
            _showWordSelectionDialog();
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Adam Asmaca'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, size: 80, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Kelime seçin...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }

      // Diğer oyuncu kelime seçiyor - bekleme ekranı
      String otherPlayerName = widget.isPlayer1
          ? _roomData!['player2']['name']
          : _roomData!['player1']['name'];

      return Scaffold(
        appBar: AppBar(
          title: const Text('Adam Asmaca'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 20),
              Text(
                '$otherPlayerName kelime seçiyor...',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                '⏳ Lütfen bekleyin',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final p1Score = _roomData?['player1']['score'] ?? 0;
    final p2Score = _roomData?['player2']['score'] ?? 0;
    final currentRound = _roomData?['currentRound'] ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adam Asmaca'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Round $currentRound/3',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Skor Tablosu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerCard(
                  _roomData!['player1']['name'],
                  p1Score,
                  widget.isPlayer1 && _isMyTurn,
                ),
                const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                _buildPlayerCard(
                  _roomData!['player2']['name'],
                  p2Score,
                  !widget.isPlayer1 && _isMyTurn,
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isMyTurn)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✨ SİZİN SIRANIZ - TAHMİN EDİN!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⏳ Rakip tahmin ediyor...',
                  style: TextStyle(fontSize: 16),
                ),
              ),

            const SizedBox(height: 20),

            // Hangman Çizimi
            _buildHangman(),

            const SizedBox(height: 20),

            // Kelime
            _buildWord(),

            const SizedBox(height: 30),

            // Klavye
            _buildKeyboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(String name, int score, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey.shade300,
          width: isActive ? 3 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customWordController.dispose();
    super.dispose();
  }
}

class HangmanPainter extends CustomPainter {
  final int wrongGuesses;

  HangmanPainter(this.wrongGuesses);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Darağacı tabanı
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.9),
      Offset(size.width * 0.5, size.height * 0.9),
      paint,
    );

    // Dikey direk
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.9),
      Offset(size.width * 0.2, size.height * 0.1),
      paint,
    );

    // Üst yatay çubuk
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.1),
      Offset(size.width * 0.6, size.height * 0.1),
      paint,
    );

    // İp
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.1),
      Offset(size.width * 0.6, size.height * 0.2),
      paint,
    );

    // Kafa
    if (wrongGuesses >= 1) {
      canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.25),
        size.height * 0.05,
        paint,
      );
    }

    // Gövde
    if (wrongGuesses >= 2) {
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.3),
        Offset(size.width * 0.6, size.height * 0.5),
        paint,
      );
    }

    // Sol kol
    if (wrongGuesses >= 3) {
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.35),
        Offset(size.width * 0.5, size.height * 0.4),
        paint,
      );
    }

    // Sağ kol
    if (wrongGuesses >= 4) {
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.35),
        Offset(size.width * 0.7, size.height * 0.4),
        paint,
      );
    }

    // Sol bacak
    if (wrongGuesses >= 5) {
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.5),
        Offset(size.width * 0.5, size.height * 0.65),
        paint,
      );
    }

    // Sağ bacak
    if (wrongGuesses >= 6) {
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.5),
        Offset(size.width * 0.7, size.height * 0.65),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}