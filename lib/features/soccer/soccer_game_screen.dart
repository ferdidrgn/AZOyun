import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ══════════════════════════════════════════════════════════════════════════════

// Top fiziksel parametreler
const double _kBallRadius  = 0.048; // normalize (0-1)
const double _kFriction    = 0.985; // her frame çarpanı
const double _kBounceLoss  = 0.62;  // duvar çarpma enerji kaybı
const double _kMinSpeed    = 0.003; // durma eşiği
const double _kMaxPower    = 5.5;   // maksimum güç
const double _kDt          = 0.016; // fizik adımı (60fps)

// Kale boyutları (normalize)
const double _kGoalLeft   = 0.20;
const double _kGoalRight  = 0.80;
const double _kGoalBottom = 0.18; // bu Y'nin altında = gol bölgesi
const double _kNetDepth   = 0.06; // ağ derinliği

// Kaleci
const double _kGkRadius   = 0.055;
const double _kGkY        = 0.155;
const double _kGkRange    = 0.25;  // max hareket mesafesi

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SoccerGameScreen extends StatefulWidget {
  const SoccerGameScreen({
    super.key,
    required this.roomId,
    required this.myKey,
    required this.myName,
  });
  final String roomId, myKey, myName;

  @override
  State<SoccerGameScreen> createState() => _SoccerGameScreenState();
}

