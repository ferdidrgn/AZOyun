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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff1d4148),
                          Color(0xff142b32),
                          Color(0xff0c1b24),
                        ],
                      ),
                    ),
                  ),
                  if (_aim)
                    Positioned(
                      left: target.dx - 34,
                      top: target.dy - 34,
                      width: 68,
                      height: 68,
                      child: _AimTarget(primary: scheme.primary),
                    ),
                  if (!_aim) ...[
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: (_lane - .10) * size.width,
                      width: size.width * .20,
                      child: const _BalanceLane(),
                    ),
                    Positioned(
                        left: (_ball * size.width - 15)
                            .clamp(0.0, math.max(0.0, size.width - 30)),
                        top: size.height * .62,
                        width: 30,
                        height: 30,
                        child: const _BalanceBall()),
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

class _AimTarget extends StatelessWidget {
  const _AimTarget({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.35, -.4),
            colors: [primary.withOpacity(.9), primary, primary.withOpacity(.55)],
          ),
          border: Border.all(color: Colors.white.withOpacity(.88), width: 2),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(.62),
              blurRadius: 22,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Color(0xBB000000),
              blurRadius: 12,
              offset: Offset(0, 7),
            ),
            const BoxShadow(
              color: Color(0x77FFFFFF),
              blurRadius: 5,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-.35, -.4),
                colors: [Color(0xFFFFFFFF), Color(0xFFE2E8E7), Color(0xFF9DAEAF)],
              ),
              border: Border.all(color: const Color(0xFFD1E0DF), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-.3, -.4),
                    colors: [Color(0xFFFF9978), Color(0xFFC84F38), Color(0xFF7C2C25)],
                  ),
                  border: Border.all(color: const Color(0xFFFFC2A9), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAA35110E),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _BalanceLane extends StatelessWidget {
  const _BalanceLane();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xAA275337), Color(0xE65DAD68), Color(0xAA275337)],
          ),
          border: Border.symmetric(
            vertical: BorderSide(color: const Color(0xCCB5F4AE), width: 2),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x665EEA87),
              blurRadius: 18,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(.16),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
}

class _BalanceBall extends StatelessWidget {
  const _BalanceBall();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-.4, -.5),
            colors: [Color(0xFFFFF2C4), Color(0xFFFFD47E), Color(0xFFDB862F)],
          ),
          border: Border.all(color: const Color(0xFFFFE6AA), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0xBB000000),
              blurRadius: 9,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x88FFE4A5),
              blurRadius: 8,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Align(
          alignment: const Alignment(-.35, -.45),
          child: FractionallySizedBox(
            widthFactor: .25,
            heightFactor: .25,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.8),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 1),
                ],
              ),
            ),
          ),
        ),
      );
}
