import 'dart:async';
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
// MODEL
// ═══════════════════════════════════════════════════════════════════

enum Piece { empty, white, black, whiteKing, blackKing }

class DamaBoard {
  final List<List<int>> cells; // 0=empty,1=white,2=black,3=wKing,4=bKing
  const DamaBoard(this.cells);

  /// Türk Dama dizilişi: taşlar en yakın iki sırada (en arka sıra hariç)
  /// TÜM sütunlarda durur — uluslararası damadaki gibi sadece koyu
  /// karelerde değil, çünkü Türk Dama'da her kare oynanabilir.
  factory DamaBoard.initial() {
    final cells = List.generate(8, (r) => List.generate(8, (c) {
      if (r == 1 || r == 2) return 2; // siyah (üstten 2. ve 3. sıra)
      if (r == 5 || r == 6) return 1; // beyaz (alttan 2. ve 3. sıra)
      return 0;
    }));
    return DamaBoard(cells);
  }

  factory DamaBoard.fromList(List raw) {
    final cells = List.generate(8, (r) =>
        List.generate(8, (c) => (raw[r] as List)[c] as int));
    return DamaBoard(cells);
  }

  List<List<int>> toList() => cells.map((r) => List<int>.from(r)).toList();

  bool isOwn(int r, int c, bool white) {
    final v = cells[r][c];
    return white ? (v == 1 || v == 3) : (v == 2 || v == 4);
  }

  bool isEnemy(int r, int c, bool white) {
    final v = cells[r][c];
    return white ? (v == 2 || v == 4) : (v == 1 || v == 3);
  }

  bool isKing(int r, int c) => cells[r][c] == 3 || cells[r][c] == 4;

  bool inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  // Tüm geçerli hamleler (yakalama zorunlu)
  List<_Move> validMoves(bool white) {
    final captures = <_Move>[];
    final normal = <_Move>[];
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (!isOwn(r, c, white)) continue;
        captures.addAll(_captures(r, c, white));
        normal.addAll(_normalMoves(r, c, white));
      }
    }
    return captures.isNotEmpty ? captures : normal;
  }

  // Türk Dama'da hareket ÇAPRAZ değil, DÜZ (yukarı/aşağı/sağ/sol) olur —
  // uluslararası damadan en büyük farkı budur.
  static const _orthoDirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];

  List<_Move> _normalMoves(int r, int c, bool white) {
    final moves = <_Move>[];
    if (isKing(r, c)) {
      // Dama (kral) taşı: kale gibi, önü açık olduğu sürece bir yönde
      // istediği kadar ilerleyebilir.
      for (final d in _orthoDirs) {
        var nr = r + d[0], nc = c + d[1];
        while (inBounds(nr, nc) && cells[nr][nc] == 0) {
          moves.add(_Move(fr: r, fc: c, tr: nr, tc: nc));
          nr += d[0];
          nc += d[1];
        }
      }
    } else {
      // Er: ileri ya da yana (sağ/sol) bir kare — geri gidemez.
      final forward = white ? -1 : 1;
      for (final d in [[forward, 0], [0, -1], [0, 1]]) {
        final nr = r + d[0], nc = c + d[1];
        if (inBounds(nr, nc) && cells[nr][nc] == 0) {
          moves.add(_Move(fr: r, fc: c, tr: nr, tc: nc));
        }
      }
    }
    return moves;
  }

  List<_Move> _captures(int r, int c, bool white) {
    final moves = <_Move>[];
    if (isKing(r, c)) {
      // Uçan dama: bir yönde boş karelerden geçip karşılaştığı ilk rakip
      // taşı atlar, arkasındaki boş karelerden herhangi birine inebilir.
      for (final d in _orthoDirs) {
        var nr = r + d[0], nc = c + d[1];
        while (inBounds(nr, nc) && cells[nr][nc] == 0) {
          nr += d[0];
          nc += d[1];
        }
        if (!inBounds(nr, nc) || !isEnemy(nr, nc, white)) continue;
        final capR = nr, capC = nc;
        var lr = nr + d[0], lc = nc + d[1];
        while (inBounds(lr, lc) && cells[lr][lc] == 0) {
          moves.add(_Move(fr: r, fc: c, tr: lr, tc: lc, capR: capR, capC: capC));
          lr += d[0];
          lc += d[1];
        }
      }
    } else {
      // Er: normalde geri gidemese de, YAKALAMA yaparken dört yönde de
      // (ileri/geri/sağ/sol) bitişik rakibi atlayabilir.
      for (final d in _orthoDirs) {
        final mr = r + d[0], mc = c + d[1];
        final lr = r + d[0] * 2, lc = c + d[1] * 2;
        if (inBounds(lr, lc) && isEnemy(mr, mc, white) && cells[lr][lc] == 0) {
          moves.add(_Move(fr: r, fc: c, tr: lr, tc: lc, capR: mr, capC: mc));
        }
      }
    }
    return moves;
  }

  DamaBoard applyMove(_Move m) {
    final newCells = toList();
    final piece = newCells[m.fr][m.fc];
    newCells[m.fr][m.fc] = 0;
    newCells[m.tr][m.tc] = piece;
    if (m.capR != null) newCells[m.capR!][m.capC!] = 0;
    // Terfi
    if (newCells[m.tr][m.tc] == 1 && m.tr == 0) newCells[m.tr][m.tc] = 3;
    if (newCells[m.tr][m.tc] == 2 && m.tr == 7) newCells[m.tr][m.tc] = 4;
    return DamaBoard(newCells);
  }

  int countPieces(bool white) {
    var cnt = 0;
    for (var r = 0; r < 8; r++) for (var c = 0; c < 8; c++) {
      if (white && (cells[r][c]==1||cells[r][c]==3)) cnt++;
      if (!white && (cells[r][c]==2||cells[r][c]==4)) cnt++;
    }
    return cnt;
  }
}

