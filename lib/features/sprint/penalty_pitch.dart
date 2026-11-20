import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'penalty_rules.dart';

class PenaltyPitch extends StatefulWidget {
  const PenaltyPitch({
    super.key,
    required this.striker,
    required this.onKick,
    this.locked = false,
  });

  final bool striker;
  final bool locked;
  final ValueChanged<int> onKick;

  @override
  State<PenaltyPitch> createState() => _PenaltyPitchState();
}

class _PenaltyPitchState extends State<PenaltyPitch> {
  int _target = 2;
  int _power = 65;
  int _curve = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.striker
              ? 'Şut sende. Kalede bir hedef seç.'
              : 'Kalecisin. Atlayacağın bölgeyi seç.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(builder: (context, bounds) {
              final goal = _goal(bounds.biggest);
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: const _PitchPainter()),
                  for (final (index, point) in penaltyTargets.indexed)
                    Positioned(
                      left: goal.left + point.x * goal.width - 24,
                      top: goal.top + point.y * goal.height - 24,
                      child: IconButton(
                        tooltip: penaltyZones[index],
                        isSelected: _target == index,
                        style: IconButton.styleFrom(
                          foregroundColor: _target == index
                              ? scheme.onPrimaryContainer
                              : Colors.white,
                          backgroundColor: _target == index
                              ? scheme.primaryContainer
                              : Colors.black54,
                        ),
                        onPressed: widget.locked
                            ? null
                            : () => setState(() => _target = index),
                        icon: const Icon(Icons.add_rounded),
                        selectedIcon: const Icon(Icons.gps_fixed_rounded),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.striker) ...[
          Text('Güç %$_power'),
          Slider(
            value: _power.toDouble(),
            max: 100,
            divisions: 20,
            label: '%$_power',
            onChanged: widget.locked
                ? null
                : (value) => setState(() => _power = value.round()),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final (curve, label) in const [
                (-1, 'Sola falso'),
                (0, 'Düz şut'),
                (1, 'Sağa falso')
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _curve == curve,
                  onSelected: widget.locked
                      ? null
                      : (_) => setState(() => _curve = curve),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: widget.locked
              ? null
              : () => widget.onKick(
                    widget.striker
                        ? encodePenaltyKick(_target, _power, _curve)
                        : _target,
                  ),
          icon: Icon(
              widget.striker ? Icons.sports_soccer : Icons.sports_handball),
          label: Text(widget.striker ? 'Şut çek' : 'Atlayışı kilitle'),
        ),
      ],
    );
  }
}

class PenaltyReplay extends StatelessWidget {
  const PenaltyReplay({super.key, required this.kick, required this.dive});
  final int? kick;
  final int dive;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (_, progress, __) => CustomPaint(
              painter: _PitchPainter(
                  flight: penaltyFlight(kick, dive), progress: progress),
            ),
          ),
        ),
      );
}

Rect _goal(Size size) => Rect.fromLTWH(
    size.width * .13, size.height * .12, size.width * .74, size.height * .58);

class _PitchPainter extends CustomPainter {
  const _PitchPainter({this.flight, this.progress = 0});
  final PenaltyFlight? flight;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final goal = _goal(size);
    final paint = Paint();
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xff124c3c));
    for (var stripe = 0; stripe < 8; stripe += 2) {
      canvas.drawRect(
          Rect.fromLTWH(
              stripe * size.width / 8, 0, size.width / 8, size.height),
          paint..color = const Color(0xff176044));
    }
    canvas.drawRect(goal, paint..color = const Color(0xff182d26));
    for (var line = 1; line < 12; line++) {
      final x = goal.left + line * goal.width / 12;
      final y = goal.top + line * goal.height / 12;
      canvas.drawLine(Offset(x, goal.top), Offset(x, goal.bottom),
          paint..color = Colors.white24);
      canvas.drawLine(Offset(goal.left, y), Offset(goal.right, y), paint);
    }
    canvas.drawRect(
        goal,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final kickSpot = Offset(size.width * .5, size.height * .88);
    final keeper = penaltyTargets[flight?.dive ?? 2];
    final keeperPosition = Offset.lerp(
        goal.center,
        Offset(goal.left + keeper.x * goal.width,
            goal.top + keeper.y * goal.height),
        progress)!;
    canvas.drawOval(
        Rect.fromCenter(center: keeperPosition, width: 32, height: 17),
        paint..color = const Color(0xffffc15b));
    final shot = flight;
    final ball = shot == null || shot.result == 'timeout'
        ? kickSpot
        : Offset.lerp(
                kickSpot,
                Offset(goal.left + shot.x * goal.width,
                    goal.top + shot.y * goal.height),
                progress)! +
            Offset(
                -shot.curve * math.sin(progress * math.pi) * size.width * .16,
                0);
    canvas.drawCircle(ball, 8 - progress * 3, paint..color = Colors.white);
    canvas.drawCircle(
        ball, 2 - progress, paint..color = const Color(0xff1c2621));
  }

  @override
  bool shouldRepaint(_PitchPainter oldDelegate) =>
      flight != oldDelegate.flight || progress != oldDelegate.progress;
}
