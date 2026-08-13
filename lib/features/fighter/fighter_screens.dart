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
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

// ═══════════════════════════════════════════════════════════════════
// FIGHTER DATA
// ═══════════════════════════════════════════════════════════════════

class FighterData {
  final String id, name, emoji;
  final int maxHp, attack, defense, speed;
  final Color color;
  final String special; // özel yetenek açıklaması
  const FighterData({
    required this.id, required this.name, required this.emoji,
    required this.maxHp, required this.attack, required this.defense,
    required this.speed, required this.color, required this.special,
  });
}

const kFighters = [
  FighterData(id:'ninja',   name:'Ninja',    emoji:'🥷', maxHp:80,  attack:25, defense:10, speed:500,  color:Color(0xFF37474F), special:'Gizlenme: 1 saldırı kaçır'),
  FighterData(id:'warrior', name:'Savaşçı',  emoji:'⚔️', maxHp:120, attack:18, defense:20, speed:900,  color:Color(0xFFB71C1C), special:'Kılıç fırtınası: 3× hasar'),
  FighterData(id:'mage',    name:'Büyücü',   emoji:'🧙', maxHp:70,  attack:32, defense:5,  speed:1100, color:Color(0xFF4A148C), special:'Ateş topu: Yanma hasarı'),
  FighterData(id:'archer',  name:'Okçu',     emoji:'🏹', maxHp:90,  attack:22, defense:8,  speed:650,  color:Color(0xFF1B5E20), special:'Kritik atış: %30 kritik şans'),
  FighterData(id:'paladin', name:'Paladin',  emoji:'🛡️', maxHp:150, attack:15, defense:30, speed:1000, color:Color(0xFFE65100), special:'Kutsal kalkan: 2 sn hasar yok'),
  FighterData(id:'rogue',   name:'Haydut',   emoji:'🗡️', maxHp:85,  attack:28, defense:6,  speed:480,  color:Color(0xFF263238), special:'Zehir bıçağı: DoT hasarı'),
];

FighterData getFighter(String id) =>
    kFighters.firstWhere((f) => f.id == id, orElse: () => kFighters[0]);

// ═══════════════════════════════════════════════════════════════════
// LOBBY
// ═══════════════════════════════════════════════════════════════════

class FighterLobbyScreen extends StatefulWidget {
  const FighterLobbyScreen({super.key});
  @override State<FighterLobbyScreen> createState() => _FLobbyState();
}

