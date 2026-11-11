import '../quickplay/game_ids.dart';
import 'player_profile.dart';

enum AchievementCondition {
  gamesPlayed,
  wins,
  winStreak,
  gameTypes,
  allGamesTried
}

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final AchievementCondition condition;
  final int threshold;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.condition,
    this.threshold = 0,
  });

  int get goal => condition == AchievementCondition.allGamesTried
      ? kQuickGameIds.length
      : threshold;

  int progress(PlayerProfile profile) => switch (condition) {
        AchievementCondition.gamesPlayed => profile.gamesPlayed,
        AchievementCondition.wins => profile.wins,
        AchievementCondition.winStreak => profile.bestWinStreak,
        AchievementCondition.gameTypes => profile.playedGameIds.length,
        AchievementCondition.allGamesTried =>
          kQuickGameIds.where(profile.playedGameIds.contains).length,
      };

  bool isMetBy(PlayerProfile profile) => progress(profile) >= goal;
}

const List<AchievementDef> kAchievements = [
  AchievementDef(
    id: 'first_step',
    title: 'İlk Adım',
    description: 'İlk maçını oyna',
    emoji: '👣',
    xpReward: 10,
    condition: AchievementCondition.gamesPlayed,
    threshold: 1,
  ),
  AchievementDef(
    id: 'ten_games',
    title: 'Işınlanan',
    description: '10 maç oyna',
    emoji: '🚀',
    xpReward: 20,
    condition: AchievementCondition.gamesPlayed,
    threshold: 10,
  ),
  AchievementDef(
    id: 'fifty_games',
    title: 'Efsane',
    description: '50 maç oyna',
    emoji: '🏆',
    xpReward: 60,
    condition: AchievementCondition.gamesPlayed,
    threshold: 50,
  ),
  AchievementDef(
    id: 'five_wins',
    title: 'Kalpli Kazanan',
    description: '5 galibiyet kazan',
    emoji: '❤️',
    xpReward: 25,
    condition: AchievementCondition.wins,
    threshold: 5,
  ),
  AchievementDef(
    id: 'twenty_wins',
    title: 'Şampiyon',
    description: '20 galibiyet kazan',
    emoji: '👑',
    xpReward: 50,
    condition: AchievementCondition.wins,
    threshold: 20,
  ),
  AchievementDef(
    id: 'win_streak_3',
    title: 'Seri Galip',
    description: 'Üst üste 3 galibiyet kazan',
    emoji: '🔥',
    xpReward: 30,
    condition: AchievementCondition.winStreak,
    threshold: 3,
  ),
  AchievementDef(
    id: 'try_them_all',
    title: 'Her Şeyi Dene',
    description: 'Hızlı oyunların hepsini en az bir kez oyna',
    emoji: '🎲',
    xpReward: 40,
    condition: AchievementCondition.allGamesTried,
  ),
  AchievementDef(
    id: 'hundred_games',
    title: 'Yüz Maç',
    description: '100 maç oyna',
    emoji: '🎖️',
    xpReward: 35,
    condition: AchievementCondition.gamesPlayed,
    threshold: 100,
  ),
  AchievementDef(
    id: 'ten_game_types',
    title: 'Oyun Gezgini',
    description: '10 farklı oyun oyna',
    emoji: '🧭',
    xpReward: 20,
    condition: AchievementCondition.gameTypes,
    threshold: 10,
  ),
];
