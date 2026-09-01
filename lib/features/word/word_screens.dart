import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

const _wordBank = [
  'ELMA','KALEM','KAPI','MASA','SU','EV','ARABA','KEDI','KOPEK',
  'GUNES','AY','YILDIZ','DENIZ','DAG','ORMAN','CICEK','AGAC',
  'KITAP','SILGI','CETVEL','DEFTER','CANTA','SANDALYE',
  'BILGISAYAR','TELEFON','TABLET','KLAVYE','FARE','EKRAN',
  'FUTBOL','BASKETBOL','TENIS','YUZME','BISIKLET',
  'EKMEK','SUT','YAG','SEKER','TUZ','BIBER','DOMATES','SALATALIK',
  'PENCERE','TAVAN','ZEMIN','DUVAR','BAHCE','BALKON',
  'KAPLAN','ASLAN','KARTAL','PENGUEN','YUNUS','ZEBRA',
  'GITAR','PIYANO','KEMAN','DAVUL','TROMPET',
];

class WordLobbyScreen extends StatefulWidget {
  const WordLobbyScreen({super.key});
  @override State<WordLobbyScreen> createState() => _WordLobbyScreenState();
}

class _WordLobbyScreenState extends State<WordLobbyScreen> {
  final _rooms    = RoomService.instance;
  final _storage  = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _playerName; bool _loading = false;
  static const _kCyan = Color(0xFF7FA79B);

  @override void initState() { super.initState(); _loadName(); }
  @override void dispose()   { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _loadName() async {
    final n = await _storage.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _playerName = n);
    else _askName();
  }
  Future<void> _askName() async {
    final name = await showNameDialog(context, current: _playerName, accentColor: _kCyan);
    if (name == null || !mounted) return;
    await _storage.setPlayerName(name);
    setState(() => _playerName = name);
  }
  Future<void> _createRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final seed = Random().nextInt(100000);
      final id   = await _rooms.createRoom(
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
    } catch (e) { context.snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _joinRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { context.snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.wordPuzzle, code: code);
      if (r == null)                     { context.snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { context.snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 4)           { context.snack('Oda dolu'); return; }
      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(gamePath: GamePaths.wordPuzzle, roomId: r.id,
          updates: {'players/$myKey': {'name': _playerName, 'isHost': false, 'score': 0}});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          WordRoomScreen(roomId: r.id, myKey: myKey, myName: _playerName!)));
    } catch (e) { context.snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradCyan,
      child: Column(children: [
        Expanded(child: SingleChildScrollView(
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
            AZNameChip(name: _playerName, onTap: _askName),
            const SizedBox(height: 36),
            AZButton(label: 'YENİ ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
                onPressed: _createRoom, color: _kCyan, loading: _loading, width: 300),
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
        )),
        const AdaptiveBannerAdWidget(),
      ]),
    );
  }
}

class WordRoomScreen extends StatefulWidget {
  const WordRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<WordRoomScreen> createState() => _WordRoomScreenState();
}

