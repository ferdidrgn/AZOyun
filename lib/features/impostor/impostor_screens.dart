import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// "HAİN KİM?" — Among Us'tan ilham alan, özgün temalı görev + gizli hain oyunu.
// Vampir Köylü ile aynı Firebase oda altyapısını kullanır.
// ═══════════════════════════════════════════════════════════════════════════

const _kTasksPerPlayer = 5;
const _kTaskDefs = [
  ('Kabloları Bağla', '🔌'),
  ('Motoru Kalibre Et', '⚙️'),
  ('Yakıt Doldur', '⛽'),
  ('Atıkları Boşalt', '🗑️'),
  ('Reaktörü Onar', '🔋'),
];
const _kMinPlayers = 4;
const _kMaxPlayers = 10;
const _kSpaceGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
);

int _impostorCountFor(int players) => players >= 7 ? 2 : 1;

// ═══════════════════════════════════════════════════════════════════════════
// LOBBY
// ═══════════════════════════════════════════════════════════════════════════

class ImpostorLobbyScreen extends StatefulWidget {
  const ImpostorLobbyScreen({super.key});
  @override
  State<ImpostorLobbyScreen> createState() => _ImpostorLobbyScreenState();
}

class _ImpostorLobbyScreenState extends State<ImpostorLobbyScreen> {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _name;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final n = await _storage.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty) {
      setState(() => _name = n);
    } else {
      _ask();
    }
  }

  Future<void> _ask() async {
    final n = await showNameDialog(context, current: _name, accentColor: const Color(0xFF2C5364));
    if (n == null || !mounted) return;
    await _storage.setPlayerName(n);
    setState(() => _name = n);
  }

  Future<void> _create() async {
    if (_name == null) {
      await _ask();
      if (_name == null) return;
    }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final id = await _rooms.createRoom(gamePath: GamePaths.impostor, data: {
        'code': code,
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'phase': 'playing',
        'players': {
          'p1': {'name': _name, 'isHost': true, 'role': null, 'alive': true, 'vote': ''}
        },
      });
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ImpostorRoomScreen(roomId: id, myKey: 'p1', myName: _name!)));
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    if (_name == null) {
      await _ask();
      if (_name == null) return;
    }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      _snack('6 haneli kodu girin');
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.impostor, code: code);
      if (r == null) {
        _snack('Oda bulunamadı');
        return;
      }
      if (r.data['status'] != 'waiting') {
        _snack('Oyun başlamış');
        return;
      }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= _kMaxPlayers) {
        _snack('Oda dolu');
        return;
      }
      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(
        gamePath: GamePaths.impostor,
        roomId: r.id,
        updates: {
          'players/$myKey': {'name': _name, 'isHost': false, 'role': null, 'alive': true, 'vote': ''}
        },
      );
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ImpostorRoomScreen(roomId: r.id, myKey: myKey, myName: _name!)));
    } catch (e) {
      _snack('Katılınamadı: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
        gradient: _kSpaceGradient,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context)),
                ),
                const Text('👨‍🚀', style: TextStyle(fontSize: 72)),
                const Text('HAİN KİM?',
                    style: TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const Text('4-10 Oyuncu · Görevleri tamamla ya da haini bul',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _ask,
                  child: AZFrostCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(_name ?? 'Ad seç',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                AZButton(
                    label: 'YENİ ODA',
                    icon: Icons.add_circle_outline_rounded,
                    onPressed: _create,
                    color: const Color(0xFF2C5364),
                    loading: _loading,
                    width: 280),
                const SizedBox(height: 20),
                const Text('— veya —', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 20),
                AZFrostCard(
                  child: Column(children: [
                    AZCodeField(controller: _codeCtrl),
                    const SizedBox(height: 14),
                    AZJoinButton(onPressed: _join, loading: _loading),
                  ]),
                ),
                const SizedBox(height: 24),
                AZFrostCard(
                  opacity: 0.08,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('👨‍🚀 Nasıl oynanır?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 8),
                      Text(
                        '• 4-10 oyuncu, 1-2 gizli hain\n'
                        '• Mürettebat görevleri tamamlar\n'
                        '• Hain(ler) mürettebatı eler\n'
                        '• Şüphelenen "Acil Toplantı" çağırıp oylama başlatır\n'
                        '• Tüm görevler biter ya da hainler elenirse mürettebat kazanır\n'
                        '• Hainler mürettebata sayıca eşitlenirse hainler kazanır',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const AdaptiveBannerAdWidget(),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOM (BEKLEME ODASI)
// ═══════════════════════════════════════════════════════════════════════════

class ImpostorRoomScreen extends StatefulWidget {
  const ImpostorRoomScreen({super.key, required this.roomId, required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override
  State<ImpostorRoomScreen> createState() => _ImpostorRoomScreenState();
}

class _ImpostorRoomScreenState extends State<ImpostorRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.impostor, roomId: widget.roomId).listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.impostor, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    final players = (d['players'] as Map?) ?? {};
    if (players.isEmpty) {
      _rooms.deleteRoom(gamePath: GamePaths.impostor, roomId: widget.roomId);
      if (mounted) Navigator.pop(context);
      return;
    }
    if (d['status'] == 'playing' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ImpostorGameScreen(roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)),
      );
    }
  }

  Map<String, dynamic> get _players => Map<String, dynamic>.from((_room['players'] as Map?) ?? {});
  String get _code => _room['code'] ?? '------';
  bool get _isHost => widget.myKey == 'p1';
  bool get _canStart => _players.length >= _kMinPlayers;

  Future<void> _start() async {
    if (!_canStart) {
      _snack('En az $_kMinPlayers oyuncu');
      return;
    }
    final keys = _players.keys.toList()..shuffle(Random.secure());
    final impostorCount = _impostorCountFor(keys.length);
    final updates = <String, dynamic>{'status': 'playing', 'phase': 'playing', 'lastEjected': ''};
    for (var i = 0; i < keys.length; i++) {
      final isImpostor = i < impostorCount;
      updates['players/${keys[i]}/role'] = isImpostor ? 'impostor' : 'crew';
      updates['players/${keys[i]}/vote'] = '';
      updates['players/${keys[i]}/alive'] = true;
      if (!isImpostor) {
        updates['players/${keys[i]}/tasks'] = List.filled(_kTasksPerPlayer, false);
      }
    }
    await _rooms.updateRoom(gamePath: GamePaths.impostor, roomId: widget.roomId, updates: updates);
  }

  Future<void> _leave() async {
    final pl = Map.from(_players)..remove(widget.myKey);
    if (pl.isEmpty || _isHost) {
      await _rooms.deleteRoom(gamePath: GamePaths.impostor, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(gamePath: GamePaths.impostor, roomId: widget.roomId, playerKey: widget.myKey);
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvoked: (_) => _leave(),
        child: AZGradientScaffold(
          gradient: _kSpaceGradient,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
                const Expanded(
                  child: Text('HAİN KİM?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 48),
              ]),
              const SizedBox(height: 20),
              AZRoomCode(code: _code, accentColor: const Color(0xFF4FC3F7)),
              const SizedBox(height: 20),
              AZFrostCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mürettebat (${_players.length}/$_kMaxPlayers)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  for (final e in _players.entries)
                    AZPlayerTile(
                        name: e.value['name'] as String? ?? e.key,
                        isMe: e.key == widget.myKey,
                        isHost: e.value['isHost'] == true,
                        emoji: '👨‍🚀',
                        present: true),
                  if (!_canStart)
                    Text('En az ${_kMinPlayers - _players.length} oyuncu daha',
                        style: const TextStyle(color: Colors.white54, fontSize: 13))
                  else
                    Text('${_impostorCountFor(_players.length)} gizli hain olacak',
                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ]),
              ),
              const Spacer(),
              if (_isHost)
                AZButton(
                    label: 'OYUNU BAŞLAT',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _canStart ? _start : null,
                    color: const Color(0xFF2C5364),
                    width: double.infinity)
              else
                const AZWaitingCard(message: 'Host oyunu başlatacak...'),
            ]),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME
// ═══════════════════════════════════════════════════════════════════════════

class ImpostorGameScreen extends StatefulWidget {
  const ImpostorGameScreen({super.key, required this.roomId, required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override
  State<ImpostorGameScreen> createState() => _ImpostorGameScreenState();
}

class _ImpostorGameScreenState extends State<ImpostorGameScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _rooms = RoomService.instance;
  late final DatabaseReference _ref = _db.child('${GamePaths.impostor}/${widget.roomId}');
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  bool _roleRevealShown = false;
  bool _processing = false;
  bool _roomGone = false;
  int? _completingTaskIndex;
  final Set<int> _fakeCompleted = {};
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sub = _ref.onValue.listen(_onFB);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _onFB(DatabaseEvent e) {
    if (!mounted) return;
    if (e.snapshot.value == null) {
      // Oda silindi (host oyundan ayrıldı ya da bağlantısı koptu) —
      // eskiden burada sessizce return edilirdi ve diğer oyuncuların ekranı
      // sonsuza dek donuk kalırdı. Artık herkesi ana menüye döndürüyoruz.
      if (!_roomGone) {
        _roomGone = true;
        Navigator.popUntil(context, (r) => r.isFirst);
      }
      return;
    }
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() => _room = d);
    if (!_roleRevealShown && (d['players']?[widget.myKey]?['role']) != null) {
      _roleRevealShown = true;
      Future.delayed(const Duration(milliseconds: 350), _showRoleReveal);
    }
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 300), _showFinal);
    }
    // Oy sayımını SADECE sabit 'p1' değil, o an CANLI olan en düşük anahtarlı
    // oyuncu yapar. Eskiden p1'e sabitlenmişti — p1 oyundan ayrılır ya da
    // bağlantısı koparsa oylama hiçbir zaman sonuçlanmıyordu (kalıcı kilit).
    if (!_processing &&
        widget.myKey == _voteTallyLeaderKey &&
        d['status'] == 'playing' &&
        (d['phase'] as String?) == 'voting') {
      _checkVotes(d);
    }
  }

  String? get _voteTallyLeaderKey {
    final aliveKeys = _players.entries
        .where((e) => (e.value['alive'] as bool?) == true)
        .map((e) => e.key)
        .toList()
      ..sort();
    return aliveKeys.isEmpty ? null : aliveKeys.first;
  }

  void _showRoleReveal() {
    if (!mounted) return;
    final isImpostor = _isImpostor;
    showRoleRevealCard(
      context,
      emoji: isImpostor ? '👽' : '👨‍🚀',
      title: isImpostor ? 'SEN GİZLİ HAİNSİN' : 'SEN MÜRETTEBATSIN',
      color: isImpostor ? const Color(0xFF7A0C2E) : const Color(0xFF0D5C63),
      description: isImpostor
          ? 'Kimse senin hain olduğunu bilmemeli. Görevleri sahte yaparak '
              'gizlen, fırsat bulunca mürettebatı tek tek ele. Mürettebat '
              'sayıca sana eşit ya da az kalırsa kazanırsın.'
          : 'Görevlerini tamamla, hain(ler)i gözlemle. Şüphelendiğinde '
              '"Acil Toplantı" çağırıp oylama başlatabilirsin. Tüm '
              'görevler biter ya da hainler elenirse kazanırsın.',
    );
  }

  Map<String, dynamic> get _players => Map<String, dynamic>.from((_room['players'] as Map?) ?? {});
  String get _phase => (_room['phase'] as String?) ?? 'playing';
  bool get _isVoting => _phase == 'voting';
  bool get _isAlive => (_players[widget.myKey]?['alive'] as bool?) ?? true;
  String get _myRole => (_players[widget.myKey]?['role'] as String?) ?? 'crew';
  bool get _isImpostor => _myRole == 'impostor';
  String get _myVote => (_players[widget.myKey]?['vote'] as String?) ?? '';
  bool get _hasVoted => _myVote.isNotEmpty;
  String? get _lastEjected {
    final v = _room['lastEjected'] as String?;
    return (v == null || v.isEmpty) ? null : v;
  }

  List<bool> _tasksOf(String key) =>
      ((_players[key]?['tasks'] as List?) ?? []).map((e) => e == true).toList();

  int get _tasksDone {
    var done = 0;
    for (final e in _players.entries) {
      if ((e.value['role'] as String?) == 'crew') done += _tasksOf(e.key).where((t) => t).length;
    }
    return done;
  }

  int get _tasksTotal => _players.values.where((v) => v['role'] == 'crew').length * _kTasksPerPlayer;

  List<MapEntry<String, dynamic>> get _aliveOthers =>
      _players.entries.where((e) => e.key != widget.myKey && (e.value['alive'] as bool?) == true).toList();

  List<MapEntry<String, dynamic>> get _killTargets =>
      _aliveOthers.where((e) => (e.value['role'] as String?) != 'impostor').toList();

  int get _votedCount {
    final alive = _players.entries.where((e) => (e.value['alive'] as bool?) == true);
    return alive.where((e) => ((e.value['vote'] as String?) ?? '').isNotEmpty).length;
  }

  int get _voterCount => _players.entries.where((e) => (e.value['alive'] as bool?) == true).length;

  bool get _canCallMeeting => _isAlive && !_isVoting;

  /// Firebase'de saklanır (players/$myKey/killCooldownUntil, epoch ms) —
  /// sadece yerel state olsaydı ekran yeniden oluştuğunda ya da başka bir
  /// ekrana gidip gelindiğinde bekleme süresi sıfırlanırdı.
  Duration? get _killCooldownLeft {
    final until = (_players[widget.myKey]?['killCooldownUntil'] as int?) ?? 0;
    if (until == 0) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  Future<void> _callMeeting() async {
    if (!_canCallMeeting) return;
    final updates = <String, dynamic>{'phase': 'voting', 'lastMeetingBy': widget.myName};
    for (final e in _players.entries) {
      updates['players/${e.key}/vote'] = '';
    }
    await _ref.update(updates);
  }

  Future<void> _vote(String key) async {
    if (_hasVoted || !_isAlive || !_isVoting) return;
    await _ref.update({'players/${widget.myKey}/vote': key});
  }

  Future<void> _checkVotes(Map<String, dynamic> d) async {
    if (_processing) return;
    final players = Map<String, dynamic>.from((d['players'] as Map?) ?? {});
    final alive = players.entries.where((e) => (e.value['alive'] as bool?) == true).toList();
    if (alive.isEmpty) return;
    final allVoted = alive.every((e) => ((e.value['vote'] as String?) ?? '').isNotEmpty);
    if (!allVoted) return;
    setState(() => _processing = true);
    try {
      final votes = <String, int>{};
      for (final v in alive) {
        final g = v.value['vote'] as String? ?? '';
        if (g.isNotEmpty) votes[g] = (votes[g] ?? 0) + 1;
      }
      String? topKey;
      var topCount = 0;
      var tie = false;
      votes.forEach((k, v) {
        if (v > topCount) {
          topCount = v;
          topKey = k;
          tie = false;
        } else if (v == topCount) {
          tie = true;
        }
      });
      final upd = <String, dynamic>{};
      for (final p in alive) {
        upd['players/${p.key}/vote'] = '';
      }
      String? ejected;
      if (!tie && topKey != null && topKey != 'skip') {
        ejected = topKey;
        upd['players/$ejected/alive'] = false;
      }
      upd['lastEjected'] = ejected ?? '';
      upd['phase'] = 'playing';
      await _ref.update(upd);
      await _checkWin();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Aktif oyun ekranında önceden HİÇBİR çıkış yolu yoktu — bir oyuncu geri
  /// tuşuna basıp uygulamayı arka plana alsa bile Firebase'deki kaydı
  /// silinmiyordu, bu da "herkes oy versin" bekleyen oylamayı sonsuza dek
  /// kilitleyebiliyordu. Artık kendini players'tan tamamen kaldırıyoruz —
  /// bu, oy sayımını ve mürettebat/hain oranını anında düzeltir.
  Future<void> _leaveGame() async {
    final remaining = Map<String, dynamic>.from(_players)..remove(widget.myKey);
    if (remaining.isEmpty) {
      await _rooms.deleteRoom(gamePath: GamePaths.impostor, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(
          gamePath: GamePaths.impostor, roomId: widget.roomId, playerKey: widget.myKey);
      await _checkWin();
    }
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _kill(String targetKey) async {
    if (!_isAlive || !_isImpostor || _killCooldownLeft != null) return;
    final cooldownUntil = DateTime.now().add(const Duration(seconds: 25)).millisecondsSinceEpoch;
    await _ref.update({
      'players/$targetKey/alive': false,
      'players/${widget.myKey}/killCooldownUntil': cooldownUntil,
      'lastKilled': targetKey,
    });
    await _checkWin();
  }

  Future<void> _completeTask(int index) async {
    if (!_isAlive) return;
    if (_isImpostor) {
      if (_fakeCompleted.contains(index)) return;
      setState(() => _completingTaskIndex = index);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() {
        _fakeCompleted.add(index);
        _completingTaskIndex = null;
      });
      return;
    }
    final myTasks = _tasksOf(widget.myKey);
    if (index >= myTasks.length || myTasks[index]) return;
    setState(() => _completingTaskIndex = index);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final updated = List<bool>.from(myTasks)..[index] = true;
    await _ref.update({'players/${widget.myKey}/tasks': updated});
    setState(() => _completingTaskIndex = null);
    await _checkWin();
  }

  Future<void> _checkWin() async {
    final snap = await _ref.child('players').get();
    if (!snap.exists) return;
    final players = Map<String, dynamic>.from(snap.value as Map);
    final alive = players.entries.where((e) => (e.value['alive'] as bool?) == true);
    final impostors = alive.where((e) => (e.value['role'] as String?) == 'impostor').length;
    final crew = alive.where((e) => (e.value['role'] as String?) == 'crew').length;
    var tasksDone = 0, tasksTotal = 0;
    for (final e in players.entries) {
      if ((e.value['role'] as String?) == 'crew') {
        final tasks = ((e.value['tasks'] as List?) ?? []).map((t) => t == true).toList();
        tasksDone += tasks.where((t) => t).length;
        tasksTotal += _kTasksPerPlayer;
      }
    }
    if (impostors == 0) {
      await _ref.update({'status': 'finished', 'winner': 'crew'});
    } else if (impostors >= crew) {
      await _ref.update({'status': 'finished', 'winner': 'impostors'});
    } else if (tasksTotal > 0 && tasksDone >= tasksTotal) {
      await _ref.update({'status': 'finished', 'winner': 'crew'});
    }
  }

  void _showFinal() {
    if (!mounted) return;
    final winner = (_room['winner'] as String?) ?? 'crew';
    final iWon = winner == 'impostors' ? _isImpostor : !_isImpostor;
    unawaited(ProfileService.instance.reportGameResult(gameId: 'impostor', won: iWon));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(winner == 'impostors' ? '👽 Hainler Kazandı!' : '🎉 Mürettebat Kazandı!',
            textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(iWon ? '🏆 Kazandın!' : '😔 Kaybettin',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Divider(),
            const Text('Roller:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._players.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text((e.value['role'] as String?) == 'impostor' ? '👽' : '👨‍🚀'),
                    const SizedBox(width: 8),
                    Text(e.value['name'] as String? ?? e.key),
                    if (e.value['alive'] != true) const Text(' ☠️'),
                  ]),
                )),
          ]),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2C5364)),
            onPressed: () async {
              await _ref.remove();
              if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Oyundan çık?'),
        content: const Text('Aktif bir oyunun ortasındasın. Çıkarsan takımın bir '
            'oyuncu eksik kalır ve bu geri alınamaz.'),
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

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _confirmLeave(),
      child: Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _kSpaceGradient,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Stack(alignment: Alignment.topLeft, children: [
              Positioned(left: 4, top: -4,
                  child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: _confirmLeave)),
              Column(children: [
              Text(_isImpostor ? '👽 SEN GİZLİ HAİNSİN' : '👨‍🚀 SEN MÜRETTEBATSIN',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.black.withAlpha(150), blurRadius: 8)])),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(20)),
                child: Text('🛠️ Görevler: $_tasksDone/$_tasksTotal',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              ]),
            ]),
          ),
          if (_lastEjected != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.red.shade900.withAlpha(180),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade400)),
              child: Row(children: [
                const Text('🚀', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_players[_lastEjected]?['name'] ?? _lastEjected} dışarı atıldı! '
                    '(${(_players[_lastEjected]?['role'] as String?) == 'impostor' ? '👽 Hainmiş!' : '👨‍🚀 Mürettebatmış'})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ]),
            ),
          if (_processing)
            Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Oylama sonuçlanıyor...', style: TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            ),
          Expanded(child: _buildBody()),
          const BannerAdWidget(),
        ]),
      ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isAlive) {
      return Center(
        child: AZFrostCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Text('☠️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('Elendin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Oyunu izlemeye devam et', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
      );
    }
    if (_isVoting) return _buildVoting();
    return _buildPlaying();
  }

  Widget _buildVoting() {
    if (_hasVoted) {
      return Center(
        child: AZFrostCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🗳️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text('Oyunu verdin!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('$_votedCount/$_voterCount oy toplandı', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 12),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Text('🚨 Kim şüpheli?', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
        Text('$_votedCount/$_voterCount oy', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              for (final e in _aliveOthers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () => _vote(e.key),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF37474F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(e.value['name'] as String? ?? e.key,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ElevatedButton(
                onPressed: () => _vote('skip'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Kimseyi Atma (Pas)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildPlaying() {
    final fakeTasks = List.generate(_kTasksPerPlayer, (i) => _fakeCompleted.contains(i));
    final tasks = _isImpostor ? fakeTasks : _tasksOf(widget.myKey);
    final cooldown = _killCooldownLeft;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (_isImpostor) ...[
          AZFrostCard(
            opacity: 0.15,
            child: Column(children: [
              const Text('👽 Hain Görevin', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                cooldown == null
                    ? 'Mürettebattan birini ele! Görevleri sahte yaparak gizlen.'
                    : 'Tekrar eleme için ${cooldown.inSeconds + 1} sn bekle',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              for (final e in _killTargets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: cooldown == null ? () => _kill(e.key) : null,
                      icon: const Icon(Icons.dangerous_rounded, size: 18),
                      label: Text(e.value['name'] as String? ?? e.key),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
                    ),
                  ),
                ),
              if (_killTargets.isEmpty)
                const Text('Elenecek mürettebat kalmadı', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_isImpostor ? 'Sahte Görevler' : 'Görevlerin',
              style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _kTasksPerPlayer; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, tasks[i] ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(AZRadius.lg),
                border: Border.all(
                    color: tasks[i] ? const Color(0x20FFFFFF) : const Color(0x40FFFFFF)),
                boxShadow: tasks[i]
                    ? const []
                    : [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tasks[i] ? const Color(0x14FFFFFF) : const Color(0x26FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(_kTaskDefs[i].$2, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(_kTaskDefs[i].$1,
                      style: TextStyle(
                          color: tasks[i] ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: tasks[i] ? TextDecoration.lineThrough : null)),
                ),
                if (tasks[i])
                  const Icon(Icons.check_circle_rounded, color: AZColors.success, size: 22)
                else if (_completingTaskIndex == i)
                  const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  FilledButton(
                    onPressed: () => _completeTask(i),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0x33FFFFFF),
                        foregroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AZRadius.md))),
                    child: const Text('YAP', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ]),
            ),
          ),
        const SizedBox(height: 16),
        if (_canCallMeeting)
          AZButton(
              label: '🚨 ACİL TOPLANTI ÇAĞIR',
              color: Colors.orange.shade800,
              onPressed: _callMeeting),
        const SizedBox(height: 16),
      ]),
    );
  }
}
