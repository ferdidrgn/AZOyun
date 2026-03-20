// ═══════════════════════════════════════════════════════════════════
// ADAM ASMACA  —  Production-ready multiplayer
// ═══════════════════════════════════════════════════════════════════
//
// Firebase schema  hangman_rooms/<roomId>
//   code          : String   6-char room code
//   status        : String   'waiting' | 'playing' | 'finished'
//   round         : int      1..maxRounds
//   maxRounds     : int      default 6
//   phase         : String   'choose' | 'play' | 'result'
//   chooser       : String   'p1' | 'p2'   (who picks the word)
//   players/p1    : { name, score, isHost }
//   players/p2    : { name, score }
//   game          : {
//     word        : String   uppercase
//     guessed     : [String] letters guessed so far
//     wrong       : int      0..6
//   }
//   result        : {
//     winner      : String   'p1' | 'p2'
//     word        : String   revealed word
//     reason      : 'found' | 'hanged'
//   }
//
// Phase flow
//   waiting   → (host presses start)
//   playing   → phase='choose', chooser='p1'
//             → chooser writes word   → phase='play'
//             → guesser finds/fails   → phase='result', result={...}
//             → (ONLY HOST calls advance) round++, swap chooser, phase='choose'
//             → ... repeat maxRounds rounds ...
//   finished (status set in last result write)
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

// ─── word list (Turkish-safe uppercase) ─────────────────────────────────────

const _words = [
  'FLUTTER','ANDROID','KOTLIN','PYTHON','JAVASCRIPT','YAZILIM',
  'BILGISAYAR','PROGRAMLAMA','INTERNET','VERITABANI','ALGORITMA',
  'FUTBOL','BASKETBOL','TENIS','YUZME','BISIKLET','OLIMPIYAT',
  'SAMPIYONA','STADYUM','ANTRENMAN','VOLEYBOL','ATLETIZM',
  'ISTANBUL','ANKARA','IZMIR','ANTALYA','BURSA','TRABZON',
  'KONYA','ADANA','ESKISEHIR','GAZIANTEP','SAMSUN','DIYARBAKIR',
  'KAPLAN','ASLAN','KARTAL','PENGUEN','YUNUS','ZEBRA',
  'GITAR','PIYANO','KEMAN','DAVUL','TROMPET','SAKSAFON',
  'MELODI','KONSER','ORKESTRA','SENFONI','OPERA','BALE',
  'TATIL','SEYAHAT','UCAK','PASAPORT','OTEL','PLAJ',
  'MUTFAK','PENCERE','BALKON','BAHCE','MERDIVEN','TAVAN',
  'ELMA','ARMUT','MANGO','KIRAZ','PORTAKAL','AVOKADO',
  'ASTRONOT','GALAKSI','METEOR','YILDIZ','GEZEGEN','ROKET',
  'DOKTOR','MUHENDIS','OGRETMEN','AVUKAT','PILOT','MIMAR',
  'KITAP','ROMAN','SENARYO','MAKALE','DERGI','GAZETE',
];

// ─── colours ────────────────────────────────────────────────────────────────

const _red   = Color(0xFFD32F2F);
const _redLt = Color(0xFFFFEBEE);
const _green = Color(0xFF2E7D32);
const _grey  = Color(0xFF9E9E9E);
const _bgCol = Color(0xFFFAFAFA);

// ════════════════════════════════════════════════════════════════════════════
// LOBBY
// ════════════════════════════════════════════════════════════════════════════

class HangmanLobbyScreen extends StatefulWidget {
  const HangmanLobbyScreen({super.key});
  @override State<HangmanLobbyScreen> createState() => _HangmanLobbyState();
}

class _HangmanLobbyState extends State<HangmanLobbyScreen> {
  final _rooms   = RoomService.instance;
  final _store   = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _name;
  bool _busy = false;

  @override void initState() { super.initState(); _init(); }
  @override void dispose()  { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _init() async {
    final n = await _store.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _name = n);
    else                           _askName();
  }

