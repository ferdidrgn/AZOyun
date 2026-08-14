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

// ══════════════════════════════════════════════════════════════════════════════
// DATA
// ══════════════════════════════════════════════════════════════════════════════

const _cityData = {
  'İSTANBUL': ['Türkiye\'nin en kalabalık şehri', 'İki kıtada kurulu', 'Boğaz\'ı var'],
  'ANKARA':   ['Türkiye\'nin başkenti', 'İç Anadolu\'da', 'Anıtkabir burada'],
  'İZMİR':    ['Ege\'nin incisi', 'Deniz kıyısında', 'Saat kulesi ünlü'],
  'ANTALYA':  ['Turizm cenneti', 'Akdeniz kıyısında', 'Dünyaca ünlü plajları var'],
  'BURSA':    ['Yeşil Bursa', 'Uludağ\'ı var', 'İlk Osmanlı başkentlerinden'],
  'TRABZON':  ['Karadeniz\'in gözü', 'Çay üretim merkezi', 'Sümela Manastırı yakınında'],
  'KONYA':    ['Mevlana\'nın şehri', 'İç Anadolu ovalarında', 'Türkiye\'nin en büyük yüzölçümlü ili'],
  'ADANA':    ['Akdeniz\'de', 'Seyrandan geçer Seyhan', 'Kebabıyla ünlü'],
  'ESKİŞEHİR':['Porsuk çayı akar', 'Üniversite kenti', 'Osmanlı\'da önemli ticaret merkezi'],
  'GAZİANTEP':['Baklava ile ünlü', 'Güneydoğu Anadolu\'da', 'Zeugma mozaikleri burada'],
};

// ══════════════════════════════════════════════════════════════════════════════
// LOBBY
// ══════════════════════════════════════════════════════════════════════════════

class CityLobbyScreen extends StatefulWidget {
  const CityLobbyScreen({super.key});
  @override
  State<CityLobbyScreen> createState() => _CityLobbyScreenState();
}

class _CityLobbyScreenState extends State<CityLobbyScreen> {
  final _rooms    = RoomService.instance;
  final _storage  = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _playerName;
  bool    _loading = false;
  static const _kPink = Color(0xFFf5576c);

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
    final name = await showNameDialog(context, current: _playerName, accentColor: _kPink);
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
        gamePath: GamePaths.cityPuzzle,
        data: {
          'code': code, 'status': 'waiting',
          'createdAt': ServerValue.timestamp,
          'currentRound': 1, 'maxRounds': 5,
          'players': {'p1': {'name': _playerName, 'isHost': true, 'score': 0}},
        },
      );
      if (!mounted) return;
      _nav(CityRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!));
    } catch (e) { _snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _joinRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.cityPuzzle, code: code);
      if (r == null)                     { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { _snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 4)           { _snack('Oda dolu'); return; }
      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(
        gamePath: GamePaths.cityPuzzle, roomId: r.id,
        updates: {'players/$myKey': {'name': _playerName, 'isHost': false, 'score': 0}},
      );
      if (!mounted) return;
      _nav(CityRoomScreen(roomId: r.id, myKey: myKey, myName: _playerName!));
    } catch (e) { _snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _nav(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradPink,
      child: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Align(alignment: Alignment.centerLeft,
                child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context))),
              const SizedBox(height: 8),
              const Text('🏙️', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              const Text('ŞEHİR BULMACA',
                  style: TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text('2-4 Oyuncu · 5 Tur · İpuçlarla şehri bul',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 28),
              GestureDetector(onTap: _askName,
                child: AZFrostCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(_playerName ?? 'Ad seç',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_rounded, color: Colors.white60, size: 14),
                  ]),
                ),
              ),
              const SizedBox(height: 36),
              AZButton(label: 'YENİ ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
                  onPressed: _createRoom, color: _kPink, loading: _loading, width: 300),
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
                    Text('🏙️  Nasıl oynanır?',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 10),
                    Text(
                      '• Her turda bir şehir için 3 ipucu verilir\n'
                      '• İlk ipucuyla bil → 10 puan\n'
                      '• İkinci ipucuyla → 7 puan, üçüncüyle → 4 puan\n'
                      '• 5 tur sonunda en yüksek puan kazanır\n'
                      '• 📺 Reklam izleyerek ekstra ipucu kazanabilirsin!',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.65),
                    ),
                  ])),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        // Banner reklam — lobby altında
        const AdaptiveBannerAdWidget(),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ROOM
