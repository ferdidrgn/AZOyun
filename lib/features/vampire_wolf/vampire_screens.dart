import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

// ════════════════════════════════════════════════════════════════════════════
// LOBBY
// ════════════════════════════════════════════════════════════════════════════

class VampireLobbyScreen extends StatefulWidget {
  const VampireLobbyScreen({super.key});

  @override
  State<VampireLobbyScreen> createState() => _VampireLobbyScreenState();
}

class _VampireLobbyScreenState extends State<VampireLobbyScreen> {
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
        current: _playerName, accentColor: Colors.deepPurple);
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
        gamePath: GamePaths.vampire,
        data: {
          'code': code, 'status': 'waiting', 'createdAt': ServerValue.timestamp,
          'phase': 'lobby',
          'players': {'p1': {'name': _playerName, 'isHost': true,
              'role': null, 'alive': true, 'vote': ''}},
        },
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          VampireRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!)));
    } catch (e) { _snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _joinRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.vampire, code: code);
      if (r == null) { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { _snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 8) { _snack('Oda dolu (max 8)'); return; }
      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(gamePath: GamePaths.vampire, roomId: r.id,
          updates: {'players/$myKey': {'name': _playerName, 'isHost': false,
              'role': null, 'alive': true, 'vote': ''}});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          VampireRoomScreen(roomId: r.id, myKey: myKey, myName: _playerName!)));
    } catch (e) { _snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradDark,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context))),
          const SizedBox(height: 8),
          const Text('🧛', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          const Text('VAMPİR KÖYLÜ',
              style: TextStyle(color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('4-8 Oyuncu · Rol bazlı · Mafia tarzı',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 28),
          GestureDetector(onTap: _askName, child: AZFrostCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_playerName ?? 'Ad seç',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Icon(Icons.edit_rounded, color: Colors.white60, size: 14),
            ]),
          )),
          const SizedBox(height: 36),
          AZButton(label: 'YENİ ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
              onPressed: _createRoom, color: Colors.deepPurple,
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
                Text('🧛  Nasıl oynanır?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 10),
                Text('• 4-8 oyuncu ile oynanır\n'
                    '• Host rolleri dağıtır: Vampir veya Köylü\n'
                    '• Gece: Vampirler köylü seçer\n'
                    '• Gündüz: Herkes vampir sandığını oylar\n'
                    '• Vampirler yoksa Köylüler, sayı eşitlenirsek Vampirler kazanır',
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

class VampireRoomScreen extends StatefulWidget {
  const VampireRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;

  @override
  State<VampireRoomScreen> createState() => _VampireRoomScreenState();
}

class _VampireRoomScreenState extends State<VampireRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.vampire, roomId: widget.roomId).listen(_onData);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_navigating) {
      _navigating = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          VampireGameScreen(roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)));
    }
  }

  Map    get _players  => (_room['players'] as Map?) ?? {};
  String get _code     => _room['code'] ?? '------';
  bool   get _isHost   => widget.myKey == 'p1';
  bool   get _canStart => _players.length >= 4;

  Future<void> _start() async {
    if (!_canStart) { _snack('En az 4 oyuncu gerekli'); return; }
    // Assign roles
    final playerKeys  = _players.keys.toList()..shuffle(Random.secure());
    final vampireCount = max(1, (playerKeys.length / 4).floor());
    final updates = <String, dynamic>{'status': 'playing', 'phase': 'night', 'day': 1};
    for (var i = 0; i < playerKeys.length; i++) {
      updates['players/${playerKeys[i]}/role'] = i < vampireCount ? 'vampire' : 'villager';
    }
    await _rooms.updateRoom(gamePath: GamePaths.vampire, roomId: widget.roomId, updates: updates);
  }

  Future<void> _leave() async {
    if (_isHost) await _rooms.deleteRoom(gamePath: GamePaths.vampire, roomId: widget.roomId);
    else await _rooms.removePlayer(gamePath: GamePaths.vampire, roomId: widget.roomId, playerKey: widget.myKey);
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, onPopInvoked: (_) => _leave(),
      child: AZGradientScaffold(gradient: AZColors.gradDark,
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
            const Expanded(child: Text('VAMPİR KÖYLÜ', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 20),
          AZRoomCode(code: _code, accentColor: Colors.deepPurpleAccent),
          const SizedBox(height: 20),
          AZFrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Oyuncular (${_players.length}/8)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            for (final entry in _players.entries)
              AZPlayerTile(
                  name: entry.value['name'] as String? ?? entry.key,
                  isMe: entry.key == widget.myKey,
                  isHost: entry.value['isHost'] == true,
                  emoji: '🧛', present: true),
            if (!_canStart) Padding(padding: const EdgeInsets.only(top: 8),
                child: const Text('En az 4 oyuncu gerekli',
                    style: TextStyle(color: Colors.white54, fontSize: 13))),
          ])),
          const Spacer(),
          if (_isHost)
            AZButton(label: 'OYUNU BAŞLAT', icon: Icons.play_arrow_rounded,
                onPressed: _canStart ? _start : null,
                color: Colors.deepPurple, width: double.infinity)
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

class VampireGameScreen extends StatefulWidget {
  const VampireGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;

  @override
  State<VampireGameScreen> createState() => _VampireGameScreenState();
}

