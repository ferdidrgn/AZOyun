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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final stopwatch = Stopwatch()..start();
    final onboardingDone = await OnboardingService.instance.isDone();
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
      decoration: const BoxDecoration(gradient: AZColors.gradPurple),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports, size: 88, color: Colors.white),
            SizedBox(height: 20),
            Text('AZ OYUN',
                style: TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    ),
  );
}
