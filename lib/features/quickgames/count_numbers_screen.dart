import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class CountNumbersLobbyScreen extends StatelessWidget {
  const CountNumbersLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Sayı Say',
        emoji: '1️⃣',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions: 'Yıldızları say ve doğru sayıyı seç. Sekiz tur.',
      );
}

class _NumberChoice extends StatelessWidget {
  const _NumberChoice({required this.value, required this.onPressed});

  final int value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF81E6E6), Color(0xFF32B7CB), Color(0xFF187A9C)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB8FFFF), width: 1.4),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 9, offset: Offset(0, 6)),
            BoxShadow(color: Color(0x668DF4F2), blurRadius: 10, offset: Offset(-2, -2)),
          ],
        ),
        child: Tooltip(
          message: 'Seçenek $value',
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              overlayColor: Colors.white.withOpacity(.16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 28,
                height: 1,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0x990B425A), blurRadius: 4, offset: Offset(0, 3)),
                  Shadow(color: Color(0x99FFFFFF), blurRadius: 2, offset: Offset(-1, -1)),
                ],
              ),
            ),
          ),
        ),
      );
}

class CountNumbersGameScreen extends StatelessWidget {
  const CountNumbersGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'count123',
        gradient: AZColors.gradCyan,
        title: 'Sayı Say',
        emoji: '1️⃣',
        sessionBuilder: (context, player, onFinished) =>
            _CountSession(player: player, onFinished: onFinished),
      );
}

class _CountSession extends StatefulWidget {
  const _CountSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_CountSession> createState() => _CountSessionState();
}

class _Round {
  _Round(this.count, this.options);
  final int count;
  final List<int> options;
}

class _CountSessionState extends State<_CountSession> {
  final _rng = Random();
  late final List<_Round> _rounds = List.generate(8, (_) => _make());
  int _index = 0;
  int _score = 0;

  _Round _make() {
    final count = _rng.nextInt(8) + 1;
    final options = <int>{count};
    while (options.length < 4) {
      final next = _rng.nextInt(9) + 1;
      options.add(next);
    }
    return _Round(count, options.toList()..shuffle(_rng));
  }

  void _pick(int value) {
    if (value == _rounds[_index].count) {
      _score += 10;
    }
    if (_index == _rounds.length - 1) {
      widget.onFinished(_score);
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  ${_index + 1}/8  $_score puan',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        Semantics(
          container: true,
          label: 'Sayılacak yıldız sayısı: ${round.count}',
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minHeight: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF287E91), Color(0xFF14566D), Color(0xFF103C54)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x778EEBEE), width: 1.3),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 9)),
                  BoxShadow(color: Color(0x448DF8F2), blurRadius: 15, offset: Offset(-4, -4)),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < round.count; i++)
                    Transform.rotate(
                      angle: sin(i * 2.1) * .06,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            center: Alignment(-.35, -.45),
                            colors: [Color(0xFFFFFFD0), Color(0xFFFFD45E), Color(0xFFD98731)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFF1B4), width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 4)),
                            BoxShadow(color: Color(0x66FFF0A0), blurRadius: 5, offset: Offset(-2, -2)),
                          ],
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 26,
                          color: Color(0xFFAC6B28),
                          shadows: [Shadow(color: Color(0xAAFFF1B5), blurRadius: 3, offset: Offset(-1, -1))],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        const Text(
          'Yıldızları say ve sayıyı seç',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: AZSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - AZSpacing.sm) / 2;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: AZSpacing.sm,
              runSpacing: AZSpacing.sm,
              children: [
                for (final option in round.options)
                  SizedBox(
                    width: tileWidth,
                    height: 72,
                    child: _NumberChoice(value: option, onPressed: () => _pick(option)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
