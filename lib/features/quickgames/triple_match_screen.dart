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
  int _matchSerial = 0;

  int get _cleared => 18 - _board.length - _tray.length;

  void _take(int index) {
    if (_over || _tray.length >= 7) {
      return;
    }
    final tile = _board.removeAt(index);
    final nextTray = clearTriples([..._tray, tile]);
    if (nextTray.length < _tray.length + 1) {
      _matchSerial++;
    }
    _tray = nextTray;
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
        TweenAnimationBuilder<double>(
          key: ValueKey(_matchSerial),
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(milliseconds: 650),
          builder: (context, pulse, child) {
            final glow = _matchSerial == 0 ? 0.0 : pulse * pulse;
            return Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AZRadius.md),
                border: Border.all(
                  color: const Color(0xFFFFD76A).withOpacity(0.75 * glow),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC83D).withOpacity(0.42 * glow),
                    blurRadius: 18 * glow,
                    spreadRadius: 2 * glow,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: child!),
                  if (glow > 0.02)
                    Positioned(
                      right: 7,
                      top: 5,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: glow.clamp(0.0, 1.0).toDouble(),
                          child: Transform.scale(
                            scale: .88 + .12 * glow,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFF0A8), Color(0xFFFFC43D), Color(0xFFDB8124)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 1),
                                boxShadow: const [
                                  BoxShadow(color: Color(0xAAFFB72D), blurRadius: 10, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Text(
                                'TRIPLE!',
                                style: TextStyle(
                                  color: Color(0xFF60340C),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .7,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final tile in _tray)
                Container(
                  width: 48,
                  margin: const EdgeInsets.only(right: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFEF7), Color(0xFFE8E1D2)],
                    ),
                    borderRadius: BorderRadius.circular(AZRadius.sm),
                    border: Border.all(color: const Color(0xFFB6AA94)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x660D1730),
                        offset: Offset(0, 3),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: Color(0xCCFFFFFF),
                        offset: Offset(-1, -1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(tile, style: const TextStyle(fontSize: 24)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AZSpacing.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(-.5, -.65),
                radius: 1.35,
                colors: [Color(0xFF394B71), Color(0xFF222D4B), Color(0xFF141B32)],
              ),
              borderRadius: BorderRadius.circular(AZRadius.lg),
              border: Border.all(color: Colors.white.withOpacity(.24), width: 1.4),
              boxShadow: const [
                BoxShadow(color: Color(0x99071020), blurRadius: 18, offset: Offset(0, 9)),
                BoxShadow(color: Color(0x334A8BDA), blurRadius: 12, offset: Offset(0, 1)),
              ],
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(3),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
              ),
              itemCount: _board.length,
              itemBuilder: (context, index) => Material(
                color: const Color(0xFFD7CBB5),
                elevation: 4.5 + (index % 3).toDouble(),
                shadowColor: const Color(0xCC071020),
                borderRadius: BorderRadius.circular(AZRadius.sm + 2.0),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFF4F0E6), Color(0xFFD7CBB5)],
                    ),
                    borderRadius: BorderRadius.circular(AZRadius.sm + 2.0),
                    border: Border.all(color: const Color(0xFFFFFEF5), width: 1.4),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AZRadius.sm + 2.0),
                    onTap: () => _take(index),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 2,
                          right: 2,
                          top: 2,
                          height: 7,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(.85), Colors.white.withOpacity(0)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 5,
                          right: 5,
                          bottom: 2,
                          height: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF9E9079),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            _board[index],
                            style: const TextStyle(
                              fontSize: 24,
                              shadows: [Shadow(color: Color(0x550D1730), blurRadius: 4, offset: Offset(0, 2))],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
