import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';

bool soupInBowl(double t) => t >= 0.58 && t <= 0.74;

enum LeafLanding { early, landed, over }

LeafLanding leafLanding(double x) {
  if (x < 0.62) return LeafLanding.early;
  if (x <= 0.82) return LeafLanding.landed;
  return LeafLanding.over;
}

bool hiccupOnBeat(double wave) => wave >= 0.75;

bool slipperSeated(double degrees) {
  var turn = degrees % 360;
  if (turn < 0) turn += 360;
  final delta = turn > 180 ? 360 - turn : turn;
  return delta <= 18;
}

class TersMamaLobbyScreen extends StatelessWidget {
  const TersMamaLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Ters Mama',
        emoji: '🐱',
        gradient: AZColors.gradOrange,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Kedi çorap, şemsiye ve saat yer. Balığa dokunma.',
      );
}

class TersMamaGameScreen extends StatelessWidget {
  const TersMamaGameScreen({super.key, required this.players});
  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'tersmama',
        gradient: AZColors.gradOrange,
        title: 'Ters Mama',
        emoji: '🐱',
        formatScore: (score) => '$score lokma',
        sessionBuilder: (context, player, onFinished) =>
            _TersSession(player: player, onFinished: onFinished),
      );
}

class _TersSession extends StatefulWidget {
  const _TersSession({required this.player, required this.onFinished});
  final QPPlayer player;
  final void Function(int score) onFinished;
  @override
  State<_TersSession> createState() => _TersSessionState();
}

class _TersSessionState extends State<_TersSession> {
  static const _silly = ['🧦', '☂️', '⏰', '🔑', '🥄', '🎩'];
  final _rng = Random();
  Timer? _clock;
  late List<String> _plate = _deal();
  int _score = 0;
  int _left = 25;
  bool _started = false;

  List<String> _deal() {
    final plate = List.generate(5, (i) => i == 0 ? '🐟' : _silly[_rng.nextInt(_silly.length)]);
    plate.shuffle(_rng);
    return plate;
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _left--;
      if (_left <= 0) {
        _clock?.cancel();
        widget.onFinished(_score);
        return;
      }
      setState(() {});
    });
  }

  void _tap(String item) {
    if (!_started) return;
    if (item == '🐟') {
      _clock?.cancel();
      widget.onFinished(_score);
      return;
    }
    setState(() {
      _score++;
      _plate = _deal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  $_score lokma  ${_started ? '$_left sn' : ''}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        const Text('🐱  Kedi bunları yer. Balık yasak.', style: TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: AZSpacing.md),
        for (final item in _plate)
          Padding(
            padding: const EdgeInsets.only(bottom: AZSpacing.sm),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _started ? () => _tap(item) : null,
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AZColors.textPrimary),
                child: Text(item, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
        const Spacer(),
        if (!_started)
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AZColors.orangeDk),
              child: const Text('Mama ver'),
            ),
          ),
      ],
    );
  }
}

class HiccupTowerLobbyScreen extends StatelessWidget {
  const HiccupTowerLobbyScreen({super.key});
  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Hıçkırık Kulesi',
        emoji: '🥞',
        gradient: AZColors.gradPink,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Halka genişleyince Hık’a bas. Her vuruş bir pankek ekler. Ritim kaçarsa kule devrilir.',
      );
}

class HiccupTowerGameScreen extends StatelessWidget {
  const HiccupTowerGameScreen({super.key, required this.players});
  final List<QPPlayer> players;
  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'hiccuptower',
        gradient: AZColors.gradPink,
        title: 'Hıçkırık Kulesi',
        emoji: '🥞',
        formatScore: (score) => '$score pankek',
        sessionBuilder: (context, player, onFinished) =>
            _HiccupSession(player: player, onFinished: onFinished),
      );
}

class _HiccupSession extends StatefulWidget {
  const _HiccupSession({required this.player, required this.onFinished});
  final QPPlayer player;
  final void Function(int score) onFinished;
  @override
  State<_HiccupSession> createState() => _HiccupSessionState();
}

class _HiccupSessionState extends State<_HiccupSession> {
  Timer? _timer;
  double _phase = 0;
  int _score = 0;
  bool _started = false;
  bool _over = false;

  double get _wave => sin(_phase);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_over) return;
      _phase += 0.08 + _score * 0.004;
      setState(() {});
    });
  }

  void _hit() {
    if (!_started) {
      _start();
      return;
    }
    if (_over) return;
    if (hiccupOnBeat(_wave)) {
      setState(() => _score++);
      return;
    }
    _over = true;
    _timer?.cancel();
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onFinished(_score);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text('${widget.player.name}  $_score pankek',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: AZSpacing.md),
        Expanded(
          child: CustomPaint(
            painter: _PancakePainter(count: _score, wave: _started ? _wave : 0),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _over ? null : _hit,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF8E4E62)),
            child: Text(_started ? 'Hık' : 'Kuleyi kur'),
          ),
        ),
      ],
    );
  }
}