class _SoccerGameScreenState extends State<SoccerGameScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  final _rooms = RoomService.instance;
  late DatabaseReference _ref;
  StreamSubscription? _sub;

  Map<String, dynamic> _room = {};
  bool _finalShown  = false;
  bool _roomGone    = false;
  bool _isMyTurn    = false;
  int  _myScore     = 0;
  int  _currentRound = 1;
  int  _totalRounds  = 5;

  // Sırası gelmeyen oyuncunun ekranında topu senkron göstermek için:
  // vuran taraf periyodik olarak top/kaleci konumunu Firebase'e yazar
  // (_syncTimer), izleyen taraf kendi fizik motorunu hiç çalıştırmadan
  // bu değerleri doğrudan gösterir. Vuruş sonucu da aynı şekilde
  // resultSeq/result üzerinden senkronize edilir.
  Timer? _syncTimer;
  int _shownResultSeq = 0;

  // ── Drag ────────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool    _canShoot = true; // sürükleme kilidi

  // ── Ball physics ─────────────────────────────────────────────────────────
  Offset _ball     = const Offset(0.50, 0.72);
  Offset _ballVel  = Offset.zero;
  bool   _moving   = false;
  bool   _inNet    = false; // top ağa girdi mi (animasyon için)

  // ── Goalkeeper ───────────────────────────────────────────────────────────
  double _gkX       = 0.50;
  double _gkTargetX = 0.50;
  double _gkVel     = 0.0;

  // ── Animations ───────────────────────────────────────────────────────────
  late AnimationController _physCtrl;
  late AnimationController _goalCtrl;
  late AnimationController _missCtrl;
  late Animation<double>   _goalScale;
  late Animation<double>   _missShake;

  bool _celebrating = false;
  bool _missed      = false;
  bool _blocked     = false;

  final _rng = Random();

  // Spin / after-touch efekti (top havada döner)
  double _spin = 0.0;

  // Powerbar için renk
  Color get _powerColor {
    if (_dragStart == null || _dragCurrent == null) return Colors.white;
    final pct = (_dragStart! - _dragCurrent!).distance / 0.35;
    if (pct < 0.4) return Colors.greenAccent;
    if (pct < 0.7) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.soccer}/${widget.roomId}');

    _physCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_physicsTick);

    _goalCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _goalScale = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _goalCtrl, curve: Curves.elasticOut));

    _missCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _missShake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 18.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 18.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end:  0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _missCtrl, curve: Curves.easeOut));

    _sub = _ref.onValue.listen(_onFirebase);
  }

  @override
  void dispose() {
    _physCtrl.dispose();
    _goalCtrl.dispose();
    _missCtrl.dispose();
    _syncTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  // ── Firebase ─────────────────────────────────────────────────────────────

  void _onFirebase(DatabaseEvent e) {
    if (!mounted) return;
    if (e.snapshot.value == null) {
      // Oda silindi (rakip ayrıldı ya da bağlantısı koptu) — eskiden burada
      // sessizce return edilirdi ve ekran sonsuza dek donuk kalırdı. Artık
      // ana menüye dönüyoruz.
      if (!_roomGone) {
        _roomGone = true;
        Navigator.popUntil(context, (r) => r.isFirst);
      }
      return;
    }
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);
    final prevPlayer = _room['currentPlayer'] as String?;
    final newPlayer  = d['currentPlayer'] as String?;
    setState(() {
      _room         = d;
      _currentRound = (d['currentRound'] as int?) ?? 1;
      _totalRounds  = (d['totalRounds']  as int?) ?? 5;
      _isMyTurn     = d['currentPlayer'] == widget.myKey;
      _myScore      = (d['players']?[widget.myKey]?['score'] as int?) ?? 0;
    });

    // Sıra yeni bir oyuncuya geçti — top yeni vuruş için resetlenir
    // (hem vuran hem izleyen tarafta).
    if (newPlayer != null && newPlayer != prevPlayer) {
      _resetBall();
    }

    // İzleyen taraf (sırası gelmeyen oyuncu): vuran tarafın senkronize
    // ettiği top/kaleci konumunu DOĞRUDAN uygular — kendi fizik motorunu
    // hiç çalıştırmaz, sadece gelen veriyi görselleştirir.
    if (!_isMyTurn) {
      final ball = d['ball'] as Map?;
      if (ball != null) {
        final bx = (ball['x'] as num?)?.toDouble();
        final by = (ball['y'] as num?)?.toDouble();
        if (bx != null && by != null) {
          setState(() {
            _ball    = Offset(bx, by);
            _ballVel = Offset(
                (ball['vx'] as num?)?.toDouble() ?? 0,
                (ball['vy'] as num?)?.toDouble() ?? 0);
            _spin    = (ball['spin'] as num?)?.toDouble() ?? 0;
            _gkX     = (ball['gkX'] as num?)?.toDouble() ?? 0.5;
            _moving  = ball['moving'] == true;
          });
        }
      }
      // Vuran tarafın bildirdiği sonucu (gol/kaleci kurtardı/kaçırdı) göster.
      final resultSeq = (d['resultSeq'] as int?) ?? 0;
      if (resultSeq != 0 && resultSeq != _shownResultSeq) {
        _shownResultSeq = resultSeq;
        switch (d['result'] as String?) {
          case 'goal':    _playGoalFx(); break;
          case 'blocked': _playBlockedFx(); break;
          case 'miss':    _playMissFx(); break;
        }
      }
    }

    if (d['status'] == 'finished' && !_finalShown) {
      _finalShown = true;
      AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds: 600), _showFinalDialog);
    }
  }

  // ── Physics tick (60fps) ─────────────────────────────────────────────────

  void _physicsTick() {
    if (!_moving) return;
    setState(() {
      // Hareketi uygula
      _ball    += _ballVel * _kDt;
      _ballVel *= _kFriction;

      // Spin efekti — topun yatay çizgisi hafif bükülür
      _spin += _ballVel.dx * 0.1;

      // ── Goalkeeper hareketi ──
      final gkDiff = _gkTargetX - _gkX;
      _gkVel  = _gkVel * 0.7 + gkDiff * 0.25;
      _gkX   += _gkVel * _kDt * 60;
      _gkX    = _gkX.clamp(
          _kGoalLeft  + _kGkRadius,
          _kGoalRight - _kGkRadius);

      // ── Saha duvarı (sol/sağ/alt) — TOP ÇIKMAZ ──
      if (_ball.dx - _kBallRadius < 0) {
        _ball    = Offset(_kBallRadius, _ball.dy);
        _ballVel = Offset(-_ballVel.dx * _kBounceLoss, _ballVel.dy * 0.92);
        HapticFeedback.lightImpact();
      }
      if (_ball.dx + _kBallRadius > 1) {
        _ball    = Offset(1 - _kBallRadius, _ball.dy);
        _ballVel = Offset(-_ballVel.dx * _kBounceLoss, _ballVel.dy * 0.92);
        HapticFeedback.lightImpact();
      }
      if (_ball.dy + _kBallRadius > 1) {
        _ball    = Offset(_ball.dx, 1 - _kBallRadius);
        _ballVel = Offset(_ballVel.dx * 0.92, -_ballVel.dy * _kBounceLoss);
        HapticFeedback.lightImpact();
      }

      // ── Kale direği çarpması ──
      // Sol direk
      _collidePost(Offset(_kGoalLeft,  _kGoalBottom));
      // Sağ direk
      _collidePost(Offset(_kGoalRight, _kGoalBottom));
      // Üst sol köşe
      _collidePost(Offset(_kGoalLeft,  0));
      // Üst sağ köşe
      _collidePost(Offset(_kGoalRight, 0));

      // ── Kale üst direği (crossbar) çarpması ──
      // Top kale üstünden geri sektiyse
      if (_ball.dy - _kBallRadius < 0 &&
          _ball.dx > _kGoalLeft &&
          _ball.dx < _kGoalRight) {
        _ball    = Offset(_ball.dx, _kBallRadius);
        _ballVel = Offset(_ballVel.dx, -_ballVel.dy * _kBounceLoss);
        HapticFeedback.lightImpact();
      }

      // ── Kaleci çarpması ──
      if (_ball.dy < _kGoalBottom + 0.05) {
        final gkDx = _ball.dx - _gkX;
        final gkDy = _ball.dy - _kGkY;
        final dist = sqrt(gkDx * gkDx + gkDy * gkDy);
        if (dist < _kBallRadius + _kGkRadius) {
          // Sekme yönü
          final nx    = gkDx / dist;
          final ny    = gkDy / dist;
          final speed = _ballVel.distance * 0.75;
          _ballVel    = Offset(nx * speed, ny * speed.abs() * 1.2);
          // Top kaleciden dışarı it
          final overlap = (_kBallRadius + _kGkRadius) - dist;
          _ball = Offset(
              _ball.dx + nx * overlap,
              _ball.dy + ny * overlap);
          HapticFeedback.mediumImpact();
        }
      }

      // ── Durma kontrolü ──
      if (_ballVel.distance < _kMinSpeed) {
        _ballVel = Offset.zero;
        _moving  = false;
        _spin    = 0;
        _physCtrl.stop();
        _checkResult();
      }
    });
  }

  /// Silindirik kale direğiyle çarpışma
  void _collidePost(Offset postPos) {
    const postRadius = 0.018;
    final dx   = _ball.dx - postPos.dx;
    final dy   = _ball.dy - postPos.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < _kBallRadius + postRadius && dist > 0) {
      final nx    = dx / dist;
      final ny    = dy / dist;
      final dot   = _ballVel.dx * nx + _ballVel.dy * ny;
      _ballVel    = Offset(
          _ballVel.dx - 2 * dot * nx * 0.65,
          _ballVel.dy - 2 * dot * ny * 0.65);
      final overlap = (_kBallRadius + postRadius) - dist;
      _ball = Offset(_ball.dx + nx * overlap, _ball.dy + ny * overlap);
      HapticFeedback.lightImpact();
    }
  }

  // ── Drag input ────────────────────────────────────────────────────────────

  Offset _norm(Offset local, Size size) =>
      Offset(local.dx / size.width, local.dy / size.height);

  void _onPanStart(DragStartDetails d, Size size) {
    if (!_isMyTurn || !_canShoot || _moving) return;
    final tap = _norm(d.localPosition, size);
    // Top yakınında mı kontrol et (biraz geniş tolerans)
    if ((tap - _ball).distance > 0.18) return;
    setState(() { _dragStart = tap; _dragCurrent = tap; });
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = _norm(d.localPosition, size));
  }

  void _onPanEnd(DragEndDetails _, Size size) {
    if (_dragStart == null || _dragCurrent == null || !_isMyTurn || !_canShoot) return;
    final delta = _dragStart! - _dragCurrent!;
    if (delta.distance < 0.015) {
      setState(() { _dragStart = null; _dragCurrent = null; });
      return;
    }

    // Güç hesapla
    final rawPower = (delta.distance * 14.0).clamp(1.0, _kMaxPower);
    final dir      = delta / delta.distance;

    // Hafif spin — yatay bileşen topun dönüşünü etkiler
    final lateralBias = Offset(-dir.dy * 0.15, dir.dx * 0.15);

    setState(() {
      _canShoot    = false;
      _moving      = true;
      _inNet       = false;
      _celebrating = false;
      _missed      = false;
      _blocked     = false;
      _ballVel     = (dir + lateralBias) * rawPower;
      _dragStart   = null;
      _dragCurrent = null;
      // Kaleci rastgele bir tarafa atılır
      _gkTargetX = _rng.nextBool()
          ? _kGoalLeft  + _kGkRadius + _rng.nextDouble() * _kGkRange
          : _kGoalRight - _kGkRadius - _rng.nextDouble() * _kGkRange;
    });

    _physCtrl.repeat();
    HapticFeedback.mediumImpact();

    // Top hareket etmeye başladı — izleyen tarafın ekranında görünmesi
    // için hemen bir kez, sonra 10fps'de senkronize et.
    _syncBallToFirebase();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
        const Duration(milliseconds: 100), (_) => _syncBallToFirebase());
  }

  Future<void> _syncBallToFirebase() async {
    if (!_isMyTurn) return;
    await _ref.update({
      'ball': {
        'x': _ball.dx, 'y': _ball.dy,
        'vx': _ballVel.dx, 'vy': _ballVel.dy,
        'spin': _spin, 'gkX': _gkX,
        'moving': _moving,
      },
    });
  }

  // ── Result check ──────────────────────────────────────────────────────────

  Future<void> _checkResult() async {
    // Top durdu — periyodik senkronu kapat, izleyen tarafa son (durma)
    // konumunu bir kez daha gönder.
    _syncTimer?.cancel();
    unawaited(_syncBallToFirebase());

    // Gol bölgesi: x [GoalLeft..GoalRight], y < GoalBottom
    final inGoal = _ball.dx > _kGoalLeft  + 0.01 &&
                   _ball.dx < _kGoalRight - 0.01 &&
                   _ball.dy < _kGoalBottom + 0.01;

    // Kaleci bloğu (kaleci yakınındaysa zaten fiziksel olarak sekmiştir)
    // Ek yazılımsal kontrol: Kaleci gerçekten kurtardı mı?
    final gkDist = (_ball.dx - _gkX).abs();
    final gkSave = gkDist < _kGkRadius * 1.5 && _ball.dy < _kGoalBottom + 0.08;

    if (inGoal) {
      await _onGoal();
    } else if (gkSave) {
      await _onBlocked();
    } else {
      await _onMiss();
    }
  }

  // _playXFx(): sadece görsel efekt — hem vuran taraf (doğrudan) hem
  // izleyen taraf (Firebase'den gelen resultSeq üzerinden, bkz.
  // _onFirebase) tarafından çağrılır. _onX(): SADECE vuran tarafta
  // çalışır — efekti oynatır, skor/sonucu Firebase'e yazar ve sırayı
  // ilerletir.

  Future<void> _playGoalFx() async {
    setState(() { _celebrating = true; _inNet = true; });
    _goalCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() { _celebrating = false; });
  }

  Future<void> _playBlockedFx() async {
    setState(() { _blocked = true; });
    HapticFeedback.mediumImpact();
    _missCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() { _blocked = false; });
  }

  Future<void> _playMissFx() async {
    setState(() { _missed = true; });
    HapticFeedback.lightImpact();
    _missCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() { _missed = false; });
  }

  Future<void> _onGoal() async {
    final newScore = _myScore + 1;
    await _ref.update({
      'players/${widget.myKey}/score': newScore,
      'result': 'goal', 'resultSeq': ServerValue.increment(1),
    });
    await _playGoalFx();
    _resetBall();
    await _advanceTurn();
  }

  Future<void> _onBlocked() async {
    await _ref.update({'result': 'blocked', 'resultSeq': ServerValue.increment(1)});
    await _playBlockedFx();
    _resetBall();
    await _advanceTurn();
  }

  Future<void> _onMiss() async {
    await _ref.update({'result': 'miss', 'resultSeq': ServerValue.increment(1)});
    await _playMissFx();
    _resetBall();
    await _advanceTurn();
  }

  void _resetBall() {
    setState(() {
      _ball      = const Offset(0.50, 0.72);
      _ballVel   = Offset.zero;
      _moving    = false;
      _canShoot  = true;
      _inNet     = false;
      _spin      = 0;
      _gkX       = 0.50;
      _gkTargetX = 0.50;
      _gkVel     = 0.0;
    });
  }

  Future<void> _advanceTurn() async {
    if (!_isMyTurn) return;
    final players = (_room['players'] as Map?)?.keys.toList() ?? ['p1', 'p2'];
    final idx     = players.indexOf(widget.myKey);
    final nextKey = players[(idx + 1) % players.length];

    if (_currentRound >= _totalRounds && nextKey == players.first) {
      await _ref.update({'status': 'finished'});
    } else {
      final newRound = nextKey == players.first ? _currentRound + 1 : _currentRound;
      await _ref.update({'currentPlayer': nextKey, 'currentRound': newRound});
    }
  }

  // ── Final dialog ──────────────────────────────────────────────────────────

  void _showFinalDialog() {
    if (!mounted) return;
    final players = (_room['players'] as Map?) ?? {};
    final sorted  = players.entries.toList()
      ..sort((a, b) =>
          ((b.value['score'] as int?) ?? 0).compareTo((a.value['score'] as int?) ?? 0));
    final iWon = sorted.isNotEmpty && sorted.first.key == widget.myKey;
    ProfileService.instance
        .reportGameResult(gameId: 'soccer', won: iWon)
        .then((_) => AchievementService.instance.checkAndUnlock());
    const medals = ['🥇', '🥈'];

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Maç Bitti!', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: sorted.asMap().entries.map((e) {
            final isMe  = e.value.key == widget.myKey;
            final score = (e.value.value['score'] as int?) ?? 0;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.orange.shade50 : null,
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text(e.key < medals.length ? medals[e.key] : '?',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    e.value.value['name'] as String? ?? e.value.key,
                    style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16))),
                Text('$score gol',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            );
          }).toList(),
        ),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AZColors.orange),
          onPressed: () async {
            await _db.child('${GamePaths.soccer}/${widget.roomId}').remove();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  /// Aktif maçta önceden HİÇBİR çıkış yolu yoktu — sırası gelen oyuncu
  /// ayrılırsa (geri tuşu/uygulamayı kapatma), rakip "Rakibin vuruyor..."
  /// ekranında sonsuza dek beklerdi çünkü sırayı sadece o oyuncunun kendi
  /// vuruşu ilerletir. Ayrılmadan önce sırası bendeyse rakibe devrediyoruz.
  Future<void> _leaveGame() async {
    final players = Map<String, dynamic>.from((_room['players'] as Map?) ?? {});
    final remaining = Map<String, dynamic>.from(players)..remove(widget.myKey);
    if (remaining.isEmpty) {
      await _rooms.deleteRoom(gamePath: GamePaths.soccer, roomId: widget.roomId);
    } else {
      if (_isMyTurn) {
        await _ref.update({'currentPlayer': remaining.keys.first});
      }
      await _rooms.removePlayer(
          gamePath: GamePaths.soccer, roomId: widget.roomId, playerKey: widget.myKey);
    }
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmLeave() async {
    final ok = await confirmLeaveGame(
      context,
      title:   'Maçtan çık?',
      message: 'Aktif bir maçın ortasındasın. Çıkarsan bu geri alınamaz.',
    );
    if (ok) await _leaveGame();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(
          backgroundColor: AZColors.greenDk,
          body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    return AZLeaveGuard(
      onLeave: _confirmLeave,
      child: Scaffold(
      backgroundColor: AZColors.greenDk,
      body: SafeArea(child: Column(children: [

        // ── Score bar ──────────────────────────────────────────────────────
        _SoccerScoreBar(
          players:  (_room['players'] as Map?) ?? {},
          myKey:    widget.myKey,
          round:    _currentRound,
          maxRound: _totalRounds,
          onLeave:  _confirmLeave,
        ),

        // ── Status strip ──────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isMyTurn ? AZColors.green : AZColors.greenDk,
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(child: Text(
            _celebrating ? '⚽ GOL! Harika vuruş! 🎉'
                : _blocked ? '🧤 Kaleci kurtardı!'
                : _missed  ? '❌ Iskaladın!'
                : _moving  ? '🌀 Top gidiyor...'
                : _isMyTurn ? '🎯 Topa dokun, geri çek, bırak!'
                : '⏳ Rakibin vuruyor...',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 13),
          )),
        ),

        // ── Field ─────────────────────────────────────────────────────────
        Expanded(child: LayoutBuilder(builder: (_, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            onPanStart:  (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd:    (d) => _onPanEnd(d, size),
            child: Stack(children: [

              // Ana saha painter
              AnimatedBuilder(
                animation: _missShake,
                builder: (_, __) => Transform.translate(
                  offset: _missed || _blocked
                      ? Offset(_missShake.value, 0) : Offset.zero,
                  child: CustomPaint(
                    size: size,
                    painter: _SoccerFieldPainter(
                      ball:        _ball,
                      ballVel:     _ballVel,
                      spin:        _spin,
                      inNet:       _inNet,
                      gkX:         _gkX,
                      dragStart:   _isMyTurn && _canShoot ? _dragStart : null,
                      dragCurrent: _dragCurrent,
                      powerColor:  _powerColor,
                    ),
                  ),
                ),
              ),

              // GOL animasyonu
              if (_celebrating)
                AnimatedBuilder(
                  animation: _goalScale,
                  builder: (_, __) => Positioned.fill(
                    child: IgnorePointer(child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withAlpha(
                                (50 * (1 - _goalCtrl.value)).toInt()),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(child: Transform.scale(
                        scale: _goalScale.value,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('⚽', style: TextStyle(fontSize: 72)),
                          const SizedBox(height: 4),
                          Text('GOL!',
                              style: TextStyle(
                                  fontSize: 48, fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 6,
                                  shadows: [
                                    Shadow(blurRadius: 20,
                                        color: Colors.black.withAlpha(180)),
                                    Shadow(blurRadius: 40,
                                        color: Colors.orange.withAlpha(200)),
                                  ])),
                        ]),
                      )),
                    )),
                  ),
                  child: const SizedBox.shrink(),
                ),

              // Kaleci kurtardı overlay
              if (_blocked)
                Positioned.fill(child: IgnorePointer(child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(220),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Text('🧤 Kaleci Kurtardı!',
                        style: TextStyle(color: Colors.white,
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ))),

              // Iskaladı overlay
              if (_missed)
                Positioned.fill(child: IgnorePointer(child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.red.withAlpha(200),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Text('❌ Iskaladın!',
                        style: TextStyle(color: Colors.white,
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ))),
            ]),
          );
        })),

        // ── Banner reklam ────────────────────────────────────────────────
        const BannerAdWidget(),
      ])),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCORE BAR
// ══════════════════════════════════════════════════════════════════════════════

class _SoccerScoreBar extends StatelessWidget {
  const _SoccerScoreBar({
    required this.players, required this.myKey,
    required this.round,   required this.maxRound,
    required this.onLeave,
  });
  final Map players; final String myKey; final int round, maxRound;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AZColors.green, AZColors.greenDk],
      ),
      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onLeave),
      const SizedBox(width: 4),
      Text('Vuruş $round/$maxRound',
          style: const TextStyle(color: Color(0xB3FFFFFF),
              fontSize: 12, fontWeight: FontWeight.w600)),
      Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end,
        children: players.entries.map((e) {
          final isMe  = e.key == myKey;
          final score = (e.value['score'] as int?) ?? 0;
          return Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: isMe ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(12)),
            child: Text('${e.value['name']}: $score ⚽',
                style: TextStyle(
                    color: isMe ? AZColors.green : Colors.white,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12)),
          );
        }).toList(),
      )),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER — gerçekçi saha
