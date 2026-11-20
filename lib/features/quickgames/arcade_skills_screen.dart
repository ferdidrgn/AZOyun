import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';

enum ArcadeSkill {
  aim('Hedef Atışı', '🎯', 'trivia', AZColors.gradCyan,
      'Hareketli hedefe dokun. Merkeze ne kadar yakınsan o kadar çok puan alırsın. 20 saniyede 10 atışın var.'),
  balance('Denge Hattı', '🟢', 'elitequiz', AZColors.gradOrange,
      'Parmağını kaydırıp topu hareketli şeritte tut. Şeritte kaldığın süre puan kazandırır.');

  const ArcadeSkill(
      this.title, this.emoji, this.gameId, this.gradient, this.instructions);
  final String title, emoji, gameId, instructions;
  final Gradient gradient;

  Widget lobby() => QuickPlaySetup(
      gameTitle: title,
      emoji: emoji,
      gradient: gradient,
      minPlayers: 1,
      maxPlayers: 6,
      instructions: instructions);

  Widget game(List<QPPlayer> players) => TurnBasedChase(
      title: title,
      emoji: emoji,
      gameId: gameId,
      gradient: gradient,
      players: players,
      sessionBuilder: (_, player, finish) =>
          _ArcadeSkillRound(skill: this, onFinish: finish));
}

class _ArcadeSkillRound extends StatefulWidget {
  const _ArcadeSkillRound({required this.skill, required this.onFinish});
  final ArcadeSkill skill;
  final ValueChanged<int> onFinish;

  @override
  State<_ArcadeSkillRound> createState() => _ArcadeSkillRoundState();
}

class _ArcadeSkillRoundState extends State<_ArcadeSkillRound>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;
  double _guided = .5;
  double _ball = .5;
  double _inside = 0;
  int _shots = 0;
  int _score = 0;
  bool _done = false;
  static const _seconds = 20;

  bool get _aim => widget.skill == ArcadeSkill.aim;
  double get _lane => .5 + .31 * math.sin(_time * 1.7) * math.cos(_time * .36);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final next = elapsed.inMicroseconds / 1000000;
      final frame = (next - _time).clamp(0.0, .05);
      setState(() {
        _time = next;
        if (!_aim) {
          _ball += (_guided - _ball) * math.min(1, frame * 9);
          if ((_ball - _lane).abs() <= .10) _inside += frame;
          _score = (60 * _inside / _seconds).round().clamp(0, 60);
        }
      });
      if (_time >= _seconds) _finish();
    })
      ..start();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _ticker.stop();
    widget.onFinish(_score);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Offset _target(Size size) => Offset(
      size.width * (.5 + .32 * math.sin(_time * 2.5 + _shots * 2.2)),
      size.height * (.5 + .28 * math.cos(_time * 2.1 + _shots * 1.8)));

  void _shoot(Offset at, Offset target) {
    if (_done) return;
    final radius = (at - target).distance;
    setState(() {
      _shots++;
      _score += radius <= 12
          ? 10
          : radius <= 24
              ? 7
              : radius <= 34
                  ? 4
                  : 0;
    });
    if (_shots >= 10) _finish();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            '$_score puan · ${math.max(0, (_seconds - _time).ceil())} sn'
            '${_aim ? ' · ${10 - _shots} atış' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 17)),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(builder: (context, bounds) {
            final size = bounds.biggest;
            final target = _target(size);
            void guide(Offset point) =>
                _guided = (point.dx / size.width).clamp(0.0, 1.0);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _aim
                  ? _shoot(details.localPosition, target)
                  : guide(details.localPosition),
              onHorizontalDragStart:
                  _aim ? null : (details) => guide(details.localPosition),
              onHorizontalDragUpdate:
                  _aim ? null : (details) => guide(details.localPosition),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(fit: StackFit.expand, children: [
                  const ColoredBox(color: Color(0xff142b32)),
                  if (_aim)
                    for (final (diameter, color) in [
                      (68.0, scheme.primary),
                      (48.0, Colors.white),
                      (24.0, const Color(0xffb54f35))
                    ])
                      Positioned(
                          left: target.dx - diameter / 2,
                          top: target.dy - diameter / 2,
                          width: diameter,
                          height: diameter,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: color))),
                  if (!_aim) ...[
                    Positioned(
                        top: 0,
                        bottom: 0,
                        left: (_lane - .10) * size.width,
                        width: size.width * .20,
                        child: const ColoredBox(color: Color(0xff457d55))),
                    Positioned(
                        left: (_ball * size.width - 15)
                            .clamp(0.0, math.max(0.0, size.width - 30)),
                        top: size.height * .62,
                        width: 30,
                        height: 30,
                        child: const DecoratedBox(
                            decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffffd47e),
                        ))),
                  ],
                ]),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(widget.skill.instructions,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