// ══════════════════════════════════════════════════════════════════════════════

class CityRoomScreen extends StatefulWidget {
  const CityRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override
  State<CityRoomScreen> createState() => _CityRoomScreenState();
}

class _CityRoomScreenState extends State<CityRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;
  static const _kPink = Color(0xFFf5576c);

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.cityPuzzle, roomId: widget.roomId)
        .listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.cityPuzzle, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
  }
  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_navigating) {
      _navigating = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          CityGameScreen(roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)));
    }
  }

  Map    get _players  => (_room['players'] as Map?) ?? {};
  String get _code     => _room['code'] ?? '------';
  bool   get _isHost   => widget.myKey == 'p1';
  bool   get _canStart => _players.length >= 2;

  Future<void> _start() async {
    if (!_canStart) { _snack('En az 2 oyuncu'); return; }
    final cities = _cityData.keys.toList()..shuffle(Random.secure());
    await _rooms.updateRoom(
      gamePath: GamePaths.cityPuzzle, roomId: widget.roomId,
      updates: {
        'status': 'playing', 'currentRound': 1,
        'cityOrder': cities.take(5).toList(), 'hintIndex': 0,
      },
    );
  }

  Future<void> _leave() async {
    if (_isHost) await _rooms.deleteRoom(gamePath: GamePaths.cityPuzzle, roomId: widget.roomId);
    else await _rooms.removePlayer(gamePath: GamePaths.cityPuzzle, roomId: widget.roomId, playerKey: widget.myKey);
    if (mounted) Navigator.pop(context);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, onPopInvoked: (_) => _leave(),
      child: AZGradientScaffold(
        gradient: AZColors.gradPink,
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
            const Expanded(child: Text('ŞEHİR BULMACA', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 20),
          AZRoomCode(code: _code, accentColor: _kPink),
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
                emoji: '🏙️', present: _players.containsKey(slot),
              ),
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
                color: _kPink, width: double.infinity)
          else
            const AZWaitingCard(message: 'Host oyunu başlatacak...'),
        ])),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GAME
// ══════════════════════════════════════════════════════════════════════════════

class CityGameScreen extends StatefulWidget {
  const CityGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override
  State<CityGameScreen> createState() => _CityGameScreenState();
}

class _CityGameScreenState extends State<CityGameScreen> {
  final _db   = FirebaseDatabase.instance.ref();
  late  DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  final _answerCtrl = TextEditingController();
  bool _answered    = false;
  bool _usedRewardedHint = false; // bu tur rewarded ipucu kullandı mı