class _FLobbyState extends State<FighterLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _name; bool _loading = false;
  FighterData _sel = kFighters[0];
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _glow = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _load();
  }

  @override void dispose() { _glowCtrl.dispose(); _codeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final n = await _storage.getPlayerName(); if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _name = n); else _ask();
  }

  Future<void> _ask() async {
    final n = await showNameDialog(context, current: _name, accentColor: const Color(0xFFB71C1C));
    if (n == null || !mounted) return;
    await _storage.setPlayerName(n); setState(() => _name = n);
  }

  Map<String, dynamic> _playerData(String key) => {
    'name': _name, 'isHost': key == 'p1',
    'fighterId': _sel.id,
    'hp': _sel.maxHp, 'maxHp': _sel.maxHp,
    'attack': _sel.attack, 'defense': _sel.defense, 'speed': _sel.speed,
    'combo': 0, 'shield': false, 'poisoned': false, 'burning': false,
    'score': 0, 'wins': 0,
  };

  Future<void> _create() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final id = await _rooms.createRoom(gamePath: GamePaths.fighter, data: {
        'code': code, 'status': 'waiting', 'round': 1, 'maxRounds': 3,
        'createdAt': ServerValue.timestamp,
        'players': {'p1': _playerData('p1')},
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          FighterRoomScreen(roomId: id, myKey: 'p1', myName: _name!, fighter: _sel)));
    } catch (e) { _snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _join() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.fighter, code: code);
      if (r == null) { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { _snack('Maç başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 2) { _snack('Oda dolu'); return; }
      await _rooms.updateRoom(gamePath: GamePaths.fighter, roomId: r.id,
          updates: {'players/p2': _playerData('p2')});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          FighterRoomScreen(roomId: r.id, myKey: 'p2', myName: _name!, fighter: _sel)));
    } catch (e) { _snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A0000), Color(0xFF0A0010), Color(0xFF000A00)],
          ),
        ),
        child: SafeArea(child: Column(children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Align(alignment: Alignment.centerLeft,
                  child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Navigator.pop(context))),
              // Başlık
              AnimatedBuilder(
                animation: _glow,
                builder: (_, __) => Text('⚔️', style: TextStyle(fontSize: 64,
                    shadows: [Shadow(blurRadius: 30 * _glow.value,
                        color: Colors.red.withAlpha((200 * _glow.value).toInt()))])),
              ),
              const SizedBox(height: 8),
              const Text('DÖVÜŞÇÜLER',
                  style: TextStyle(color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.bold, letterSpacing: 4)),
              const Text('1v1 · Gerçek Zamanlı · 3 Raunt',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 24),

              // Karakter seç
              const _SectionTitle('KARAKTERINI SEÇ'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 0.78,
                    mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: kFighters.length,
                itemBuilder: (_, i) {
                  final f = kFighters[i];
                  final sel = f.id == _sel.id;
                  return GestureDetector(
                    onTap: () => setState(() => _sel = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: sel ? f.color.withAlpha(160) : Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: sel ? Colors.white : Colors.white24,
                            width: sel ? 2.5 : 1),
                        boxShadow: sel ? [BoxShadow(
                            color: f.color.withAlpha(150), blurRadius: 12)] : [],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(f.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(f.name, style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _MiniStat('❤️', f.maxHp, 150),
                        _MiniStat('⚔️', f.attack, 32),
                        _MiniStat('🛡️', f.defense, 30),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Seçili karakter detay
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_sel.color.withAlpha(100), Colors.black87],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _sel.color.withAlpha(180), width: 2),
                ),
                child: Row(children: [
                  Text(_sel.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_sel.name, style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('✨ ${_sel.special}',
                        style: const TextStyle(color: Colors.amberAccent,
                            fontSize: 11, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    _StatBar('CAN', _sel.maxHp, 150, Colors.red.shade400),
                    _StatBar('SALDIRI', _sel.attack, 32, Colors.orange.shade400),
                    _StatBar('SAVUNMA', _sel.defense, 30, Colors.blue.shade400),
                    _StatBar('HIZ', 1500 - _sel.speed, 1100, Colors.green.shade400),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),

              // İsim
              GestureDetector(onTap: _ask, child: AZFrostCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(_name ?? 'Ad seç', style: const TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_rounded, color: Colors.white38, size: 13),
                ]),
              )),
              const SizedBox(height: 20),

              // Oluştur
              SizedBox(width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _create,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_circle_outline),
                  label: const Text('ODA OLUŞTUR',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
                    shadowColor: const Color(0xFFB71C1C),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('— veya —', style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 20),
              AZFrostCard(child: Column(children: [
                AZCodeField(controller: _codeCtrl),
                const SizedBox(height: 14),
                AZJoinButton(onPressed: _loading ? null : _join, loading: _loading),
              ])),
              const SizedBox(height: 16),
            ]),
          )),
          const AdaptiveBannerAdWidget(),
        ])),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: Colors.white54, fontSize: 11,
          letterSpacing: 2.5, fontWeight: FontWeight.w700));
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.val, this.max);
  final String icon; final int val, max;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 9)),
      const SizedBox(width: 3),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: val / max,
              minHeight: 5, backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Colors.white54)))),
    ]),
  );
}

class _StatBar extends StatelessWidget {
  const _StatBar(this.label, this.val, this.max, this.color);
  final String label; final int val, max; final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      SizedBox(width: 60, child: Text(label, style: const TextStyle(
          color: Colors.white54, fontSize: 10))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(value: val / max,
              minHeight: 9, backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color)))),
      const SizedBox(width: 6),
      Text('$val', style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// ROOM
// ═══════════════════════════════════════════════════════════════════

class FighterRoomScreen extends StatefulWidget {
  const FighterRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName, required this.fighter});
  final String roomId, myKey, myName; final FighterData fighter;
  @override State<FighterRoomScreen> createState() => _FRoomState();
}

