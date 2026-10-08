import 'package:flutter/material.dart';

import '../../core/services/onboarding_service.dart';
import '../../core/theme/felt.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart';

/// Marka halkası görünsün diye kısa bir bekleyiş, sonra onboarding veya ana sayfa.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final stopwatch = Stopwatch()..start();
    final onboardingDone = await OnboardingService.instance.isDone();
    final remaining = 1100 - stopwatch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return Scaffold(
      body: FeltBackdrop(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FeltMark(size: 180),
              const SizedBox(height: 20),
              Text('AZ Oyun', style: feltDisplay(palette.ink, 40)),
              const SizedBox(height: 8),
              Text('Arkadaşlarınla oyna', style: feltUi(palette.muted, 16)),
            ],
          ),
        ),
      ),
    );
  }
}
