import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

const _liarTopics = [
  'Tatil', 'Okul', 'Yemek', 'Spor', 'Film', 'Müzik',
  'Hayvan', 'Seyahat', 'Alışveriş', 'Aile', 'İş', 'Hobi',
];

// ════════════════════════════════════════════════════════════════════════════
// LOBBY
// ════════════════════════════════════════════════════════════════════════════

class LiarLobbyScreen extends StatefulWidget {
  const LiarLobbyScreen({super.key});
  @override State<LiarLobbyScreen> createState() => _LiarLobbyScreenState();
}

class _LiarLobbyScreenState extends State<LiarLobbyScreen> {
  final _rooms    = RoomService.instance;
  final _storage  = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _playerName; bool _loading = false;
  static const _kRose = AZColors.red;

  @override void initState() { super.initState(); _loadName(); }
  @override void dispose()   { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _loadName() async {
    final n = await _storage.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _playerName = n);
    else _askName();
  }
  Future<void> _askName() async {
    final name = await showNameDialog(context, current: _playerName, accentColor: _kRose);
    if (name == null || !mounted) return;
    await _storage.setPlayerName(name);
    setState(() => _playerName = name);
  }
  Future<void> _createRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final id   = await _rooms.createRoom(
        gamePath: GamePaths.liarCafe,
        data: {
          'code': code, 'status': 'waiting',
          'createdAt': ServerValue.timestamp,
          'phase': 'lobby', 'round': 0, 'maxRounds': 3,
          'players': {'p1': {'name': _playerName, 'isHost': true, 'score': 0}},
        },
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          LiarRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!)));
    } catch (e) { context.snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _joinRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { context.snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.liarCafe, code: code);
      if (r == null)                     { context.snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { context.snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 6)           { context.snack('Oda dolu (max 6)'); return; }
      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(
        gamePath: GamePaths.liarCafe, roomId: r.id,
        updates: {'players/$myKey': {'name': _playerName, 'isHost': false, 'score': 0}},
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          LiarRoomScreen(roomId: r.id, myKey: myKey, myName: _playerName!)));
    } catch (e) { context.snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradRose,
      child: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Align(alignment: Alignment.centerLeft,
                child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context))),
            const SizedBox(height: 8),
            const Text('☕', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 8),
            const Text('YALANCILAR KAHVESİ',
                style: TextStyle(color: Colors.white, fontSize: 24,
                    fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            const Text('3-6 Oyuncu · 3 Tur · Yalanı yakala!',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 28),
            AZNameChip(name: _playerName, onTap: _askName),
            const SizedBox(height: 36),
            AZButton(label: 'YENİ ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
                onPressed: _createRoom, color: _kRose, loading: _loading, width: 300),
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
                  Text('☕  Nasıl oynanır?',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 10),
                  Text(
                    '• Herkes bir konu alır, 1 kişi yalancıdır\n'
                    '• Yalancı konuyu bilmez ama biliyormuş gibi davranır\n'
                    '• Herkes konuyla ilgili bir cümle söyler\n'
                    '• Oy ver: Kim yalancı?\n'
                    '• Doğru bulunursa köylüler, bulunamazsa yalancı kazanır!',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.65),
                  ),
                ])),
            const SizedBox(height: 24),
          ]),
        )),
        const AdaptiveBannerAdWidget(), // lobby banner
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROOM
// ════════════════════════════════════════════════════════════════════════════

class LiarRoomScreen extends StatefulWidget {
  const LiarRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<LiarRoomScreen> createState() => _LiarRoomScreenState();
}