class _FRoomState extends State<FighterRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override void initState() { super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.fighter, roomId: widget.roomId).listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.fighter, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    final players = (d['players'] as Map?) ?? {};
    if (players.isEmpty) {
      _rooms.deleteRoom(gamePath: GamePaths.fighter, roomId: widget.roomId);
      if (mounted) Navigator.pop(context); return;
    }
    if (d['status'] == 'fighting' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          FighterGameScreen(roomId: widget.roomId, myKey: widget.myKey,
              myName: widget.myName, fighter: widget.fighter)));
    }
  }

  Map get _players => (_room['players'] as Map?) ?? {};
  String get _code => _room['code'] ?? '------';
  bool get _isHost => widget.myKey == 'p1';
  bool get _canStart => _players.length >= 2;

  Future<void> _start() async {
    if (!_canStart) { _snack('Rakip bekleniyor'); return; }
    await _rooms.updateRoom(gamePath: GamePaths.fighter, roomId: widget.roomId,
        updates: {'status': 'fighting', 'startTime': ServerValue.timestamp});
  }

  Future<void> _leave() async {
    final pl = Map.from(_players)..remove(widget.myKey);
    if (pl.isEmpty || _isHost) {
      await _rooms.deleteRoom(gamePath: GamePaths.fighter, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(gamePath: GamePaths.fighter, roomId: widget.roomId, playerKey: widget.myKey);
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final p1d = _players['p1']; final p2d = _players['p2'];
    return PopScope(canPop: false, onPopInvoked: (_) => _leave(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Color(0xFF1A0000), Color(0xFF0A0010)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: _leave),
              const Expanded(child: Text('⚔️ DÖVÜŞÇÜLER', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 16),
            AZRoomCode(code: _code, accentColor: const Color(0xFFEF5350)),
            const SizedBox(height: 24),

            // Fighter showcase VS
            if (p1d != null && p2d != null) ...[
              Row(children: [
                Expanded(child: _FighterShowcase(data: p1d, isMe: widget.myKey == 'p1')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade400)),
                  child: const Text('VS', style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
                ),
                Expanded(child: _FighterShowcase(data: p2d, isMe: widget.myKey == 'p2')),
              ]),
            ] else if (p1d != null) ...[
              Center(child: _FighterShowcase(data: p1d, isMe: widget.myKey == 'p1')),
              const SizedBox(height: 20),
              const AZWaitingCard(message: 'Rakip bekleniyor...'),
            ],

            const Spacer(),
            if (_isHost)
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: _canStart ? _start : null,
                  icon: const Icon(Icons.sports_mma_rounded, size: 22),
                  label: const Text('DÖVÜŞÜ BAŞLAT!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canStart ? const Color(0xFFB71C1C) : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: _canStart ? 8 : 0,
                    shadowColor: Colors.red.shade900,
                  ),
                ),
              )
            else
              const AZWaitingCard(message: 'Host dövüşü başlatacak...'),
          ]))),
        ),
      ),
    );
  }
}

class _FighterShowcase extends StatelessWidget {
  const _FighterShowcase({required this.data, required this.isMe});
  final dynamic data; final bool isMe;
  @override
  Widget build(BuildContext context) {
    final f = getFighter(data['fighterId'] as String? ?? 'warrior');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: f.color.withAlpha(isMe ? 140 : 80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? Colors.white : f.color.withAlpha(100),
            width: isMe ? 2 : 1),
      ),
      child: Column(children: [
        Text(f.emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 4),
        Text(f.name, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold, fontSize: 13)),
        Text(data['name'] as String? ?? '?',
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        if (isMe) ...[
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('SEN', style: TextStyle(
                  color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold))),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GAME — Gerçek zamanlı dövüş
// ═══════════════════════════════════════════════════════════════════

class FighterGameScreen extends StatefulWidget {
  const FighterGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName, required this.fighter});
  final String roomId, myKey, myName; final FighterData fighter;
  @override State<FighterGameScreen> createState() => _FGameState();
}

class _FGameState extends State<FighterGameScreen> with TickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false, _processing = false;

  // Cooldown
  bool _atkCd = false, _specCd = false;
  bool _shieldOn = false;
  Timer? _shieldTimer, _dotTimer;
  int _combo = 0;
  Timer? _comboReset;

  // DoT (zehir/yanma) durumu
  bool _poisoned = false, _burning = false;
  int _dotTick = 0;