  Future<void> _askName() async {
    final c = TextEditingController(text: _name);
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('👤 Adınız'),
        content: TextField(controller: c, autofocus: true, maxLength: 12,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Oyun içi adınız'),
          onSubmitted: (_) => _saveName(c.text)),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _red),
          onPressed: () => _saveName(c.text), child: const Text('Tamam'))],
      ),
    );
  }

  Future<void> _saveName(String raw) async {
    final n = raw.trim(); if (n.isEmpty) return;
    await _store.setPlayerName(n);
    setState(() => _name = n);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _create() async {
    if (_name == null) { await _askName(); if (_name == null) return; }
    setState(() => _busy = true);
    try {
      final code = _rooms.generateCode();
      final id   = await _rooms.createRoom(
        gamePath: GamePaths.hangman,
        data: {
          'code': code, 'status': 'waiting',
          'createdAt': ServerValue.timestamp,
          'round': 0, 'maxRounds': 6,
          'phase': 'lobby', 'chooser': 'p1',
          'players': {'p1': {'name': _name, 'score': 0, 'isHost': true}},
        },
      );
      if (!mounted) return;
      _go(HangmanRoomScreen(roomId: id, myKey: 'p1', myName: _name!));
    } catch (e) { _snack('Oda oluşturulamadı'); }
    finally     { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _join() async {
    if (_name == null) { await _askName(); if (_name == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kod girin'); return; }
    setState(() => _busy = true);
    try {
      final r = await _rooms.findByCode(path: GamePaths.hangman, code: code);
      if (r == null)                        { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting')    { _snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 2)              { _snack('Oda dolu'); return; }
      await _rooms.update(GamePaths.hangman, r.id,
        {'players/p2': {'name': _name, 'score': 0, 'isHost': false}});
      if (!mounted) return;
      _go(HangmanRoomScreen(roomId: r.id, myKey: 'p2', myName: _name!));
    } catch (e) { _snack('Katılınamadı'); }
    finally     { if (mounted) setState(() => _busy = false); }
  }

  void _go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        Align(alignment: Alignment.centerLeft,
          child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context))),
        const SizedBox(height: 8),
        const Text('🎯', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 8),
        const Text('ADAM ASMACA',
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text('2 Oyuncu · 6 Tur · ${_words.length} Kelime',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 32),

        // name badge
        GestureDetector(onTap: _askName, child: FrostCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(_name ?? 'Ad seç',
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            const Icon(Icons.edit, color: Colors.white60, size: 14),
          ]))),
        const SizedBox(height: 40),

        BigButton(label: 'YENİ ODA OLUŞTUR', icon: Icons.add_circle_outline,
          onPressed: _create, color: _red, loading: _busy),
        const SizedBox(height: 28),
        const Text('— veya —', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 28),

        FrostCard(child: Column(children: [
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]'))],
            maxLength: 6, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.white),
            decoration: InputDecoration(
              counterText: '', hintText: 'ODA KODU', hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
              filled: true, fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 12),
          JoinButton(onPressed: _join, loading: _busy),
        ])),
        const SizedBox(height: 32),

        FrostCard(opacity: 0.08, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Nasıl oynanır?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 8),
          Text('• P1 kelime seçer, P2 tahmin eder\n'
               '• Her tur roller değişir (6 tur toplam)\n'
               '• Doğru tahmin → +10 puan (hata başına −1)\n'
               '• Adam asılırsa kelimeyi seçen +5 puan alır',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
        ])),
        const SizedBox(height: 24),
      ])),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROOM  (bekleme odası)
// ════════════════════════════════════════════════════════════════════════════

