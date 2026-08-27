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

// ═══════════════════════════════════════════════════════════════════
// CAR MODEL
// ═══════════════════════════════════════════════════════════════════

class CarData {
  final String id, name, emoji;
  final double maxSpeed, acceleration, handling;
  final Color color;
  const CarData({required this.id, required this.name, required this.emoji,
      required this.maxSpeed, required this.acceleration,
      required this.handling, required this.color});
}

const _cars = [
  CarData(id:'sport',  name:'Spor',    emoji:'🏎️', maxSpeed:1.0,  acceleration:0.7, handling:0.8, color:Color(0xFFE53935)),
  CarData(id:'muscle', name:'Muscle',  emoji:'🚗', maxSpeed:0.9,  acceleration:0.9, handling:0.6, color:Color(0xFF1565C0)),
  CarData(id:'rally',  name:'Rally',   emoji:'🚙', maxSpeed:0.8,  acceleration:0.8, handling:1.0, color:Color(0xFF2E7D32)),
  CarData(id:'turbo',  name:'Turbo',   emoji:'🚕', maxSpeed:1.1,  acceleration:0.6, handling:0.7, color:Color(0xFFF57F17)),
];

// ═══════════════════════════════════════════════════════════════════
// LOBBY
// ═══════════════════════════════════════════════════════════════════

class RacingLobbyScreen extends StatefulWidget {
  const RacingLobbyScreen({super.key});
  @override State<RacingLobbyScreen> createState() => _RacingLobbyState();
}

class _RacingLobbyState extends State<RacingLobbyScreen> {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _name; bool _loading = false;
  CarData _car = _cars[0];

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final n = await _storage.getPlayerName(); if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _name = n); else _ask();
  }
  Future<void> _ask() async {
    final n = await showNameDialog(context, current: _name, accentColor: const Color(0xFFE53935));
    if (n == null || !mounted) return;
    await _storage.setPlayerName(n); setState(() => _name = n);
  }

  Future<void> _create() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final id = await _rooms.createRoom(gamePath: GamePaths.racing, data: {
        'code': code, 'status': 'waiting', 'laps': 3,
        'createdAt': ServerValue.timestamp,
        'players': {'p1': {
          'name': _name, 'isHost': true, 'carId': _car.id,
          'x': 0.3, 'y': 0.8, 'angle': 0.0, 'speed': 0.0,
          'lap': 0, 'checkpoint': 0, 'finished': false, 'score': 0,
        }},
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          RacingRoomScreen(roomId: id, myKey: 'p1', myName: _name!, car: _car)));
    } catch (e) { _snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _join() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.racing, code: code);
      if (r == null) { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { _snack('Yarış başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 4) { _snack('Oda dolu (max 4)'); return; }
      final myKey = 'p${players.length + 1}';
      final startX = 0.3 + players.length * 0.1;
      await _rooms.updateRoom(gamePath: GamePaths.racing, roomId: r.id,
          updates: {'players/$myKey': {
            'name': _name, 'isHost': false, 'carId': _car.id,
            'x': startX, 'y': 0.8, 'angle': 0.0, 'speed': 0.0,
            'lap': 0, 'checkpoint': 0, 'finished': false, 'score': 0,
          }});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          RacingRoomScreen(roomId: r.id, myKey: myKey, myName: _name!, car: _car)));
    } catch (e) { _snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
    gradient: const LinearGradient(
      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    child: Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context))),
          const Text('🏁', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          const Text('ARABA YARIŞI', style: TextStyle(color: Colors.white, fontSize: 26,
              fontWeight: FontWeight.bold, letterSpacing: 2)),
          const Text('2-4 Oyuncu · 3 Tur · Üstten görünüş',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          // Araba seçimi
          const Text('ARABANIZI SEÇİN', style: TextStyle(color: Colors.white70,
              fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: _cars.map((c) {
              final sel = c.id == _car.id;
              return GestureDetector(
                onTap: () => setState(() => _car = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel ? c.color.withAlpha(180) : Colors.white12,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? Colors.white : Colors.white24, width: sel ? 2 : 1),
                  ),
                  child: Column(children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 28)),
                    Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.bold)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Seçili araba stats
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _car.color.withAlpha(60),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _car.color.withAlpha(120))),
            child: Column(children: [
              Text('${_car.emoji} ${_car.name}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _StatBarW('🏎️ Hız', _car.maxSpeed, Colors.red),
              _StatBarW('⚡ İvme', _car.acceleration, Colors.orange),
              _StatBarW('🎮 Kontrol', _car.handling, Colors.green),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(onTap: _ask, child: AZFrostCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(_name ?? 'Ad seç', style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 20),
          AZButton(label: 'ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
              onPressed: _create, color: const Color(0xFFE53935), loading: _loading, width: 280),
          const SizedBox(height: 20),
          const Text('— veya —', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          AZFrostCard(child: Column(children: [
            AZCodeField(controller: _codeCtrl),
            const SizedBox(height: 14),
            AZJoinButton(onPressed: _join, loading: _loading),
          ])),
          const SizedBox(height: 20),
          AZFrostCard(opacity: 0.1, child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏁 Nasıl Oynanır?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Ekrana basılı tut = gaz\n'
                  '• Sol/Sağ butonlarla dön\n'
                  '• Checkpoint\'leri sırayla geç\n'
                  '• 3 turu bitiren kazanır!\n'
                  '• Turuncu ışık = drift bonusu ✨',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
            ],
          )),
          const SizedBox(height: 16),
        ]),
      )),
      const AdaptiveBannerAdWidget(),
    ]),
  );
}

