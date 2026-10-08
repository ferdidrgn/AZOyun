import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class NailSalonLobbyScreen extends StatelessWidget {
  const NailSalonLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Oje Atölyesi',
        emoji: '💅',
        gradient: AZColors.gradPink,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Üstteki örneğe bak. Her tırnağa dokunarak rengi değiştir, sonra onayla.',
      );
}

class NailSalonGameScreen extends StatelessWidget {
  const NailSalonGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'nailsalon',
        gradient: AZColors.gradPink,
        title: 'Oje Atölyesi',
        emoji: '💅',
        formatScore: (score) => '$score tırnak',
        sessionBuilder: (context, player, onFinished) =>
            _NailSession(player: player, onFinished: onFinished),
      );
}

class _NailSession extends StatefulWidget {
  const _NailSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_NailSession> createState() => _NailSessionState();
}

class _NailSessionState extends State<_NailSession> {
  static const _colors = [AZColors.red, AZColors.orange, AZColors.blue, AZColors.purple, AZColors.green];
  final _rng = Random();
  late List<int> _target = _fresh();
  List<int> _paint = List.filled(5, 0);
  int _round = 1;
  int _score = 0;

  List<int> _fresh() => List.generate(5, (_) => _rng.nextInt(_colors.length));

  void _cycle(int index) {
    setState(() => _paint[index] = (_paint[index] + 1) % _colors.length);
  }

  void _confirm() {
    for (var i = 0; i < 5; i++) {
      if (_paint[i] == _target[i]) {
        _score++;
      }
    }
    if (_round == 4) {
      widget.onFinished(_score);
      return;
    }
    setState(() {
      _round++;
      _target = _fresh();
      _paint = List.filled(5, 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Örnek $_round/4  $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.lg),
        const Text('Örnek', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: AZSpacing.sm),
        _NailRow(colors: [for (final index in _target) _colors[index]]),
        const SizedBox(height: AZSpacing.lg),
        const Text('Senin tırnakların', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: AZSpacing.sm),
        _NailRow(
          colors: [for (final index in _paint) _colors[index]],
          onTap: _cycle,
        ),
        const Spacer(),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8E4E62),
            ),
            child: const Text('Onayla'),
          ),
        ),
      ],
    );
  }
}

class _NailRow extends StatelessWidget {
  const _NailRow({required this.colors, this.onTap});

  final List<Color> colors;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < colors.length; i++)
          SizedBox(
            width: 52,
            height: 72,
            child: Material(
              color: colors[i],
              borderRadius: BorderRadius.circular(AZRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AZRadius.lg),
                onTap: onTap == null ? null : () => onTap!(i),
              ),
            ),
          ),
      ],
    );
  }
}