class HangmanRoomScreen extends StatefulWidget {
  const HangmanRoomScreen({super.key, required this.roomId, required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<HangmanRoomScreen> createState() => _HangmanRoomState();
}

class _HangmanRoomState extends State<HangmanRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(GamePaths.hangman, widget.roomId).listen(_onData);
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HangmanGameScreen(
          roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)));
    }
  }

  Map    get _players  => (_room['players'] as Map?) ?? {};
  String get _code     => _room['code'] ?? '------';
  bool   get _amHost   => widget.myKey == 'p1';
  bool   get _canStart => _players.length >= 2;

  Future<void> _start() async {
    if (!_canStart) { _snack('Rakip bekleniyor...'); return; }
    // Start game: phase='choose', chooser='p1', round=1
    await _rooms.update(GamePaths.hangman, widget.roomId, {
      'status': 'playing', 'round': 1, 'phase': 'choose',
      'chooser': 'p1', 'game': null, 'result': null,
    });
  }

  Future<void> _leave() async {
    if (_amHost) await _rooms.delete(GamePaths.hangman, widget.roomId);
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, onPopInvoked: (_) => _leave(),
      child: GradientScaffold(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
            const Expanded(child: Text('ADAM ASMACA', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 20),

          AZCard(child: Column(children: [
            const Text('ODA KODU', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_code, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold,
                letterSpacing: 10, color: _red)),
              IconButton(icon: const Icon(Icons.copy, color: _red), onPressed: () {
                Clipboard.setData(ClipboardData(text: _code));
                _snack('Kopyalandı!');
              }),
            ]),
            const Text('Arkadaşınla paylaş', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          const SizedBox(height: 20),

          FrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Oyuncular (${_players.length}/2)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            _RoomPlayerTile(pKey: 'p1', data: _players['p1'], myKey: widget.myKey),
            const SizedBox(height: 8),
            _RoomPlayerTile(pKey: 'p2', data: _players['p2'], myKey: widget.myKey),
            if (!_canStart) Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: const [
                SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                SizedBox(width: 8),
                Text('Rakip bekleniyor...', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ])),
          ])),

          const Spacer(),

          if (_amHost)
            BigButton(
              label: 'OYUNU BAŞLAT', icon: Icons.play_arrow_rounded,
              onPressed: _canStart ? _start : null, color: _red, width: double.infinity)
          else
            FrostCard(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 14),
              Text('Host başlatacak...', style: TextStyle(color: Colors.white, fontSize: 15)),
            ])),
        ])),
      ),
    );
  }
}

class _RoomPlayerTile extends StatelessWidget {
  const _RoomPlayerTile({required this.pKey, required this.data, required this.myKey});
  final String pKey, myKey; final dynamic data;

  @override
  Widget build(BuildContext context) {
    final present = data != null;
    final isMe    = pKey == myKey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: Colors.white, width: 1.5) : null),
      child: Row(children: [
        Icon(present ? Icons.person_rounded : Icons.person_outline,
          color: present ? Colors.white : Colors.white38, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(
          present ? (data['name'] as String? ?? pKey) : 'Bekleniyor...',
          style: TextStyle(color: present ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w600, fontSize: 15))),
        if (data?['isHost'] == true) _badge('HOST', Colors.yellow, Colors.brown),
        if (isMe) ...[const SizedBox(width: 4), _badge('SEN', Colors.white30, Colors.white)],
      ]),
    );
  }

  Widget _badge(String t, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)));
}

// ════════════════════════════════════════════════════════════════════════════
// GAME
// ════════════════════════════════════════════════════════════════════════════