class _StatBarW extends StatelessWidget {
  const _StatBarW(this.label, this.val, this.color);
  final String label; final double val; final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: val, backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color), minHeight: 10),
      )),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// ROOM
// ═══════════════════════════════════════════════════════════════════

class RacingRoomScreen extends StatefulWidget {
  const RacingRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName, required this.car});
  final String roomId, myKey, myName; final CarData car;
  @override State<RacingRoomScreen> createState() => _RRoomState();
}

class _RRoomState extends State<RacingRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override void initState() { super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.racing, roomId: widget.roomId).listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.racing, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: _isHost);
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    final players = (d['players'] as Map?) ?? {};
    if (players.isEmpty) {
      _rooms.deleteRoom(gamePath: GamePaths.racing, roomId: widget.roomId);
      if (mounted) Navigator.pop(context); return;
    }
    if (d['status'] == 'racing' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          RacingGameScreen(roomId: widget.roomId, myKey: widget.myKey,
              myName: widget.myName, car: widget.car)));
    }
  }

  Map get _players => (_room['players'] as Map?) ?? {};
  String get _code => _room['code'] ?? '------';
  bool get _isHost => widget.myKey == 'p1';
  bool get _canStart => _players.length >= 2;

  Future<void> _start() async {
    if (!_canStart) { _snack('En az 2 oyuncu'); return; }
    await _rooms.updateRoom(gamePath: GamePaths.racing, roomId: widget.roomId,
        updates: {'status': 'racing', 'startTime': ServerValue.timestamp});
  }

  Future<void> _leave() async {
    final pl = Map.from(_players)..remove(widget.myKey);
    if (pl.isEmpty || _isHost) {
      await _rooms.deleteRoom(gamePath: GamePaths.racing, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(gamePath: GamePaths.racing, roomId: widget.roomId, playerKey: widget.myKey);
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => PopScope(canPop: false, onPopInvoked: (_) => _leave(),
    child: AZGradientScaffold(
      gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
          const Expanded(child: Text('🏁 ARABA YARIŞI', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(width: 48),
        ]),
        const SizedBox(height: 20),
        AZRoomCode(code: _code, accentColor: const Color(0xFFE53935)),
        const SizedBox(height: 20),
        AZFrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pilotlar (${_players.length}/4)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          ..._players.entries.map((e) {
            final carId = e.value['carId'] as String? ?? 'sport';
            final c = _cars.firstWhere((c) => c.id == carId, orElse: () => _cars[0]);
            return AZPlayerTile(name: '${c.emoji} ${e.value['name'] ?? e.key}',
                isMe: e.key == widget.myKey, isHost: e.value['isHost'] == true,
                emoji: c.emoji, present: true);
          }),
          if (!_canStart) const Text('En az 2 pilot gerekli',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
        ])),
        const Spacer(),
        if (_isHost) AZButton(label: 'YARISMAYI BAŞLAT! 🏁', icon: Icons.sports_motorsports_rounded,
            onPressed: _canStart ? _start : null,
            color: const Color(0xFFE53935), width: double.infinity)
        else const AZWaitingCard(message: 'Host yarışı başlatacak...'),
      ])),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// GAME — Top-down racer
