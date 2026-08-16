import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LOBİ
// ═══════════════════════════════════════════════════════════════════════════

class VampireLobbyScreen extends StatefulWidget {
  const VampireLobbyScreen({super.key});
  @override
  State<VampireLobbyScreen> createState() => _VLS();
}

class _VLS extends State<VampireLobbyScreen> {
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
    final n = await showNameDialog(context, current: _name, accentColor: Colors.deepPurple);
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
      final id = await _rooms.createRoom(gamePath: GamePaths.vampire, data: {
        'code': code,
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'phase': 'lobby',
        'players': {
          'p1': {'name': _name, 'isHost': true, 'role': null, 'alive': true, 'vote': ''}
        },
      });
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => VampireRoomScreen(roomId: id, myKey: 'p1', myName: _name!)));
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
      final r = await _rooms.findByCode(gamePath: GamePaths.vampire, code: code);
      if (r == null) {
        _snack('Oda bulunamadı');
        return;
      }
      if (r.data['status'] != 'waiting') {
        _snack('Oyun başlamış');
        return;
      }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 8) {
        _snack('Oda dolu');
        return;
      }
      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(
        gamePath: GamePaths.vampire,
        roomId: r.id,
        updates: {
          'players/$myKey': {'name': _name, 'isHost': false, 'role': null, 'alive': true, 'vote': ''}
        },
      );
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => VampireRoomScreen(roomId: r.id, myKey: myKey, myName: _name!)));
    } catch (e) {
      _snack('Katılınamadı: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
        gradient: AZColors.gradDark,
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
                const Text('🧛', style: TextStyle(fontSize: 72)),
                const Text('VAMPİR KÖYLÜ',
                    style: TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const Text('4-8 Oyuncu · Rol bazlı · Mafia tarzı',
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
                    color: Colors.deepPurple,
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
                      Text('🧛 Nasıl oynanır?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 8),
                      Text(
                        '• 4-8 oyuncu\n'
                        '• 🌙 Gece: Vampirler kurban seçer\n'
                        '• 💉 5+ oyuncuda bir Doktor gizlice birini korur\n'
                        '• 🔎 6+ oyuncuda bir Dedektif gizlice birini soruşturur\n'
                        '• ☀️ Gündüz: Herkes vampir sandığını oylar\n'
                        '• Vampir kalmayınca köy kazanır, vampirler sayıca '
                        'eşitlenirse vampirler kazanır',
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
// BEKLEME ODASI
// ═══════════════════════════════════════════════════════════════════════════

class VampireRoomScreen extends StatefulWidget {
  const VampireRoomScreen({super.key, required this.roomId, required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override
  State<VampireRoomScreen> createState() => _VRS();
}

class _VRS extends State<VampireRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.vampire, roomId: widget.roomId).listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.vampire, roomId: widget.roomId,
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
      _rooms.deleteRoom(gamePath: GamePaths.vampire, roomId: widget.roomId);
      if (mounted) Navigator.pop(context);
      return;
    }
    if (d['status'] == 'playing' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => VampireGameScreen(roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)),
      );
    }
  }

  Map<String, dynamic> get _players => Map<String, dynamic>.from((_room['players'] as Map?) ?? {});
  String get _code => _room['code'] ?? '------';
  bool get _isHost => widget.myKey == 'p1';
  bool get _canStart => _players.length >= 4;

  /// Bu oyuncu sayısıyla oynanacak özel roller.
  String get _rolePreview {
    final n = _players.length;
    if (n < 4) return '';
    final vc = max(1, (n / 4).floor());
    final parts = <String>['$vc 🧛 Vampir'];
    if (n >= 5) parts.add('1 💉 Doktor');
    if (n >= 6) parts.add('1 🔎 Dedektif');
    parts.add('${n - vc - (n >= 5 ? 1 : 0) - (n >= 6 ? 1 : 0)} 👨‍🌾 Köylü');
    return parts.join(' · ');
  }

  Future<void> _start() async {
    if (!_canStart) {
      _snack('En az 4 oyuncu');
      return;
    }
    final keys = _players.keys.toList()..shuffle(Random.secure());
    final n = keys.length;
    final vc = max(1, (n / 4).floor());
    final hasDoctor = n >= 5;
    final hasDetective = n >= 6;

    final updates = <String, dynamic>{
      'status': 'playing',
      'phase': 'night',
      'day': 1,
      'nightVictim': null,
      'nightSaved': false,
      'lastEliminated': null,
    };

    var idx = 0;
    for (var i = 0; i < vc; i++, idx++) {
      updates['players/${keys[idx]}/role'] = 'vampire';
    }
    if (hasDoctor) {
      updates['players/${keys[idx]}/role'] = 'doctor';
      idx++;
    }
    if (hasDetective) {
      updates['players/${keys[idx]}/role'] = 'detective';
      idx++;
    }
    for (; idx < n; idx++) {
      updates['players/${keys[idx]}/role'] = 'villager';
    }
    for (final k in keys) {
      updates['players/$k/vote'] = '';
      updates['players/$k/protect'] = '';
      updates['players/$k/investigate'] = '';
      updates['players/$k/alive'] = true;
    }
    await _rooms.updateRoom(gamePath: GamePaths.vampire, roomId: widget.roomId, updates: updates);
  }

  Future<void> _leave() async {
    final pl = Map.from(_players)..remove(widget.myKey);
    if (pl.isEmpty || _isHost) {
      await _rooms.deleteRoom(gamePath: GamePaths.vampire, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(gamePath: GamePaths.vampire, roomId: widget.roomId, playerKey: widget.myKey);
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvoked: (_) => _leave(),
        child: AZGradientScaffold(
          gradient: AZColors.gradDark,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
                const Expanded(
                  child: Text('VAMPİR KÖYLÜ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 48),
              ]),
              const SizedBox(height: 20),
              AZRoomCode(code: _code, accentColor: Colors.deepPurpleAccent),
              const SizedBox(height: 20),
              AZFrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oyuncular (${_players.length}/8)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 14),
                    for (final e in _players.entries)
                      AZPlayerTile(
                          name: e.value['name'] as String? ?? e.key,
                          isMe: e.key == widget.myKey,
                          isHost: e.value['isHost'] == true,
                          emoji: '🧛',
                          present: true),
                    if (!_canStart)
                      Text('En az ${4 - _players.length} oyuncu daha',
                          style: const TextStyle(color: Colors.white54, fontSize: 13))
                    else
                      Text('Bu turda: $_rolePreview',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              if (_isHost)
                AZButton(
                    label: 'OYUNU BAŞLAT',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _canStart ? _start : null,
                    color: Colors.deepPurple,
                    width: double.infinity)
              else
                const AZWaitingCard(message: 'Host oyunu başlatacak...'),
            ]),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// OYUN — Vampir/Köylü + Doktor (koruma) + Dedektif (soruşturma)
// ═══════════════════════════════════════════════════════════════════════════

class VampireGameScreen extends StatefulWidget {
  const VampireGameScreen({super.key, required this.roomId, required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override
  State<VampireGameScreen> createState() => _VGS();
}

class _VGS extends State<VampireGameScreen> {
  final _db = FirebaseDatabase.instance.ref();
  late final DatabaseReference _ref = _db.child('${GamePaths.vampire}/${widget.roomId}');
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  bool _processing = false;
  bool _revealShown = false;

  @override
  void initState() {
    super.initState();
    _sub = _ref.onValue.listen(_onFB);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onFB(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final wasEmpty = _room.isEmpty;
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() => _room = d);

    if (wasEmpty && !_revealShown) {
      _revealShown = true;
      Future.delayed(const Duration(milliseconds: 400), _showRoleReveal);
    }

    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 300), _showFinal);
    }
    // Sadece p1 (host) gece/gündüz sonuçlarını çözer.
    if (!_processing && widget.myKey == 'p1' && d['status'] == 'playing') {
      _checkVotes(d);
    }
  }

  // ── Gece/gündüz çözümleme (host-only) ─────────────────────────────────

  Future<void> _checkVotes(Map<String, dynamic> d) async {
    if (_processing) return;
    final phase = d['phase'] as String? ?? 'night';
    if (phase == 'dawn' || phase == 'dusk') return;
    final players = Map<String, dynamic>.from((d['players'] as Map?) ?? {});
    final alive = players.entries.where((e) => (e.value['alive'] as bool?) == true).toList();
    if (alive.isEmpty) return;

    if (phase == 'night') {
      await _resolveNight(players, alive);
    } else {
      await _resolveDay(d, alive);
    }
  }

  Future<void> _resolveNight(
      Map<String, dynamic> players, List<MapEntry<String, dynamic>> alive) async {
    final aliveVampires = alive.where((e) => (e.value['role'] as String?) == 'vampire').toList();
    final aliveDoctor = alive.where((e) => (e.value['role'] as String?) == 'doctor').toList();
    final aliveDetective = alive.where((e) => (e.value['role'] as String?) == 'detective').toList();
    if (aliveVampires.isEmpty) return;

    final vampiresReady = aliveVampires.every((e) => ((e.value['vote'] as String?) ?? '').isNotEmpty);
    final doctorReady =
        aliveDoctor.isEmpty || ((aliveDoctor.first.value['protect'] as String?) ?? '').isNotEmpty;
    final detectiveReady = aliveDetective.isEmpty ||
        ((aliveDetective.first.value['investigate'] as String?) ?? '').isNotEmpty;
    if (!(vampiresReady && doctorReady && detectiveReady)) return;

    setState(() => _processing = true);
    try {
      final votes = <String, int>{};
      for (final v in aliveVampires) {
        final g = v.value['vote'] as String? ?? '';
        if (g.isNotEmpty) votes[g] = (votes[g] ?? 0) + 1;
      }
      String? elim;
      var mx = 0;
      votes.forEach((k, v) {
        if (v > mx) {
          mx = v;
          elim = k;
        }
      });

      final protectedKey = aliveDoctor.isNotEmpty ? (aliveDoctor.first.value['protect'] as String?) : null;
      final saved = elim != null && elim == protectedKey;
      final actualElim = saved ? null : elim;

      final upd = <String, dynamic>{};
      for (final p in players.entries) {
        upd['players/${p.key}/vote'] = '';
        upd['players/${p.key}/protect'] = '';
        upd['players/${p.key}/investigate'] = '';
      }
      upd['phase'] = 'dawn';
      upd['nightSaved'] = saved;
      await _ref.update(upd);

      await Future.delayed(const Duration(seconds: 3));
      final finalUpd = <String, dynamic>{'phase': 'day', 'nightVictim': null};
      if (actualElim != null) {
        finalUpd['players/$actualElim/alive'] = false;
        finalUpd['lastEliminated'] = actualElim;
      } else {
        finalUpd['lastEliminated'] = '';
      }
      await _ref.update(finalUpd);
      await _checkWin();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _resolveDay(Map<String, dynamic> d, List<MapEntry<String, dynamic>> alive) async {
    final allVoted = alive.every((e) => ((e.value['vote'] as String?) ?? '').isNotEmpty);
    if (!allVoted) return;

    setState(() => _processing = true);
    try {
      final votes = <String, int>{};
      for (final v in alive) {
        final g = v.value['vote'] as String? ?? '';
        if (g.isNotEmpty) votes[g] = (votes[g] ?? 0) + 1;
      }
      String? elim;
      var mx = 0;
      votes.forEach((k, v) {
        if (v > mx) {
          mx = v;
          elim = k;
        }
      });
      final upd = <String, dynamic>{};
      for (final p in alive) {
        upd['players/${p.key}/vote'] = '';
      }
      if (elim != null) {
        upd['players/$elim/alive'] = false;
        upd['lastEliminated'] = elim;
      }
      upd['phase'] = 'dusk';
      upd['day'] = (d['day'] as int? ?? 1) + 1;
      await _ref.update(upd);
      await _checkWin();
      await Future.delayed(const Duration(seconds: 3));
      final statusSnap = await _ref.child('status').get();
      if ((statusSnap.value as String?) != 'finished') {
        await _ref.update({'phase': 'night', 'lastEliminated': null});
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _checkWin() async {
    final snap = await _ref.child('players').get();
    if (!snap.exists) return;
    final players = Map<String, dynamic>.from(snap.value as Map);
    final alive = players.entries.where((e) => (e.value['alive'] as bool?) == true);
    final vamps = alive.where((e) => (e.value['role'] as String?) == 'vampire').length;
    final town = alive.where((e) => (e.value['role'] as String?) != 'vampire').length;
    if (vamps == 0) {
      await _ref.update({'status': 'finished', 'winner': 'villagers'});
    } else if (vamps >= town) {
      await _ref.update({'status': 'finished', 'winner': 'vampires'});
    }
  }

  // ── Getters ────────────────────────────────────────────────────────────

  Map<String, dynamic> get _players => Map<String, dynamic>.from((_room['players'] as Map?) ?? {});
  String get _phase => (_room['phase'] as String?) ?? 'night';
  int get _day => (_room['day'] as int?) ?? 1;
  bool get _isNight => _phase == 'night';
  bool get _nightSaved => (_room['nightSaved'] as bool?) ?? false;
  bool get _isAlive => (_players[widget.myKey]?['alive'] as bool?) ?? true;
  String get _myRole => (_players[widget.myKey]?['role'] as String?) ?? 'villager';
  bool get _isVampire => _myRole == 'vampire';
  bool get _isDoctor => _myRole == 'doctor';
  bool get _isDetective => _myRole == 'detective';
  String get _myVote => (_players[widget.myKey]?['vote'] as String?) ?? '';
  bool get _hasVoted => _myVote.isNotEmpty;
  String get _myProtect => (_players[widget.myKey]?['protect'] as String?) ?? '';
  bool get _hasProtected => _myProtect.isNotEmpty;
  String get _myInvestigate => (_players[widget.myKey]?['investigate'] as String?) ?? '';
  bool get _hasInvestigated => _myInvestigate.isNotEmpty;
  String? get _lastElim {
    final v = _room['lastEliminated'] as String?;
    return (v == null || v.isEmpty) ? null : v;
  }

  List<MapEntry<String, dynamic>> get _killTargets => _players.entries
      .where((e) =>
          e.key != widget.myKey &&
          (e.value['alive'] as bool?) == true &&
          (e.value['role'] as String?) != 'vampire')
      .toList();

  List<MapEntry<String, dynamic>> get _protectTargets =>
      _players.entries.where((e) => (e.value['alive'] as bool?) == true).toList();

  List<MapEntry<String, dynamic>> get _investigateTargets => _players.entries
      .where((e) => e.key != widget.myKey && (e.value['alive'] as bool?) == true)
      .toList();

  List<MapEntry<String, dynamic>> get _dayTargets =>
      _players.entries.where((e) => e.key != widget.myKey && (e.value['alive'] as bool?) == true).toList();

  int get _votedCount {
    final alive = _players.entries.where((e) => (e.value['alive'] as bool?) == true);
    final voters = _isNight ? alive.where((e) => (e.value['role'] as String?) == 'vampire') : alive;
    return voters.where((e) => ((e.value['vote'] as String?) ?? '').isNotEmpty).length;
  }

  int get _voterCount {
    final alive = _players.entries.where((e) => (e.value['alive'] as bool?) == true);
    final voters = _isNight ? alive.where((e) => (e.value['role'] as String?) == 'vampire') : alive;
    return voters.length;
  }

  // ── Aksiyonlar ─────────────────────────────────────────────────────────

  Future<void> _vote(String key) async {
    if (_hasVoted || !_isAlive) return;
    if (_isNight && !_isVampire) return;
    await _ref.update({'players/${widget.myKey}/vote': key});
  }

  Future<void> _protect(String key) async {
    if (_hasProtected || !_isAlive || !_isNight || !_isDoctor) return;
    await _ref.update({'players/${widget.myKey}/protect': key});
  }

  Future<void> _investigate(String key) async {
    if (_hasInvestigated || !_isAlive || !_isNight || !_isDetective) return;
    final role = _players[key]?['role'] as String? ?? 'villager';
    final name = _players[key]?['name'] as String? ?? key;
    await _ref.update({'players/${widget.myKey}/investigate': key});
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔎 Soruşturma Sonucu'),
        content: Text('$name aslında: ${_roleEmoji(role)} ${_roleName(role)}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
      ),
    );
  }

  String _roleEmoji(String? role) => switch (role) {
        'vampire' => '🧛',
        'doctor' => '💉',
        'detective' => '🔎',
        _ => '👨‍🌾',
      };

  String _roleName(String? role) => switch (role) {
        'vampire' => 'Vampir',
        'doctor' => 'Doktor',
        'detective' => 'Dedektif',
        _ => 'Köylü',
      };

  String _roleBannerText(String? role) => switch (role) {
        'vampire' => 'SEN BİR VAMPİRSİN',
        'doctor' => 'SEN DOKTORSUN',
        'detective' => 'SEN DEDEKTİFSİN',
        _ => 'SEN BİR KÖYLÜSÜN',
      };

  void _showRoleReveal() {
    if (!mounted) return;
    final (emoji, title, color, desc) = switch (_myRole) {
      'vampire' => (
          '🧛',
          'SEN BİR VAMPİRSİN',
          const Color(0xFF4A0000),
          'Geceleri diğer vampirlerle birlikte bir kurbanı seç. Kimse senin '
              'vampir olduğunu bilmemeli. Köylüleri sayıca geçersen kazanırsın.'
        ),
      'doctor' => (
          '💉',
          'SEN DOKTORSUN',
          const Color(0xFF004D40),
          'Her gece bir kişiyi (kendin dahil) koruyabilirsin. Vampirler o '
              'kişiyi hedef alırsa saldırı boşa çıkar. Kimliğini gizli tut.'
        ),
      'detective' => (
          '🔎',
          'SEN DEDEKTİFSİN',
          const Color(0xFF01579B),
          'Her gece bir kişiyi gizlice soruşturup gerçek rolünü öğrenebilirsin. '
              'Bulduklarını gündüz akıllıca kullan.'
        ),
      _ => (
          '👨‍🌾',
          'SEN BİR KÖYLÜSÜN',
          const Color(0xFF1B5E20),
          'Özel bir yeteneğin yok ama gözlemlerin çok değerli. Gündüzleri oy '
              'vererek vampirleri bulmaya çalış.'
        ),
    };
    showRoleRevealCard(
      context,
      emoji: emoji,
      title: title,
      description: desc,
      color: color,
    );
  }

  void _showFinal() {
    if (!mounted) return;
    final winner = (_room['winner'] as String?) ?? 'villagers';
    final iWon = winner == 'vampires' ? _isVampire : !_isVampire;
    ProfileService.instance
        .reportGameResult(gameId: 'vampire', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(winner == 'vampires' ? '🧛 Vampirler Kazandı!' : '🎉 Köy Kazandı!', textAlign: TextAlign.center),
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
                    Text(_roleEmoji(e.value['role'] as String?)),
                    const SizedBox(width: 8),
                    Text(e.value['name'] as String? ?? e.key),
                    if (e.value['alive'] != true) const Text(' ☠️'),
                  ]),
                )),
          ]),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () async {
              await _db.child('${GamePaths.vampire}/${widget.roomId}').remove();
              if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }
    final isTransition = _phase == 'dawn' || _phase == 'dusk';
    return Scaffold(
      backgroundColor: _isNight ? const Color(0xFF0D0D1F) : const Color(0xFFFFF9C4),
      body: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: _isNight || isTransition
                    ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
                    : [Colors.orange.shade700, Colors.yellow.shade600]),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(130), blurRadius: 16, offset: const Offset(0, 6))]),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_isNight ? '🌙' : (isTransition ? '🌅' : '☀️'), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('${_isNight ? "GECE" : (isTransition ? "GEÇİŞ" : "GÜNDÜZ")}${_day > 1 ? " — Gün $_day" : ""}',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: _isVampire
                    ? [Colors.red.shade900, Colors.purple.shade900]
                    : (_isDoctor
                        ? [Colors.teal.shade900, Colors.green.shade800]
                        : (_isDetective
                            ? [Colors.blue.shade900, Colors.indigo.shade800]
                            : [Colors.green.shade800, Colors.teal.shade800]))),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 12, offset: const Offset(0, 6))]),
            child: Row(children: [
              Text(_roleEmoji(_myRole), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_roleBannerText(_myRole),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ]),
          ),
          if (_lastElim != null && !_isNight)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.red.shade900.withAlpha(180),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade400)),
              child: Row(children: [
                const Text('☠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_players[_lastElim]?['name'] ?? _lastElim} elendi! '
                    '(${_roleEmoji(_players[_lastElim]?['role'] as String?)} '
                    '${_roleName(_players[_lastElim]?['role'] as String?)})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                Text('Sonuç hesaplanıyor...', style: TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            ),
          Expanded(child: _buildBody(isTransition)),
          const BannerAdWidget(),
        ]),
      ),
    );
  }

  Widget _buildBody(bool isTransition) {
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

    if (isTransition) {
      final showSaved = _phase == 'dawn' && _nightSaved;
      return Center(
        child: AZFrostCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(showSaved ? '🛡️' : (_phase == 'dawn' ? '🌅' : '🌆'), style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              showSaved
                  ? 'Doktor birini kurtardı! Kimse ölmedi.'
                  : (_phase == 'dawn' ? 'Yeni gün başlıyor...' : 'Gece bastırıyor...'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ]),
        ),
      );
    }

    if (_isNight) {
      if (_isVampire) return _hasVoted ? _waitingCard('🩸', 'Kurbanın seçildi!') : _actionList(
          title: '🩸 Kimi ısıralım?',
          color: Colors.deepPurple.shade700,
          targets: _killTargets,
          onTap: _vote);
      if (_isDoctor) return _hasProtected ? _waitingCard('💉', 'Koruman hazır!', showCount: false) : _actionList(
          title: '💉 Kimi koruyalım?',
          color: Colors.teal.shade700,
          targets: _protectTargets,
          onTap: _protect);
      if (_isDetective) return _hasInvestigated ? _waitingCard('🔎', 'Soruşturman tamamlandı!', showCount: false) : _actionList(
          title: '🔎 Kimi soruşturalım?',
          color: Colors.blue.shade700,
          targets: _investigateTargets,
          onTap: _investigate);
      return Center(
        child: AZFrostCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Text('😴', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('Uyku vakti...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Diğerleri gizli görevlerini yapıyor', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
      );
    }

    // Gündüz oylaması
    if (_hasVoted) return _waitingCard('🗳️', 'Oyunu verdin!');
    return _actionList(
      title: '🗳️ Kim vampir?',
      color: Colors.amber.shade600,
      targets: _dayTargets,
      onTap: _vote,
    );
  }

  // showCount: Doktor/Dedektif tek başına eylem yapan roller — "hazır"
  // sayacı yalnızca gece vampir oylamasını ve gündüz genel oylamayı
  // hesaplıyor (bkz. _votedCount/_voterCount), bu yüzden Doktor/Dedektif
  // beklerken önceden kendileriyle hiç alakası olmayan (ve dolaylı olarak
  // vampir sayısını ele veren) bir "vampir oy" sayısı gösteriliyordu.
  Widget _waitingCard(String emoji, String message, {bool showCount = true}) => Center(
        child: AZFrostCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            if (showCount)
              Text('$_votedCount/$_voterCount hazır', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 12),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ]),
        ),
      );

  Widget _actionList({
    required String title,
    required Color color,
    required List<MapEntry<String, dynamic>> targets,
    required void Function(String key) onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: targets.map((e) {
              final isSelf = e.key == widget.myKey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () => onTap(e.key),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(
                    isSelf ? '${widget.myName} (kendin)' : (e.value['name'] as String? ?? e.key),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}
