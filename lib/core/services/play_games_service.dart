import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

class PlayGamesService extends ChangeNotifier {
  PlayGamesService._();
  static final PlayGamesService instance = PlayGamesService._();

  static const profileSlot = 'azoyun_profile_v2';
  static const _requestTimeout = Duration(seconds: 8);
  static const _defaultLeaderboardId = 'CgkIxOrNg4kPEAIQAQ';
  static const xpLeaderboardId =
      String.fromEnvironment('PGS_XP_LEADERBOARD_ID');

  static const _achievementIds = {
    'first_step': 'CgkIxOrNg4kPEAIQAw',
    'ten_games': String.fromEnvironment('PGS_ACHIEVEMENT_TEN_GAMES'),
    'fifty_games': String.fromEnvironment('PGS_ACHIEVEMENT_FIFTY_GAMES'),
    'five_wins': String.fromEnvironment('PGS_ACHIEVEMENT_FIVE_WINS'),
    'twenty_wins': String.fromEnvironment('PGS_ACHIEVEMENT_TWENTY_WINS'),
    'win_streak_3': String.fromEnvironment('PGS_ACHIEVEMENT_WIN_STREAK_3'),
    'try_them_all': String.fromEnvironment('PGS_ACHIEVEMENT_TRY_THEM_ALL'),
    'hundred_games': String.fromEnvironment('PGS_ACHIEVEMENT_HUNDRED_GAMES'),
    'ten_game_types': String.fromEnvironment('PGS_ACHIEVEMENT_TEN_GAME_TYPES'),
  };

  String? _playerId;
  String? _playerName;
  Future<void>? _sessionRequest;

  String? get playerId => _playerId;
  String? get playerName => _playerName;
  bool get isSignedIn => _playerId != null;
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> refreshSignIn() => _updateSession(interactive: false);
  Future<void> signIn() => _updateSession(interactive: true);

  Future<void> _updateSession({required bool interactive}) async {
    if (!isSupported) return;
    final pending = _sessionRequest;
    if (pending != null) {
      await pending;
      if (!interactive || isSignedIn) return;
    }
    final request = _readSession(interactive);
    _sessionRequest = request;
    try {
      await request;
    } finally {
      if (identical(_sessionRequest, request)) _sessionRequest = null;
    }
  }

  Future<void> _readSession(bool interactive) async {
    try {
      if (interactive &&
          !await GamesServices.isSignedIn.timeout(_requestTimeout)) {
        await GamesServices.signIn();
      }
      if (!await GamesServices.isSignedIn.timeout(_requestTimeout)) {
        _setPlayer(null, null);
        return;
      }
      final id = await GamesServices.getPlayerID().timeout(_requestTimeout);
      String? name;
      try {
        name = await GamesServices.getPlayerName().timeout(_requestTimeout);
      } catch (_) {
        // The account ID is sufficient when the profile name is unavailable.
      }
      _setPlayer(id?.isNotEmpty == true ? id : null, name);
    } catch (error) {
      debugPrint('[PlayGamesService] oturum okunamadı: $error');
    }
  }

  void _setPlayer(String? id, String? name) {
    if (_playerId == id && _playerName == name) return;
    _playerId = id;
    _playerName = id == null ? null : name;
    notifyListeners();
  }

  Future<bool> ensureSignedIn() async {
    if (!isSignedIn) await signIn();
    return isSignedIn;
  }

  Future<void> _verifyPlayer(String id) async {
    if (playerId != id ||
        await GamesServices.getPlayerID().timeout(_requestTimeout) != id) {
      throw StateError('Play Games hesabı değişti.');
    }
  }

  Future<String?> loadProfile(String id) async {
    await _verifyPlayer(id);
    final saves = await GamesServices.getSavedGames(forceRefresh: true)
        .timeout(_requestTimeout);
    if (saves == null) throw StateError('Bulut kayıt listesi alınamadı.');
    if (!saves.any((save) => save.name == profileSlot)) return null;
    final data = await GamesServices.loadGame(name: profileSlot)
        .timeout(_requestTimeout);
    if (data == null) throw StateError('Bulut profili okunamadı.');
    await _verifyPlayer(id);
    return data;
  }

  Future<void> saveProfile(String id, String data) async {
    await _verifyPlayer(id);
    await GamesServices.saveGame(name: profileSlot, data: data)
        .timeout(_requestTimeout);
  }

  Future<void> submitScore({required String gameId, required int score}) =>
      _submitScore(_defaultLeaderboardId, score);

  Future<void> submitProfileXp(int xp) => _submitScore(xpLeaderboardId, xp);

  Future<void> _submitScore(String leaderboardId, int value) async {
    if (!isSignedIn || leaderboardId.isEmpty) return;
    try {
      await GamesServices.submitScore(
        score: Score(androidLeaderboardID: leaderboardId, value: value),
      );
    } catch (error) {
      debugPrint('[PlayGamesService] skor gönderilemedi: $error');
    }
  }

  Future<void> unlockAchievement(String achievementDefId) async {
    if (!isSignedIn) return;
    final id = _achievementIds[achievementDefId];
    if (id == null || id.isEmpty) return;
    try {
      await GamesServices.unlock(
        achievement: Achievement(androidID: id, percentComplete: 100),
      );
    } catch (error) {
      debugPrint('[PlayGamesService] başarım açılamadı: $error');
    }
  }

  Future<void> showLeaderboard(String gameId) async {
    if (!await ensureSignedIn()) return;
    final id = gameId == 'profile_xp' ? xpLeaderboardId : _defaultLeaderboardId;
    if (id.isEmpty) return;
    try {
      await GamesServices.showLeaderboards(androidLeaderboardID: id);
    } catch (error) {
      debugPrint('[PlayGamesService] liderlik tablosu açılamadı: $error');
    }
  }

  Future<void> showAchievements() async {
    if (!await ensureSignedIn()) return;
    try {
      await GamesServices.showAchievements();
    } catch (error) {
      debugPrint('[PlayGamesService] başarımlar açılamadı: $error');
    }
  }
}
