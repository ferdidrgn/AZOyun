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
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AZRadius.lg),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE3D7), Color(0xFFE6AFA0), Color(0xFFB86F70)],
                    stops: [0, .54, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF471D37).withOpacity(.22),
                      blurRadius: 9,
                      offset: const Offset(0, 5),
                    ),
                    const BoxShadow(
                      color: Color(0x55FFFFFF),
                      blurRadius: 3,
                      offset: Offset(-2, -2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AZRadius.lg),
                  onTap: onTap == null ? null : () => onTap!(i),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 5,
                        child: Container(
                          width: 27,
                          height: 9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF9D5E62).withOpacity(.26),
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 49,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(17),
                            bottom: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: const Alignment(-.8, -.9),
                            end: const Alignment(.8, .9),
                            colors: [
                              Color.lerp(colors[i], Colors.white, .42)!,
                              colors[i],
                              Color.lerp(colors[i], Colors.black, .28)!,
                            ],
                            stops: const [0, .42, 1],
                          ),
                          border: Border.all(
                            color: Color.lerp(colors[i], Colors.white, .6)!,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.lerp(colors[i], Colors.black, .48)!
                                  .withOpacity(.38),
                              blurRadius: 5,
                              offset: const Offset(1.5, 3),
                            ),
                            const BoxShadow(
                              color: Color(0x88FFFFFF),
                              blurRadius: 3,
                              offset: Offset(-1.5, -1.5),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: const Alignment(-.48, -.52),
                          child: Container(
                            width: 4,
                            height: 23,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(.72),
                                  Colors.white.withOpacity(.04),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
