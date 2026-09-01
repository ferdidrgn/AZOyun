import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class MiniBowlingLobbyScreen extends StatelessWidget {
  const MiniBowlingLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Mini Bovling',
        emoji: '🎳',
        gradient: AZColors.gradBlue,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Önce nişan al, sonra gücü ayarla — hareketli çubuk istediğin '
            'noktadayken dokunup durdur. 2 atış hakkın var, en çok pin '
            'deviren kazanır!',
      );
}

enum _Phase { aiming, power, thrown }

class MiniBowlingGameScreen extends StatelessWidget {
  const MiniBowlingGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'minibowling',
        gradient: AZColors.gradBlue,
        title: 'Mini Bovling',
        emoji: '🎳',
        formatScore: (s) => '$s pin',
        sessionBuilder: (context, player, onFinished) =>
            _BowlingSession(player: player, onFinished: onFinished),
      );
}

class _BowlingSession extends StatefulWidget {
  const _BowlingSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_BowlingSession> createState() => _BowlingSessionState();
}

class _BowlingSessionState extends State<_BowlingSession> {
  static const _pinX = [0.0, -0.13, 0.13, -0.26, 0.0, 0.26, -0.39, -0.13, 0.13, 0.39];
  static const _pinY = [0.31, 0.24, 0.24, 0.17, 0.17, 0.17, 0.10, 0.10, 0.10, 0.10];

  Timer? _timer;
  double _t = 0;
  double? _aim;
  final List<bool> _pinsDown = List.filled(10, false);
  int _throwsLeft = 2;
  bool _started = false;
  _Phase _phase = _Phase.aiming;
  double _ballX = 0;
  double _ballY = 0.88;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _startOsc();
  }

  void _startOsc() {
    _timer?.cancel();
    _t = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (mounted) setState(() => _t += 0.09);
    });
  }

  double get _osc => (sin(_t) + 1) / 2;

  void _tapBar() {
    if (_phase == _Phase.aiming) {
      setState(() {
        _aim = _osc * 2 - 1;
        _phase = _Phase.power;
        _t = 0;
      });
    } else if (_phase == _Phase.power) {
      _throwBall();
    }
  }

  void _throwBall() {
    final aim = _aim!;
    final power = _osc;
    _timer?.cancel();
    final landing = (aim * (0.55 + power * 0.5)).clamp(-1.0, 1.0);
    setState(() {
      _phase = _Phase.thrown;
      _ballX = landing;
      _ballY = 0.20;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _resolveThrow(landing, power);
    });
  }

  void _resolveThrow(double landing, double power) {
    final radius = 0.15 + power * 0.09;
    setState(() {
      for (var i = 0; i < 10; i++) {
        if (_pinsDown[i]) continue;
        if ((_pinX[i] - landing).abs() < radius) _pinsDown[i] = true;
      }
      _throwsLeft--;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_throwsLeft <= 0 || _pinsDown.every((d) => d)) {
        widget.onFinished(_pinsDown.where((d) => d).length);
      } else {
        setState(() {
          _phase = _Phase.aiming;
          _aim = null;
          _ballX = 0;
          _ballY = 0.88;
        });
        _startOsc();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎳', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('${widget.player.name}, hazır mısın?',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AZButton(label: 'BAŞLA', icon: Icons.play_arrow_rounded, color: AZColors.blueDk, onPressed: _start),
        ]),
      );
    }
    final knocked = _pinsDown.where((d) => d).length;
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.player.name} · Atış ${2 - _throwsLeft}/2 · Devrilen: $knocked/10',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(0.35),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E241D), Color(0xFF7A6552)],
                ),
                borderRadius: BorderRadius.circular(AZRadius.md),
              ),
              child: Stack(children: [
                for (var i = 0; i < 10; i++)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: (0.5 + _pinX[i] * 0.5) * w - 9,
                    top: _pinY[i] * h - 9,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _pinsDown[i] ? 0.15 : 1,
                      child: const Text('🎳', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOut,
                  left: (0.5 + _ballX * 0.5) * w - 10,
                  top: _ballY * h - 10,
                  child: const Text('🔴', style: TextStyle(fontSize: 20)),
                ),
              ]),
            ),
          );
        }),
      ),
      const SizedBox(height: 16),
      if (_phase != _Phase.thrown) _buildBar(),
      const SizedBox(height: 12),
    ]);
  }

  Widget _buildBar() {
    final label =
        _phase == _Phase.aiming ? 'NİŞAN AL — durdurmak için dokun' : 'GÜÇ — durdurmak için dokun';
    return GestureDetector(
      onTap: _tapBar,
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(14)),
          child: LayoutBuilder(builder: (context, constraints) {
            final barW = constraints.maxWidth;
            return Stack(children: [
              Positioned(
                left: _osc * (barW - 18),
                top: 4,
                child: Container(
                  width: 18,
                  height: 20,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]);
          }),
        ),
      ]),
    );
  }
}
