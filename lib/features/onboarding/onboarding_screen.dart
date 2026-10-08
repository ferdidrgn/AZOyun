import 'package:flutter/material.dart';

import '../../core/services/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/theme/felt.dart';
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
    final palette = FeltPalette.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: FeltBackdrop(
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(t('common_skip'), style: feltUi(palette.muted, 15)),
              ),
            ),
            const FeltMark(size: 96),
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
                        Text(emoji, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 24),
                        Text(
                          t(titleKey),
                          textAlign: TextAlign.center,
                          style: feltDisplay(palette.ink, 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t(bodyKey),
                          textAlign: TextAlign.center,
                          style: feltUi(palette.muted, 16),
                        ),
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
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? FeltColors.brass : palette.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: FeltColors.felt,
                    foregroundColor: FeltColors.ivory,
                  ),
                  child: Text(
                    _page < _pages.length - 1 ? t('onboarding_next') : t('onboarding_start'),
                    style: feltUi(FeltColors.ivory, 16, weight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
