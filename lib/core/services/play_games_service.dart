import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';

class PlayGamesService extends ChangeNotifier {
  PlayGamesService._();
  static final PlayGamesService instance = PlayGamesService._();

  static const profileSlot = 'azoyun_profile_v2';
  static const _requestTimeout = Duration(seconds: 8);
  static const _interactiveTimeout = Duration(minutes: 2);
  static const _channel = MethodChannel('azoyun/play_games');
  static const _defaultLeaderboardId = 'CgkIxOrNg4kPEAIQAQ';
  static const xpLeaderboardId =
      String.fromEnvironment('PGS_XP_LEADERBOARD_ID', defaultValue: 'CgkIxOrNg4kPEAIQEA');

  static const _achievementIds = {
    'first_step': 'CgkIxOrNg4kPEAIQAw',
    'ten_games': String.fromEnvironment('PGS_ACHIEVEMENT_TEN_GAMES', defaultValue: 'CgkIxOrNg4kPEAIQCw'),
    'fifty_games': String.fromEnvironment('PGS_ACHIEVEMENT_FIFTY_GAMES', defaultValue: 'CgkIxOrNg4kPEAIQDg'),
    'five_wins': String.fromEnvironment('PGS_ACHIEVEMENT_FIVE_WINS', defaultValue: 'CgkIxOrNg4kPEAIQDA'),
    'twenty_wins': String.fromEnvironment('PGS_ACHIEVEMENT_TWENTY_WINS', defaultValue: 'CgkIxOrNg4kPEAIQDQ'),
    'win_streak_3': String.fromEnvironment('PGS_ACHIEVEMENT_WIN_STREAK_3', defaultValue: 'CgkIxOrNg4kPEAIQDw'),
    'try_them_all': String.fromEnvironment('PGS_ACHIEVEMENT_TRY_THEM_ALL', defaultValue: 'CgkIxOrNg4kPEAIQCg'),
    'hundred_games': String.fromEnvironment('PGS_ACHIEVEMENT_HUNDRED_GAMES', defaultValue: 'CgkIxOrNg4kPEAIQEQ'),
    'ten_game_types': String.fromEnvironment('PGS_ACHIEVEMENT_TEN_GAME_TYPES', defaultValue: 'CgkIxOrNg4kPEAIQEg'),
  };

  String? _playerId;
  String? _playerName;
  Future<void>? _sessionRequest;
  bool _interactiveRequest = false;
  String? _signInError;

  String? get playerId => _playerId;
  String? get playerName => _playerName;
  String? get signInError => _signInError;
  bool get isSignedIn => _playerId != null;
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> refreshSignIn() => _updateSession(interactive: false);
  Future<void> signIn() => _updateSession(interactive: true);

  Future<void> _updateSession({required bool interactive}) async {
    if (!isSupported) return;
    final pending = _sessionRequest;
    if (pending != null) {
      final pendingIsInteractive = _interactiveRequest;
      await pending;
      if (interactive && !pendingIsInteractive && !isSignedIn) {
        await _updateSession(interactive: true);
      }
      return;
    }
    _interactiveRequest = interactive;
    final request = _updatePlayer(interactive);
    _sessionRequest = request;
    try {
      await request;
    } finally {
      if (identical(_sessionRequest, request)) _sessionRequest = null;
    }
  }

  Future<Map<String, String>?> _readPlayer({bool interactive = false}) =>
      _channel.invokeMapMethod<String, String>('player', {
        'interactive': interactive,
      }).timeout(interactive ? _interactiveTimeout : _requestTimeout);

  Future<void> _updatePlayer(bool interactive) async {
    try {
      final player = await _readPlayer(interactive: interactive);
      final id = player?['id'];
      final connected = id != null && id.isNotEmpty;
      if (interactive) {
        _signInError =
            connected ? null : 'Play Games hesabını seçip tekrar dene.';
      }
      _setPlayer(connected ? id : null, player?['name']);
    } catch (error) {
      if (interactive) {
        _signInError = switch (error) {
          TimeoutException() =>
            'Play Games zamanında yanıt vermedi. Tekrar dene.',
          PlatformException(code: 'services_unavailable') =>
            'Google Play Hizmetleri kullanılamıyor. Cihazındaki Play Hizmetleri’ni güncelle.',
          PlatformException(details: 7) =>
            'Play Games’e erişilemedi. İnternet bağlantını kontrol edip tekrar dene.',
          PlatformException(details: 10) =>
            'Bu AZOyun sürümü Play Games ile doğrulanamadı (kod 10).',
          PlatformException(details: 16) => 'Play Games girişi iptal edildi.',
          PlatformException(details: final int code) =>
            'Play Games bağlantısı kurulamadı (kod $code).',
          _ => 'Play Games bağlantısı kurulamadı. Tekrar dene.',
        };
      }
      _setPlayer(null, null);
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
    if (playerId != id || (await _readPlayer())?['id'] != id) {
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
