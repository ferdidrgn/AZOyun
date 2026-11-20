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

  Widget _tile(int index) {
    final isFound = found?.contains(index) ?? false;
    return Material(
      color: Colors.transparent,
      elevation: isFound ? 5 : 2,
      shadowColor: isFound ? const Color(0xAA39E58B) : const Color(0x77031020),
      borderRadius: BorderRadius.circular(AZRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(index),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isFound
                  ? const [Color(0xFFB8F7CE), Color(0xFF45C98A)]
                  : const [Colors.white, Color(0xFFE1EAF2)],
            ),
            borderRadius: BorderRadius.circular(AZRadius.sm),
            border: Border.all(
              color: isFound ? const Color(0xFFB7FFE0) : const Color(0xFFBDD0DF),
              width: isFound ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99FFFFFF),
                offset: Offset(-1, -1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(child: Text(faces[index], style: const TextStyle(fontSize: 20))),
              if (isFound)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.check_circle,
                    size: 13,
                    color: Color(0xFF087F50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFindBoard = onTap != null;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFindBoard
              ? const [Color(0xFF426987), Color(0xFF18364E)]
              : const [Color(0xFF54766E), Color(0xFF233F42)],
        ),
        borderRadius: BorderRadius.circular(AZRadius.md),
        border: Border.all(color: const Color(0xBFFFFFFF), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x70030D18),
            offset: Offset(0, 8),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0x33FFFFFF),
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Container(
              height: 28,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFindBoard
                      ? const [Color(0xFF71B7D5), Color(0xFF397C9D)]
                      : const [Color(0xFF83AE92), Color(0xFF527D69)],
                ),
                borderRadius: BorderRadius.circular(AZRadius.sm),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFindBoard ? Icons.touch_app_rounded : Icons.visibility_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFindBoard ? 'FARKLARI BUL' : 'ÖRNEK PANOSU',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(2),
                crossAxisCount: 4,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                children: [for (var i = 0; i < faces.length; i++) _tile(i)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