class _PancakePainter extends CustomPainter {
  _PancakePainter({required this.count, required this.wave});
  final int count;
  final double wave;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = wave < 0 ? 0.0 : wave;
    final ring = 40.0 + pulse * 36;
    canvas.drawCircle(
      Offset(size.width / 2, 48),
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = FeltColors.brass,
    );
    for (var i = 0; i < count && i < 12; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height - 28 - i * 16),
          width: 120 - i * 4,
          height: 22,
        ),
        Paint()..color = i.isEven ? AZColors.orange : FeltColors.clay,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PancakePainter oldDelegate) => true;
}

class SoupBackLobbyScreen extends StatelessWidget {
  const SoupBackLobbyScreen({super.key});
  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Geri Sar Çorba',
        emoji: '🥣',
        gradient: AZColors.gradGreen,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Kaşık kaseye dönerken Dur’a bas. Beş deneme.',
      );
}

class SoupBackGameScreen extends StatelessWidget {
  const SoupBackGameScreen({super.key, required this.players});
  final List<QPPlayer> players;
  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'soupback',
        gradient: AZColors.gradGreen,
        title: 'Geri Sar Çorba',
        emoji: '🥣',
        formatScore: (score) => '$score kaşık',
        sessionBuilder: (context, player, onFinished) =>
            _SoupSession(player: player, onFinished: onFinished),
      );
}

class _SoupSession extends StatefulWidget {
  const _SoupSession({required this.player, required this.onFinished});
  final QPPlayer player;
  final void Function(int score) onFinished;
  @override
  State<_SoupSession> createState() => _SoupSessionState();
}

class _SoupSessionState extends State<_SoupSession> {
  Timer? _timer;
  double _t = 0;
  int _try = 0;
  int _score = 0;
  bool _started = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      _t += 0.012;
      if (_t >= 1) _settle(false);
      setState(() {});
    });
  }

  bool _lock = false;

  void _settle(bool pressed) {
    if (_lock || _try >= 5) return;
    _lock = true;
    if (pressed && soupInBowl(_t)) _score++;
    _try++;
    _t = 0;
    _lock = false;
    if (_try >= 5) {
      _timer?.cancel();
      widget.onFinished(_score);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text('${widget.player.name}  $_score/5',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: AZSpacing.md),
        Expanded(
          child: CustomPaint(
            painter: _SoupPainter(t: _started ? _t : 0.2),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: !_started ? _start : () => _settle(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AZColors.greenDk),
            child: Text(_started ? 'Dur' : 'Geri sar'),
          ),
        ),
      ],
    );
  }
}

class _SoupPainter extends CustomPainter {
  _SoupPainter({required this.t});
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final bowl = Rect.fromCenter(center: Offset(size.width * 0.66, size.height * 0.62), width: 90, height: 48);
    canvas.drawOval(bowl, Paint()..color = FeltColors.clay);
    canvas.drawCircle(
      Offset(size.width * (0.15 + t * 0.7), size.height * 0.42),
      16,
      Paint()..color = FeltColors.ivory,
    );
  }

  @override
  bool shouldRepaint(covariant _SoupPainter oldDelegate) => true;
}

class HairLeafLobbyScreen extends StatelessWidget {
  const HairLeafLobbyScreen({super.key});
  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Saçtaki Yaprak',
        emoji: '🍃',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Üfle’ye basılı tut. Yaprağı yuvada bırak. Fazla üflersen kaçar.',
      );
}

class HairLeafGameScreen extends StatelessWidget {
  const HairLeafGameScreen({super.key, required this.players});
  final List<QPPlayer> players;
  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'hairleaf',
        gradient: AZColors.gradCyan,
        title: 'Saçtaki Yaprak',
        emoji: '🍃',
        formatScore: (score) => '$score yaprak',
        sessionBuilder: (context, player, onFinished) =>
            _LeafSession(player: player, onFinished: onFinished),
      );
}

class _LeafSession extends StatefulWidget {
  const _LeafSession({required this.player, required this.onFinished});
  final QPPlayer player;
  final void Function(int score) onFinished;
  @override
  State<_LeafSession> createState() => _LeafSessionState();
}

