import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class ColorMemoryLobbyScreen extends StatelessWidget {
  const ColorMemoryLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Renk Hafızası',
        emoji: '🎨',
        gradient: AZColors.gradPink,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Cihaz sana renk dizisini gösterecek, aynı sırayla dokunarak '
            'tekrarla. Her turda dizi bir renk daha uzar. En uzun diziye '
            'ulaşan kazanır!',
      );
}

const _kMemoryColors = [
  AZColors.red,
  AZColors.blue,
  AZColors.green,
  AZColors.orange,
];

class ColorMemoryGameScreen extends StatelessWidget {
  const ColorMemoryGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'colormemory',
        gradient: AZColors.gradPink,
        title: 'Renk Hafızası',
        emoji: '🎨',
        formatScore: (s) => '$s tur',
        sessionBuilder: (context, player, onFinished) =>
            _ColorMemorySession(player: player, onFinished: onFinished),
      );
}

class _ColorMemorySession extends StatefulWidget {
  const _ColorMemorySession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_ColorMemorySession> createState() => _ColorMemorySessionState();
}

class _ColorMemorySessionState extends State<_ColorMemorySession> {
  final _rng = Random();
  final List<int> _sequence = [];
  int _step = 0;
  int? _highlighted;
  bool _showingSequence = false;
  bool _accepting = false;
  bool _wrong = false;
  bool _started = false;

  void _start() {
    setState(() => _started = true);
    _addToSequence();
  }

  void _addToSequence() {
    _sequence.add(_rng.nextInt(_kMemoryColors.length));
    _step = 0;
    _playSequence();
  }

  Future<void> _playSequence() async {
    setState(() {
      _showingSequence = true;
      _accepting = false;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    for (final c in _sequence) {
      if (!mounted) return;
      setState(() => _highlighted = c);
      await Future.delayed(const Duration(milliseconds: 430));
      if (!mounted) return;
      setState(() => _highlighted = null);
      await Future.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted) return;
    setState(() {
      _showingSequence = false;
      _accepting = true;
    });
  }

  void _tapColor(int c) {
    if (!_accepting) return;
    if (c == _sequence[_step]) {
      setState(() => _highlighted = c);
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => _highlighted = null);
      });
      _step++;
      if (_step == _sequence.length) {
        _accepting = false;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _addToSequence();
        });
      }
    } else {
      _accepting = false;
      setState(() => _wrong = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onFinished(_sequence.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎨', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('${widget.player.name}, hazır mısın?',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AZButton(label: 'BAŞLA', icon: Icons.play_arrow_rounded, color: AZColors.purple, onPressed: _start),
        ]),
      );
    }
    return Column(children: [
      AZFrostCard(
        child: Text(
          _wrong ? 'Yanlış! Ulaştığın tur: ${_sequence.length - 1}' : '${widget.player.name} · Tur: ${_sequence.length}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _showingSequence
            ? 'İzle...'
            : (_accepting ? 'Sıra sende, sırayla dokun' : ' '),
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _buildSequenceMeter(),
      const SizedBox(height: 12),
      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [
            for (var i = 0; i < _kMemoryColors.length; i++) _buildColorPad(i),
          ],
        ),
      ),
    ]);
  }

  Widget _buildSequenceMeter() {
    final activeSteps = _accepting ? _step : 0;
    return Column(
      children: [
        Text(
          _showingSequence ? 'Dizi' : 'İlerlemen',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _sequence.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: i < activeSteps ? 12 : 9,
                  height: i < activeSteps ? 12 : 9,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: i < activeSteps
                        ? const RadialGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFFFD976), Color(0xFFDF8D4A)],
                          )
                        : const RadialGradient(
                            colors: [Color(0xFF786F91), Color(0xFF38334B)],
                          ),
                    border: Border.all(color: Colors.white.withAlpha(i < activeSteps ? 210 : 70)),
                    boxShadow: [
                      BoxShadow(
                        color: i < activeSteps ? const Color(0xFFFFD976).withAlpha(110) : Colors.black38,
                        blurRadius: i < activeSteps ? 8 : 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorPad(int index) {
    final base = _kMemoryColors[index];
    final lit = _highlighted == index;
    return GestureDetector(
      onTap: () => _tapColor(index),
      child: AnimatedScale(
        scale: lit ? .965 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AZRadius.lg),
            color: Color.lerp(base, Colors.black, .48),
            boxShadow: [
              BoxShadow(
                color: lit ? base.withAlpha(210) : Colors.black.withAlpha(90),
                blurRadius: lit ? 26 : 12,
                offset: Offset(0, lit ? 2 : 8),
              ),
              if (!lit)
                BoxShadow(color: base.withAlpha(95), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.only(bottom: 5, right: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AZRadius.lg),
              border: Border.all(color: lit ? Colors.white : Colors.white.withAlpha(125), width: 2),
              gradient: RadialGradient(
                center: const Alignment(-.45, -.55),
                radius: 1.25,
                colors: lit
                    ? [Colors.white, Color.lerp(base, Colors.white, .75)!, base]
                    : [Color.lerp(base, Colors.white, .48)!, base, Color.lerp(base, Colors.black, .35)!],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AZRadius.lg - 2),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withAlpha(lit ? 210 : 95), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(-.55, -.6),
                    child: Container(
                      width: 22,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(lit ? 150 : 60),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