class _WordRoomScreenState extends State<WordRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;
  static const _kCyan = Color(0xFF7FA79B);

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId)
        .listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

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
    if (!_canStart) { context.snack('En az 2 oyuncu'); return; }
    await _rooms.updateRoom(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId,
        updates: {'status': 'playing', 'startTime': ServerValue.timestamp});
  }
  Future<void> _leave() async {
    await _rooms.leaveRoom(
        gamePath:  GamePaths.wordPuzzle,
        roomId:    widget.roomId,
        playerKey: widget.myKey,
        isHost:    _isHost);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AZLeaveGuard(onLeave: _leave,
      child: AZGradientScaffold(gradient: AZColors.gradCyan,
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          AZRoomHeader(title: 'KELİME BULMACA', onClose: _leave),
          const SizedBox(height: 20),
          AZRoomCode(code: _code, accentColor: _kCyan),
          const SizedBox(height: 20),
          AZFrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Oyuncular (${_players.length}/4)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            for (final slot in ['p1', 'p2', 'p3', 'p4'])
              AZPlayerTile(
                  name:    (_players[slot]?['name'] as String?) ?? slot,
                  isMe:    slot == widget.myKey,
                  isHost:  _players[slot]?['isHost'] == true,
                  emoji:   '🔤', present: _players.containsKey(slot)),
            if (!_canStart) Padding(padding: const EdgeInsets.only(top: 8),
                child: Row(children: const [
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
                  SizedBox(width: 8),
                  Text('Rakip bekleniyor...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ])),
          ])),
          const Spacer(),
          if (_isHost)
            AZButton(label: 'OYUNU BAŞLAT', icon: Icons.play_arrow_rounded,
                onPressed: _canStart ? _start : null,
                color: _kCyan, width: double.infinity)
          else
            const AZWaitingCard(message: 'Host oyunu başlatacak...'),
        ])),
      ),
    );
  }
}