  // Hit animasyonları
  late AnimationController _hitCtrl, _myHitCtrl;
  late Animation<double> _hitFlash, _myShake;
  bool _showHit = false;

  // Son atılan aksiyon log
  final List<String> _actionLog = [];
  final _rng = Random();

  // Swipe için
  Offset? _swipeStart;
  DateTime? _swipeSt;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.fighter}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFB);

    _hitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _showHit = false);
      });
    _myHitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _hitFlash = Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _hitCtrl, curve: Curves.easeOut));
    _myShake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _myHitCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hitCtrl.dispose(); _myHitCtrl.dispose();
    _shieldTimer?.cancel(); _dotTimer?.cancel(); _comboReset?.cancel();
    _sub?.cancel(); super.dispose();
  }

  void _onFB(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    final prevOppHp = (_room['players']?[_oppKey]?['hp'] as int?) ?? 999;
    setState(() => _room = d);
    final newOppHp = (d['players']?[_oppKey]?['hp'] as int?) ?? 999;
    // Biz vuruş aldıysak animasyon
    final myHp = (d['players']?[widget.myKey]?['hp'] as int?) ?? 999;
    final prevMyHp = (_room['players']?[widget.myKey]?['hp'] as int?) ?? 999;
    if (myHp < prevMyHp) { _myHitCtrl.forward(from: 0); HapticFeedback.mediumImpact(); }
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true; AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 600), _showFinal);
    }
  }

  // ── Getters ─────────────────────────────────────────────────────

  Map get _players => (_room['players'] as Map?) ?? {};
  String get _oppKey => widget.myKey == 'p1' ? 'p2' : 'p1';
  int get _myHp => (_players[widget.myKey]?['hp'] as int?) ?? 0;
  int get _myMaxHp => (_players[widget.myKey]?['maxHp'] as int?) ?? widget.fighter.maxHp;
  int get _oppHp => (_players[_oppKey]?['hp'] as int?) ?? 0;
  int get _oppMaxHp => (_players[_oppKey]?['maxHp'] as int?) ?? 100;
  bool get _alive => _myHp > 0;

  // ── Saldırı ─────────────────────────────────────────────────────

  Future<void> _normalAttack() async {
    if (_atkCd || !_alive || _processing) return;
    setState(() { _atkCd = true; });

    _combo = (_combo + 1).clamp(1, 5);
    _comboReset?.cancel();
    _comboReset = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _combo = 0);
    });

    final base = widget.fighter.attack;
    final crit = _rng.nextDouble() < (widget.fighter.id == 'archer' ? 0.30 : 0.12);
    final comboBns = 1.0 + (_combo - 1) * 0.18;
    final dmg = ((base * comboBns) * (crit ? 1.6 : 1.0)).round();
    final oppDef = (_players[_oppKey]?['defense'] as int?) ?? 10;
    final oppShield = (_players[_oppKey]?['shield'] as bool?) ?? false;
    final finalDmg = (dmg - (oppShield ? oppDef * 2 : oppDef ~/ 3)).clamp(1, 999);
    final newHp = ((_players[_oppKey]?['hp'] as int?) ?? _oppMaxHp) - finalDmg;

    _addLog(crit ? '💥 Kritik! $finalDmg hasar × $_combo kombo!'
        : '⚔️ $_combo kombo · $finalDmg hasar');
    _showHitFx();

    await _dealDamage(_oppKey, finalDmg, newHp);

    Future.delayed(Duration(milliseconds: widget.fighter.speed), () {
      if (mounted) setState(() => _atkCd = false);
    });
  }

  Future<void> _specialAttack() async {
    if (_specCd || !_alive || _processing) return;
    setState(() { _specCd = true; });

    await _applySpecial();

    Future.delayed(Duration(milliseconds: widget.fighter.speed * 5), () {
      if (mounted) setState(() => _specCd = false);
    });
  }

  Future<void> _applySpecial() async {
    switch (widget.fighter.id) {
      case 'ninja':
        // Gizlenme: kalkan aktif
        await _ref.update({'players/${widget.myKey}/shield': true});
        setState(() => _shieldOn = true);
        _addLog('🥷 Gizlenme aktif!');
        _shieldTimer?.cancel();
        _shieldTimer = Timer(const Duration(seconds: 2), () async {
          if (!mounted) return;
          setState(() => _shieldOn = false);
          await _ref.update({'players/${widget.myKey}/shield': false});
        });
        break;
      case 'warrior':
        // 3× hasar
        final dmg = (widget.fighter.attack * 3.0).round();
        final newHp = ((_players[_oppKey]?['hp'] as int?) ?? _oppMaxHp) - dmg;
        _addLog('⚔️ Kılıç Fırtınası! $dmg hasar!');
        _showHitFx();
        await _dealDamage(_oppKey, dmg, newHp);
        break;
      case 'mage':
        // Yanma DoT
        final dmg = widget.fighter.attack;
        final newHp = ((_players[_oppKey]?['hp'] as int?) ?? _oppMaxHp) - dmg;
        await _ref.update({'players/$_oppKey/burning': true});
        _addLog('🔥 Ateş Topu! $dmg + yanma!');
        _showHitFx();
        await _dealDamage(_oppKey, dmg, newHp);
        // 3 tik yanma (her sn 5 hasar)
        _dotTimer?.cancel(); _dotTick = 3;
        _dotTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
          if (!mounted || _dotTick <= 0) { t.cancel(); return; }
          _dotTick--;
          final cur = (_players[_oppKey]?['hp'] as int?) ?? 0;
          final h = (cur - 5).clamp(0, _oppMaxHp);
          _addLog('🔥 Yanma 5 hasar');
          await _dealDamage(_oppKey, 5, h);
          if (_dotTick == 0) await _ref.update({'players/$_oppKey/burning': false});
        });
        break;
      case 'archer':
        // Kritik atış
        final dmg = (widget.fighter.attack * 2.2).round();
        final newHp = ((_players[_oppKey]?['hp'] as int?) ?? _oppMaxHp) - dmg;
        _addLog('🏹 Kritik Atış! $dmg hasar!');
        _showHitFx();
        await _dealDamage(_oppKey, dmg, newHp);
        break;
      case 'paladin':
        // Kutsal kalkan — 2 sn hasar yok
        await _ref.update({'players/${widget.myKey}/shield': true});
        setState(() => _shieldOn = true);
        _addLog('🛡️ Kutsal Kalkan aktif!');
        _shieldTimer?.cancel();
        _shieldTimer = Timer(const Duration(seconds: 3), () async {
          if (!mounted) return;
          setState(() => _shieldOn = false);
          await _ref.update({'players/${widget.myKey}/shield': false});
        });
        break;
      case 'rogue':
        // Zehir DoT
        final dmg = widget.fighter.attack;
        final newHp = ((_players[_oppKey]?['hp'] as int?) ?? _oppMaxHp) - dmg;
        await _ref.update({'players/$_oppKey/poisoned': true});
        _addLog('🗡️ Zehir Bıçağı! $dmg + zehir!');
        _showHitFx();
        await _dealDamage(_oppKey, dmg, newHp);
        _dotTimer?.cancel(); _dotTick = 4;
        _dotTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
          if (!mounted || _dotTick <= 0) { t.cancel(); return; }
          _dotTick--;
          final cur = (_players[_oppKey]?['hp'] as int?) ?? 0;
          final h = (cur - 7).clamp(0, _oppMaxHp);
          _addLog('☠️ Zehir 7 hasar');
          await _dealDamage(_oppKey, 7, h);
          if (_dotTick == 0) await _ref.update({'players/$_oppKey/poisoned': false});
        });
        break;
    }
  }

  Future<void> _activateShield() async {
    if (_shieldOn || !_alive) return;
    setState(() => _shieldOn = true);
    await _ref.update({'players/${widget.myKey}/shield': true});
    _addLog('🛡️ Blok!');
    HapticFeedback.lightImpact();
    _shieldTimer?.cancel();
    _shieldTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      setState(() => _shieldOn = false);
      await _ref.update({'players/${widget.myKey}/shield': false});
    });
  }

  Future<void> _dealDamage(String key, int dmg, int newHp) async {
    setState(() => _processing = true);
    try {
      final clamped = newHp.clamp(0, _oppMaxHp);
      await _ref.update({'players/$key/hp': clamped});
      HapticFeedback.mediumImpact();
      if (clamped <= 0) await _onKill();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _onKill() async {
    final myScore = ((_players[widget.myKey]?['score'] as int?) ?? 0) + 1;
    final round = (_room['round'] as int?) ?? 1;
    final maxR = (_room['maxRounds'] as int?) ?? 3;
    if (myScore >= (maxR / 2).ceil() + 1 || round >= maxR) {
      // Maç sona erdi
      await _ref.update({
        'status': 'finished', 'winner': widget.myKey,
        'players/${widget.myKey}/score': myScore,
      });
    } else {
      // Yeni raunt — HP sıfırla
      final oppFid = _players[_oppKey]?['fighterId'] as String? ?? 'warrior';
      final oppF = getFighter(oppFid);
      await _ref.update({
        'round': round + 1,
        'players/${widget.myKey}/hp': widget.fighter.maxHp,
        'players/${widget.myKey}/score': myScore,
        'players/$_oppKey/hp': oppF.maxHp,
        'players/$_oppKey/shield': false,
        'players/$_oppKey/poisoned': false,
        'players/$_oppKey/burning': false,
      });
      _addLog('🏆 Raunt $round kazandın!');
    }
  }

  void _showHitFx() {
    setState(() => _showHit = true);
    _hitCtrl.forward(from: 0);
  }

  void _addLog(String msg) {
    setState(() {
      _actionLog.insert(0, msg);
      if (_actionLog.length > 5) _actionLog.removeLast();
    });
  }

  // Swipe gestures
  void _onSwipeStart(DragStartDetails d) => _swipeStart = d.localPosition;
  void _onSwipeEnd(DragEndDetails d) {
    if (_swipeStart == null) return;
    final vel = d.velocity.pixelsPerSecond;
    final spd = vel.distance;
    if (spd > 600) {
      // Hızlı swipe = özel saldırı
      if (!_specCd) _specialAttack();
    } else if (spd > 200) {
      // Normal swipe = saldırı
      _normalAttack();
    }
    _swipeStart = null;
  }

  void _showFinal() {
    if (!mounted) return;
    final winner = _room['winner'] as String? ?? '';
    final iWon = winner == widget.myKey;
    ProfileService.instance
        .reportGameResult(gameId: 'fighter', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());
    final oppData = _players[_oppKey];
    final myF = widget.fighter;
    final oppF = getFighter(oppData?['fighterId'] as String? ?? 'warrior');

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: iWon ? Colors.amber : Colors.red.shade800, width: 2)),
        title: Text(iWon ? '🏆 ZAFER!' : '💀 YENİLDİN',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: iWon ? Colors.amber : Colors.red.shade300,
                fontSize: 28, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [
              Text(myF.emoji, style: const TextStyle(fontSize: 44)),
              Text(widget.myName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(_players[widget.myKey]?['score'] as int?) ?? 0} raunt',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ]),
            Text('VS', style: TextStyle(color: Colors.red.shade400,
                fontSize: 20, fontWeight: FontWeight.bold)),
            Column(children: [
              Text(oppF.emoji, style: const TextStyle(fontSize: 44)),
              Text(oppData?['name'] as String? ?? '?',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(oppData?['score'] as int?) ?? 0} raunt',
                  style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ]),
        actions: [
          FilledButton(
            onPressed: () async {
              await _db.child('${GamePaths.fighter}/${widget.roomId}').remove();
              if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
            style: FilledButton.styleFrom(
                backgroundColor: iWon ? Colors.amber.shade700 : Colors.grey.shade800),
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty || _players.isEmpty) {
      return const Scaffold(backgroundColor: Color(0xFF1A0000),
          body: Center(child: CircularProgressIndicator(color: Colors.red)));
    }

    final oppData = _players[_oppKey];
    final oppF = getFighter(oppData?['fighterId'] as String? ?? 'warrior');
    final round = (_room['round'] as int?) ?? 1;
    final maxR = (_room['maxRounds'] as int?) ?? 3;
    final myScore = (_players[widget.myKey]?['score'] as int?) ?? 0;
    final oppScore = (oppData?['score'] as int?) ?? 0;
    final oppShield = (oppData?['shield'] as bool?) ?? false;
    final oppPoisoned = (oppData?['poisoned'] as bool?) ?? false;
    final oppBurning = (oppData?['burning'] as bool?) ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF100010),
      body: SafeArea(child: Column(children: [
        // HP barları + skor
        _FightHUD(
          myName: widget.myName, myEmoji: widget.fighter.emoji,
          myHp: _myHp, myMaxHp: _myMaxHp, myScore: myScore,
          oppName: oppData?['name'] as String? ?? '?',
          oppEmoji: oppF.emoji, oppHp: _oppHp, oppMaxHp: _oppMaxHp,
          oppScore: oppScore, round: round, maxR: maxR,
          oppShield: oppShield, oppPoisoned: oppPoisoned, oppBurning: oppBurning,
          myShield: _shieldOn,
        ),

        // Arena
        Expanded(child: GestureDetector(
          onPanStart: _onSwipeStart,
          onPanEnd: _onSwipeEnd,
          behavior: HitTestBehavior.opaque,
          child: Stack(children: [
            // Arka plan gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [const Color(0xFF1A0010), const Color(0xFF0A0020),
                      const Color(0xFF1A0000)],
                ),
              ),
            ),

            // Zemin çizgisi
            Positioned(bottom: 120, left: 0, right: 0,
                child: Container(height: 2,
                    decoration: BoxDecoration(gradient: LinearGradient(
                        colors: [Colors.transparent,
                            Colors.red.shade900.withAlpha(150), Colors.transparent])))),

            // Rakip karakter
            Positioned(top: 20, right: 30,
              child: AnimatedBuilder(
                animation: _hitFlash,
                builder: (_, __) => Column(children: [
                  Text(oppF.emoji, style: TextStyle(fontSize: 76,
                      shadows: _showHit ? [Shadow(
                          color: Colors.red.withAlpha((220 * _hitFlash.value).toInt()),
                          blurRadius: 20 * _hitFlash.value)] : [])),
                  // Durum ikonları
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    if (oppShield) const Text('🛡️', style: TextStyle(fontSize: 16)),
                    if (oppPoisoned) const Text('☠️', style: TextStyle(fontSize: 16)),
                    if (oppBurning) const Text('🔥', style: TextStyle(fontSize: 16)),
                  ]),
                ]),
              ),
            ),

            // Ben
            Positioned(bottom: 130, left: 30,
              child: AnimatedBuilder(
                animation: _myShake,
                builder: (_, __) => Transform.translate(
                  offset: Offset(_myShake.value, 0),
                  child: Column(children: [
                    if (_shieldOn)
                      const Text('🛡️', style: TextStyle(fontSize: 28)),
                    Text(widget.fighter.emoji,
                        style: TextStyle(fontSize: 76,
                            shadows: _shieldOn ? [const Shadow(
                                color: Colors.blueAccent, blurRadius: 20)] : [])),
                  ]),
                ),
              ),
            ),

            // Kombo göstergesi
            if (_combo > 1)
              Positioned(left: 0, right: 0, top: 100,
                child: Center(child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade900.withAlpha(200),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange)),
                  child: Text('×$_combo KOMBO!',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 18,
                          letterSpacing: 2)),
                )),
              ),

            // Aksiyon log
            Positioned(top: 8, left: 12, right: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                children: _actionLog.take(3).map((msg) => Text(msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)]))).toList()),
            ),

            // Swipe ipucu
            const Positioned(bottom: 10, left: 0, right: 0,
              child: Text('← Sürükle: Saldırı  |  Hızlı Sürükle: Özel ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 10)),
            ),
          ]),
        )),

        // Kontrol butonları
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A0000), Color(0xFF100010)])),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            // Normal saldırı
            _FightBtn(
              label: '⚔️', sublabel: _atkCd ? '...' : 'SALDIR',
              onTap: _normalAttack,
              active: !_atkCd && _alive,
              color: const Color(0xFFB71C1C),
              flex: 3,
            ),
            const SizedBox(width: 10),
            // Kalkan
            _FightBtn(
              label: '🛡️', sublabel: _shieldOn ? 'AKTİF' : 'BLOK',
              onTap: _activateShield,
              active: !_shieldOn && _alive,
              color: const Color(0xFF0D47A1),
            ),
            const SizedBox(width: 10),
            // Özel
            _FightBtn(
              label: '✨', sublabel: _specCd ? '...' : 'ÖZEL',
              onTap: _specialAttack,
              active: !_specCd && _alive,
              color: const Color(0xFF4A148C),
            ),
          ]),
        ),

        const BannerAdWidget(),
      ])),
    );
  }
}

