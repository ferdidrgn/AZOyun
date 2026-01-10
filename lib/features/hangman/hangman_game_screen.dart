import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../core/services/ad_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/banner_ad.dart';
import '../../core/widgets/game_button.dart';

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
  bool _hasShownWordDialog = false;
  bool _hasShownFinalDialog = false;
  int _lastRound = 0;

  final List<String> _wordList = [
    'FLUTTER',
    'FIREBASE',
    'KOTLIN',
    'ANDROID',
    'PYTHON',
    'JAVASCRIPT',
    'DATABASE',
    'COMPUTER',
    'KEYBOARD',
    'INTERNET',
    'TELEFON',
    'OYUN',
    'BILGISAYAR',
    'PROGRAMLAMA',
    'YAZILIM',
  ];

  @override
  void initState() {
    super.initState();
    _listenToRoom();
    AdManager().onGameStart();
  }

  void _listenToRoom() {
    _database.child('hangman_rooms/${widget.roomId}').onValue.listen((
      final event,
    ) {
      if (event.snapshot.value == null || !mounted) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        _roomData = data;
        _gameStatus = data['status'] ?? 'waiting';

        if (data['currentGame'] != null) {
          final game = Map<String, dynamic>.from(data['currentGame'] as Map);
          _currentWord = game['word'];
          _guessedLetters = List<String>.from(game['guessedLetters'] ?? []);
          _wrongGuesses = game['wrongGuesses'] ?? 0;

          String wordChooser = game['wordChooser'] ?? 'player1';
          String myRole = widget.isPlayer1 ? 'player1' : 'player2';
          _isMyTurn = wordChooser != myRole;
        } else {
          _currentWord = null;
          _guessedLetters = [];
          _wrongGuesses = 0;
          _isMyTurn = false;
        }

        // Round değişti mi?
        final currentRound = data['currentRound'] ?? 1;
        if (currentRound != _lastRound) {
          _lastRound = currentRound;
          _hasShownWordDialog = false;
        }
      });

      // SADECE OYUN BAŞLADIYSA VE KELİME SEÇİLMEDİYSE
      if (_gameStatus == 'playing' &&
          _currentWord == null &&
          _shouldIChooseWord() &&
          !_hasShownWordDialog) {
        _hasShownWordDialog = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showWordSelectionDialog();
        });
      }

      // Oyun bitti mi?
      if (_gameStatus == 'finished' && !_hasShownFinalDialog) {
        _hasShownFinalDialog = true;
        _checkGameEnd();
      }

      // Round bitti mi?
      if (_currentWord != null) {
        _checkRoundEnd();
      }
    });
  }

  bool _shouldIChooseWord() {
    if (_roomData == null) return false;

    // SIRALAMA SİSTEMİ:
    // Round 1 → Player 1 seçer
    // Round 2 → Player 2 seçer
    // Round 3 → Player 1 seçer
    // Round 4 → Player 2 seçer
    // Round 5 → Player 1 seçer
    // Round 6 → Player 2 seçer

    final currentRound = _roomData!['currentRound'] ?? 1;

    // Tek roundlarda Player1, çift roundlarda Player2
    if (currentRound % 2 == 1) {
      // Tek round - Player1 seçmeli
      return widget.isPlayer1;
    } else {
      // Çift round - Player2 seçmeli
      return !widget.isPlayer1;
    }
  }

  void _checkRoundEnd() {
    if (_currentWord == null) return;

    // Kelime tamamlandı mı?
    bool wordCompleted = _currentWord!
        .split('')
        .every(
          (final letter) => _guessedLetters.contains(letter) || letter == ' ',
        );

    if (wordCompleted || _wrongGuesses >= 6) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _handleRoundEnd(wordCompleted);
      });
    }
  }

  Future<void> _handleRoundEnd(final bool guesserWon) async {
    final game = Map<String, dynamic>.from(_roomData!['currentGame'] as Map);
    String wordChooser = game['wordChooser'];
    String guesser = wordChooser == 'player1' ? 'player2' : 'player1';
    String winner = guesserWon ? guesser : wordChooser;

    // Skoru güncelle
    if (widget.isPlayer1) {
      final currentScore = _roomData?[winner]['score'] ?? 0;
      await _database
          .child('hangman_rooms/${widget.roomId}/$winner/score')
          .set(currentScore + 1);
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final currentRound = _roomData?['currentRound'] ?? 1;
    if (currentRound >= 6) {
      // 6 EL YAPILDI
      // Oyun bitti
      await _database
          .child('hangman_rooms/${widget.roomId}/status')
          .set('finished');
    } else {
      // Yeni round
      if (widget.isPlayer1) {
        await _database.child('hangman_rooms/${widget.roomId}').update({
          'currentRound': currentRound + 1,
          'currentGame': null,
        });
      }
    }
  }

  void _checkGameEnd() {
    Future.delayed(const Duration(milliseconds: 1000), _showFinalScores);
  }

  void _showWordSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 10),
              const Expanded(child: Text('🎯 Kelime Seç!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning, width: 2),
                ),
                child: Text(
                  'Rakibin bekliyor!\nKelime seçmelisin.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.bold,
                ),
              ),
              const SizedBox(height: 20),
              GameButton(
                text: 'LİSTEDEN SEÇ',
                icon: Icons.list,
                onPressed: () {
                  Navigator.pop(context);
                  _showPredefinedWords();
                },
                color: AppColors.hangmanPrimary,
              ),
              const SizedBox(height: 12),
              GameButton(
                text: 'KENDİ KELİMEN',
                icon: Icons.create,
                onPressed: () {
                  Navigator.pop(context);
                  _showCustomWordDialog();
                },
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPredefinedWords() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('Kelime Seç'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            itemCount: _wordList.length,
            itemBuilder: (final context, final index) {
              return Card(
                child: ListTile(
                  title: Text(
                    _wordList[index],
                    style: AppTextStyles.bodyLarge.bold,
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
      ),
    );
  }

  void _showCustomWordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('Kendi Kelimeni Yaz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customWordController,
              decoration: const InputDecoration(
                hintText: 'KELİME',
                border: OutlineInputBorder(),
                helperText: 'Min 3, Max 15 harf',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 15,
              style: AppTextStyles.h4,
            ),
          ],
        ),
        actions: [
          GameButton(
            text: 'BAŞLAT',
            onPressed: () {
              String word = _customWordController.text
                  .toUpperCase()
                  .trim()
                  .replaceAll(RegExp(r'[^A-ZÇĞİÖŞÜ]'), '');

              if (word.length >= 3) {
                Navigator.pop(context);
                _startGameWithWord(word);
                _customWordController.clear();
              }
            },
            color: AppColors.hangmanPrimary,
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }

  Future<void> _startGameWithWord(final String word) async {
    String wordChooser = widget.isPlayer1 ? 'player1' : 'player2';

    await _database.child('hangman_rooms/${widget.roomId}/currentGame').set({
      'word': word,
      'guessedLetters': [],
      'wrongGuesses': 0,
      'wordChooser': wordChooser,
      'roundStartTime': ServerValue.timestamp,
    });
  }

  Future<void> _guessLetter(final String letter) async {
    if (!_isMyTurn ||
        _guessedLetters.contains(letter) ||
        _currentWord == null) {
      return;
    }

    final newGuessedLetters = [..._guessedLetters, letter];
    final isCorrect = _currentWord!.contains(letter);

    await _database.child('hangman_rooms/${widget.roomId}/currentGame').update({
      'guessedLetters': newGuessedLetters,
      'wrongGuesses': isCorrect ? _wrongGuesses : _wrongGuesses + 1,
    });
  }

  Future<void> _showFinalScores() async {
    if (_roomData == null) return;

    await AdManager().onGameEnd();

    final p1Score = _roomData!['player1']['score'] ?? 0;
    final p2Score = _roomData!['player2']['score'] ?? 0;
    final p1Name = _roomData!['player1']['name'];
    final p2Name = _roomData!['player2']['name'];

    String winner = p1Score > p2Score ? p1Name : p2Name;
    if (p1Score == p2Score) winner = 'BERABERE!';

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text('🏆 Oyun Bitti!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winner == 'BERABERE!' ? '🤝 $winner' : '👑 $winner Kazandı!',
              style: AppTextStyles.h4.bold,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _buildScoreRow(p1Name, p1Score, p1Name == widget.playerName),
            _buildScoreRow(p2Name, p2Score, p2Name == widget.playerName),
          ],
        ),
        actions: [
          GameButton(
            text: 'ANA MENÜYE DÖN',
            onPressed: () {
              Navigator.of(context).popUntil((final route) => route.isFirst);
            },
            color: AppColors.hangmanPrimary,
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(final String name, final int score, final bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.hangmanPrimary.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name + (isMe ? ' (SEN)' : ''),
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(score.toString(), style: AppTextStyles.h4.bold),
        ],
      ),
    );
  }

  Widget _buildHangman() {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        size: const Size(200, 200),
        painter: HangmanPainter(_wrongGuesses),
      ),
    );
  }

  Widget _buildWord() {
    if (_currentWord == null) return const SizedBox();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _currentWord!.split('').map((final letter) {
          if (letter == ' ') {
            return const SizedBox(width: 20);
          }

          bool isGuessed = _guessedLetters.contains(letter);
          return Container(
            width: 35,
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isGuessed ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isGuessed ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                isGuessed ? letter : '_',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isGuessed ? Colors.white : Colors.grey.shade600,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: keyboard.map((final row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((final letter) {
              bool isGuessed = _guessedLetters.contains(letter);
              bool isDisabled = !_isMyTurn || isGuessed;
              bool isCorrect =
                  isGuessed && _currentWord?.contains(letter) == true;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 36,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isDisabled ? null : () => _guessLetter(letter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGuessed
                          ? (isCorrect ? Colors.green : Colors.red)
                          : AppColors.hangmanPrimary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      elevation: isGuessed ? 0 : 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(final BuildContext context) {
    if (_gameStatus == 'waiting' || _currentWord == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🎯 Adam Asmaca'),
          backgroundColor: AppColors.hangmanPrimary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.hangmanPrimary),
              const SizedBox(height: 20),
              Text(
                _shouldIChooseWord()
                    ? 'Kelime seçmelisin...'
                    : 'Rakip kelime seçiyor...',
                style: AppTextStyles.h5,
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
        title: Text('Round $currentRound/6'), // 6 EL
        backgroundColor: AppColors.hangmanPrimary,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text('$p1Score', style: AppTextStyles.h5.white),
                  const SizedBox(width: 8),
                  const Text('VS', style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 8),
                  Text('$p2Score', style: AppTextStyles.h5.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Durum bildirimi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _isMyTurn
                ? AppColors.success.withOpacity(0.2)
                : AppColors.warning.withOpacity(0.2),
            child: Text(
              _isMyTurn ? '✨ SENİN SIRAN!' : '⏳ Rakip tahmin ediyor...',
              style: AppTextStyles.bodyLarge.bold,
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHangman(),
                  const SizedBox(height: 20),
                  _buildWord(),
                  const SizedBox(height: 30),
                  _buildKeyboard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          const BannerAdWidget(),
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

// Extension'lar - En Alta Ekledik
extension ColorExtension on Color {
  Color darken(final double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color lighten(final double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

class HangmanPainter extends CustomPainter {
  final int wrongGuesses;

  HangmanPainter(this.wrongGuesses);

  @override
  void paint(final Canvas canvas, final Size size) {
    // 3D AHŞAP DARAAĞACI
    _drawGallows3D(canvas, size);

    // 3D ADAM
    _drawPerson3D(canvas, size);
  }

  void _drawGallows3D(final Canvas canvas, final Size size) {
    // Ahşap rengi
    final woodColor = const Color(0xFF8B4513);
    final woodDark = const Color(0xFF654321);
    final woodLight = const Color(0xFFA0826D);

    // GÖLGELİ TABAN
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.05 + 3,
        size.height * 0.88 + 3,
        size.width * 0.5,
        size.height * 0.08,
      ),
      shadowPaint,
    );

    // TABAN (3D gradient)
    final basePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [woodLight, woodColor, woodDark],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.05,
              size.height * 0.88,
              size.width * 0.5,
              size.height * 0.08,
            ),
          );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.88,
        size.width * 0.5,
        size.height * 0.08,
      ),
      basePaint,
    );

    // Taban kenar çizgisi
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.88,
        size.width * 0.5,
        size.height * 0.08,
      ),
      Paint()
        ..color = woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // DİKEY DİREK (3D)
    final verticalPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.88)
      ..lineTo(size.width * 0.15, size.height * 0.08)
      ..lineTo(size.width * 0.19, size.height * 0.07)
      ..lineTo(size.width * 0.19, size.height * 0.87)
      ..close();

    canvas.drawPath(
      verticalPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [woodDark, woodColor, woodLight],
            ).createShader(
              Rect.fromLTWH(
                size.width * 0.15,
                size.height * 0.07,
                size.width * 0.04,
                size.height * 0.81,
              ),
            ),
    );

    canvas.drawPath(
      verticalPath,
      Paint()
        ..color = woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // YATAY ÇUBUK (3D)
    final horizontalPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.08)
      ..lineTo(size.width * 0.6, size.height * 0.08)
      ..lineTo(size.width * 0.61, size.height * 0.11)
      ..lineTo(size.width * 0.16, size.height * 0.11)
      ..close();

    canvas.drawPath(
      horizontalPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [woodLight, woodColor, woodDark],
            ).createShader(
              Rect.fromLTWH(
                size.width * 0.15,
                size.height * 0.08,
                size.width * 0.46,
                size.height * 0.03,
              ),
            ),
    );

    canvas.drawPath(
      horizontalPath,
      Paint()
        ..color = woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // İP (bükümlü halat)
    if (wrongGuesses >= 0) {
      final ropePaint = Paint()
        ..color = const Color(0xFFD2691E)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      for (double i = size.height * 0.11; i <= size.height * 0.2; i += 3) {
        canvas.drawLine(
          Offset(size.width * 0.6 + sin(i * 0.5) * 1.5, i),
          Offset(size.width * 0.6 + sin((i + 3) * 0.5) * 1.5, i + 3),
          ropePaint,
        );
      }
    }
  }

  void _drawPerson3D(final Canvas canvas, final Size size) {
    // Renkli 3D adam
    final bodyColor = const Color(0xFF2196F3); // Mavi
    final skinColor = const Color(0xFFFFDBB5); // Ten rengi

    // KAFA (1. hata) - 3D sphere
    if (wrongGuesses >= 1) {
      // Gölge
      canvas.drawCircle(
        Offset(size.width * 0.6 + 2, size.height * 0.25 + 2),
        size.height * 0.05,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Kafa gradient
      canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.25),
        size.height * 0.05,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  skinColor,
                  skinColor,
                  skinColor,
                ],
                stops: [0.3, 0.7, 1.0],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.6, size.height * 0.25),
                  radius: size.height * 0.05,
                ),
              ),
      );

      // Yüz detayları
      if (wrongGuesses >= 6) {
        // X gözler (ölü)
        final eyePaint = Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(size.width * 0.57, size.height * 0.24),
          Offset(size.width * 0.585, size.height * 0.25),
          eyePaint,
        );
        canvas.drawLine(
          Offset(size.width * 0.585, size.height * 0.24),
          Offset(size.width * 0.57, size.height * 0.25),
          eyePaint,
        );
        canvas.drawLine(
          Offset(size.width * 0.615, size.height * 0.24),
          Offset(size.width * 0.63, size.height * 0.25),
          eyePaint,
        );
        canvas.drawLine(
          Offset(size.width * 0.63, size.height * 0.24),
          Offset(size.width * 0.615, size.height * 0.25),
          eyePaint,
        );

        // Üzgün ağız
        final mouthPath = Path()
          ..moveTo(size.width * 0.57, size.height * 0.27)
          ..quadraticBezierTo(
            size.width * 0.6,
            size.height * 0.265,
            size.width * 0.63,
            size.height * 0.27,
          );
        canvas.drawPath(mouthPath, eyePaint);
      } else {
        // Normal gözler
        canvas.drawCircle(
          Offset(size.width * 0.58, size.height * 0.245),
          2,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          Offset(size.width * 0.62, size.height * 0.245),
          2,
          Paint()..color = Colors.black,
        );

        // Gülümseyen ağız
        final mouthPath = Path()
          ..moveTo(size.width * 0.57, size.height * 0.265)
          ..quadraticBezierTo(
            size.width * 0.6,
            size.height * 0.275,
            size.width * 0.63,
            size.height * 0.265,
          );
        canvas.drawPath(
          mouthPath,
          Paint()
            ..color = Colors.black
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // GÖVDE (2. hata) - 3D silindir
    if (wrongGuesses >= 2) {
      canvas.drawLine(
        Offset(size.width * 0.6 + 2, size.height * 0.3 + 2),
        Offset(size.width * 0.6 + 2, size.height * 0.48 + 2),
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.3),
        Offset(size.width * 0.6, size.height * 0.48),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  bodyColor,
                  bodyColor,
                  bodyColor,
                ],
              ).createShader(
                Rect.fromLTWH(
                  size.width * 0.6 - 3,
                  size.height * 0.3,
                  6,
                  size.height * 0.18,
                ),
              )
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }

    // SOL KOL (3. hata)
    if (wrongGuesses >= 3) {
      canvas.drawLine(
        Offset(size.width * 0.6 + 2, size.height * 0.34 + 2),
        Offset(size.width * 0.52 + 2, size.height * 0.4 + 2),
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.34),
        Offset(size.width * 0.52, size.height * 0.4),
        Paint()
          ..color = bodyColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    // SAĞ KOL (4. hata)
    if (wrongGuesses >= 4) {
      canvas.drawLine(
        Offset(size.width * 0.6 + 2, size.height * 0.34 + 2),
        Offset(size.width * 0.68 + 2, size.height * 0.4 + 2),
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.34),
        Offset(size.width * 0.68, size.height * 0.4),
        Paint()
          ..color = bodyColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    // SOL BACAK (5. hata)
    if (wrongGuesses >= 5) {
      canvas.drawLine(
        Offset(size.width * 0.6 + 2, size.height * 0.48 + 2),
        Offset(size.width * 0.55 + 2, size.height * 0.6 + 2),
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.48),
        Offset(size.width * 0.55, size.height * 0.6),
        Paint()
          ..color = bodyColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    // SAĞ BACAK (6. hata - ölüm)
    if (wrongGuesses >= 6) {
      canvas.drawLine(
        Offset(size.width * 0.6 + 2, size.height * 0.48 + 2),
        Offset(size.width * 0.65 + 2, size.height * 0.6 + 2),
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.48),
        Offset(size.width * 0.65, size.height * 0.6),
        Paint()
          ..color = bodyColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      // Ölüm efekti - kırmızı parlama
      canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.4),
        size.height * 0.15,
        Paint()
          ..color = Colors.red.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => true;
}

// Extension'lar tekrar - Painter'dan sonra da ekleyelim
extension ColorExtensionHangman on Color {
  Color darken(final double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color lighten(final double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