class _LiarRoomScreenState extends State<LiarRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;
  static const _kRose = AZColors.red;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.liarCafe, roomId: widget.roomId)
        .listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.liarCafe, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_navigating) {
      _navigating = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          LiarGameScreen(roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)));
    }
  }

  Map    get _players  => (_room['players'] as Map?) ?? {};
  String get _code     => _room['code'] ?? '------';
  bool   get _isHost   => widget.myKey == 'p1';
  bool   get _canStart => _players.length >= 3;

  Future<void> _start() async {
    if (!_canStart) { context.snack('En az 3 oyuncu gerekli'); return; }
    final topic   = _liarTopics[Random().nextInt(_liarTopics.length)];
    final keys    = _players.keys.toList()..shuffle(Random.secure());
    final liarKey = keys.first;
    final updates = <String, dynamic>{
      'status': 'playing', 'phase': 'answer', 'round': 1,
      'topic': topic, 'liar': liarKey,
    };
    for (final k in keys) { updates['players/$k/answer'] = ''; updates['players/$k/guess'] = ''; }
    await _rooms.updateRoom(gamePath: GamePaths.liarCafe, roomId: widget.roomId, updates: updates);
  }

  Future<void> _leave() async {
    await _rooms.leaveRoom(
        gamePath:  GamePaths.liarCafe,
        roomId:    widget.roomId,
        playerKey: widget.myKey,
        isHost:    _isHost);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AZLeaveGuard(onLeave: _leave,
      child: AZGradientScaffold(gradient: AZColors.gradRose,
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          AZRoomHeader(title: 'YALANCILAR KAHVESİ', onClose: _leave, titleSize: 17),
          const SizedBox(height: 20),
          AZRoomCode(code: _code, accentColor: _kRose),
          const SizedBox(height: 20),
          AZFrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Oyuncular (${_players.length}/6)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            for (final e in _players.entries)
              AZPlayerTile(name: e.value['name'] as String? ?? e.key,
                  isMe: e.key == widget.myKey, isHost: e.value['isHost'] == true,
                  emoji: '☕', present: true),
            if (!_canStart) const Padding(padding: EdgeInsets.only(top: 8),
                child: Text('En az 3 oyuncu gerekli',
                    style: TextStyle(color: Colors.white54, fontSize: 13))),
          ])),
          const Spacer(),
          if (_isHost)
            AZButton(label: 'OYUNU BAŞLAT', icon: Icons.play_arrow_rounded,
                onPressed: _canStart ? _start : null,
                color: _kRose, width: double.infinity)
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

class LiarGameScreen extends StatefulWidget {
  const LiarGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<LiarGameScreen> createState() => _LiarGameScreenState();
}