class _LeafSessionState extends State<_LeafSession> {
  Timer? _timer;
  double _x = 0.12;
  int _leaf = 0;
  int _score = 0;
  bool _blowing = false;
  bool _started = false;
  bool _spiky = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_blowing) return;
      _x += 0.012;
      if (leafLanding(_x) == LeafLanding.over) _release();
      setState(() {});
    });
  }

  void _press() {
    if (!_started) _start();
    _blowing = true;
    _spiky = false;
  }

  void _release() {
    if (!_blowing) return;
    _blowing = false;
    final landing = leafLanding(_x);
    if (landing == LeafLanding.landed) _score++;
    if (landing == LeafLanding.over) _spiky = true;
    _leaf++;
    _x = 0.12;
    if (_leaf >= 5) {
      _timer?.cancel();
      widget.onFinished(_score);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text('${widget.player.name}  $_score/5',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: AZSpacing.md),
        Expanded(
          child: CustomPaint(
            painter: _HairPainter(x: _x, spiky: _spiky),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: Listener(
            onPointerDown: (_) => _press(),
            onPointerUp: (_) => _release(),
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AZColors.blueDk),
              child: const Text('Üfle'),
            ),
          ),
        ),
      ],
    );
  }
}

class _HairPainter extends CustomPainter {
  _HairPainter({required this.x, required this.spiky});
  final double x;
  final bool spiky;
  @override
  void paint(Canvas canvas, Size size) {
    final head = Offset(size.width * 0.28, size.height * 0.55);
    canvas.drawCircle(head, 36, Paint()..color = const Color(0xFFE7C8A8));
    final hair = Paint()
      ..color = FeltColors.feltDeep
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      final tip = spiky ? -50.0 : -18.0;
      canvas.drawLine(head.translate(i * 10, -20), head.translate(i * 14, tip), hair);
    }
    canvas.drawCircle(Offset(size.width * x, head.dy - 30), 8, Paint()..color = AZColors.green);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.72, head.dy - 8), width: 36, height: 18),
      Paint()..color = FeltColors.brass,
    );
  }

  @override
  bool shouldRepaint(covariant _HairPainter oldDelegate) => true;
}

class SlipperFlipLobbyScreen extends StatelessWidget {
  const SlipperFlipLobbyScreen({super.key});
  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Tek Terlik',
        emoji: '🩴',
        gradient: AZColors.gradPurple,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Terliği çevir. Eşinin üstüne oturunca Bırak. Beş terlik.',
      );
}

class SlipperFlipGameScreen extends StatelessWidget {
  const SlipperFlipGameScreen({super.key, required this.players});
  final List<QPPlayer> players;
  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'slipperflip',
        gradient: AZColors.gradPurple,
        title: 'Tek Terlik',
        emoji: '🩴',
        formatScore: (score) => '$score terlik',
        sessionBuilder: (context, player, onFinished) =>
            _SlipperSession(player: player, onFinished: onFinished),
      );
}

class _SlipperSession extends StatefulWidget {
  const _SlipperSession({required this.player, required this.onFinished});
  final QPPlayer player;
  final void Function(int score) onFinished;
  @override
  State<_SlipperSession> createState() => _SlipperSessionState();
}

class _SlipperSessionState extends State<_SlipperSession> {
  Timer? _timer;
  double _wiggle = 0;
  double _turns = 20;
  int _n = 0;
  int _score = 0;
  bool _started = false;

  double get _degrees => _turns + sin(_wiggle) * 10;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      _wiggle += 0.12;
      setState(() {});
    });
  }

  void _twist() {
    if (!_started) _start();
    setState(() => _turns += 45);
  }

  void _drop() {
    if (!_started) return;
    if (slipperSeated(_degrees)) _score++;
    _n++;
    _turns = 20 + _n * 15;
    if (_n >= 5) {
      _timer?.cancel();
      widget.onFinished(_score);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text('${widget.player.name}  $_score/5',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: AZSpacing.md),
        Expanded(
          child: CustomPaint(
            painter: _SlipperPainter(degrees: _started ? _degrees : 20),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _twist,
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AZColors.purpleDk),
                  child: const Text('Çevir'),
                ),
              ),
            ),
            const SizedBox(width: AZSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _started ? _drop : null,
                  style: FilledButton.styleFrom(backgroundColor: FeltColors.felt, foregroundColor: FeltColors.ivory),
                  child: const Text('Bırak'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SlipperPainter extends CustomPainter {
  _SlipperPainter({required this.degrees});
  final double degrees;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degrees * pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-50, -18, 100, 36), const Radius.circular(18)),
      Paint()..color = AZColors.orange,
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 70), width: 110, height: 28),
        const Radius.circular(14),
      ),
      Paint()..color = FeltColors.ivory,
    );
  }

  @override
  bool shouldRepaint(covariant _SlipperPainter oldDelegate) => true;
}