class HangmanGameScreen extends StatefulWidget {
  const HangmanGameScreen(
      {super.key, required this.roomId, required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<HangmanGameScreen> createState() => _HangmanGameState();
}

class _HangmanGameState extends State<HangmanGameScreen>
    with TickerProviderStateMixin {
  final _db    = FirebaseDatabase.instance.ref();
  late  DatabaseReference _ref;
  StreamSubscription? _sub;

  Map<String, dynamic> _room = {};

  // ── dialog guard: use a "handled" set keyed on (round, phase) ─────────────
  final _handled = <String>{};

  // ── shake animation on wrong guess ────────────────────────────────────────
  late final AnimationController _shakeCtrl;
  late final Animation<double>    _shakeAnim;
  int _prevWrong = 0;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.hangman}/${widget.roomId}');

    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0,  end: 0.0),  weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _sub = _ref.onValue.listen((e) {
      if (!mounted || e.snapshot.value == null) return;
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);

      // detect new wrong guess → shake
      final nw = (d['game']?['wrong'] as int?) ?? 0;
      if (nw > _prevWrong) { _prevWrong = nw; _shakeCtrl.forward(from: 0); }

      setState(() => _room = d);
      _react(d);
    });
  }

  @override
  void dispose() { _shakeCtrl.dispose(); _sub?.cancel(); super.dispose(); }

  // ── computed ───────────────────────────────────────────────────────────────

  Map    get _players  => (_room['players'] as Map?) ?? {};
  String get _phase    => (_room['phase']   as String?) ?? 'choose';
  int    get _round    => (_room['round']   as int?)    ?? 1;
  int    get _maxR     => (_room['maxRounds'] as int?)  ?? 6;
  String get _chooser  => (_room['chooser'] as String?) ?? 'p1';
  String get _guesser  => _chooser == 'p1' ? 'p2' : 'p1';
  bool   get _amHost   => widget.myKey == 'p1';
  bool   get _amChooser => _chooser == widget.myKey;
  bool   get _amGuesser => _guesser == widget.myKey;

  String? get _word    => _room['game']?['word'] as String?;
  List<String> get _guessed => List<String>.from(_room['game']?['guessed'] ?? []);
  int    get _wrong    => (_room['game']?['wrong'] as int?) ?? 0;

  String _name(String key) => (_players[key]?['name'] as String?) ?? key;
  int    _score(String key) => (_players[key]?['score'] as int?)   ?? 0;

  // ── react to Firebase changes ──────────────────────────────────────────────

  void _react(Map<String, dynamic> d) {
    final status = d['status'] as String? ?? '';
    final phase  = d['phase']  as String? ?? '';
    final round  = d['round']  as int?    ?? 1;

    if (status == 'finished') {
      final key = 'final';
      if (!_handled.contains(key)) { _handled.add(key); _showFinal(d); }
      return;
    }

    if (phase == 'result') {
      final key = 'result_$round';
      if (!_handled.contains(key)) {
        _handled.add(key);
        _showResult(d, round);
      }
    }
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _submitWord(String raw) async {
    final w = raw.toUpperCase()
      .replaceAll(RegExp(r'[^A-ZÇĞİÖŞÜ]'), '');
    if (w.length < 3) { _snack('En az 3 harf olmalı!'); return; }
    await _ref.update({
      'game': {'word': w, 'guessed': [], 'wrong': 0},
      'phase': 'play',
    });
    _prevWrong = 0;
  }

  Future<void> _guess(String letter) async {
    if (!_amGuesser || _word == null) return;
    if (_guessed.contains(letter)) return;

    final newGuessed = [..._guessed, letter];
    final hit        = _word!.contains(letter);
    final newWrong   = hit ? _wrong : _wrong + 1;

    await _ref.child('game').update({'guessed': newGuessed, 'wrong': newWrong});

    // check termination
    final allFound = _word!.split('').every(newGuessed.contains);
    if (allFound)      { await _endRound(guesserWon: true,  wrong: newWrong); return; }
    if (newWrong >= 6) { await _endRound(guesserWon: false, wrong: newWrong); }
  }

  Future<void> _endRound({required bool guesserWon, required int wrong}) async {
    final winner = guesserWon ? _guesser : _chooser;
    final bonus  = guesserWon ? (10 - wrong).clamp(4, 10) : 5;
    final prev   = _score(winner);
    final isLast = _round >= _maxR;

    final updates = <String, dynamic>{
      'phase':  'result',
      'result': {'winner': winner, 'word': _word, 'reason': guesserWon ? 'found' : 'hanged'},
      'players/$winner/score': prev + bonus,
      if (isLast) 'status': 'finished',
    };
    await _ref.update(updates);
  }

  // Only host advances to next round (prevents race condition)
  Future<void> _advance() async {
    if (!_amHost) return;
    final nextChooser = _chooser == 'p1' ? 'p2' : 'p1';
    await _ref.update({
      'round':   _round + 1,
      'chooser': nextChooser,
      'phase':   'choose',
      'game':    null,
      'result':  null,
    });
  }

  Future<void> _deleteRoom() =>
    _db.child('${GamePaths.hangman}/${widget.roomId}').remove();

  // ── dialogs ────────────────────────────────────────────────────────────────

  void _showResult(Map<String, dynamic> d, int round) {
    final result  = Map<String, dynamic>.from(d['result'] as Map);
    final winner  = result['winner']  as String;
    final word    = result['word']    as String;
    final reason  = result['reason']  as String;
    final iWon    = winner == widget.myKey;
    final isLast  = round >= ((d['maxRounds'] as int?) ?? 6);

    showDialog(context: context, barrierDismissible: false, builder: (_) => _ResultDialog(
      title:    iWon ? '🎉 Tur Kazandın!' : '😔 Tur Kaybettin',
      subtitle: reason == 'found'
        ? '${_name(winner)} kelimeyi buldu!'
        : 'Adam asıldı! ${_name(winner)} puan aldı.',
      word:     word,
      p1Name:  _name('p1'), p1Score: _score('p1'),
      p2Name:  _name('p2'), p2Score: _score('p2'),
      myKey:   widget.myKey,
      btnLabel: isLast ? 'Sonuçlara Git' : 'Sonraki Tur →',
      onBtn: () {
        Navigator.pop(context);
        if (!isLast) _advance(); // only host writes; non-host: no-op
      },
    ));
  }

  void _showFinal(Map<String, dynamic> d) {
    final p1s = _score('p1'), p2s = _score('p2');
    final p1n = _name('p1'),  p2n = _name('p2');
    final headline = p1s > p2s ? '🏆 $p1n kazandı!'
                   : p2s > p1s ? '🏆 $p2n kazandı!'
                   : '🤝 Berabere!';

    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      title: const Text('Oyun Bitti!', textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(headline, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _ScoreRow(p1Name: p1n, p2Name: p2n, p1Score: p1s, p2Score: p2s, myKey: widget.myKey),
      ]),
      actions: [FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _red),
        onPressed: () async {
          await _deleteRoom();
          if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
        },
        child: const Text('Ana Menü'))],
    ));
  }

  void _snack(String m) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(backgroundColor: _bgCol,
        body: Center(child: CircularProgressIndicator(color: _red)));
    }

    return Scaffold(
      backgroundColor: _bgCol,
      body: SafeArea(child: Column(children: [
        _TopBar(
          round: _round, maxRounds: _maxR,
          p1Name: _name('p1'), p1Score: _score('p1'), isP1Me: widget.myKey == 'p1',
          p2Name: _name('p2'), p2Score: _score('p2'),
        ),
        Expanded(child: _phase == 'choose'
          ? _buildChoose()
          : _buildPlay()),
      ])),
    );
  }

  // ── choose phase ──────────────────────────────────────────────────────────

  Widget _buildChoose() {
    if (_amChooser) return _ChooserPanel(guesserName: _name(_guesser), onSubmit: _submitWord);
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 56, height: 56,
        child: CircularProgressIndicator(strokeWidth: 3, color: _red)),
      const SizedBox(height: 24),
      Text('${_name(_chooser)} kelime seçiyor...',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Hazır ol!', style: TextStyle(color: _grey)),
    ]));
  }

  // ── play phase ────────────────────────────────────────────────────────────

  Widget _buildPlay() {
    if (_word == null) return const Center(child: CircularProgressIndicator(color: _red));
    return Column(children: [
      // role badge
      Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: (_amGuesser ? _green : Colors.orange).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _amGuesser ? _green : Colors.orange)),
        child: Text(
          _amGuesser ? '🔍 Sıra sende — harf seç!' : '👀 ${_name(_guesser)} tahmin ediyor...',
          style: TextStyle(color: _amGuesser ? _green : Colors.orange.shade800,
            fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center)),
      // hangman
      AnimatedBuilder(animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0), child: child),
        child: SizedBox(height: 190,
          child: CustomPaint(size: const Size(220, 190),
            painter: _HangmanPainter(_wrong)))),
      // wrong count
      Text('${_wrong}/6 yanlış',
        style: TextStyle(color: _wrong >= 4 ? _red : _grey, fontSize: 12,
          fontWeight: _wrong >= 5 ? FontWeight.bold : FontWeight.normal)),
      const SizedBox(height: 8),
      // word display
      _WordDisplay(word: _word!, guessed: _guessed),
      const Spacer(),
      // keyboard or wait
      if (_amGuesser)
        _TurkishKeyboard(guessed: _guessed, word: _word!, onTap: _guess)
      else
        Padding(padding: const EdgeInsets.all(16),
          child: Text('${_name(_guesser)} tahmin ediyor...',
            style: const TextStyle(color: _grey, fontStyle: FontStyle.italic, fontSize: 14))),
      const SizedBox(height: 6),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WORD CHOOSER PANEL
