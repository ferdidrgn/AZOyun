import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

// ════════════════════════════════════════════════════════════════════════════
// DATA
// ════════════════════════════════════════════════════════════════════════════

const _wordBank = [
  'ELMA','KALEM','KAPI','MASA','SU','EV','ARABA','KEDI','KOPEK',
  'GUNES','AY','YILDIZ','DENIZ','DAG','ORMAN','CICEK','AGAC',
  'KITAP','KALEM','SILGI','CETVEL','DEFTER','CANTA','SANDALYE',
  'BILGISAYAR','TELEFON','TABLET','KLAVYE','FARE','EKRAN',
  'FUTBOL','BASKETBOL','TENIS','YUZME','BISIKLET',
  'EKMEK','SUT','YAG','SEKER','TUZ','BIBER','DOMATES','SALATALIK',
];

// ════════════════════════════════════════════════════════════════════════════
// LOBBY
// ════════════════════════════════════════════════════════════════════════════

class WordLobbyScreen extends StatefulWidget {
  const WordLobbyScreen({super.key});

  @override
  State<WordLobbyScreen> createState() => _WordLobbyScreenState();
}

class _WordLobbyScreenState extends State<WordLobbyScreen> {
  final _rooms    = RoomService.instance;
  final _storage  = StorageService.instance;
  final _codeCtrl = TextEditingController();

  String? _playerName;
  bool    _loading = false;

  @override
  void initState() { super.initState(); _loadName(); }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _loadName() async {
    final n = await _storage.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _playerName = n);
    else _askName();
  }

  Future<void> _askName() async {
    final name = await showNameDialog(context,
        current: _playerName, accentColor: const Color(0xFF00f2fe));
    if (name == null || !mounted) return;
    await _storage.setPlayerName(name);
    setState(() => _playerName = name);
  }

  Future<void> _createRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    setState(() => _loading = true);
    try {
      final code  = _rooms.generateCode();
      final seed  = Random().nextInt(100000);
      final id    = await _rooms.createRoom(
        gamePath: GamePaths.wordPuzzle,
        data: {
          'code': code, 'status': 'waiting',
          'createdAt': ServerValue.timestamp,
          'gameDuration': 60, 'seed': seed,
          'players': {'p1': {'name': _playerName, 'isHost': true, 'score': 0}},
        },
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          WordRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!)));
    } catch (e) { _snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _joinRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.wordPuzzle, code: code);
      if (r == null) { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { _snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 4) { _snack('Oda dolu'); return; }
      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(gamePath: GamePaths.wordPuzzle, roomId: r.id,
          updates: {'players/$myKey': {'name': _playerName, 'isHost': false, 'score': 0}});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          WordRoomScreen(roomId: r.id, myKey: myKey, myName: _playerName!)));
    } catch (e) { _snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradCyan,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context))),
          const SizedBox(height: 8),
          const Text('🔤', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          const Text('KELİME BULMACA',
              style: TextStyle(color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('2-4 Oyuncu · 60 Saniye · Harf karıştır kelime yap',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 28),
          GestureDetector(onTap: _askName, child: AZFrostCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_playerName ?? 'Ad seç', style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Icon(Icons.edit_rounded, color: Colors.white60, size: 14),
            ]),
          )),
          const SizedBox(height: 36),
          AZButton(label: 'YENİ ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
              onPressed: _createRoom, color: const Color(0xFF00f2fe),
              loading: _loading, width: 300),
          const SizedBox(height: 28),
          const Text('— veya —', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 28),
          AZFrostCard(child: Column(children: [
            AZCodeField(controller: _codeCtrl),
            const SizedBox(height: 14),
            AZJoinButton(onPressed: _joinRoom, loading: _loading),
          ])),
          const SizedBox(height: 32),
          AZFrostCard(opacity: 0.08, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('🔤  Nasıl oynanır?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 10),
                Text('• Verilen harflerden kelimeler oluştur\n'
                    '• 60 saniye süren yarışma\n'
                    '• Uzun kelimeler daha çok puan\n'
                    '• En çok puan toplayan kazanır',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.65)),
              ])),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROOM
