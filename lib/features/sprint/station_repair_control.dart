import 'package:flutter/material.dart';

class StationRepairControl extends StatefulWidget {
  const StationRepairControl({
    super.key,
    required this.target,
    required this.onLock,
    required this.busy,
  });

  final double target;
  final ValueChanged<bool> onLock;
  final bool busy;

  @override
  State<StationRepairControl> createState() => _StationRepairControlState();
}

class _StationRepairControlState extends State<StationRepairControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('İbre yeşil alana girdiğinde devreyi kilitle.'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (_, bounds) {
          final width = bounds.maxWidth;
          return SizedBox(
            height: 44,
            child: Stack(children: [
              Positioned.fill(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ))),
              Positioned(
                  left: width * (widget.target - .11),
                  width: width * .22,
                  top: 6,
                  bottom: 6,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                    color: const Color(0xff327556),
                    borderRadius: BorderRadius.circular(6),
                  ))),
              AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Positioned(
                        left: (width - 8) * _pulse.value,
                        width: 8,
                        top: 3,
                        bottom: 3,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: scheme.onPrimary, width: 1.5),
                        )),
                      )),
            ]),
          );
        }),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.busy
              ? null
              : () =>
                  widget.onLock((_pulse.value - widget.target).abs() <= .11),
          icon: const Icon(Icons.electric_bolt_rounded),
          label: const Text('Devreyi kilitle'),
        ),
      ],
    );
  }
}