// ════════════════════════════════════════════════════════════════════════════

class _ChooserPanel extends StatefulWidget {
  const _ChooserPanel({required this.guesserName, required this.onSubmit});
  final String guesserName;
  final Future<void> Function(String) onSubmit;
  @override State<_ChooserPanel> createState() => _ChooserPanelState();
}

class _ChooserPanelState extends State<_ChooserPanel> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  Future<void> _go(String w) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onSubmit(w);
    if (mounted) setState(() { _busy = false; _ctrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _redLt, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline, color: _red, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '${widget.guesserName} bu kelimeyi tahmin edecek — gizli tutulur!',
              style: const TextStyle(color: _red, fontSize: 13))),
          ])),
        const SizedBox(height: 20),

        TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-ZÇĞİÖŞÜa-zçğışöü]'))],
          style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Kendi kelimenizi yazın',
            suffixIcon: IconButton(
              icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _red))
                : const Icon(Icons.send, color: _red),
              onPressed: _busy ? null : () => _go(_ctrl.text))),
          onSubmitted: (v) => _go(v)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _busy ? null : () => _go(_ctrl.text),
            child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('GÖNDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        const Text('— veya listeden seç —',
          style: TextStyle(color: _grey, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 2.6, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: _words.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: _busy ? null : () => _go(_words[i]),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _redLt, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.3))),
              child: Text(_words[i],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _red))))),
      ]));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WORD DISPLAY