// ════════════════════════════════════════════════════════════════════════════

class WordRoomScreen extends StatefulWidget {
  const WordRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;

  @override
  State<WordRoomScreen> createState() => _WordRoomScreenState();
}

class _WordRoomScreenState extends State<WordRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId)
        .listen(_onData);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_navigating) {
      _navigating = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          WordGameScreen(roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)));
    }
  }

  Map    get _players  => (_room['players'] as Map?) ?? {};
  String get _code     => _room['code'] ?? '------';
  bool   get _isHost   => widget.myKey == 'p1';
  bool   get _canStart => _players.length >= 2;

  Future<void> _start() async {
    if (!_canStart) { _snack('En az 2 oyuncu'); return; }
    await _rooms.updateRoom(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId,
        updates: {'status': 'playing', 'startTime': ServerValue.timestamp});
  }

  Future<void> _leave() async {
    if (_isHost) await _rooms.deleteRoom(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId);
    else await _rooms.removePlayer(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId, playerKey: widget.myKey);
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, onPopInvoked: (_) => _leave(),
      child: AZGradientScaffold(gradient: AZColors.gradCyan,
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
            const Expanded(child: Text('KELİME BULMACA', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 20),
          AZRoomCode(code: _code, accentColor: const Color(0xFF00f2fe)),
          const SizedBox(height: 20),
          AZFrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Oyuncular (${_players.length}/4)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            for (final slot in ['p1', 'p2', 'p3', 'p4'])
              AZPlayerTile(name: (_players[slot]?['name'] as String?) ?? slot,
                  isMe: slot == widget.myKey, isHost: _players[slot]?['isHost'] == true,
                  emoji: '🔤', present: _players.containsKey(slot)),
            if (!_canStart) Padding(padding: const EdgeInsets.only(top: 8),
                child: Row(children: const [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
                  SizedBox(width: 8),
                  Text('Rakip bekleniyor...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ])),
          ])),
          const Spacer(),
          if (_isHost)
            AZButton(label: 'OYUNU BAŞLAT', icon: Icons.play_arrow_rounded,
                onPressed: _canStart ? _start : null,
                color: const Color(0xFF00f2fe), width: double.infinity)
          else
            const AZWaitingCard(message: 'Host oyunu başlatacak...'),
        ])),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GAME
// ════════════════════════════════════════════════════════════════════════════

class WordGameScreen extends StatefulWidget {
  const WordGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen> with TickerProviderStateMixin {
  final _db  = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;

  // Local game state
  List<String> _letters     = [];
  List<String> _selected    = [];
  Set<String>  _foundWords  = {};
  int          _myScore     = 0;
  int          _timeLeft    = 60;
  Timer?       _timer;
  bool         _gameOver    = false;

  late AnimationController _successCtrl;
  late Animation<double>   _successScale;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.wordPuzzle}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFirebase);

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));

    _generateLetters();
    _startTimer();
  }

  @override
  void dispose() { _timer?.cancel(); _successCtrl.dispose(); _sub?.cancel(); super.dispose(); }

  void _onFirebase(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() => _room = d);
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 300), _showFinal);
    }
  }

  void _generateLetters() {
    final seed    = (_room['seed'] as int?) ?? 42;
    final rng     = Random(seed);
    const vowels  = 'AEIİOÖUÜ';
    const consonants = 'BCÇDFGĞHJKLMNPRSŞTVYZ';
    _letters = [
      ...List.generate(5, (_) => String.fromCharCode(vowels.codeUnitAt(rng.nextInt(vowels.length)))),
      ...List.generate(7, (_) => String.fromCharCode(consonants.codeUnitAt(rng.nextInt(consonants.length)))),
    ]..shuffle(rng);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _endGame();
      }
    });
  }

  Future<void> _endGame() async {
    setState(() => _gameOver = true);
    await _ref.update({
      'players/${widget.myKey}/score': _myScore,
      'players/${widget.myKey}/done':  true,
    });
    // Wait for all players
    await Future.delayed(const Duration(seconds: 3));
    await _ref.update({'status': 'finished'});
  }

  void _tapLetter(int idx) {
    if (_gameOver || _selected.contains('$idx')) return;
    setState(() => _selected.add('$idx'));
  }

  void _removeLast() {
    if (_selected.isEmpty) return;
    setState(() => _selected.removeLast());
  }

  Future<void> _submitWord() async {
    final word = _selected.map((i) => _letters[int.parse(i)]).join();
    if (word.length < 2) return;

    if (_wordBank.contains(word) && !_foundWords.contains(word)) {
      _foundWords.add(word);
      final pts = word.length * 10;
      setState(() { _myScore += pts; _selected = []; });
      _successCtrl.forward(from: 0);
      HapticFeedback.mediumImpact();
      _snack('✅ $word  +$pts puan!');
    } else {
      _snack('❌ Geçersiz kelime');
      setState(() => _selected = []);
    }
  }

  void _showFinal() {
    if (!mounted) return;
    final players = (_room['players'] as Map?) ?? {};
    final sorted  = players.entries.toList()
      ..sort((a, b) => ((b.value['score'] as int?) ?? 0)
          .compareTo((a.value['score'] as int?) ?? 0));
    const medals = ['🥇', '🥈', '🥉', '4.'];

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🔤 Süre Doldu!', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: sorted.asMap().entries.map((e) {
            final isMe  = e.value.key == widget.myKey;
            final score = (e.value.value['score'] as int?) ?? 0;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: isMe ? Colors.cyan.shade50 : null,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text(e.key < medals.length ? medals[e.key] : '?',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value.value['name'] ?? e.value.key,
                    style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 16))),
                Text('$score puan', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            );
          }).toList(),
        ),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00f2fe)),
          onPressed: () async {
            await _db.child('${GamePaths.wordPuzzle}/${widget.roomId}').remove();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 1)));

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final players = (_room['players'] as Map?) ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(child: Column(children: [
        // Top bar
        Container(
          color: const Color(0xFF00f2fe),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _timeLeft <= 10 ? Colors.red : Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('⏱ $_timeLeft',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _timeLeft <= 10 ? Colors.white : const Color(0xFF00f2fe))),
            ),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end,
              children: players.entries.map((e) {
                final isMe  = e.key == widget.myKey;
                final score = (e.key == widget.myKey) ? _myScore : ((e.value['score'] as int?) ?? 0);
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: isMe ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${e.value['name']}: $score',
                      style: TextStyle(
                          color: isMe ? const Color(0xFF00f2fe) : Colors.white,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                );
              }).toList(),
            )),
          ]),
        ),

        Expanded(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Current word display
            AnimatedBuilder(
              animation: _successScale,
              builder: (_, child) => Transform.scale(scale: _successScale.value, child: child),
              child: Container(
                width: double.infinity, height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00f2fe), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)]),
                child: Text(
                  _selected.isEmpty ? '...' : _selected.map((i) => _letters[int.parse(i)]).join(' '),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      letterSpacing: 6, color: Color(0xFF00838F)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Found words
            if (_foundWords.isNotEmpty)
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _foundWords.map((w) => Chip(
                  label: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: const TextStyle(color: Colors.green),
                )).toList(),
              ),
            const Spacer(),

            // Letter grid
            Wrap(
              spacing: 10, runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _letters.asMap().entries.map((e) {
                final idx      = e.key;
                final letter   = e.value;
                final isUsed   = _selected.contains('$idx');
                return GestureDetector(
                  onTap: () => _tapLetter(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: isUsed ? const Color(0xFF00f2fe) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isUsed ? [] : const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Center(child: Text(letter,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                            color: isUsed ? Colors.white : Colors.black87))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _removeLast,
                icon: const Icon(Icons.backspace_outlined),
                label: const Text('Sil'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: FilledButton.icon(
                onPressed: _submitWord,
                icon: const Icon(Icons.check_rounded),
                label: const Text('KONTROL ET', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00f2fe),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
            ]),
            const SizedBox(height: 12),
          ]),
        )),
      ])),
    );
  }
}
