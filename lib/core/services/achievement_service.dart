import '../models/achievement.dart';
import 'play_games_service.dart';
import 'profile_service.dart';

/// Maç sonrası hangi başarımların yeni açıldığını hesaplar ve kaydeder.
class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  /// [ProfileService.reportGameResult] çağrıldıktan SONRA çağrılmalı.
  /// Yeni açılan başarımları döner (UI'da göstermek için).
  Future<List<AchievementDef>> checkAndUnlock() async {
    await ProfileService.instance.load();
    final newlyUnlocked = <AchievementDef>[];

    for (final def in kAchievements) {
      final profile = ProfileService.instance.profile;
      if (profile.unlockedAchievementIds.contains(def.id)) continue;
      if (!def.isMetBy(profile)) continue;

      await ProfileService.instance.unlockAchievement(def.id);
      await ProfileService.instance.grantBonusXp(def.xpReward);
      newlyUnlocked.add(def);
      PlayGamesService.instance.unlockAchievement(def.id);
    }

    return newlyUnlocked;
  }
}