// ════════════════════════════════════════════════════════════════════════════

class _WordDisplay extends StatelessWidget {
  const _WordDisplay({required this.word, required this.guessed});
  final String word; final List<String> guessed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(alignment: WrapAlignment.center, spacing: 5, runSpacing: 6,
        children: word.split('').map((l) {
          final show = guessed.contains(l);
          return SizedBox(width: 32, height: 44,
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(show ? l : '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _red)),
              const SizedBox(height: 2),
              Container(height: 2.5, decoration: BoxDecoration(
                color: show ? _red : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2))),
            ]));
        }).toList()));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TURKISH KEYBOARD
// ════════════════════════════════════════════════════════════════════════════

class _TurkishKeyboard extends StatelessWidget {
  const _TurkishKeyboard(
      {required this.guessed, required this.word, required this.onTap});
  final List<String> guessed;
  final String word;
  final Future<void> Function(String) onTap;

  static const _rows = [
    ['Q','W','E','R','T','Y','U','I','O','P','Ğ','Ü'],
    ['A','S','D','F','G','H','J','K','L','Ş','İ'],
    ['Z','X','C','V','B','N','M','Ö','Ç'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(children: _rows.map((row) =>
        Padding(padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((l) {
              final used    = guessed.contains(l);
              final correct = used && word.contains(l);
              final wrong   = used && !word.contains(l);
              return GestureDetector(
                onTap: used ? null : () => onTap(l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28, height: 36, margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: correct ? _green : wrong ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: correct ? _green : Colors.grey.shade300),
                    boxShadow: used ? [] :
                      [const BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))]),
                  child: Center(child: Text(l,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: correct ? Colors.white
                           : wrong   ? Colors.grey.shade400
                           : Colors.black87)))));
            }).toList()))).toList()));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HANGMAN PAINTER
// ════════════════════════════════════════════════════════════════════════════

class _HangmanPainter extends CustomPainter {
  const _HangmanPainter(this.wrong);
  final int wrong;