  static const _kPink = Color(0xFFf5576c);

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.cityPuzzle}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFirebase);
  }
  @override
  void dispose() { _answerCtrl.dispose(); _sub?.cancel(); super.dispose(); }

  void _onFirebase(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    // Yeni tura geçince rewarded hint sıfırla
    final newRound = (d['currentRound'] as int?) ?? 1;
    final oldRound = (_room['currentRound'] as int?) ?? 1;
    if (newRound != oldRound) setState(() => _usedRewardedHint = false);
    setState(() { _room = d; _answered = false; });
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      AdService.instance.onGameEnd(); // interstitial tetikle
      Future.delayed(const Duration(milliseconds: 300), _showFinal);
    }
  }

  Map    get _players   => (_room['players'] as Map?) ?? {};
  int    get _round     => (_room['currentRound'] as int?) ?? 1;
  int    get _maxRound  => (_room['maxRounds']    as int?) ?? 5;
  int    get _hintIndex => (_room['hintIndex']    as int?) ?? 0;

  String get _currentCity {
    final order = (_room['cityOrder'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (order.isEmpty || _round > order.length) return '';
    return order[_round - 1];
  }
  List<String> get _hints => _cityData[_currentCity] ?? [];

  // Rewarded reklam ile bir sonraki ipucunu aç (ücretsiz)
  void _watchAdForHint() {
    AdService.instance.showRewarded(
      onRewarded: (_) async {
        if (!mounted) return;
        setState(() => _usedRewardedHint = true);
        if (_hintIndex < 2) {
          await _ref.update({'hintIndex': _hintIndex + 1});
          _snack('🎁 Ekstra ipucu kazandın!');
        }
      },
      onNotReady: () => _snack('Reklam henüz hazır değil, biraz bekleyin.'),
    );
  }

  Future<void> _checkAnswer() async {
    if (_answered) return;
    final answer = _answerCtrl.text.trim().toUpperCase();
    final correct = _currentCity.toUpperCase();
    if (answer == correct || answer.replaceAll(' ', '') == correct.replaceAll(' ', '')) {
      _answered = true;
      // Rewarded ile açılan ipucu = bonus puan yok, normal puan verilir ama düşük
      final pts = _usedRewardedHint ? 3 : (_hintIndex == 0 ? 10 : _hintIndex == 1 ? 7 : 4);
      final prev = (_players[widget.myKey]?['score'] as int?) ?? 0;
      await _ref.update({'players/${widget.myKey}/score': prev + pts});
      _snack('✅ Doğru! +$pts puan');
      _answerCtrl.clear();
      await Future.delayed(const Duration(seconds: 1));
      _nextRound();
    } else {
      _snack('❌ Yanlış, tekrar dene!');
      _answerCtrl.clear();
    }
  }

  Future<void> _nextHint() async {
    if (_hintIndex < 2) await _ref.update({'hintIndex': _hintIndex + 1});
  }

  Future<void> _nextRound() async {
    if (_round >= _maxRound) {
      await _ref.update({'status': 'finished'});
    } else {
      setState(() => _usedRewardedHint = false);
      await _ref.update({'currentRound': _round + 1, 'hintIndex': 0});
    }
  }

  void _showFinal() {
    if (!mounted) return;
    final sorted = _players.entries.toList()
      ..sort((a, b) => ((b.value['score'] as int?) ?? 0)
          .compareTo((a.value['score'] as int?) ?? 0));
    final iWon = sorted.isNotEmpty && sorted.first.key == widget.myKey;
    ProfileService.instance
        .reportGameResult(gameId: 'city', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());
    const medals = ['🥇', '🥈', '🥉', '4.'];
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🏙️ Oyun Bitti!', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: sorted.asMap().entries.map((e) {
            final isMe  = e.value.key == widget.myKey;
            final score = (e.value.value['score'] as int?) ?? 0;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.pink.shade50 : null,
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
          style: FilledButton.styleFrom(backgroundColor: _kPink),
          onPressed: () async {
            await _db.child('${GamePaths.cityPuzzle}/${widget.roomId}').remove();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  // Rewarded buton gösterilsin mi?
  bool get _canShowRewardedBtn =>
      _hintIndex >= 2 && !_answered && !_usedRewardedHint;

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final hints     = _hints;
    final shownHint = _hintIndex < hints.length ? hints[_hintIndex] : '';

    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      body: SafeArea(child: Column(children: [

        // Score bar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color.lerp(_kPink, Colors.black, 0.12)!, _kPink],
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
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
                      style: TextStyle(
                          color: isMe ? _kPink : Colors.white,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12)),
                );
              }).toList(),
            )),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 10),

            // Hint card
            AZCard(child: Column(children: [
              Text('İpucu ${_hintIndex + 1}/3',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 12),
              Text(shownHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              // Normal ipucu butonu (puan kaybı)
              if (_hintIndex < 2 && !_answered)
                OutlinedButton.icon(
                  onPressed: _nextHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Sonraki İpucu (${[7, 4][_hintIndex]} puan)'),
                  style: OutlinedButton.styleFrom(foregroundColor: _kPink),
                ),

              // Rewarded reklam ile ekstra ipucu (tüm ipuçları bitti ama hâlâ bilemiyor)
              if (_canShowRewardedBtn) ...[
                const SizedBox(height: 8),
                RewardedAdButton(
                  label: 'Ekstra İpucu Al',
                  icon: Icons.lightbulb_rounded,
                  color: _kPink,
                  onRewarded: (_) async {
                    setState(() => _usedRewardedHint = true);
                    _snack('🎁 Reklam izledin! Ekstra ipucu: $_currentCity ← İlk 2 harf: ${_currentCity.substring(0, 2)}');
                  },
                ),
              ],
            ])),
            const SizedBox(height: 20),

            TextField(
              controller: _answerCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Şehir adını yaz...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: _kPink),
                  onPressed: _checkAnswer,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _checkAnswer,
              style: FilledButton.styleFrom(
                  backgroundColor: _kPink,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('CEVAPLA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ]),
        )),

        // Banner reklam — oyun altında
        const BannerAdWidget(),
      ])),
    );
  }
}