// ── Widget helpers ────────────────────────────────────────────────────────────

class _FightHUD extends StatelessWidget {
  const _FightHUD({
    required this.myName, required this.myEmoji,
    required this.myHp, required this.myMaxHp, required this.myScore,
    required this.oppName, required this.oppEmoji,
    required this.oppHp, required this.oppMaxHp, required this.oppScore,
    required this.round, required this.maxR,
    required this.oppShield, required this.oppPoisoned, required this.oppBurning,
    required this.myShield,
  });
  final String myName, myEmoji, oppName, oppEmoji;
  final int myHp, myMaxHp, myScore, oppHp, oppMaxHp, oppScore, round, maxR;
  final bool oppShield, oppPoisoned, oppBurning, myShield;

  Color _hpColor(int hp, int max) {
    final pct = hp / max;
    if (pct > 0.5) return Colors.green.shade400;
    if (pct > 0.25) return Colors.yellow.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0D0000),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(children: [
      // Raunt göstergesi
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 1; i <= maxR; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < round ? Colors.amber
                  : i == round ? Colors.white : Colors.white24,
            ),
          ),
        const SizedBox(width: 8),
        Text('RAUNT $round/$maxR',
            style: const TextStyle(color: Colors.white70, fontSize: 10,
                fontWeight: FontWeight.w600, letterSpacing: 1)),
      ]),
      const SizedBox(height: 6),
      // HP barları
      Row(children: [
        // Ben
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(myEmoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(myName, style: const TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.bold)),
            if (myShield) const Text(' 🛡️', style: TextStyle(fontSize: 11)),
          ]),
          const SizedBox(height: 3),
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (myHp / myMaxHp).clamp(0.0, 1.0),
                backgroundColor: Colors.red.shade900.withAlpha(80),
                valueColor: AlwaysStoppedAnimation(_hpColor(myHp, myMaxHp)),
                minHeight: 14,
              )),
          Text('$myHp/$myMaxHp  ★$myScore',
              style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ])),

        // VS orta
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('VS', style: TextStyle(color: Colors.red.shade600,
                fontSize: 14, fontWeight: FontWeight.bold))),

        // Rakip
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (oppShield) const Text('🛡️ ', style: TextStyle(fontSize: 11)),
            if (oppPoisoned) const Text('☠️ ', style: TextStyle(fontSize: 11)),
            if (oppBurning) const Text('🔥 ', style: TextStyle(fontSize: 11)),
            Text(oppName, style: const TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(oppEmoji, style: const TextStyle(fontSize: 14)),
          ]),
          const SizedBox(height: 3),
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (oppHp / oppMaxHp).clamp(0.0, 1.0),
                backgroundColor: Colors.red.shade900.withAlpha(80),
                valueColor: AlwaysStoppedAnimation(_hpColor(oppHp, oppMaxHp)),
                minHeight: 14,
              )),
          Text('$oppHp/$oppMaxHp  ★$oppScore',
              style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ])),
      ]),
    ]),
  );
}

class _FightBtn extends StatelessWidget {
  const _FightBtn({required this.label, required this.sublabel,
      required this.onTap, required this.active, required this.color,
      this.flex = 1});
  final String label, sublabel;
  final VoidCallback onTap; final bool active;
  final Color color; final int flex;

  @override
  Widget build(BuildContext context) => Expanded(flex: flex, child: GestureDetector(
    onTap: active ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      height: 60,
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(colors: [color, color.withAlpha(180)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(colors: [Colors.grey.shade900, Colors.grey.shade800]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: active ? [BoxShadow(color: color.withAlpha(120), blurRadius: 10)] : [],
        border: Border.all(color: active ? color.withAlpha(200) : Colors.grey.shade700),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(fontSize: 20)),
        Text(sublabel, style: TextStyle(
            color: active ? Colors.white : Colors.white38,
            fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ]),
    ),
  ));
}