class WordGameScreen extends StatefulWidget {
  const WordGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen>
    with TickerProviderStateMixin {
  final _db   = FirebaseDatabase.instance.ref();
  final _rooms = RoomService.instance;
  late  DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  bool _roomGone = false;

  List<String> _letters  = [];
  List<int>    _selected = [];
  Set<String>  _foundWords = {};
  int          _myScore  = 0;
  int          _timeLeft = 60;
  Timer?       _timer;
  bool         _gameOver = false;
  int?         _startTimeMs;
  int          _gameDurationSec = 60;

  late AnimationController _successCtrl;
  late Animation<double>   _successScale;
  static const _kCyan = Color(0xFF7FA79B);

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.wordPuzzle}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFirebase);
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
  }
  @override
  void dispose() { _timer?.cancel(); _successCtrl.dispose(); _sub?.cancel(); super.dispose(); }

  void _onFirebase(DatabaseEvent e) {
    if (!mounted) return;
    if (e.snapshot.value == null) {
      // Oda silindi (host ayrıldı ya da bağlantısı koptu) — eskiden burada
      // sessizce return edilirdi ve diğer oyuncuların ekranı sonsuza dek
      // donuk kalırdı. Artık herkesi ana menüye döndürüyoruz.
      if (!_roomGone) {
        _roomGone = true;
        Navigator.popUntil(context, (r) => r.isFirst);
      }
      return;
    }
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() => _room = d);
    if (_startTimeMs == null) {
      final st = d['startTime'];
      if (st is int) {
        _startTimeMs = st;
        _gameDurationSec = (d['gameDuration'] as int?) ?? 60;
        _generateLetters((d['seed'] as int?) ?? 42);
        _startTimer();
      }
    }
    // Bir oyuncu, süresi henüz DOLMAMIŞ başka oyuncular varken erken
    // bitirmiş olabilir (bkz. _endGame). Eskiden herkes kendi süresi
    // dolduğunda KAYITSIZ ŞARTSIZ 'status':'finished' yazıyordu — bu,
    // ağ/navigasyon gecikmesi yüzünden geç başlayan oyuncuların oyununu
    // erken kesiyordu. Artık sadece HERKES bitirdiğinde sonlanır.
    if (d['status'] != 'finished') {
      final players = Map<String, dynamic>.from((d['players'] as Map?) ?? {});
      if (players.isNotEmpty && players.values.every((p) => p['done'] == true)) {
        _ref.update({'status': 'finished'});
      }
    }
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      _timer?.cancel();
      AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 300), _showFinal);
    }
  }

  void _generateLetters(int seed) {
    final rng = Random(seed);
    // Kelime bankasındaki (ASCII normalize) kelimelerin ~15'i düz "I"
    // (noktasız) harfi içeriyor (KAPI, KEDI, YILDIZ, DENIZ, ...) — bu harf
    // havuzda hiç yoktu, o kelimeler tahtada asla kurulamıyordu.
    const vowels     = 'AEİIOÖUÜ';
    const consonants = 'BCÇDFGĞHJKLMNPRSŞTVYZ';
    _letters = [
      ...List.generate(5, (_) => vowels[rng.nextInt(vowels.length)]),
      ...List.generate(7, (_) => consonants[rng.nextInt(consonants.length)]),
    ]..shuffle(rng);
  }

  // Geri sayım artık odanın paylaşılan 'startTime' sunucu zaman damgasından
  // hesaplanıyor — önceden her oyuncu KENDİ ekranı açıldığı anda bağımsız
  // bir 60 saniyelik sayaç başlatıyordu, bu yüzden ağ/navigasyon gecikmesi
  // farkına göre bazı oyuncuların süresi diğerlerinden önce/sonra bitiyordu.
  void _startTimer() {
    void tick() {
      if (!mounted) return;
      final elapsed = DateTime.now().millisecondsSinceEpoch - _startTimeMs!;
      final remaining = _gameDurationSec - (elapsed / 1000).floor();
      if (remaining <= 0) {
        _timer?.cancel();
        setState(() => _timeLeft = 0);
        _endGame();
      } else {
        setState(() => _timeLeft = remaining);
      }
    }
    tick();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  Future<void> _endGame() async {
    if (_gameOver) return;
    setState(() => _gameOver = true);
    // Sadece kendi skorumu/bitişimi yazıyorum — oyunu kayıtsız şartsız
    // 'finished' yapmıyorum. Süresi henüz dolmamış başka oyuncular varsa
    // onların oyununu erken kesmemek için, bitiş SADECE herkes bitirdiğinde
    // gerçekleşir (bkz. _onFirebase'deki "hepsi done mı" kontrolü).
    await _ref.update({
      'players/${widget.myKey}/score': _myScore,
      'players/${widget.myKey}/done':  true,
    });
  }

  void _tapLetter(int idx) {
    if (_gameOver || _selected.contains(idx)) return;
    setState(() => _selected.add(idx));
  }
  void _removeLast()    { if (_selected.isEmpty) return; setState(() => _selected.removeLast()); }
  void _clearSelection() => setState(() => _selected = []);

  Future<void> _submitWord() async {
    if (_selected.isEmpty) return;
    final word = _selected.map((i) => _letters[i]).join();
    if (word.length < 2) return;
    if (_wordBank.contains(word) && !_foundWords.contains(word)) {
      final pts = word.length * 10;
      setState(() { _foundWords.add(word); _myScore += pts; _selected = []; });
      _successCtrl.forward(from: 0);
      HapticFeedback.mediumImpact();
      context.snack('✅ $word  +$pts puan!');
    } else {
      context.snack('❌ ${_wordBank.contains(word) ? "Zaten bulundu!" : "Geçersiz kelime"}');
      _clearSelection();
    }
  }

  void _showFinal() {
    if (!mounted) return;
    final players = (_room['players'] as Map?) ?? {};
    final sorted  = players.entries.toList()
      ..sort((a, b) => ((b.value['score'] as int?) ?? 0)
          .compareTo((a.value['score'] as int?) ?? 0));
    final iWon = sorted.isNotEmpty && sorted.first.key == widget.myKey;
    ProfileService.instance
        .reportGameResult(gameId: 'word', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());
    const medals = ['🥇', '🥈', '🥉', '4.'];
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🔤 Süre Doldu!', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: sorted.asMap().entries.map((e) {
            final isMe  = e.value.key == widget.myKey;
            final score = e.key == 0 && isMe ? _myScore
                : (e.value.value['score'] as int?) ?? 0;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: isMe ? Theme.of(context).colorScheme.primary.withAlpha(28) : null,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text(e.key < medals.length ? medals[e.key] : '?',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value.value['name'] as String? ?? e.value.key,
                    style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 16))),
                Text('$score puan', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            );
          }).toList(),
        ),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kCyan),
          onPressed: () async {
            await _db.child('${GamePaths.wordPuzzle}/${widget.roomId}').remove();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  /// Aktif oyunda önceden HİÇBİR çıkış yolu yoktu — biri süresi bitmeden
  /// ayrılırsa, kalanlar "hepsi bitirsin" kontrolünde sonsuza dek beklerdi.
  Future<void> _leaveGame() async {
    final players = Map<String, dynamic>.from((_room['players'] as Map?) ?? {});
    final remaining = Map<String, dynamic>.from(players)..remove(widget.myKey);
    if (remaining.isEmpty) {
      await _rooms.deleteRoom(gamePath: GamePaths.wordPuzzle, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(
          gamePath: GamePaths.wordPuzzle, roomId: widget.roomId, playerKey: widget.myKey);
      if (remaining.values.every((p) => (p as Map)['done'] == true)) {
        await _ref.update({'status': 'finished'});
      }
    }
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmLeave() async {
    final ok = await confirmLeaveGame(
      context,
      title:   'Oyundan çık?',
      message: 'Aktif bir oyunun ortasındasın. Çıkarsan bu geri alınamaz.',
    );
    if (ok) await _leaveGame();
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty || _letters.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final players = (_room['players'] as Map?) ?? {};
    final current = _selected.map((i) => _letters[i]).join();

    return AZLeaveGuard(
      onLeave: _confirmLeave,
      child: Scaffold(
      backgroundColor: const Color(0xFFE6EEEC),
      body: SafeArea(child: Column(children: [

        // Score bar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color.lerp(_kCyan, Colors.black, 0.12)!, _kCyan],
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _confirmLeave),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _timeLeft <= 10 ? AZColors.red : Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('⏱ $_timeLeft',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: _timeLeft <= 10 ? Colors.white : _kCyan)),
            ),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end,
              children: players.entries.map((e) {
                final isMe  = e.key == widget.myKey;
                final score = isMe ? _myScore : ((e.value['score'] as int?) ?? 0);
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: isMe ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${e.value['name']}: $score',
                      style: TextStyle(color: isMe ? _kCyan : Colors.white,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                );
              }).toList(),
            )),
          ]),
        ),

        if (_gameOver)
          Container(
            width: double.infinity,
            color: const Color(0xFF4F7A79),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text('⏳ Süren doldu! Diğer oyuncular bekleniyor...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),

        Expanded(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            AnimatedBuilder(
              animation: _successScale,
              builder: (_, child) => Transform.scale(scale: _successScale.value, child: child),
              child: Container(
                width: double.infinity, height: 64, alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kCyan, width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)]),
                child: Text(
                  current.isEmpty ? '...' : current.split('').join(' '),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      letterSpacing: 6, color: Color(0xFF4F7A79)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_foundWords.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 6,
                children: _foundWords.map((w) => Chip(
                  label: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: const TextStyle(color: Colors.green),
                )).toList()),
            const Spacer(),
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: _letters.asMap().entries.map((e) {
                final isUsed = _selected.contains(e.key);
                return GestureDetector(
                  onTap: () => _tapLetter(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: isUsed ? _kCyan : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isUsed
                          ? [BoxShadow(color: _kCyan.withAlpha(140), blurRadius: 6, offset: const Offset(0, 1))]
                          : const [
                              BoxShadow(color: Color(0x28000000), blurRadius: 6, offset: Offset(0, 4)),
                            ],
                    ),
                    child: Center(child: Text(e.value,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                            color: isUsed ? Colors.white : Colors.black87))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
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
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _clearSelection,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                child: const Icon(Icons.clear),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: FilledButton.icon(
                onPressed: _submitWord,
                icon: const Icon(Icons.check_rounded),
                label: const Text('KONTROL ET',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(backgroundColor: _kCyan,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
            ]),
            const SizedBox(height: 8),
          ]),
        )),

        // Banner reklam
        const BannerAdWidget(),
      ])),
      ),
    );
  }
}
