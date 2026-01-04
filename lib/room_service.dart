import 'package:firebase_database/firebase_database.dart';

class RoomService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String _createRoomCode() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
  }

  Future<String> createRoom({String word = 'FLUTTER'}) async {
    final code = _createRoomCode();

    await _db.child('rooms/$code').set({
      'status': 'waiting',
      'hostJoined': true,
      'guestJoined': false,

      // ✅ HANGMAN STATE
      'word': word.toUpperCase(),
      'maskedWord': List.filled(word.length, '_').join(' '),
      'livesLeft': 6,
      'guessedLetters': {}, // push ile ekleyeceğiz
    });

    return code;
  }

  Future<bool> joinRoom(String code) async {
    final ref = _db.child('rooms/$code');
    final snapshot = await ref.get();
    if (!snapshot.exists) return false;

    await ref.update({'guestJoined': true});
    return true;
  }

  Future<void> startGame(String code) async {
    await _db.child('rooms/$code').update({'status': 'playing'});
  }

  Stream<DatabaseEvent> roomStream(String code) {
    return _db.child('rooms/$code').onValue;
  }

  // ✅ EKLENDİ: HANGMAN HARF TAHMİNİ
  Future<void> guessLetter({
    required String roomCode,
    required String letter,
  }) async {
    final ref = _db.child('rooms/$roomCode');
    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    final word = (data['word'] ?? '').toString();
    final masked = (data['maskedWord'] ?? '').toString().split(' ');
    int lives = (data['livesLeft'] ?? 6) as int;

    // Daha önce tahmin edildiyse tekrar işleme
    final guessedMapRaw = data['guessedLetters'];
    final guessed = <String>{};
    if (guessedMapRaw != null) {
      final gm = Map<String, dynamic>.from(guessedMapRaw as Map);
      guessed.addAll(gm.values.map((e) => e.toString()));
    }
    if (guessed.contains(letter)) return;

    bool correct = false;

    for (int i = 0; i < word.length; i++) {
      if (word[i] == letter) {
        masked[i] = letter;
        correct = true;
      }
    }

    if (!correct) lives = lives - 1;

    // guessedLetters'a ekle (push => map)
    await ref.child('guessedLetters').push().set(letter);

    await ref.update({
      'maskedWord': masked.join(' '),
      'livesLeft': lives,
    });
  }
}