// ═══════════════════════════════════════════════════════════════════

// Pist checkpointleri (normalize 0-1)
const _checkpoints = [
  Offset(0.5, 0.12),  // üst merkez
  Offset(0.88, 0.30), // sağ üst
  Offset(0.88, 0.70), // sağ alt
  Offset(0.5, 0.88),  // alt merkez
  Offset(0.12, 0.70), // sol alt
  Offset(0.12, 0.30), // sol üst
];

class RacingGameScreen extends StatefulWidget {
  const RacingGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName, required this.car});
  final String roomId, myKey, myName; final CarData car;
  @override State<RacingGameScreen> createState() => _RGameState();
}

class _RGameState extends State<RacingGameScreen> with SingleTickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  final _rooms = RoomService.instance;
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  bool _roomGone = false;

  // Fizik state
  double _x = 0.5, _y = 0.75, _angle = -pi / 2;
  double _speed = 0.0, _angularVel = 0.0;
  bool _gasDown = false, _leftDown = false, _rightDown = false, _brakeDown = false;
  int _myLap = 0, _myCheckpoint = 0;
  bool _finished = false;
  double _drift = 0.0;

  Timer? _physicsTimer;
  Timer? _syncTimer;
  Timer? _countdownTimer;
  late AnimationController _countdownCtrl;
  int _countdown = 3;
  bool _started = false;
  int? _startTimeMs;

  static const _laps = 3;
  static const _countdownMs = 3000;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.racing}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFB);
    _loadStartPosition();
    _countdownCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    // Geri sayım artık _onFB'de, odanın paylaşılan 'startTime' sunucu zaman
    // damgasından tetikleniyor (bkz. _scheduleCountdown) — burada BAĞIMSIZ
    // bir zamanlayıcı başlatmıyoruz.
  }

  @override void dispose() {
    _physicsTimer?.cancel(); _syncTimer?.cancel(); _countdownTimer?.cancel();
    _countdownCtrl.dispose(); _sub?.cancel(); super.dispose();
  }

  // Eskiden her oyuncu, KENDİ ekranı ne zaman açılırsa açılsın bağımsız bir
  // "3-2-1-GO" sayacı başlatıyordu — ağ/navigasyon gecikmesi farkı yüzünden
  // oyuncular gerçekte aynı anda başlamıyordu (biri diğerinden yüzlerce ms
  // önce gaza basabiliyordu). Artık host'un yarışı başlattığı ANI (odaya
  // yazılan ServerValue.timestamp) ortak referans alıyoruz — TÜM oyuncuların
  // "GO!" anı, cihaz/ağ farkından bağımsız olarak gerçek zamanda aynı.
  void _scheduleCountdown() {
    if (_startTimeMs == null || _started) return;
    void tick() {
      if (!mounted) return;
      final elapsed = DateTime.now().millisecondsSinceEpoch - _startTimeMs!;
      final remaining = ((_countdownMs - elapsed) / 1000).ceil();
      if (remaining <= 0) {
        _countdownTimer?.cancel();
        if (mounted) setState(() => _countdown = 0);
        _startRace();
      } else if (mounted) {
        setState(() => _countdown = remaining);
      }
    }
    tick();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 150), (_) => tick());
  }

  // Lobide her oyuncuya farklı bir başlangıç X'i atanıyor (bkz.
  // RacingLobbyScreen._create/_join) ama fizik state'i sabit değerlerle
  // başlıyordu — bu yüzden tüm arabalar görsel olarak aynı noktada üst
  // üste başlıyordu. Bir kerelik okuma ile gerçek başlangıç X'ini alıyoruz;
  // Y ve açı, pist yönüne göre doğru olan sabit değerlerde kalıyor.
  Future<void> _loadStartPosition() async {
    final snap = await _ref.child('players/${widget.myKey}/x').get();
    if (!mounted || !snap.exists) return;
    final startX = (snap.value as num?)?.toDouble();
    if (startX == null) return;
    setState(() => _x = startX);
  }

  void _onFB(DatabaseEvent e) {
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
        _scheduleCountdown();
      }
    }
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true; AdService.instance.onGameEnd();
      _physicsTimer?.cancel(); _syncTimer?.cancel(); _countdownTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), _showFinal);
    }
  }

  void _startRace() {
    if (!mounted) return;
    setState(() => _started = true);
    // 60fps fizik
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _physicsTick());
    // 10fps Firebase sync
    _syncTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _syncToFirebase());
  }

  // Rakip arabaların en son bilinen Firebase konumu/açısı (10fps'te
  // güncellenir) doğrudan çizilirse araba her ~100ms'de bir yerinde
  // "ışınlanıyormuş" gibi görünür. Bunun yerine, 60fps'lik bu fizik
  // döngüsünde her tikte hedefe doğru küçük bir adım atarak (üstel
  // yumuşatma) akıcı bir hareket hissi veriyoruz.
  final Map<String, Offset> _oppRenderPos = {};
  final Map<String, double> _oppRenderAngle = {};

  void _smoothOpponentsInPlace() {
    final players = (_room['players'] as Map?) ?? {};
    for (final entry in players.entries) {
      final key = entry.key as String;
      if (key == widget.myKey) continue;
      final data = entry.value as Map;
      final targetX = (data['x'] as num?)?.toDouble() ?? 0.5;
      final targetY = (data['y'] as num?)?.toDouble() ?? 0.5;
      final targetAngle = (data['angle'] as num?)?.toDouble() ?? 0.0;
      final curX = _oppRenderPos[key]?.dx ?? targetX;
      final curY = _oppRenderPos[key]?.dy ?? targetY;
      final curAngle = _oppRenderAngle[key] ?? targetAngle;
      const smooth = 0.22;
      // Açı farkını en kısa yoldan al (ör. -π'den +π'ye sıçramayı önler).
      var da = targetAngle - curAngle;
      while (da > pi) da -= 2 * pi;
      while (da < -pi) da += 2 * pi;
      _oppRenderPos[key] = Offset(
          curX + (targetX - curX) * smooth, curY + (targetY - curY) * smooth);
      _oppRenderAngle[key] = curAngle + da * smooth;
    }
  }

  void _physicsTick() {
    if (!mounted || !_started) return;
    setState(() {
      // Rakip yumuşatması, ben bitirsem bile (ekranda hâlâ diğerlerini
      // izlerken) çalışmaya devam etmeli — bu yüzden erken dönüşten önce.
      _smoothOpponentsInPlace();
      if (_finished) return;

      final car = widget.car;
      const dt = 0.016;
      const maxSpd = 0.006;

      // Dönüş
      final turnRate = 2.5 * car.handling;
      if (_leftDown)  _angularVel = -turnRate;
      else if (_rightDown) _angularVel = turnRate;
      else _angularVel *= 0.7;

      _angle += _angularVel * dt;
      _drift = (_angularVel * _speed * 20).clamp(-1.0, 1.0);

      // Hız
      final accel = car.acceleration * 0.00025;
      final brake = 0.0004;
      if (_gasDown && !_brakeDown) {
        _speed = (_speed + accel).clamp(0.0, maxSpd * car.maxSpeed);
      } else if (_brakeDown) {
        _speed = (_speed - brake).clamp(0.0, maxSpd * car.maxSpeed);
      } else {
        _speed *= 0.97; // friction
      }

      // Hareket
      _x += cos(_angle) * _speed;
      _y += sin(_angle) * _speed;

      // Duvar çarpışması
      if (_x < 0.06) { _x = 0.06; _speed *= 0.5; }
      if (_x > 0.94) { _x = 0.94; _speed *= 0.5; }
      if (_y < 0.06) { _y = 0.06; _speed *= 0.5; }
      if (_y > 0.94) { _y = 0.94; _speed *= 0.5; }

      // Checkpoint kontrolü
      final nextCp = _checkpoints[_myCheckpoint % _checkpoints.length];
      final dx = _x - nextCp.dx; final dy = _y - nextCp.dy;
      if (dx * dx + dy * dy < 0.004) {
        _myCheckpoint++;
        HapticFeedback.lightImpact();
        if (_myCheckpoint % _checkpoints.length == 0) {
          _myLap++;
          HapticFeedback.heavyImpact();
          if (_myLap >= _laps) _finish();
        }
      }
    });
  }

  Future<void> _syncToFirebase() async {
    if (!_started) return;
    await _ref.update({
      'players/${widget.myKey}/x': _x,
      'players/${widget.myKey}/y': _y,
      'players/${widget.myKey}/angle': _angle,
      'players/${widget.myKey}/speed': _speed,
      'players/${widget.myKey}/lap': _myLap,
      'players/${widget.myKey}/checkpoint': _myCheckpoint,
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    setState(() { _finished = true; _speed = 0; });
    _physicsTimer?.cancel();
    final players = (_room['players'] as Map?) ?? {};
    // Sıralama artık burada YEREL (potansiyel olarak eski) veriden tahmin
    // edilip yazılmıyor — foto-finişte iki oyuncu, birbirinin bitişini henüz
    // görmemiş olabileceğinden aynı anda "1. sıra" yazabiliyordu. Bunun
    // yerine sadece sunucu zaman damgalı 'finishedAt' yazılıyor; gerçek
    // sıralama, TÜM bitiş zamanları toplandıktan sonra _showFinal()'da bu
    // damgalara göre türetiliyor — bu asla çakışmaz.
    await _ref.update({
      'players/${widget.myKey}/finished': true,
      'players/${widget.myKey}/finishedAt': ServerValue.timestamp,
    });
    // Herkes bitirince oyun biter — sadece 1. olan kişi bitirdi diye
    // yarışı tüm oyuncular için erken kesmemeli (önceden "pos == 1" de
    // bu koşulu tetikliyordu, bu da hâlâ pistte olan diğer oyuncuların
    // fizik motorunu anında durduruyordu).
    final allFinished = players.length == (players.values.where((p) => p['finished'] == true).length + 1);
    if (allFinished) {
      await _ref.update({'status': 'finished', 'winner': widget.myKey});
    }
  }

  /// Aktif yarış ekranında önceden HİÇBİR çıkış yolu yoktu. Bu sadece
  /// rahatsız edici değildi — biri bitirmeden ayrılırsa (geri tuşu/uygulamayı
  /// kapatma), kalan herkes bitirmiş olsa bile "herkes bitirsin" kontrolü
  /// hiç tetiklenmiyor ve bitiş ekranı sonsuza dek gelmiyordu.
  Future<void> _leaveGame() async {
    final remaining = Map<String, dynamic>.from((_room['players'] as Map?) ?? {})
      ..remove(widget.myKey);
    if (remaining.isEmpty) {
      await _rooms.deleteRoom(gamePath: GamePaths.racing, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(
          gamePath: GamePaths.racing, roomId: widget.roomId, playerKey: widget.myKey);
      final allDone = remaining.values.every((p) => (p as Map)['finished'] == true);
      if (allDone) {
        await _ref.update({'status': 'finished', 'winner': remaining.keys.first});
      }
    }
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yarıştan çık?'),
        content: const Text('Aktif bir yarışın ortasındasın. Çıkarsan bu geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Çık')),
        ],
      ),
    );
    if (ok == true) await _leaveGame();
  }

  void _showFinal() {
    if (!mounted) return;
    final players = (_room['players'] as Map?) ?? {};
    // Sıralama, her oyuncunun 'finishedAt' SUNUCU zaman damgasına göre
    // türetiliyor — bitmemiş (finishedAt'ı olmayan, örn. yarışı hiç
    // bitiremeden odadan atılan) oyuncular en sona atılır.
    final sorted = players.entries.toList()
      ..sort((a, b) {
        final fa = a.value['finishedAt'] as int?;
        final fb = b.value['finishedAt'] as int?;
        if (fa == null && fb == null) return 0;
        if (fa == null) return 1;
        if (fb == null) return -1;
        return fa.compareTo(fb);
      });
    const medals = ['🥇', '🥈', '🥉', '4.'];
    const scores = [100, 75, 50, 25];

    final myIndex = sorted.indexWhere((e) => e.key == widget.myKey);
    if (myIndex != -1) {
      ProfileService.instance
          .reportGameResult(gameId: 'racing', won: myIndex == 0)
          .then((_) => AchievementService.instance.checkAndUnlock());
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      title: const Text('🏁 Yarış Bitti!', textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min,
        children: sorted.asMap().entries.map((e) {
          final isMe = e.value.key == widget.myKey;
          final pos = e.key + 1;
          final score = scores[min(pos - 1, scores.length - 1)];
          final carId = e.value.value['carId'] as String? ?? 'sport';
          final c = _cars.firstWhere((c) => c.id == carId, orElse: () => _cars[0]);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: isMe ? Colors.orange.shade50 : null,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Text(pos <= medals.length ? medals[pos - 1] : '?',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(c.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value.value['name'] as String? ?? e.value.key,
                  style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal))),
              Text('$score pt', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList(),
      ),
      actions: [FilledButton(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
        onPressed: () async {
          await _db.child('${GamePaths.racing}/${widget.roomId}').remove();
          if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
        },
        child: const Text('Ana Menü'),
      )],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final players = (_room['players'] as Map?) ?? {};

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _confirmLeave(),
      child: Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: SafeArea(child: Column(children: [
        // HUD üst
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF23233F), Color(0xFF1A1A2E)],
            ),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _confirmLeave),
            const SizedBox(width: 4),
            Text('Tur: $_myLap/$_laps',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 16),
            Text('Hız: ${(_speed * 1000).toStringAsFixed(0)} km/h',
                style: TextStyle(color: Colors.yellow.shade300, fontSize: 13)),
            const Spacer(),
            ...players.entries.map((e) {
              final isMe = e.key == widget.myKey;
              final lap = (e.value['lap'] as int?) ?? 0;
              final carId = e.value['carId'] as String? ?? 'sport';
              final c = _cars.firstWhere((cd) => cd.id == carId, orElse: () => _cars[0]);
              return Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: isMe ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${c.emoji}$lap',
                    style: TextStyle(color: isMe ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 12)),
              );
            }),
          ]),
        ),

        // Pist
        Expanded(child: LayoutBuilder(builder: (_, constraints) {
          final W = constraints.maxWidth;
          final H = constraints.maxHeight;
          return GestureDetector(
            child: Stack(children: [
              // Zemin
              CustomPaint(size: Size(W, H),
                  painter: _TrackPainter(checkpoints: _checkpoints,
                      myCheckpoint: _myCheckpoint % _checkpoints.length)),

              // Rakip arabalar — 10fps ağ verisi yerine yumuşatılmış
              // (_smoothOpponentsInPlace) konum kullanılır, böylece araba
              // her senkronizasyonda ışınlanmak yerine akıcı kayar.
              ...players.entries.where((e) => e.key != widget.myKey).map((e) {
                final smoothed = _oppRenderPos[e.key];
                final ox = (smoothed?.dx ?? (e.value['x'] as num?)?.toDouble() ?? 0.5) * W;
                final oy = (smoothed?.dy ?? (e.value['y'] as num?)?.toDouble() ?? 0.5) * H;
                final oa = _oppRenderAngle[e.key] ?? (e.value['angle'] as num?)?.toDouble() ?? 0.0;
                final carId = e.value['carId'] as String? ?? 'sport';
                final c = _cars.firstWhere((cd) => cd.id == carId, orElse: () => _cars[0]);
                return Positioned(left: ox - 14, top: oy - 14,
                    // Araba emojileri varsayılan olarak sola bakar; hareket
                    // matematiği açı 0'da sağa gitmeyi varsayıyor — +pi
                    // düzeltmesi olmadan araba hep ters yöne bakar.
                    child: Transform.rotate(angle: oa + pi,
                        child: _CarSprite(emoji: c.emoji, color: c.color, size: 28)));
              }),

              // Benim arabam
              Positioned(left: _x * W - 16, top: _y * H - 16,
                child: Transform.rotate(angle: _angle + pi,
                  child: _CarSprite(emoji: widget.car.emoji, color: widget.car.color,
                      size: 32, isMe: true, drift: _drift.abs())),
              ),

              // Countdown
              if (!_started)
                Center(child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.yellow, width: 3)),
                  child: Text(_countdown > 0 ? '$_countdown' : 'GO!',
                      style: TextStyle(color: _countdown > 0 ? Colors.white : Colors.green,
                          fontSize: 48, fontWeight: FontWeight.bold)),
                )),

              // Finish banner
              if (_finished)
                Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(color: Colors.black87,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('🏁 BİTTİ!',
                      style: TextStyle(color: Colors.amber, fontSize: 32,
                          fontWeight: FontWeight.bold)),
                )),
            ]),
          );
        })),

        // Kontroller
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF13131F)],
            ),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, -4))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            // Sol
            _CtrlBtn(label: '◀', onDown: () => setState(() => _leftDown = true),
                onUp: () => setState(() => _leftDown = false), color: Colors.blue),
            const SizedBox(width: 8),
            // Fren
            _CtrlBtn(label: '🔴', onDown: () => setState(() => _brakeDown = true),
                onUp: () => setState(() => _brakeDown = false), color: Colors.red.shade800),
            const Spacer(),
            // Gaz
            _CtrlBtn(label: '⚡ GAZ', onDown: () => setState(() => _gasDown = true),
                onUp: () => setState(() => _gasDown = false),
                color: _gasDown ? Colors.green.shade700 : Colors.green.shade900,
                wide: true),
            const Spacer(),
            // Sağ
            _CtrlBtn(label: '▶', onDown: () => setState(() => _rightDown = true),
                onUp: () => setState(() => _rightDown = false), color: Colors.blue),
          ]),
        ),

        const BannerAdWidget(),
      ])),
      ),
    );
  }
}

