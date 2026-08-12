/// Oyuncunun yerel ilerleme profili — XP, seviye, coin, istatistikler.
class PlayerProfile {
  final int xp;
  final int coins;
  final int gamesPlayed;
  final int wins;
  final int winStreak;
  final int bestWinStreak;
  final Set<String> playedGameIds;
  final Set<String> unlockedAchievementIds;

  const PlayerProfile({
    required this.xp,
    required this.coins,
    required this.gamesPlayed,
    required this.wins,
    required this.winStreak,
    required this.bestWinStreak,
    required this.playedGameIds,
    required this.unlockedAchievementIds,
  });

  factory PlayerProfile.initial() => const PlayerProfile(
        xp: 0,
        coins: 0,
        gamesPlayed: 0,
        wins: 0,
        winStreak: 0,
        bestWinStreak: 0,
        playedGameIds: {},
        unlockedAchievementIds: {},
      );

  /// Basit ve öngörülebilir seviye formülü: her 100 XP bir seviye.
  int get level => (xp / 100).floor() + 1;
  int get xpIntoLevel => xp % 100;
  static const int xpPerLevel = 100;

  PlayerProfile copyWith({
    int? xp,
    int? coins,
    int? gamesPlayed,
    int? wins,
    int? winStreak,
    int? bestWinStreak,
    Set<String>? playedGameIds,
    Set<String>? unlockedAchievementIds,
  }) {
    return PlayerProfile(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      winStreak: winStreak ?? this.winStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      playedGameIds: playedGameIds ?? this.playedGameIds,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'coins': coins,
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        'winStreak': winStreak,
        'bestWinStreak': bestWinStreak,
        'playedGameIds': playedGameIds.toList(),
        'unlockedAchievementIds': unlockedAchievementIds.toList(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        winStreak: (json['winStreak'] as num?)?.toInt() ?? 0,
        bestWinStreak: (json['bestWinStreak'] as num?)?.toInt() ?? 0,
        playedGameIds: ((json['playedGameIds'] as List?) ?? [])
            .map((e) => e.toString())
            .toSet(),
        unlockedAchievementIds:
            ((json['unlockedAchievementIds'] as List?) ?? [])
                .map((e) => e.toString())
                .toSet(),
      );
}
