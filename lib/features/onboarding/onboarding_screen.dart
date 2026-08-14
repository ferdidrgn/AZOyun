import 'package:flutter/material.dart';

import '../../core/services/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _pages = [
    ('🎮', 'onboarding_title_1', 'onboarding_body_1'),
    ('🏆', 'onboarding_title_2', 'onboarding_body_2'),
    ('📱', 'onboarding_title_3', 'onboarding_body_3'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await OnboardingService.instance.markDone();
    // Bildirim izni onboarding'in sonunda, tek seferlik olarak istenir.
    await NotificationService.instance.requestPermission();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AZTheme.dynamicGradient(context)),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(t('common_skip'), style: const TextStyle(color: Colors.white70)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (emoji, titleKey, bodyKey) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 88)),
                        const SizedBox(height: 32),
                        Text(t(titleKey),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(t(bodyKey),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AZButton(
                label: _page < _pages.length - 1 ? t('onboarding_next') : t('onboarding_start'),
                icon: Icons.arrow_forward_rounded,
                color: Theme.of(context).colorScheme.primary,
                onPressed: _next,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
