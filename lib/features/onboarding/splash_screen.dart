import 'package:flutter/material.dart';

import '../../core/services/onboarding_service.dart';
import '../../core/theme/az_theme.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart';

/// Uygulama açılış ekranı. Ağır servisler `main()` içinde zaten yüklendi;
/// burada sadece marka görünür kılınır (minimum süre) ve onboarding'in
/// daha önce gösterilip gösterilmediğine göre bir sonraki ekrana geçilir.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _logoScale = Tween(begin: 0.72, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)));
    _logoFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.35, curve: Curves.easeOut));

    _titleFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.25, 0.6, curve: Curves.easeOut));
    _titleSlide = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.25, 0.6, curve: Curves.easeOut)));

    _taglineFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 0.85, curve: Curves.easeOut));

    _ctrl.forward();
    _boot();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final stopwatch = Stopwatch()..start();
    final onboardingDone = await OnboardingService.instance.isDone();
    // Marka animasyonu (900ms) tamamen görünmeden bir sonraki ekrana
    // geçilmesin — minimum bekleme, animasyon süresiyle aynı budgeye bağlı.
    final remaining = 900 - stopwatch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: BoxDecoration(gradient: AZTheme.dynamicGradient(context)),
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x33FFFFFF),
                      border: Border.all(color: const Color(0x55FFFFFF), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 12)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.sports_esports_rounded, size: 56, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: const Text('AZ OYUN',
                      style: TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _taglineFade,
                child: const Text('Arkadaşlarınla oyna',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 14, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _taglineFade,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