  @override
  void paint(Canvas canvas, Size s) {
    final gallows = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // gallows structure
    canvas.drawLine(Offset(s.width*.10, s.height*.95), Offset(s.width*.55, s.height*.95), gallows);
    canvas.drawLine(Offset(s.width*.22, s.height*.95), Offset(s.width*.22, s.height*.04), gallows);
    canvas.drawLine(Offset(s.width*.22, s.height*.04), Offset(s.width*.68, s.height*.04), gallows);
    canvas.drawLine(Offset(s.width*.68, s.height*.04), Offset(s.width*.68, s.height*.18), gallows);

    final body = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (wrong >= 1) {
      // head
      canvas.drawCircle(Offset(s.width*.68, s.height*.26), s.height*.08, body);
    }
    if (wrong >= 2) {
      // torso
      canvas.drawLine(Offset(s.width*.68, s.height*.34), Offset(s.width*.68, s.height*.60), body);
    }
    if (wrong >= 3) {
      // left arm
      canvas.drawLine(Offset(s.width*.68, s.height*.42), Offset(s.width*.52, s.height*.53), body);
    }
    if (wrong >= 4) {
      // right arm
      canvas.drawLine(Offset(s.width*.68, s.height*.42), Offset(s.width*.84, s.height*.53), body);
    }
    if (wrong >= 5) {
      // left leg
      canvas.drawLine(Offset(s.width*.68, s.height*.60), Offset(s.width*.52, s.height*.80), body);
    }
    if (wrong >= 6) {
      // right leg
      canvas.drawLine(Offset(s.width*.68, s.height*.60), Offset(s.width*.84, s.height*.80), body);
      // X eyes
      final dead = Paint()..color = _red..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      final cx = s.width*.68; final cy = s.height*.26;
      canvas.drawLine(Offset(cx-6, cy-6), Offset(cx+6, cy+6), dead);
      canvas.drawLine(Offset(cx+6, cy-6), Offset(cx-6, cy+6), dead);
    }
  }

  @override bool shouldRepaint(_HangmanPainter o) => o.wrong != wrong;
}

// ════════════════════════════════════════════════════════════════════════════
// SMALL REUSABLES
// ════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.round, required this.maxRounds,
    required this.p1Name, required this.p1Score, required this.isP1Me,
    required this.p2Name, required this.p2Score,
  });
  final int round, maxRounds;
  final String p1Name, p2Name; final int p1Score, p2Score; final bool isP1Me;

  @override
  Widget build(BuildContext context) => Container(
    color: _red,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      _Pill(name: p1Name, score: p1Score, isMe: isP1Me),
      Expanded(child: Column(children: [
        Text('Tur $round/$maxRounds',
          style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const Text('ADAM ASMACA',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ])),
      _Pill(name: p2Name, score: p2Score, isMe: !isP1Me),
    ]));
}

class _Pill extends StatelessWidget {
  const _Pill({required this.name, required this.score, required this.isMe});
  final String name; final int score; final bool isMe;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isMe ? Colors.white : Colors.white24,
      borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      Text(name, style: TextStyle(fontSize: 11, color: isMe ? _red : Colors.white70,
        fontWeight: FontWeight.w600)),
      Text('$score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
        color: isMe ? _red : Colors.white)),
    ]));
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.title,    required this.subtitle,
    required this.word,     required this.btnLabel,
    required this.p1Name,   required this.p1Score,
    required this.p2Name,   required this.p2Score,
    required this.myKey,    required this.onBtn,
  });
  final String title, subtitle, word, btnLabel;
  final String p1Name, p2Name, myKey; final int p1Score, p2Score;
  final VoidCallback onBtn;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title, textAlign: TextAlign.center),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(subtitle, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Kelime: ', style: TextStyle(color: Colors.grey)),
          Text(word, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
            color: Colors.blue, letterSpacing: 3)),
        ])),
      const SizedBox(height: 16),
      _ScoreRow(p1Name: p1Name, p2Name: p2Name, p1Score: p1Score, p2Score: p2Score, myKey: myKey),
    ]),
    actions: [FilledButton(
      style: FilledButton.styleFrom(backgroundColor: _red),
      onPressed: onBtn, child: Text(btnLabel))],
  );
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.p1Name, required this.p2Name,
    required this.p1Score, required this.p2Score, required this.myKey});
  final String p1Name, p2Name, myKey; final int p1Score, p2Score;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _SI(name: p1Name, score: p1Score, isMe: myKey == 'p1'),
      const Text('vs', style: TextStyle(color: _grey)),
      _SI(name: p2Name, score: p2Score, isMe: myKey == 'p2'),
    ]));
}

class _SI extends StatelessWidget {
  const _SI({required this.name, required this.score, required this.isMe});
  final String name; final int score; final bool isMe;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(name, style: TextStyle(fontWeight: FontWeight.bold,
      color: isMe ? _red : Colors.black87)),
    Text('$score', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
      color: isMe ? _red : Colors.black54)),
    Text('puan', style: TextStyle(fontSize: 11, color: isMe ? _red : _grey)),
  ]);
}