class _LiarGameScreenState extends State<LiarGameScreen> {
  final _db  = FirebaseDatabase.instance.ref();
  late  DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown  = false;
  bool _roomGone = false;
  final _answerCtrl = TextEditingController();
  static const _kRose = AZColors.red;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.liarCafe}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFirebase);
  }
  @override void dispose() { _answerCtrl.dispose(); _sub?.cancel(); super.dispose(); }

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
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 300), _showFinal);
    }
  }

  Map    get _players   => (_room['players'] as Map?) ?? {};
  String get _phase     => (_room['phase']   as String?) ?? 'answer';
  int    get _round     => (_room['round']   as int?)    ?? 1;
  int    get _maxRound  => (_room['maxRounds'] as int?)  ?? 3;
  String get _topic     => (_room['topic']   as String?) ?? '';
  String get _liarKey   => (_room['liar']    as String?) ?? '';
  bool   get _amLiar    => widget.myKey == _liarKey;
  bool   get _hasAnswered => ((_players[widget.myKey]?['answer'] as String?) ?? '').isNotEmpty;
  bool   get _hasGuessed  => ((_players[widget.myKey]?['guess']  as String?) ?? '').isNotEmpty;

  Future<void> _submitAnswer() async {
    final txt = _answerCtrl.text.trim();
    if (txt.isEmpty) return;
    await _ref.update({'players/${widget.myKey}/answer': txt});
    _answerCtrl.clear();
    final allAnswered = _players.values.every((p) =>
        ((p['answer'] as String?) ?? '').isNotEmpty);
    if (allAnswered) await _ref.update({'phase': 'vote'});
  }

  Future<void> _vote(String targetKey) async {
    if (_hasGuessed) return;
    await _ref.update({'players/${widget.myKey}/guess': targetKey});
    final all = _players.values.every((p) =>
        ((p['guess'] as String?) ?? '').isNotEmpty);
    if (!all) return;
    final votes = <String, int>{};
    for (final p in _players.values) {
      final g = p['guess'] as String? ?? '';
      if (g.isNotEmpty) votes[g] = (votes[g] ?? 0) + 1;
    }
    String? topGuess; int max = 0;
    votes.forEach((k, v) { if (v > max) { max = v; topGuess = k; } });
    final liarCaught = topGuess == _liarKey;
    final updates = <String, dynamic>{};
    for (final e in _players.entries) {
      final isLiar = e.key == _liarKey;
      final guessedRight = e.value['guess'] == _liarKey;
      final prev = (e.value['score'] as int?) ?? 0;
      if (liarCaught && guessedRight && !isLiar) updates['players/${e.key}/score'] = prev + 3;
      else if (!liarCaught && isLiar) updates['players/${e.key}/score'] = prev + 5;
      updates['players/${e.key}/guess']  = '';
      updates['players/${e.key}/answer'] = '';
    }
    updates['phase'] = 'result'; updates['liarCaught'] = liarCaught;
    await _ref.update(updates);
    await Future.delayed(const Duration(seconds: 4));
    if (_round >= _maxRound) {
      await _ref.update({'status': 'finished'});
    } else {
      final topic   = _liarTopics[Random().nextInt(_liarTopics.length)];
      final keys    = _players.keys.toList()..shuffle(Random.secure());
      await _ref.update({
        'phase': 'answer', 'round': _round + 1,
        'topic': topic, 'liar': keys.first,
      });
    }
  }

  void _showFinal() {
    if (!mounted) return;
    final sorted = _players.entries.toList()
      ..sort((a, b) => ((b.value['score'] as int?) ?? 0)
          .compareTo((a.value['score'] as int?) ?? 0));
    final iWon = sorted.isNotEmpty && sorted.first.key == widget.myKey;
    ProfileService.instance
        .reportGameResult(gameId: 'liar', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());
    const medals = ['🥇', '🥈', '🥉', '4.', '5.', '6.'];
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('☕ Oyun Bitti!', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: sorted.asMap().entries.map((e) {
            final isMe  = e.value.key == widget.myKey;
            final score = (e.value.value['score'] as int?) ?? 0;
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
          style: FilledButton.styleFrom(backgroundColor: _kRose),
          onPressed: () async {
            await _db.child('${GamePaths.liarCafe}/${widget.roomId}').remove();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final liarCaught = (_room['liarCaught'] as bool?) ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E3E0),
      body: SafeArea(child: Column(children: [

        // Top bar
        Container(
          color: _kRose,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Text('Tur $_round/$_maxRound',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end,
              children: _players.entries.map((e) {
                final isMe  = e.key == widget.myKey;
                final score = (e.value['score'] as int?) ?? 0;
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: isMe ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${e.value['name']}: $score',
                      style: TextStyle(color: isMe ? _kRose : Colors.white,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                );
              }).toList(),
            )),
          ]),
        ),

        // Body
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // Rol kartı — her tur değiştiğinde canlanan geçiş animasyonu
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Container(
                key: ValueKey('$_round-$_amLiar'),
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _amLiar
                        ? [const Color(0xFFB8776A), const Color(0xFF6B3A32)]
                        : [_kRose, AZColors.redDk],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: (_amLiar ? AZColors.redDk : _kRose).withAlpha(90),
                        blurRadius: 24,
                        offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(children: [
                  Text(_amLiar ? '😈' : '🗣️', style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(
                    _amLiar ? 'SEN YALANCISIN!' : 'Konu: $_topic',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  if (_amLiar) ...[
                    const SizedBox(height: 8),
                    const Text('Konuyu bilmiyorsun ama biliyormuş gibi davran!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ANSWER PHASE
            if (_phase == 'answer') ...[
              if (!_hasAnswered) ...[
                const Text('Konuyla ilgili bir cümle söyle:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _answerCtrl,
                  decoration: InputDecoration(
                    hintText: _amLiar ? 'Yalan söyle ama inandır...'
                        : 'Konuyla ilgili bir şey söyle...',
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: _kRose),
                        onPressed: _submitAnswer),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onSubmitted: (_) => _submitAnswer(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submitAnswer,
                  style: FilledButton.styleFrom(backgroundColor: _kRose,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('GÖNDER',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ] else
                AZCard(child: Column(children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  const SizedBox(height: 8),
                  const Text('Cevabın alındı!', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Diğerleri bekleniyor...', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(color: _kRose),
                ])),
            ],

            // VOTE PHASE
            if (_phase == 'vote') ...[
              AZCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Cevaplar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ..._players.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 16,
                        backgroundColor: _kRose.withAlpha(50),
                        child: Text((e.value['name'] as String? ?? '?')[0],
                            style: const TextStyle(color: _kRose, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.value['name'] as String? ?? e.key,
                          style: TextStyle(fontWeight: e.key == widget.myKey
                              ? FontWeight.bold : FontWeight.normal)),
                      Text(e.value['answer'] as String? ?? '...',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ])),
                  ]),
                )),
              ])),
              const SizedBox(height: 20),
              if (!_hasGuessed) ...[
                const Text('🤔 Kim yalancı?', textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 14),
                ..._players.entries
                    .where((e) => e.key != widget.myKey)
                    .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () => _vote(e.key),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kRose, foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(e.value['name'] as String? ?? e.key,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )),
              ] else
                AZCard(child: Column(children: [
                  const Icon(Icons.how_to_vote, color: _kRose, size: 40),
                  const SizedBox(height: 8),
                  const Text('Oyun bekleniyor...', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(color: _kRose),
                ])),
            ],

            // RESULT PHASE
            if (_phase == 'result')
              AZCard(child: Column(children: [
                Text(liarCaught ? '🎉 Yalancı Yakalandı!' : '😈 Yalancı Kazandı!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                        color: liarCaught ? Colors.green : Colors.red)),
                const SizedBox(height: 12),
                Text('Yalancı: ${_players[_liarKey]?['name'] ?? _liarKey}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Sonraki tura geçiliyor...', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                const CircularProgressIndicator(color: _kRose),
              ])),
          ]),
        )),

        // Banner reklam — oyun altında
        const BannerAdWidget(),
      ])),
    );
  }
}
