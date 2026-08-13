import '../quickplay/game_ids.dart';
import 'player_profile.dart';

enum AchievementCondition { gamesPlayed, wins, winStreak, allGamesTried }

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

  bool isMetBy(PlayerProfile p) {
    switch (condition) {
      case AchievementCondition.gamesPlayed:
        return p.gamesPlayed >= threshold;
      case AchievementCondition.wins:
        return p.wins >= threshold;
      case AchievementCondition.winStreak:
        return p.bestWinStreak >= threshold;
      case AchievementCondition.allGamesTried:
        return kQuickGameIds.every(p.playedGameIds.contains);
    }
  }
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
];
