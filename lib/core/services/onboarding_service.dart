import 'package:shared_preferences/shared_preferences.dart';

/// İlk açılış onboarding'inin bir kez gösterilip gösterilmediğini takip
/// eder.
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _key = 'az_onboarding_done_v1';

  Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
