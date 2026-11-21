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
import '../../core/widgets/az_online_lobby.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LOBİ
// ═══════════════════════════════════════════════════════════════════════════

class VampireLobbyScreen extends StatefulWidget {
  const VampireLobbyScreen({super.key, this.initialCode});
  final String? initialCode;
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
    seedRoomCode(_codeCtrl, widget.initialCode);
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
      await _ask();
    }
    if (mounted && widget.initialCode != null && _name != null && !_loading) {
      await _join();
    }
  }

  Future<void> _ask() async {
    final n = await showNameDialog(context, current: _name, accentColor: AZColors.purple);
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
      context.snack('Hata: $e');
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
      context.snack('6 haneli kodu girin');
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.vampire, code: code);
      if (r == null) {
        context.snack('Oda bulunamadı');
        return;
      }
      if (r.data['status'] != 'waiting') {
        context.snack('Oyun başlamış');
        return;
      }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 8) {
        context.snack('Oda dolu');
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
      context.snack('Katılınamadı: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AZOnlineLobby(
        title: 'Vampir Köylü',
        icon: Icons.nights_stay_rounded,
        summary: '4–8 oyuncu · Gizli roller ve oylama',
        instructions:
            'Gece vampirler hedef seçer; doktor korur, dedektif araştırır. Gündüz herkes oy verir. Köy, tüm vampirleri bulursa kazanır.',
        playerName: _name,
        codeController: _codeCtrl,
        loading: _loading,
        onRename: _ask,
        onCreate: _create,
        onJoin: _join,
        footer: const AdaptiveBannerAdWidget(),
      );
}

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
      context.snack('En az 4 oyuncu');
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
    await _rooms.leaveRoomClosingIfLast(
        gamePath:  GamePaths.vampire,
        roomId:    widget.roomId,
        playerKey: widget.myKey,
        isHost:    _isHost,
        players:   _players);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AZLeaveGuard(
        onLeave: _leave,
        child: AZGradientScaffold(
          gradient: AZColors.gradDark,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              AZRoomHeader(title: 'VAMPİR KÖYLÜ', onClose: _leave),
              const SizedBox(height: 20),
              AZRoomCode(code: _code, accentColor: AZColors.purple, inviteGame: 'vampire'),
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
                    color: AZColors.purple,
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
  final _rooms = RoomService.instance;
  late final DatabaseReference _ref = _db.child('${GamePaths.vampire}/${widget.roomId}');
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false;
  bool _processing = false;
  bool _revealShown = false;
  bool _roomGone = false;

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
    // Gece/gündüz sonuçlarını SADECE sabit 'p1' değil, o an CANLI olan en
    // düşük anahtarlı oyuncu çözer. Eskiden p1'e sabitlenmişti — p1 oyundan
    // ayrılır ya da bağlantısı koparsa çözümleme hiçbir zaman olmuyordu.
    if (!_processing && widget.myKey == _resolveLeaderKey && d['status'] == 'playing') {
      _checkVotes(d);
    }
  }

  String? get _resolveLeaderKey {
    final aliveKeys = _players.entries
        .where((e) => (e.value['alive'] as bool?) == true)
        .map((e) => e.key)
        .toList()
      ..sort();
    return aliveKeys.isEmpty ? null : aliveKeys.first;
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
          const Color(0xFF5C2A26),
          'Geceleri diğer vampirlerle birlikte bir kurbanı seç. Kimse senin '
              'vampir olduğunu bilmemeli. Köylüleri sayıca geçersen kazanırsın.'
        ),
      'doctor' => (
          '💉',
          'SEN DOKTORSUN',
          const Color(0xFF2C4A46),
          'Her gece bir kişiyi (kendin dahil) koruyabilirsin. Vampirler o '
              'kişiyi hedef alırsa saldırı boşa çıkar. Kimliğini gizli tut.'
        ),
      'detective' => (
          '🔎',
          'SEN DEDEKTİFSİN',
          const Color(0xFF31485A),
          'Her gece bir kişiyi gizlice soruşturup gerçek rolünü öğrenebilirsin. '
              'Bulduklarını gündüz akıllıca kullan.'
        ),
      _ => (
          '👨‍🌾',
          'SEN BİR KÖYLÜSÜN',
          const Color(0xFF33402E),
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
        .reportGameResult(gameId: 'vampire', resultId: widget.roomId, won: iWon)
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
            style: FilledButton.styleFrom(backgroundColor: AZColors.purple),
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

  /// Aktif oyun ekranında önceden HİÇBİR çıkış yolu yoktu — bir oyuncu geri
  /// tuşuna basıp uygulamayı arka plana alsa bile Firebase'deki kaydı
  /// silinmiyordu, bu da "herkes hazır olsun" bekleyen gece/gündüz
  /// çözümlemesini sonsuza dek kilitleyebiliyordu. Artık kendini players'tan
  /// tamamen kaldırıyoruz — bu, oy/hazır sayımını anında düzeltir.
  Future<void> _leaveGame() async {
    final remaining = Map<String, dynamic>.from(_players)..remove(widget.myKey);
    if (remaining.isEmpty) {
      await _rooms.deleteRoom(gamePath: GamePaths.vampire, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(
          gamePath: GamePaths.vampire, roomId: widget.roomId, playerKey: widget.myKey);
      await _checkWin();
    }
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmLeave() async {
    final ok = await confirmLeaveGame(
      context,
      title:   'Oyundan çık?',
      message: 'Aktif bir oyunun ortasındasın. Çıkarsan köyün bir '
          'oyuncu eksik kalır ve bu geri alınamaz.',
    );
    if (ok) await _leaveGame();
  }

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF23202E),
        body: Center(child: CircularProgressIndicator(color: AZColors.purple)),
      );
    }
    final isTransition = _phase == 'dawn' || _phase == 'dusk';
    final aliveCount = _players.values.where((p) => (p['alive'] as bool?) == true).length;
    final playerCount = _players.length;
    return AZLeaveGuard(
      onLeave: _confirmLeave,
      child: Scaffold(
        backgroundColor: _isNight ? AZColors.bgDark : const Color(0xFFF2E9C9),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _VampireVillagePainter(isNight: _isNight, transition: isTransition),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isNight || isTransition
                            ? [const Color(0xFF3A3350), const Color(0xFF2E2F4A)]
                            : [AZColors.orange, AZColors.accentGoldSoft],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(130), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 4,
                          child: IconButton(
                            tooltip: 'Oyundan çık',
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: _confirmLeave,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isNight ? '🌙' : (isTransition ? '🌅' : '☀️'),
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Text(
                                  '\${_isNight ? "GECE" : (isTransition ? "GEÇİŞ" : "GÜNDÜZ")}'
                                  '\${_day > 1 ? " — Gün $_day" : ""}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 56),
                              child: Row(
                                children: [
                                  const Icon(Icons.groups_rounded, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text('$aliveCount / $playerCount hayatta',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: playerCount == 0 ? 0 : aliveCount / playerCount,
                                        minHeight: 7,
                                        backgroundColor: Colors.black26,
                                        color: _isNight ? const Color(0xFFE4B9FF) : const Color(0xFFFFF0B4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isVampire
                            ? [const Color(0xFF5C2A26), const Color(0xFF4A3550)]
                            : (_isDoctor
                                ? [const Color(0xFF2C4A46), const Color(0xFF33452F)]
                                : (_isDetective
                                    ? [const Color(0xFF31485A), const Color(0xFF3A3350)]
                                    : [const Color(0xFF33452F), const Color(0xFF2C4A46)])),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(48)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(_roleEmoji(_myRole), style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_roleBannerText(_myRole),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(widget.myName,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(_isAlive ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                            color: _isAlive ? const Color(0xFFFF8E9B) : Colors.white54),
                      ],
                    ),
                  ),
                  if (_lastElim != null && !_isNight)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AZColors.redDk.withAlpha(210),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AZColors.red),
                      ),
                      child: Row(
                        children: [
                          const Text('☠️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '\${_players[_lastElim]?['name'] ?? _lastElim} elendi! '
                              '(\${_roleEmoji(_players[_lastElim]?['role'] as String?)} '
                              '\${_roleName(_players[_lastElim]?['role'] as String?)})',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_processing)
                    Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Sonuç hesaplanıyor...', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey('\$_phase-\$_day-\$_myVote-\$_myProtect-\$_myInvestigate-\$_isAlive'),
                        child: _buildBody(isTransition),
                      ),
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              ),
            ),
          ],
        ),
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
          color: AZColors.purpleDk,
          targets: _killTargets,
          onTap: _vote);
      if (_isDoctor) return _hasProtected ? _waitingCard('💉', 'Koruman hazır!', showCount: false) : _actionList(
          title: '💉 Kimi koruyalım?',
          color: const Color(0xFF4F7A79),
          targets: _protectTargets,
          onTap: _protect);
      if (_isDetective) return _hasInvestigated ? _waitingCard('🔎', 'Soruşturman tamamlandı!', showCount: false) : _actionList(
          title: '🔎 Kimi soruşturalım?',
          color: AZColors.blueDk,
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
      color: AZColors.orange,
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
    final selectedKey = !_isNight
        ? _myVote
        : (_isVampire ? _myVote : (_isDoctor ? _myProtect : _myInvestigate));
    final actionLabel = !_isNight
        ? 'OYUNU VER'
        : (_isVampire ? 'GİZLİ HEDEF SEÇ' : (_isDoctor ? 'KORUMA SEÇ' : 'ARAŞTIR'));
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      _isNight
                          ? 'Gizli gece eylemi · seçimin yalnızca sana görünür'
                          : 'Köy meydanında oy ver · seçimler sonuçlanınca açıklanır',
                      style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: color.withAlpha(150)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isNight ? Icons.visibility_off_rounded : Icons.how_to_vote_rounded,
                        size: 15, color: color),
                    const SizedBox(width: 5),
                    Text(_isNight ? 'GİZLİ' : 'OY',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: targets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final entry = targets[index];
                final isSelf = entry.key == widget.myKey;
                final isSelected = entry.key == selectedKey;
                final name = entry.value['name'] as String? ?? entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withAlpha(45) : Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withAlpha(38),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withAlpha(45), blurRadius: 16, spreadRadius: 1)]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onTap(entry.key),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [color.withAlpha(210), color.withAlpha(90)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white.withAlpha(105)),
                              ),
                              child: Center(
                                child: Text(isSelf ? '🙂' : '👤', style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSelf ? '$name · Sen' : name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isSelf ? 'Kendini seç' : actionLabel,
                                    style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                              color: isSelected ? color : Colors.white70,
                              size: 25,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isNight && _isVampire)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Center(
                child: Text('Vampirler aynı hedefte buluşmalı · \$_votedCount/$_voterCount seçim',
                    style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

}


class _VampireVillagePainter extends CustomPainter {
  const _VampireVillagePainter({required this.isNight, required this.transition});

  final bool isNight;
  final bool transition;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = isNight || transition;
    final sky = Rect.fromLTWH(0, 0, size.width, size.height);
    final top = dark ? const Color(0xFF171426) : const Color(0xFF9C5C44);
    final bottom = dark ? const Color(0xFF38304A) : const Color(0xFFF0BD70);
    canvas.drawRect(
      sky,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom, dark ? const Color(0xFF18212A) : const Color(0xFF566747)],
        stops: const [0, .62, 1],
      ).createShader(sky),
    );

    final orb = Offset(size.width * .78, size.height * .22);
    final radius = math.min(size.width, size.height) * .075;
    if (dark) {
      canvas.drawCircle(orb, radius * 1.55, Paint()..color = const Color(0xFFB9A8F8).withAlpha(16));
      canvas.drawCircle(orb, radius, Paint()..color = const Color(0xFFE6DDFB));
      canvas.drawCircle(orb.translate(radius * .4, -radius * .18), radius * .86,
          Paint()..color = const Color(0xFF302A41));
      for (var i = 0; i < 24; i++) {
        final x = ((i * 73 + 31) % 997) / 997 * size.width;
        final y = ((i * 47 + 11) % 503) / 503 * size.height * .55;
        final r = 1.0 + (i % 3) * .45;
        canvas.drawCircle(Offset(x, y), r, Paint()..color = Colors.white.withAlpha(90 + (i % 4) * 30));
      }
    } else {
      canvas.drawCircle(orb, radius * 1.5, Paint()..color = const Color(0xFFFFD990).withAlpha(24));
      canvas.drawCircle(orb, radius, Paint()..color = const Color(0xFFFFE5A1));
    }

    final farHill = Path()
      ..moveTo(0, size.height * .70)
      ..quadraticBezierTo(size.width * .28, size.height * .55, size.width * .52, size.height * .72)
      ..quadraticBezierTo(size.width * .75, size.height * .82, size.width, size.height * .64)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farHill, Paint()..color = dark ? const Color(0xFF24243B) : const Color(0xFF526548));

    final nearHill = Path()
      ..moveTo(0, size.height * .82)
      ..quadraticBezierTo(size.width * .34, size.height * .70, size.width * .56, size.height * .84)
      ..quadraticBezierTo(size.width * .81, size.height * .93, size.width, size.height * .78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(nearHill, Paint()..color = dark ? const Color(0xFF171B2C) : const Color(0xFF354D3F));

    final houseY = size.height * .73;
    final houseColor = dark ? const Color(0xFF171725) : const Color(0xFF463A35);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (.08 + i * .245);
      final w = size.width * .17;
      final h = size.height * (.13 + (i % 2) * .035);
      final house = Rect.fromLTWH(x, houseY - h, w, h);
      canvas.drawRect(house, Paint()..color = houseColor);
      final roof = Path()
        ..moveTo(x - w * .08, houseY - h)
        ..lineTo(x + w / 2, houseY - h - h * .46)
        ..lineTo(x + w * 1.08, houseY - h)
        ..close();
      canvas.drawPath(roof, Paint()..color = dark ? const Color(0xFF11121D) : const Color(0xFF633F36));
      final windowPaint = Paint()..color = dark ? const Color(0xFFFFD27B).withAlpha(175) : const Color(0xFFFFD98C).withAlpha(190);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * .18, houseY - h * .67, w * .19, h * .22),
          const Radius.circular(2),
        ),
        windowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * .62, houseY - h * .67, w * .19, h * .22),
          const Radius.circular(2),
        ),
        windowPaint,
      );
    }

    if (dark) {
      final mistPaint = Paint()..color = const Color(0xFFD6CBFF).withAlpha(14);
      canvas.drawOval(Rect.fromLTWH(-size.width * .15, size.height * .77, size.width * .75, size.height * .05), mistPaint);
      canvas.drawOval(Rect.fromLTWH(size.width * .48, size.height * .84, size.width * .78, size.height * .06), mistPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VampireVillagePainter oldDelegate) =>
      oldDelegate.isNight != isNight || oldDelegate.transition != transition;
}
