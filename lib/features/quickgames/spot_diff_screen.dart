import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class SpotDiffLobbyScreen extends StatelessWidget {
  const SpotDiffLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Farkı Bul',
        emoji: '🔍',
        gradient: AZColors.gradBlue,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Sağ karede soldan farklı üç hücreyi bul. Dört pano.',
      );
}

class SpotDiffGameScreen extends StatelessWidget {
  const SpotDiffGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'spotdiff',
        gradient: AZColors.gradBlue,
        title: 'Farkı Bul',
        emoji: '🔍',
        formatScore: (score) => '$score fark',
        sessionBuilder: (context, player, onFinished) =>
            _SpotSession(player: player, onFinished: onFinished),
      );
}

class _SpotSession extends StatefulWidget {
  const _SpotSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_SpotSession> createState() => _SpotSessionState();
}

class _SpotSessionState extends State<_SpotSession> {
  static const _faces = ['🌟', '🌙', '☁️', '🔥', '💧', '🍀'];
  final _rng = Random();
  late List<String> _left;
  late List<String> _right;
  late Set<int> _diff;
  final _found = <int>{};
  int _board = 1;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    _left = List.generate(16, (_) => _faces[_rng.nextInt(_faces.length)]);
    _right = List.of(_left);
    final picks = <int>{};
    while (picks.length < 3) {
      picks.add(_rng.nextInt(16));
    }
    _diff = picks;
    for (final index in _diff) {
      var next = _faces[_rng.nextInt(_faces.length)];
      while (next == _left[index]) {
        next = _faces[_rng.nextInt(_faces.length)];
      }
      _right[index] = next;
    }
    _found.clear();
  }

  void _tap(int index) {
    if (!_diff.contains(index) || _found.contains(index)) {
      return;
    }
    _found.add(index);
    _score++;
    if (_found.length == 3) {
      if (_board == 4) {
        widget.onFinished(_score);
        return;
      }
      setState(() {
        _board++;
        _deal();
      });
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Pano $_board/4  $_score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _Grid(faces: _left)),
              const SizedBox(width: AZSpacing.sm),
              Expanded(child: _Grid(faces: _right, found: _found, onTap: _tap)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.faces, this.found, this.onTap});

  final List<String> faces;
  final Set<int>? found;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (var i = 0; i < faces.length; i++)
          Material(
            color: found != null && found!.contains(i) ? AZColors.green : Colors.white,
            borderRadius: BorderRadius.circular(AZRadius.sm),
            child: InkWell(
              onTap: onTap == null ? null : () => onTap!(i),
              child: Center(child: Text(faces[i], style: const TextStyle(fontSize: 20))),
            ),
          ),
      ],
    );
  }
}
