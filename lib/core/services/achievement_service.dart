import '../models/achievement.dart';
import 'profile_service.dart';

class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  Future<List<AchievementDef>> checkAndUnlock() =>
      ProfileService.instance.reconcileAchievements();
}