class _VampireGameScreenState extends State<VampireGameScreen> {
  final _db  = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  bool _voted = false;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.vampire}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFirebase);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _onFirebase(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() {
      _room  = d;
      _voted = d['players']?[widget.myKey]?['vote'] != null &&
               (d['players'][widget.myKey]['vote'] as String).isNotEmpty;
    });
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      Future.delayed(const Duration(milliseconds: 300), _showFinal);
    }
  }

  Map    get _players => (_room['players'] as Map?) ?? {};
  String get _phase   => (_room['phase']   as String?) ?? 'night';
  int    get _day     => (_room['day']      as int?)    ?? 1;
  String get _myRole  => (_players[widget.myKey]?['role'] as String?) ?? 'villager';
  bool   get _alive   => (_players[widget.myKey]?['alive'] as bool?) ?? true;
  bool   get _isVampire => _myRole == 'vampire';

  Future<void> _vote(String targetKey) async {
    if (_voted || !_alive) return;
    await _ref.update({'players/${widget.myKey}/vote': targetKey});
    _checkAllVoted();
  }

  Future<void> _checkAllVoted() async {
    final alive = _players.entries.where((e) => e.value['alive'] == true).toList();
    final allVoted = alive.every((e) {
      final vote = e.value['vote'] as String? ?? '';
      return vote.isNotEmpty;
    });
    if (!allVoted) return;

    // Count votes
    final votes = <String, int>{};
    for (final p in alive) {
      final v = p.value['vote'] as String? ?? '';
      if (v.isNotEmpty) votes[v] = (votes[v] ?? 0) + 1;
    }

    String? eliminated;
    int max = 0;
    votes.forEach((k, v) { if (v > max) { max = v; eliminated = k; } });

    final updates = <String, dynamic>{};
    // Clear votes
    for (final p in alive) updates['players/${p.key}/vote'] = '';
    if (eliminated != null) updates['players/$eliminated/alive'] = false;
    // Toggle phase
    updates['phase'] = _phase == 'night' ? 'day' : 'night';
    if (_phase == 'day') updates['day'] = _day + 1;

    await _ref.update(updates);
    _checkWin();
  }

  Future<void> _checkWin() async {
    final alive     = _players.entries.where((e) => e.value['alive'] == true);
    final vampires  = alive.where((e) => e.value['role'] == 'vampire').length;
    final villagers = alive.where((e) => e.value['role'] == 'villager').length;

    if (vampires == 0) {
      await _ref.update({'status': 'finished', 'winner': 'villagers'});
    } else if (vampires >= villagers) {
      await _ref.update({'status': 'finished', 'winner': 'vampires'});
    }
  }

  void _showFinal() {
    if (!mounted) return;
    final winner = (_room['winner'] as String?) ?? 'villagers';
    final isWinner = winner == 'vampires' ? _isVampire : !_isVampire;

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(winner == 'vampires' ? '🧛 Vampirler Kazandı!' : '🎉 Köylüler Kazandı!',
            textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isWinner ? '🏆 Kazandın!' : '😔 Kaybettin',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Roller:', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._players.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(e.value['role'] == 'vampire' ? '🧛' : '👨‍🌾'),
              const SizedBox(width: 8),
              Text(e.value['name'] as String? ?? e.key),
              if (e.value['alive'] != true)
                const Text(' (elendi)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          )),
        ]),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
          onPressed: () async {
            await _db.child('${GamePaths.vampire}/${widget.roomId}').remove();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) return const Scaffold(backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.purple)));

    final isNight = _phase == 'night';
    final targets = _players.entries
        .where((e) => e.key != widget.myKey && e.value['alive'] == true)
        .where((e) => isNight ? _isVampire : true) // at night only vampires vote
        .toList();

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF0D0D1F) : const Color(0xFFFFF9C4),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Phase indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
                color: isNight ? Colors.deepPurple : Colors.amber,
                borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(isNight ? '🌙' : '☀️', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(isNight ? 'GECE $dayText' : 'GÜNDÜZ $dayText',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 20),

          // My role card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _isVampire ? Colors.red.shade900 : Colors.green.shade800,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Text(_isVampire ? '🧛' : '👨‍🌾', style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isVampire ? 'SEN BİR VAMPİRSİN' : 'SEN BİR KÖYLÜSÜN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_isVampire
                    ? 'Köylüleri seç — kimliğini gizle!'
                    : 'Vampiri bul ve oyla!',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Action area
          if (!_alive)
            AZFrostCard(child: const Center(child: Text('☠️ Elendin\nİzlemeye devam edebilirsin',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16))))
          else if (_voted)
            AZFrostCard(child: const Center(child: Column(children: [
              SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(height: 10),
              Text('Oyun bekleniyor...', style: TextStyle(color: Colors.white)),
            ])))
          else if (isNight && !_isVampire)
            AZFrostCard(child: const Text(
              '🌙 Uyku vakti...\nVampirler kurban seçiyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ))
          else
            Expanded(child: Column(children: [
              Text(isNight ? '🩸 Kim ısırılsın?' : '🗳️ Kim vampir?',
                  style: TextStyle(color: isNight ? Colors.white : Colors.black87,
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Expanded(child: ListView(
                children: targets.map((e) {
                  final name = e.value['name'] as String? ?? e.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      onPressed: () => _vote(e.key),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isNight ? Colors.red.shade800 : Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              )),
            ])),
        ]),
      )),
    );
  }

  String get dayText => _day > 1 ? '- Gün $_day' : '';
}
