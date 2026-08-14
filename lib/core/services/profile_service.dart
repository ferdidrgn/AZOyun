import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_profile.dart';
import 'analytics_service.dart';

class GameRewardResult {
  final int earnedXp;
  final int earnedCoins;
  final bool leveledUp;
  final int newLevel;

  const GameRewardResult({
    required this.earnedXp,
    required this.earnedCoins,
    required this.leveledUp,
    required this.newLevel,
  });
}

/// Oyuncunun XP/coin/istatistik profilini yönetir. Yerelde (SharedPreferences)
/// saklanır; Play Games'e bağlıysa gelecekte bulut kaydıyla senkronize edilir.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _key = 'az_player_profile_v1';
  static const _baseXp = 5;
  static const _winXp = 15;
  static const _baseCoin = 2;
  static const _winCoin = 10;

  PlayerProfile _profile = PlayerProfile.initial();
  bool _loaded = false;

  PlayerProfile get profile => _profile;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _profile = PlayerProfile.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _profile = PlayerProfile.initial();
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_profile.toJson()));
  }

  /// Bir hızlı oyun maçı bitince çağrılır. Kazanılan ödülü döner.
  Future<GameRewardResult> reportGameResult({
    required String gameId,
    required bool won,
  }) async {
    await load();
    final earnedXp = _baseXp + (won ? _winXp : 0);
    final earnedCoins = _baseCoin + (won ? _winCoin : 0);
    final prevLevel = _profile.level;
    final newStreak = won ? _profile.winStreak + 1 : 0;

    _profile = _profile.copyWith(
      xp: _profile.xp + earnedXp,
      coins: _profile.coins + earnedCoins,
      gamesPlayed: _profile.gamesPlayed + 1,
      wins: _profile.wins + (won ? 1 : 0),
      winStreak: newStreak,
      bestWinStreak:
          newStreak > _profile.bestWinStreak ? newStreak : _profile.bestWinStreak,
      playedGameIds: {..._profile.playedGameIds, gameId},
    );
    await _persist();

    // Tek çağrı noktası: 30+ oyunun tamamı reportGameResult üzerinden geçtiği
    // için her oyuna ayrı analytics kodu eklemeye gerek kalmıyor.
    unawaited(AnalyticsService.instance.logGameEnd(gameId: gameId, won: won));
    final leveledUp = _profile.level > prevLevel;
    if (leveledUp) {
      unawaited(AnalyticsService.instance.logLevelUp(_profile.level));
    }

    return GameRewardResult(
      earnedXp: earnedXp,
      earnedCoins: earnedCoins,
      leveledUp: leveledUp,
      newLevel: _profile.level,
    );
  }

  Future<void> unlockAchievement(String id) async {
    await load();
    if (_profile.unlockedAchievementIds.contains(id)) return;
    _profile = _profile.copyWith(
      unlockedAchievementIds: {..._profile.unlockedAchievementIds, id},
    );
    await _persist();
    unawaited(AnalyticsService.instance.logAchievementUnlocked(id));
  }

  Future<void> addCoins(int amount) async {
    await load();
    _profile = _profile.copyWith(coins: _profile.coins + amount);
    await _persist();
  }

  /// Maç sonucundan bağımsız bonus XP (ör. başarım ödülü).
  Future<void> grantBonusXp(int amount) async {
    await load();
    _profile = _profile.copyWith(xp: _profile.xp + amount);
    await _persist();
  }

  Future<void> reset() async {
    _profile = PlayerProfile.initial();
    await _persist();
  }
}
