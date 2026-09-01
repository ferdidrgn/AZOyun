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
      const SizedBox(height: 20),
      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [
            for (var i = 0; i < _kMemoryColors.length; i++)
              GestureDetector(
                onTap: () => _tapColor(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: _highlighted == i ? Colors.white : _kMemoryColors[i],
                    borderRadius: BorderRadius.circular(AZRadius.lg),
                    border: Border.all(
                        color: _highlighted == i ? _kMemoryColors[i] : Colors.white24, width: 3),
                  ),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}
