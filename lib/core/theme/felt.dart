import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Keçe masa kimliği. Açık temada fildişi sayfa, koyu temada keçe.
/// Kart masasının kendisi her iki temada yeşil kalır.
abstract class FeltColors {
  static const ink = Color(0xFF141C16);
  static const felt = Color(0xFF1B4332);
  static const feltDeep = Color(0xFF101610);
  static const feltLift = Color(0xFF24382C);
  static const ivory = Color(0xFFF3EFE6);
  static const brass = Color(0xFFD7B56D);
  static const clay = Color(0xFFC4563A);
  static const mist = Color(0xFF8FA396);
  static const cardFace = Color(0xFFFFFBF5);
  static const clayPage = Color(0xFFF6E4D8);
  static const clayPageDeep = Color(0xFFE7CDB8);
  static const brassPage = Color(0xFFF8F1DE);
  static const brassPageDeep = Color(0xFFE7D7A8);
}

TextStyle feltDisplay(Color color, double size) => GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.05,
    );

TextStyle feltUi(
  Color color,
  double size, {
  FontWeight weight = FontWeight.w500,
  double height = 1.35,
}) =>
    GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

class FeltPalette {
  const FeltPalette._({
    required this.dark,
    required this.canvasTop,
    required this.canvasBottom,
    required this.ink,
    required this.muted,
    required this.surface,
    required this.line,
  });

  factory FeltPalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const FeltPalette._(
        dark: true,
        canvasTop: FeltColors.felt,
        canvasBottom: FeltColors.feltDeep,
        ink: FeltColors.ivory,
        muted: FeltColors.mist,
        surface: FeltColors.feltLift,
        line: Color(0x33F3EFE6),
      );
    }
    return const FeltPalette._(
      dark: false,
      canvasTop: FeltColors.ivory,
      canvasBottom: Color(0xFFE7E0D2),
      ink: FeltColors.ink,
      muted: Color(0xFF5E6B62),
      surface: Colors.white,
      line: Color(0x1F141C16),
    );
  }

  final bool dark;
  final Color canvasTop;
  final Color canvasBottom;
  final Color ink;
  final Color muted;
  final Color surface;
  final Color line;
}

/// Sayfa zemini. [showMark] yalnızca imza halkanın bu ekranda duracağı yerde true.
class FeltBackdrop extends StatelessWidget {
  const FeltBackdrop({super.key, required this.child, this.canvasTop, this.canvasBottom});

  final Widget child;
  final Color? canvasTop;
  final Color? canvasBottom;

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [canvasTop ?? palette.canvasTop, canvasBottom ?? palette.canvasBottom],
        ),
      ),
      child: child,
    );
  }
}

/// Tek imza: keçe halkası. Azaltılmış harekette çizim anında tamamlanır.
class FeltMark extends StatefulWidget {
  const FeltMark({super.key, this.size = 168});

  final double size;

  @override
  State<FeltMark> createState() => _FeltMarkState();
}

class _FeltMarkState extends State<FeltMark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.value = 1;
      return;
    }
    if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _FeltMarkPainter(progress: _controller.value),
          ),
        ),
      );
}

class _FeltMarkPainter extends CustomPainter {
  const _FeltMarkPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = FeltColors.brass
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * progress.clamp(0.0, 1.0),
      false,
      ring,
    );
    final suitT = ((progress - 0.62) / 0.38).clamp(0.0, 1.0);
    if (suitT <= 0) {
      return;
    }
    const suits = ['♠', '♥', '♣', '♦'];
    const colors = [
      FeltColors.brass,
      FeltColors.clay,
      FeltColors.brass,
      FeltColors.clay,
    ];
    final anchors = [
      center + Offset(0, -radius),
      center + Offset(radius, 0),
      center + Offset(0, radius),
      center + Offset(-radius, 0),
    ];
    for (var i = 0; i < suits.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: suits[i],
          style: TextStyle(fontSize: size.shortestSide * 0.11, color: colors[i].withValues(alpha: suitT)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        anchors[i] - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FeltMarkPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Oyun ekranlarının gradyanı üzerinde kenar kararması. Metin rengini değiştirmez.
class FeltVignettePainter extends CustomPainter {
  const FeltVignettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x00000000), Color(0x59000000)],
        stops: [0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant FeltVignettePainter oldDelegate) => false;
}
