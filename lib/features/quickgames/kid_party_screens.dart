import 'dart:async';
import 'dart:math';
import 'dart:math' as math;

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
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.15,
            mainAxisSpacing: AZSpacing.sm,
            crossAxisSpacing: AZSpacing.sm,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < _plate.length; i++)
                FilledButton(
                  onPressed: _started ? () => _tap(_plate[i]) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: i.isEven
                        ? const Color(0xFFFFF7E8)
                        : const Color(0xFFEAF6F0),
                    foregroundColor: AZColors.textPrimary,
                    disabledBackgroundColor: Colors.white.withAlpha(235),
                    elevation: _started ? 7 : 4,
                    shadowColor: Colors.black.withAlpha(90),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Colors.white.withAlpha(190),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(_plate[i], style: const TextStyle(fontSize: 34)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
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
    final ringCenter = Offset(size.width / 2, 48);
    canvas.drawCircle(
      ringCenter.translate(0, 2),
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = const Color(0xAA25151A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      ringCenter,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = FeltColors.brass.withOpacity(.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(
      ringCenter,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF0B7), Color(0xFFE4A83E), Color(0xFF9D642A)],
        ).createShader(Rect.fromCircle(center: ringCenter, radius: ring)),
    );
    canvas.drawCircle(
      ringCenter.translate(-1, -1),
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xCCFFF2C6),
    );

    final centerX = size.width / 2;
    final plateY = size.height - 29;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, plateY + 8),
        width: 218,
        height: 34,
      ),
      Paint()
        ..color = const Color(0x88000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final plateTop = Rect.fromCenter(
      center: Offset(centerX, plateY - 3),
      width: 204,
      height: 38,
    );
    final plateBottom = Rect.fromCenter(
      center: Offset(centerX, plateY + 8),
      width: 190,
      height: 34,
    );
    canvas.drawOval(
      plateBottom,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6B3637), Color(0xFF3A202B)],
        ).createShader(plateBottom),
    );
    canvas.drawOval(
      plateTop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFDFA4), Color(0xFFDB9860), Color(0xFF945342)],
        ).createShader(plateTop),
    );
    canvas.drawOval(
      plateTop.deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xCCFFE9BD),
    );

    for (var i = 0; i < count && i < 12; i++) {
      final width = math.max(68.0, 132.0 - i * 3.8).toDouble();
      final wobble =
          (math.sin(wave * .8 + i * .72) * math.min(4.0, i * .42)).toDouble();
      final center = Offset(centerX + wobble, size.height - 51 - i * 16);
      final bounds = Rect.fromCenter(center: center, width: width, height: 25);
      final under = bounds.shift(const Offset(0, 5));
      final topPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: i.isEven
              ? const [Color(0xFFFFE8A8), Color(0xFFE6A64D), Color(0xFFC77935)]
              : const [Color(0xFFFFD5A0), Color(0xFFD98C52), Color(0xFFA95B3D)],
        ).createShader(bounds);

      canvas.drawOval(
        under,
        Paint()
          ..color = const Color(0x99000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawOval(
        under,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB66D38), Color(0xFF75402F)],
          ).createShader(under),
      );
      canvas.drawOval(bounds, topPaint);
      canvas.drawOval(
        bounds,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xAAFFF0C5),
      );

      // Small toasted spots add surface detail without changing stack geometry.
      for (var spot = 0; spot < 4; spot++) {
        final dx = (spot - 1.5) * width * .19 + math.sin(i * 2 + spot) * 4;
        final dy = math.cos(i + spot * 1.7) * 4;
        canvas.drawCircle(
          center.translate(dx, dy),
          1.5 + (spot % 2) * .5,
          Paint()..color = const Color(0x55743B27),
        );
      }
    }

    if (count > 0) {
      final butterCenter = Offset(centerX, size.height - 64 - (count - 1) * 16);
      final butter = RRect.fromRectAndRadius(
        Rect.fromCenter(center: butterCenter.translate(0, -8), width: 24, height: 10),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        butter.shift(const Offset(0, 3)),
        Paint()
          ..color = const Color(0x88451F1A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(
        butter,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF1A8), Color(0xFFFFC94F), Color(0xFFE79A35)],
          ).createShader(butter.outerRect),
      );
      canvas.drawRRect(
        butter,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xCCFFF2BD),
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
    final center = Offset(size.width * 0.66, size.height * 0.62);
    final bowl = Rect.fromCenter(center: center, width: 90, height: 48);
    final widthScale = bowl.width / 90;

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 40 * widthScale),
        width: bowl.width * 1.3,
        height: 24 * widthScale,
      ),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final bowlBody = Path()
      ..moveTo(center.dx - bowl.width * .49, center.dy - 4)
      ..cubicTo(
        center.dx - bowl.width * .44,
        center.dy + bowl.height * .7,
        center.dx - bowl.width * .28,
        center.dy + bowl.height * .9,
        center.dx,
        center.dy + bowl.height * .9,
      )
      ..cubicTo(
        center.dx + bowl.width * .28,
        center.dy + bowl.height * .9,
        center.dx + bowl.width * .44,
        center.dy + bowl.height * .7,
        center.dx + bowl.width * .49,
        center.dy - 4,
      )
      ..close();
    canvas.drawPath(
      bowlBody.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0xFF4C252B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final leftHandle = Rect.fromCenter(
      center: center.translate(-bowl.width * .48, 1),
      width: 30 * widthScale,
      height: 22 * widthScale,
    );
    final rightHandle = leftHandle.shift(Offset(bowl.width * .96, 0));
    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * widthScale
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8E4544);
    canvas.drawOval(leftHandle, handlePaint);
    canvas.drawOval(rightHandle, handlePaint);
    final handleHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * widthScale
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xAAFFD3A6);
    canvas.drawArc(leftHandle, -1.2, 2.4, false, handleHighlight);
    canvas.drawArc(rightHandle, -1.2, 2.4, false, handleHighlight);

    canvas.drawPath(
      bowlBody,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FeltColors.clay.withOpacity(.95), const Color(0xFFB65B49), const Color(0xFF632F39)],
        ).createShader(bowl),
    );

    final foot = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, bowl.height * .78),
        width: bowl.width * .48,
        height: 10 * widthScale,
      ),
      Radius.circular(5 * widthScale),
    );
    canvas.drawRRect(
      foot,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8E4442), Color(0xFF532A33)],
        ).createShader(foot.outerRect),
    );

    final soup = bowl.deflate(5 * widthScale).shift(Offset(0, -8 * widthScale));
    canvas.drawOval(
      soup,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          colors: [Color(0xFFFFC76A), Color(0xFFE8873F), Color(0xFF9E482E)],
        ).createShader(soup),
    );
    canvas.drawOval(
      soup,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * widthScale
        ..color = const Color(0xFFFFD89A),
    );

    for (var i = 0; i < 5; i++) {
      final x = center.dx + (i - 2) * 11 * widthScale;
      final y = center.dy - 9 * widthScale + sin(t * 8 + i * 1.7) * 3 * widthScale;
      canvas.drawCircle(
        Offset(x, y),
        (i.isEven ? 2.2 : 1.5) * widthScale,
        Paint()..color = i.isEven ? const Color(0xFFFFE7A9) : const Color(0xFF6C372A),
      );
    }

    canvas.drawOval(
      bowl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * widthScale
        ..color = const Color(0xFF7E3D3D),
    );
    canvas.drawOval(
      bowl.deflate(2 * widthScale),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * widthScale
        ..color = const Color(0xFFFFD4A1),
    );
    canvas.drawArc(
      bowl.deflate(3 * widthScale),
      pi * 1.12,
      pi * .74,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * widthScale
        ..color = const Color(0x99FFFFFF),
    );

    for (var i = 0; i < 3; i++) {
      final steamX = center.dx + (i - 1) * 18 * widthScale;
      final steamPath = Path()
        ..moveTo(steamX, center.dy - 27 * widthScale)
        ..cubicTo(
          steamX - 9 * widthScale,
          center.dy - 39 * widthScale,
          steamX + 9 * widthScale,
          center.dy - 47 * widthScale,
          steamX + sin(t * 5 + i) * 5 * widthScale,
          center.dy - 61 * widthScale,
        );
      canvas.drawPath(
        steamPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * widthScale
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x3387E4DB)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        steamPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * widthScale
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xA8EAF8E6),
      );
    }

    final spoon = Offset(size.width * (0.15 + t * 0.7), size.height * 0.42);
    final handleEnd = spoon.translate(22 * widthScale, 23 * widthScale);
    canvas.drawLine(
      spoon.translate(5 * widthScale, 8 * widthScale),
      handleEnd,
      Paint()
        ..color = const Color(0xAA241E22)
        ..strokeWidth = 8 * widthScale
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawLine(
      spoon.translate(5 * widthScale, 8 * widthScale),
      handleEnd,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFBCC8C6), Color(0xFF727E7F)],
        ).createShader(Rect.fromPoints(spoon, handleEnd))
        ..strokeWidth = 5 * widthScale
        ..strokeCap = StrokeCap.round,
    );
    final spoonHead = Rect.fromCircle(center: spoon, radius: 16 * widthScale);
    canvas.drawCircle(
      spoon.translate(0, 3 * widthScale),
      16 * widthScale,
      Paint()
        ..color = const Color(0x88000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(
      spoonHead,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.4),
          colors: [Color(0xFFFFFFFF), Color(0xFFE4ECE8), Color(0xFF899896)],
        ).createShader(spoonHead),
    );
    canvas.drawOval(
      spoonHead,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * widthScale
        ..color = const Color(0xFFFFFFFF),
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
      RRect.fromRectAndRadius(Rect.fromLTWH(-50, -18, 100, 36), const Radius.circular(18)),
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