// ══════════════════════════════════════════════════════════════════════════════

class _SoccerFieldPainter extends CustomPainter {
  const _SoccerFieldPainter({
    required this.ball,
    required this.ballVel,
    required this.spin,
    required this.inNet,
    required this.gkX,
    required this.powerColor,
    this.dragStart,
    this.dragCurrent,
  });

  final Offset  ball, ballVel;
  final double  spin, gkX;
  final bool    inNet;
  final Color   powerColor;
  final Offset? dragStart, dragCurrent;

  @override
  void paint(Canvas canvas, Size s) {
    final W = s.width;
    final H = s.height;

    // ── Çim zemin ──────────────────────────────────────────────────────────
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AZColors.green, AZColors.greenDk],
      ).createShader(Rect.fromLTWH(0, 0, W, H));
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H), grassPaint);

    // Çim şeritleri
    for (var i = 0; i < 10; i++) {
      if (i.isOdd) {
        canvas.drawRect(
            Rect.fromLTWH(0, H * i / 10, W, H / 10),
            Paint()..color = const Color(0x0C000000));
      }
    }

    // ── Orta çizgi & çember ──────────────────────────────────────────────
    final linePaint = Paint()
      ..color = Colors.white.withAlpha(70)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, H * 0.5), Offset(W, H * 0.5), linePaint);
    canvas.drawCircle(Offset(W * 0.5, H * 0.5), W * 0.12, linePaint);
    canvas.drawCircle(Offset(W * 0.5, H * 0.5), 4,
        Paint()..color = Colors.white.withAlpha(70));

    // ── Kale çizgisi & alan ───────────────────────────────────────────────
    final goalLeft  = W * _kGoalLeft;
    final goalRight = W * _kGoalRight;
    final goalY     = H * _kGoalBottom;

    // Ceza sahası
    canvas.drawRect(
        Rect.fromLTRB(W * 0.08, 0, W * 0.92, H * 0.30),
        Paint()
          ..color = Colors.white.withAlpha(25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // ── Kale ağı (3D görünüm) ─────────────────────────────────────────────
    final netDepth = H * _kNetDepth;

    // Arka panel (gölge)
    final netBackPath = Path()
      ..moveTo(goalLeft, 0)
      ..lineTo(goalRight, 0)
      ..lineTo(goalRight + 8, netDepth)
      ..lineTo(goalLeft  - 8, netDepth)
      ..close();
    canvas.drawPath(netBackPath,
        Paint()..color = Colors.black.withAlpha(inNet ? 80 : 50));

    // Ağ yatay çizgileri
    final netPaint = Paint()
      ..color = Colors.white.withAlpha(inNet ? 180 : 110)
      ..strokeWidth = 0.8;
    for (var y = 0.0; y <= goalY; y += H * 0.028) {
      canvas.drawLine(Offset(goalLeft, y), Offset(goalRight, y), netPaint);
    }

    // Ağ dikey çizgileri
    for (var x = goalLeft; x <= goalRight; x += W * 0.05) {
      canvas.drawLine(Offset(x, 0), Offset(x, goalY), netPaint);
    }

    // Ağ ışıltısı (gol olunca)
    if (inNet) {
      final glowPath = Path()
        ..moveTo(goalLeft, 0)
        ..lineTo(goalRight, 0)
        ..lineTo(goalRight, goalY)
        ..lineTo(goalLeft, goalY)
        ..close();
      canvas.drawPath(glowPath,
          Paint()..color = AZColors.accentGold.withAlpha(40)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    }

    // Kale sol direk
    _drawPost(canvas, Offset(goalLeft, 0), Offset(goalLeft, goalY), W);
    // Kale sağ direk
    _drawPost(canvas, Offset(goalRight, 0), Offset(goalRight, goalY), W);
    // Kale üst direk (crossbar)
    _drawPost(canvas, Offset(goalLeft, 0), Offset(goalRight, 0), W,
        isHorizontal: true);

    // ── Kaleci ───────────────────────────────────────────────────────────
    _drawGoalkeeper(canvas, gkX * W, H * _kGkY, W);

    // ── Güç göstergesi ───────────────────────────────────────────────────
    if (dragStart != null && dragCurrent != null) {
      final bx    = ball.dx * W;
      final by    = ball.dy * H;
      final dx    = (dragStart!.dx - dragCurrent!.dx) * W;
      final dy    = (dragStart!.dy - dragCurrent!.dy) * H;
      final dist  = sqrt(dx * dx + dy * dy);
      final power = (dist / (W * 0.35)).clamp(0.0, 1.0);

      // Gölge çizgi
      canvas.drawLine(
          Offset(bx, by),
          Offset(bx + dx * 1.6, by + dy * 1.6),
          Paint()
            ..color = Colors.black.withAlpha(60)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // Ana çizgi
      canvas.drawLine(
          Offset(bx, by),
          Offset(bx + dx * 1.6, by + dy * 1.6),
          Paint()
            ..color = powerColor.withAlpha(200)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round);

      // Güç noktaları
      for (var i = 1; i <= 6; i++) {
        final t     = i / 7.0;
        final alpha = power >= t ? 230 : 60;
        canvas.drawCircle(
            Offset(bx + dx * 1.6 * t, by + dy * 1.6 * t),
            5.0 - i * 0.3,
            Paint()..color = powerColor.withAlpha(alpha));
      }

      // Top etrafı daire (güç göstergesi)
      canvas.drawCircle(
          Offset(bx, by),
          W * 0.06 * (0.8 + power * 0.4),
          Paint()
            ..color = powerColor.withAlpha((power * 120).toInt())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }

    // ── Top ──────────────────────────────────────────────────────────────
    _drawBall(canvas, ball.dx * W, ball.dy * H, W * _kBallRadius, spin, ballVel);
  }

  /// Kale direği
  void _drawPost(Canvas canvas, Offset a, Offset b, double W,
      {bool isHorizontal = false}) {
    // Gölge
    canvas.drawLine(
        a.translate(3, 3), b.translate(3, 3),
        Paint()
          ..color = Colors.black.withAlpha(80)
          ..strokeWidth = W * 0.022
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Metalik direk
    final postGrad = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade300, Colors.white, Colors.grey.shade400],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ).createShader(Rect.fromPoints(a, b))
      ..strokeWidth = W * 0.022
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(a, b, postGrad);
  }

  /// Kaleci
  void _drawGoalkeeper(Canvas canvas, double cx, double cy, double W) {
    final r = W * _kGkRadius;

    // Gölge
    canvas.drawCircle(Offset(cx + 3, cy + 4), r * 0.9,
        Paint()
          ..color = Colors.black.withAlpha(60)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Vücut (sarı-turuncu forma)
    final bodyPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(cx, cy), width: r * 2.2, height: r * 2.5));
    canvas.drawPath(bodyPath,
        Paint()..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [AZColors.orange, AZColors.orangeDk],
        ).createShader(Rect.fromCenter(
            center: Offset(cx, cy), width: r * 2.2, height: r * 2.5)));

    // Yüz
    canvas.drawCircle(Offset(cx, cy - r * 0.15), r * 0.68,
        Paint()..color = const Color(0xFFFFCC80));

    // Gözler
    final eyePaint = Paint()..color = Colors.brown.shade800;
    canvas.drawCircle(Offset(cx - r * 0.25, cy - r * 0.25), r * 0.12, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.25, cy - r * 0.25), r * 0.12, eyePaint);

    // Gülen ağız
    final mouthRect = Rect.fromCenter(
        center: Offset(cx, cy + r * 0.08), width: r * 0.7, height: r * 0.4);
    canvas.drawArc(mouthRect, 0.2, pi - 0.4, false,
        Paint()
          ..color = Colors.brown.shade700
          ..strokeWidth = r * 0.1
          ..style = PaintingStyle.stroke);

    // Eldivenler
    final glove = Paint()
      ..shader = RadialGradient(
        colors: [AZColors.accentGoldSoft, AZColors.orangeDk],
      ).createShader(Rect.fromCircle(center: Offset(cx - r * 1.2, cy), radius: r * 0.4));
    canvas.drawCircle(Offset(cx - r * 1.2, cy), r * 0.38, glove);
    canvas.drawCircle(Offset(cx + r * 1.2, cy), r * 0.38,
        Paint()..shader = RadialGradient(
          colors: [AZColors.accentGoldSoft, AZColors.orangeDk],
        ).createShader(Rect.fromCircle(
            center: Offset(cx + r * 1.2, cy), radius: r * 0.4)));

    // Kıyafet numarası
    final textPainter = TextPainter(
      text: const TextSpan(
          text: '1',
          style: TextStyle(color: Colors.white, fontSize: 10,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx - 5, cy + r * 0.2));
  }

  /// Top — gerçekçi futbol topu deseni
  void _drawBall(Canvas canvas, double bx, double by, double br,
      double spin, Offset vel) {
    // Hareket bulanıklığı (motion blur)
    if (vel.distance > 0.05) {
      final speed  = vel.distance.clamp(0.0, 0.3);
      final dir    = vel.distance > 0 ? vel / vel.distance : Offset.zero;
      final trailL = br * 3.0 * speed / 0.3;
      canvas.drawLine(
          Offset(bx, by),
          Offset(bx - dir.dx * trailL, by - dir.dy * trailL),
          Paint()
            ..color = Colors.white.withAlpha(
                (40 * speed / 0.3).toInt().clamp(0, 40))
            ..strokeWidth = br * 1.8
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    // Gölge
    canvas.drawCircle(Offset(bx + br * 0.3, by + br * 0.4), br * 0.85,
        Paint()
          ..color = Colors.black.withAlpha(70)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Top gövdesi
    canvas.drawCircle(Offset(bx, by), br,
        Paint()..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 1.0,
          colors: [Colors.white, Colors.grey.shade300],
        ).createShader(Rect.fromCircle(
            center: Offset(bx, by), radius: br)));

    // Futbol topu pentagonu (dönen spin ile)
    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(spin * 0.05);

    final pentPaint = Paint()..color = Colors.black87;
    // Merkez pentagon
    canvas.drawCircle(Offset.zero, br * 0.22, pentPaint);
    // Çevre pentagonlar (5 tane)
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      canvas.drawCircle(
          Offset(cos(a) * br * 0.60, sin(a) * br * 0.60),
          br * 0.18,
          pentPaint);
    }
    canvas.restore();

    // Parlama
    canvas.drawCircle(
        Offset(bx - br * 0.38, by - br * 0.38),
        br * 0.28,
        Paint()..color = Colors.white.withAlpha(180)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(_SoccerFieldPainter old) =>
      old.ball != ball || old.gkX != gkX ||
      old.dragStart != dragStart || old.inNet != inNet ||
      old.spin != spin;
}