class _CarSprite extends StatelessWidget {
  const _CarSprite({required this.emoji, required this.color, required this.size,
      this.isMe = false, this.drift = 0});
  final String emoji; final Color color; final double size;
  final bool isMe; final double drift;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
    // Zemin gölgesi — arabayı pistin üstünde "havada" gibi hissettirir.
    Positioned(
      left: size * 0.1, top: size * 0.72,
      child: Container(
        width: size * 0.8, height: size * 0.28,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(90),
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    ),
    Container(
      width: size, height: size,
      decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.5),
            colors: [Color.lerp(color, Colors.white, 0.35)!.withAlpha(isMe ? 220 : 150), color.withAlpha(isMe ? 200 : 130)],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isMe ? (drift > 0.3 ? Colors.orange : Colors.white) : Colors.white30,
              width: isMe ? 2 : 1),
          boxShadow: [BoxShadow(
              color: (isMe && drift > 0.3 ? Colors.orange : Colors.black).withAlpha(isMe ? 160 : 100),
              blurRadius: isMe ? 10 : 6, offset: const Offset(0, 3))]),
      child: Center(child: Text(emoji,
          style: TextStyle(fontSize: size * 0.5))),
    ),
  ]);
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({required this.checkpoints, required this.myCheckpoint});
  final List<Offset> checkpoints; final int myCheckpoint;

  @override
  void paint(Canvas canvas, Size s) {
    // Zemin
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()..color = const Color(0xFF4CAF50));

    // Pist (kapalı devre — oval/döngüsel)
    final pts = checkpoints.map((cp) => Offset(cp.dx * s.width, cp.dy * s.height)).toList();

    final trackPaint = Paint()
      ..color = const Color(0xFF616161) ..strokeWidth = s.width * 0.18
      ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
    path.close();
    canvas.drawPath(path, trackPaint);

    // Pist çizgisi
    final linePaint = Paint()
      ..color = Colors.white.withAlpha(80) ..strokeWidth = s.width * 0.002
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Checkpointler
    for (var i = 0; i < pts.length; i++) {
      final past = i < myCheckpoint;
      canvas.drawCircle(pts[i], 14,
          Paint()..color = past ? Colors.green.withAlpha(180) : Colors.yellow.withAlpha(180));
      canvas.drawCircle(pts[i], 14,
          Paint()..color = Colors.white ..style = PaintingStyle.stroke ..strokeWidth = 2);
    }

    // Start/Finish
    canvas.drawRect(Rect.fromCenter(center: pts[0], width: s.width * 0.18, height: 4),
        Paint()..color = Colors.white);
    // Dama deseni
    final checkPaint = Paint()..color = Colors.black;
    for (var i = 0; i < 6; i++) {
      if (i % 2 == 0) canvas.drawRect(
          Rect.fromLTWH(pts[0].dx - s.width * 0.09 + i * s.width * 0.03,
              pts[0].dy - 2, s.width * 0.03, 4), checkPaint);
    }
  }

  @override bool shouldRepaint(_TrackPainter o) => o.myCheckpoint != myCheckpoint;
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({required this.label, required this.onDown, required this.onUp,
      required this.color, this.wide = false});
  final String label; final VoidCallback onDown, onUp;
  final Color color; final bool wide;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => onDown(),
    onTapUp: (_) => onUp(),
    onTapCancel: onUp,
    child: Container(
      width: wide ? 100 : 60, height: 54,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withAlpha(150), blurRadius: 8)]),
      child: Center(child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
    ),
  );
}
