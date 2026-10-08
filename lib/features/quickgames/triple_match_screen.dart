import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

List<String> clearTriples(List<String> tray) {
  final next = List<String>.of(tray);
  var changed = true;
  while (changed) {
    changed = false;
    final counts = <String, int>{};
    for (final tile in next) {
      counts[tile] = (counts[tile] ?? 0) + 1;
    }
    String? hit;
    for (final entry in counts.entries) {
      if (entry.value >= 3) {
        hit = entry.key;
        break;
      }
    }
    if (hit != null) {
      var removed = 0;
      next.removeWhere((tile) {
        if (tile == hit && removed < 3) {
          removed++;
          return true;
        }
        return false;
      });
      changed = true;
    }
  }
  return next;
}

class TripleMatchLobbyScreen extends StatelessWidget {
  const TripleMatchLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Üçlü Eşle',
        emoji: '🍒',
        gradient: AZColors.gradPink,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Taşa dokun, tepsiye gelsin. Aynı üç taş silinir. '
            'Tepsi yedi taşı aşarsa tur biter.',
      );
}

class TripleMatchGameScreen extends StatelessWidget {
  const TripleMatchGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'triplematch',
        gradient: AZColors.gradPink,
        title: 'Üçlü Eşle',
        emoji: '🍒',
        formatScore: (score) => '$score taş',
        sessionBuilder: (context, player, onFinished) =>
            _TripleSession(player: player, onFinished: onFinished),
      );
}

class _TripleSession extends StatefulWidget {
  const _TripleSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_TripleSession> createState() => _TripleSessionState();
}

class _TripleSessionState extends State<_TripleSession> {
  static const _kinds = ['🍎', '🍋', '🍇', '🍒', '🍊', '🥝'];
  late final List<String> _board = [
    for (final kind in _kinds) ...[kind, kind, kind],
  ]..shuffle(Random());
  List<String> _tray = [];
  bool _over = false;

  int get _cleared => 18 - _board.length - _tray.length;

  void _take(int index) {
    if (_over || _tray.length >= 7) {
      return;
    }
    final tile = _board.removeAt(index);
    _tray = clearTriples([..._tray, tile]);
    if (_board.isEmpty || _tray.length >= 7) {
      _over = true;
      widget.onFinished(_cleared);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  Tepsi ${_tray.length}/7  $_cleared taş',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final tile in _tray)
                Container(
                  width: 48,
                  margin: const EdgeInsets.only(right: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AZRadius.sm),
                  ),
                  child: Text(tile, style: const TextStyle(fontSize: 24)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _board.length,
            itemBuilder: (context, index) => Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AZRadius.sm),
              child: InkWell(
                onTap: () => _take(index),
                child: Center(child: Text(_board[index], style: const TextStyle(fontSize: 22))),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