class _Move {
  final int fr, fc, tr, tc;
  final int? capR, capC;
  const _Move({required this.fr, required this.fc, required this.tr, required this.tc,
      this.capR, this.capC});
  bool get isCapture => capR != null;
}

// ═══════════════════════════════════════════════════════════════════
// LOBBY
// ═══════════════════════════════════════════════════════════════════

class DamaLobbyScreen extends StatefulWidget {
  const DamaLobbyScreen({super.key});
  @override State<DamaLobbyScreen> createState() => _DamaLobbyState();
}

class _DamaLobbyState extends State<DamaLobbyScreen> {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();
  String? _name; bool _loading = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final n = await _storage.getPlayerName(); if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _name = n); else _ask();
  }
  Future<void> _ask() async {
    final n = await showNameDialog(context, current: _name, accentColor: const Color(0xFF4E342E));
    if (n == null || !mounted) return;
    await _storage.setPlayerName(n); setState(() => _name = n);
  }

  Future<void> _create() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final board = DamaBoard.initial().toList();
      final id = await _rooms.createRoom(gamePath: GamePaths.dama, data: {
        'code': code, 'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'board': board, 'turn': 'white',
        'players': {'p1': {'name': _name, 'isHost': true, 'color': 'white', 'score': 0}},
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          DamaRoomScreen(roomId: id, myKey: 'p1', myName: _name!)));
    } catch (e) { _snack('Hata: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _join() async {
    if (_name == null) { await _ask(); if (_name == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }
    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.dama, code: code);
      if (r == null) { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { _snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 2) { _snack('Oda dolu'); return; }
      await _rooms.updateRoom(gamePath: GamePaths.dama, roomId: r.id,
          updates: {'players/p2': {'name': _name, 'isHost': false, 'color': 'black', 'score': 0}});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          DamaRoomScreen(roomId: r.id, myKey: 'p2', myName: _name!)));
    } catch (e) { _snack('Katılınamadı: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
    gradient: const LinearGradient(
      colors: [Color(0xFF4E342E), Color(0xFF1A0A00)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    child: Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context))),
          const Text('⚪⚫', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          const Text('DAMA', style: TextStyle(color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.bold, letterSpacing: 4)),
          const Text('2 Oyuncu · Türk Dama · Klasik strateji',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 24),
          GestureDetector(onTap: _ask, child: AZFrostCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(_name ?? 'Ad seç', style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 24),
          AZButton(label: 'ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
              onPressed: _create, color: const Color(0xFF6D4C41), loading: _loading, width: 280),
          const SizedBox(height: 20),
          const Text('— veya —', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          AZFrostCard(child: Column(children: [
            AZCodeField(controller: _codeCtrl),
            const SizedBox(height: 14),
            AZJoinButton(onPressed: _join, loading: _loading),
          ])),
          const SizedBox(height: 24),
          AZFrostCard(opacity: 0.1, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('⚫ Dama Nasıl?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Oda kuran ⚪ Beyaz, katılan ⚫ Siyah oynar\n'
                  '• Gerçek Türk Dama kuralları: piyonlar çapraz DEĞİL, '
                  'düz (ileri/yan) hareket eder\n'
                  '• Yakalama zorunludur (üzerinden atlama) ve aynı taş '
                  'devam edebiliyorsa zincirleme yakalamak da zorunludur\n'
                  '• Son sıraya ulaşan taş dame (uçan kral) olur\n'
                  '• Rakibinin tüm taşlarını alan ya da rakibini hamlesiz '
                  'bırakan oyuncu kazanır',
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

// ═══════════════════════════════════════════════════════════════════
// ROOM
// ═══════════════════════════════════════════════════════════════════

class DamaRoomScreen extends StatefulWidget {
  const DamaRoomScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<DamaRoomScreen> createState() => _DamaRoomState();
}

class _DamaRoomState extends State<DamaRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _nav = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms.watchRoom(gamePath: GamePaths.dama, roomId: widget.roomId).listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.dama, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    final players = (d['players'] as Map?) ?? {};
    if (players.isEmpty) {
      _rooms.deleteRoom(gamePath: GamePaths.dama, roomId: widget.roomId);
      if (mounted) Navigator.pop(context);
      return;
    }
    if (d['status'] == 'playing' && !_nav) {
      _nav = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          DamaGameScreen(roomId: widget.roomId, myKey: widget.myKey, myName: widget.myName)));
    }
  }

  Map get _players => (_room['players'] as Map?) ?? {};
  String get _code => _room['code'] ?? '------';
  bool get _isHost => widget.myKey == 'p1';
  bool get _canStart => _players.length >= 2;

  Future<void> _start() async {
    if (!_canStart) { _snack('Rakip bekleniyor'); return; }
    await _rooms.updateRoom(gamePath: GamePaths.dama, roomId: widget.roomId,
        updates: {'status': 'playing'});
  }

  Future<void> _leave() async {
    final pl = Map.from(_players)..remove(widget.myKey);
    if (pl.isEmpty || _isHost) {
      await _rooms.deleteRoom(gamePath: GamePaths.dama, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(gamePath: GamePaths.dama, roomId: widget.roomId, playerKey: widget.myKey);
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => PopScope(canPop: false, onPopInvoked: (_) => _leave(),
    child: AZGradientScaffold(
      gradient: const LinearGradient(colors: [Color(0xFF4E342E), Color(0xFF1A0A00)]),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leave),
          const Expanded(child: Text('DAMA', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(width: 48),
        ]),
        const SizedBox(height: 20),
        AZRoomCode(code: _code, accentColor: const Color(0xFF8D6E63)),
        const SizedBox(height: 20),
        AZFrostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Oyuncular (2 gerekli)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          for (final e in _players.entries)
            AZPlayerTile(
              name: '${e.value['color'] == 'white' ? '⚪' : '⚫'} ${e.value['name'] ?? e.key}',
              isMe: e.key == widget.myKey, isHost: e.value['isHost'] == true,
              emoji: e.value['color'] == 'white' ? '⚪' : '⚫', present: true,
            ),
          if (!_canStart) const Padding(padding: EdgeInsets.only(top: 8),
              child: AZWaitingCard(message: 'Rakip bekleniyor...')),
        ])),
        const Spacer(),
        if (_isHost) AZButton(label: 'OYUNU BAŞLAT', icon: Icons.sports_esports_rounded,
            onPressed: _canStart ? _start : null,
            color: const Color(0xFF6D4C41), width: double.infinity)
        else const AZWaitingCard(message: 'Host oyunu başlatacak...'),
      ])),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// GAME
// ═══════════════════════════════════════════════════════════════════

class DamaGameScreen extends StatefulWidget {
  const DamaGameScreen({super.key, required this.roomId,
      required this.myKey, required this.myName});
  final String roomId, myKey, myName;
  @override State<DamaGameScreen> createState() => _DamaGameState();
}

class _DamaGameState extends State<DamaGameScreen> {
  final _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _finalShown = false, _processing = false;
  int? _selR, _selC;
  List<_Move> _validForSel = [];

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.dama}/${widget.roomId}');
    _sub = _ref.onValue.listen(_onFB);
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }

  void _onFB(DatabaseEvent e) {
    if (!mounted || e.snapshot.value == null) return;
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    setState(() {
      _room = d;
      // Zincirleme (zorunlu çoklu) yakalama devam ediyorsa, seçili taşı
      // otomatik olarak o taşta tut ve sadece onun yakalama hamlelerini
      // göster — bkz. _applyMove.
      final chainR = d['chainR'] as int?;
      final chainC = d['chainC'] as int?;
      if (chainR != null && chainC != null && _isMyTurn && _board.isOwn(chainR, chainC, _isWhite)) {
        _selR = chainR; _selC = chainC;
        _validForSel = _board._captures(chainR, chainC, _isWhite);
      } else {
        _selR = null; _selC = null; _validForSel = [];
      }
    });
    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true; AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 400), _showFinal);
    }
  }

  /// Zincirleme yakalama zorunluluğu sürüyor mu? (sıra bende ve Firebase'de
  /// bekleyen bir chainR/chainC var)
  bool get _inChain {
    final cr = _room['chainR'] as int?;
    final cc = _room['chainC'] as int?;
    return cr != null && cc != null && _isMyTurn;
  }

  Map get _players => (_room['players'] as Map?) ?? {};
  bool get _isWhite => (_players[widget.myKey]?['color'] as String?) == 'white';
  String get _turn => (_room['turn'] as String?) ?? 'white';
  bool get _isMyTurn => (_isWhite && _turn == 'white') || (!_isWhite && _turn == 'black');

  DamaBoard get _board {
    final raw = _room['board'] as List?;
    if (raw == null) return DamaBoard.initial();
    return DamaBoard.fromList(raw);
  }

  void _onTap(int r, int c) {
    if (!_isMyTurn || _processing) return;
    final board = _board;
    if (_selR == null) {
      // Seç
      if (!board.isOwn(r, c, _isWhite)) return;
      final allValid = board.validMoves(_isWhite);
      final forSel = allValid.where((m) => m.fr == r && m.fc == c).toList();
      if (forSel.isEmpty) { _snack('Bu taş için geçerli hamle yok'); return; }
      setState(() { _selR = r; _selC = c; _validForSel = forSel; });
    } else {
      // Hamle yap
      final move = _validForSel.where((m) => m.tr == r && m.tc == c).firstOrNull;
      if (move == null) {
        if (_inChain) {
          _snack('Zincirleme yakalama zorunlu! Aynı taşla devam etmelisin.');
          return;
        }
        // Farklı taş seç
        if (board.isOwn(r, c, _isWhite)) {
          final allValid = board.validMoves(_isWhite);
          final forSel = allValid.where((m) => m.fr == r && m.fc == c).toList();
          setState(() { _selR = r; _selC = c; _validForSel = forSel; });
        } else {
          setState(() { _selR = null; _selC = null; _validForSel = []; });
        }
        return;
      }
      _applyMove(move);
    }
  }

  Future<void> _applyMove(_Move move) async {
    if (_processing) return;
    setState(() => _processing = true);
    var didChain = false;
    try {
      final newBoard = _board.applyMove(move);

      // Kazanma kontrolü — zincirleme devam etse de her hamleden sonra
      // kontrol edilir (rakibin son taşı tam bu hamlede silinmiş olabilir).
      final oppCount = newBoard.countPieces(!_isWhite);
      if (oppCount == 0) {
        await _ref.update({
          'board': newBoard.toList(),
          'status': 'finished', 'winner': widget.myKey,
          'players/${widget.myKey}/score':
              ((_players[widget.myKey]?['score'] as int?) ?? 0) + 100,
        });
        return;
      }

      // Zincirleme (zorunlu çoklu) yakalama: bu bir yakalamaydı ve aynı
      // taş, yeni konumundan başka bir taş daha yakalayabiliyorsa, gerçek
      // Türk Dama kuralına göre sıra rakibe geçmez — aynı oyuncu aynı
      // taşla yakalamaya devam etmek ZORUNDADIR.
      final chainMoves = move.isCapture
          ? newBoard._captures(move.tr, move.tc, _isWhite)
          : <_Move>[];
      if (chainMoves.isNotEmpty) {
        didChain = true;
        await _ref.update({
          'board': newBoard.toList(),
          'chainR': move.tr, 'chainC': move.tc,
        });
        setState(() { _selR = move.tr; _selC = move.tc; _validForSel = chainMoves; });
        HapticFeedback.selectionClick();
        return;
      }

      final nextTurn = _turn == 'white' ? 'black' : 'white';

      // Rakip hamle kalıp kalmadı?
      final oppMoves = newBoard.validMoves(!_isWhite);
      if (oppMoves.isEmpty) {
        await _ref.update({
          'board': newBoard.toList(), 'turn': nextTurn, 'chainR': null, 'chainC': null,
          'status': 'finished', 'winner': widget.myKey,
          'players/${widget.myKey}/score':
              ((_players[widget.myKey]?['score'] as int?) ?? 0) + 100,
        });
        return;
      }

      await _ref.update({'board': newBoard.toList(), 'turn': nextTurn, 'chainR': null, 'chainC': null});
      HapticFeedback.selectionClick();
    } finally {
      if (mounted) setState(() {
        _processing = false;
        if (!didChain) { _selR = null; _selC = null; _validForSel = []; }
      });
    }
  }

  void _showFinal() {
    if (!mounted) return;
    final winner = _room['winner'] as String? ?? '';
    final iWon = winner == widget.myKey;
    ProfileService.instance
        .reportGameResult(gameId: 'dama', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());
    final myColor = _isWhite ? '⚪' : '⚫';
    final oppKey = widget.myKey == 'p1' ? 'p2' : 'p1';
    final oppName = _players[oppKey]?['name'] as String? ?? '?';

    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      title: Text(iWon ? '🏆 Kazandın!' : '😔 Kaybettin',
          textAlign: TextAlign.center,
          style: TextStyle(color: iWon ? Colors.amber : Colors.grey)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(iWon
            ? '$myColor ${widget.myName} tüm taşları sildi!'
            : '${_isWhite ? '⚫' : '⚪'} $oppName kazandı.',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        Text('Puanın: ${(_players[widget.myKey]?['score'] as int?) ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      actions: [FilledButton(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6D4C41)),
        onPressed: () async {
          await _db.child('${GamePaths.dama}/${widget.roomId}').remove();
          if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
        },
        child: const Text('Ana Menü'),
      )],
    ));
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m),
          duration: const Duration(seconds: 1)));

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) return const Scaffold(
        body: Center(child: CircularProgressIndicator()));
    final board = _board;
    final myCount = board.countPieces(_isWhite);
    final oppCount = board.countPieces(!_isWhite);
    final targetSet = _validForSel.map((m) => '${m.tr},${m.tc}').toSet();

    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      body: SafeArea(child: Column(children: [
        // Üst bar
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A1200), Color(0xFF1A0A00)],
            ),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _turn == 'white' ? Colors.white : const Color(0xFF212121),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6, offset: const Offset(0, 3))]),
              child: Text('${_turn == 'white' ? '⚪' : '⚫'} Sıra',
                  style: TextStyle(
                      color: _turn == 'white' ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const Spacer(),
            Text('⚪ $myCount  vs  ⚫ $oppCount',
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _isMyTurn ? Colors.green.shade700 : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6, offset: const Offset(0, 3))]),
              child: Text(_isMyTurn ? '✅ Senin sıran' : '⏳ Rakip',
                  style: const TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),

        // Renk bilgisi / zincirleme yakalama uyarısı
        Container(
          color: _inChain ? const Color(0xFFD84315) : const Color(0xFF2A1000),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              _inChain
                  ? '⚡ Zincirleme yakalama! Aynı taşla devam et'
                  : 'Sen: ${_isWhite ? '⚪ Beyaz' : '⚫ Siyah'}',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: _inChain ? FontWeight.bold : FontWeight.normal),
            ),
          ]),
        ),

        // Tahta
        Expanded(child: LayoutBuilder(builder: (_, constraints) {
          final side = (constraints.maxWidth).clamp(0.0, constraints.maxHeight) - 16;
          return Center(child: Container(
            width: side + 16,
            height: side + 16,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4E342E),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 1, offset: Offset(0, 10)),
                BoxShadow(color: Color(0x33FFFFFF), blurRadius: 1, spreadRadius: -1, offset: Offset(0, -1)),
              ],
            ),
            child: SizedBox(width: side, height: side,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemCount: 64,
              itemBuilder: (_, idx) {
                final r = idx ~/ 8; final c = idx % 8;
                final isDark = (r + c) % 2 == 1;
                final piece = board.cells[r][c];
                final isSel = _selR == r && _selC == c;
                final isTarget = targetSet.contains('$r,$c');
                return GestureDetector(
                  onTap: () => _onTap(r, c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: isSel
                          ? Colors.yellow.shade600
                          : isTarget
                          ? Colors.green.shade400
                          : isDark ? const Color(0xFF5D4037) : const Color(0xFFEFEBE9),
                    ),
                    child: Center(child: piece == 0 ? null : _PieceWidget(piece: piece)),
                  ),
                );
              },
            ),
          )));
        })),

        // Mesaj
        if (_isMyTurn)
          Container(
            color: const Color(0xFF1A0A00),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_selR == null
                ? '👆 Taş seç'
                : '🎯 Gideceği yere dokun',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),

        const BannerAdWidget(),
      ])),
    );
  }
}

class _PieceWidget extends StatelessWidget {
  const _PieceWidget({required this.piece});
  final int piece;
  @override
  Widget build(BuildContext context) {
    final isWhite = piece == 1 || piece == 3;
    final isKing = piece == 3 || piece == 4;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: isWhite
              ? [Colors.white, Colors.grey.shade300]
              : [const Color(0xFF484848), const Color(0xFF121212)],
        ),
        border: Border.all(color: isWhite ? Colors.grey.shade400 : Colors.grey.shade700, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: isKing
          ? Center(child: Text('♛',
              style: TextStyle(fontSize: 18, color: isWhite ? Colors.amber : Colors.yellow.shade600)))
          : null,
    );
  }
}
