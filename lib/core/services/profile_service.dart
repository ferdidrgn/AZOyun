import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import '../models/player_profile.dart';
import 'analytics_service.dart';
import 'play_games_service.dart';

class GameRewardResult {
  final int earnedXp;
  final int earnedCoins;
  final bool leveledUp;
  final int newLevel;
  final List<AchievementDef> unlockedAchievements;
  final bool granted;

  const GameRewardResult({
    required this.earnedXp,
    required this.earnedCoins,
    required this.leveledUp,
    required this.newLevel,
    this.unlockedAchievements = const [],
    this.granted = true,
  });
}

enum ProfileCloudStatus { local, syncing, synced, unavailable }

typedef _MatchResult = ({String game, bool won, int at});
typedef _Progress = ({
  PlayerProfile profile,
  Map<String, _MatchResult> results,
  int retiredThrough,
});

class ProfileService extends ChangeNotifier with WidgetsBindingObserver {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _legacyKey = 'az_player_profile_v1';
  static const _guestKey = 'az_player_progress_guest_v2';
  static const _adoptedKey = 'az_player_progress_guest_adopted';
  static const _maxResults = 512;
  static const _baseXp = 2;
  static const _winXp = 3;
  static const _baseCoin = 1;
  static const _winCoin = 2;

  PlayerProfile _profile = PlayerProfile.initial();
  Map<String, _MatchResult> _results = {};
  int _retiredThrough = 0;
  final _random = Random.secure();
  Future<void>? _loadTask;
  Future<void> _mutations = Future.value();
  String? _account;
  bool _bound = false;
  bool _syncing = false;
  bool _syncRequested = false;
  Timer? _syncTimer;
  ProfileCloudStatus _cloudStatus = ProfileCloudStatus.local;

  PlayerProfile get profile => _profile;
  ProfileCloudStatus get cloudStatus => _cloudStatus;

  Future<void> load() => _loadTask ??= _loadLocal();

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _readGuest(prefs);
  }

  void _readGuest(SharedPreferences prefs) {
    final guest = _read(prefs.getString(_guestKey));
    final legacy =
        prefs.containsKey(_adoptedKey) ? null : prefs.getString(_legacyKey);
    if (guest != null) {
      _restore(guest);
    } else {
      _profile =
          legacy == null ? PlayerProfile.initial() : _decodeLegacy(legacy);
      _results = {};
      _retiredThrough = 0;
    }
  }

  PlayerProfile _decodeLegacy(String raw) {
    try {
      return PlayerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerProfile.initial();
    }
  }

  static String _accountKey(String id) =>
      'az_player_progress_v2_' + base64Url.encode(utf8.encode(id));

  _Progress? _read(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final profile =
          PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>);
      final results = <String, _MatchResult>{};
      for (final entry in (json['results'] as Map? ?? {}).entries) {
        final value = entry.value;
        if (entry.key is String &&
            value is List &&
            value.length == 3 &&
            value[0] is String &&
            value[1] is bool &&
            value[2] is int) {
          results[entry.key as String] =
              (game: value[0], won: value[1], at: value[2]);
        }
      }
      return (
        profile: profile,
        results: results,
        retiredThrough: (json['retiredThrough'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  String _encode({bool cloud = false}) {
    final json = _profile.toJson();
    if (cloud) json.remove('coins');
    return jsonEncode({
      'profile': json,
      'results': _results.map(
          (id, result) => MapEntry(id, [result.game, result.won, result.at])),
      'retiredThrough': _retiredThrough,
    });
  }

  _Progress get _progress => (
        profile: _profile,
        results: _results,
        retiredThrough: _retiredThrough,
      );

  void _restore(_Progress progress) {
    _profile = progress.profile;
    _results = progress.results;
    _retiredThrough = progress.retiredThrough;
  }

  Future<T> _serialize<T>(Future<T> Function() run) {
    final operation = _mutations.then((_) async {
      await load();
      return run();
    });
    _mutations = operation.then<void>((_) {},
        onError: (Object error, StackTrace trace) {});
    return operation;
  }

  Future<void> _persist({bool upload = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final account = _account;
    await prefs.setString(
        account == null ? _guestKey : _accountKey(account), _encode());
    notifyListeners();
    if (upload && account != null) _scheduleSync();
  }

  void bindPlayGames() {
    if (_bound || !PlayGamesService.instance.isSupported) return;
    _bound = true;
    PlayGamesService.instance.addListener(_scheduleSync);
    WidgetsBinding.instance.addObserver(this);
    _scheduleSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PlayGamesService.instance
          .refreshSignIn()
          .then((_) => syncPlayGames()));
    }
  }

  void _scheduleSync() {
    if (!_bound) return;
    _syncRequested = true;
    _syncTimer?.cancel();
    _syncTimer = Timer(
        const Duration(milliseconds: 350), () => unawaited(syncPlayGames()));
  }

  Future<void> syncPlayGames() async {
    if (!_bound) return;
    if (_syncing) {
      _syncRequested = true;
      return;
    }
    _syncing = true;
    _syncRequested = false;
    final play = PlayGamesService.instance;
    final id = play.playerId;
    try {
      await _serialize(() async {
        if (_account == id) return;
        final prefs = await SharedPreferences.getInstance();
        _account = id;
        if (id == null) {
          _readGuest(prefs);
        } else {
          final local = _read(prefs.getString(_accountKey(id)));
          _restore(local ??
              (
                profile: PlayerProfile.initial(),
                results: {},
                retiredThrough: 0
              ));
        }
        notifyListeners();
      });
      if (id == null) {
        _setCloudStatus(ProfileCloudStatus.local);
        return;
      }
      _setCloudStatus(ProfileCloudStatus.syncing);
      final raw = await play.loadProfile(id);
      final cloud = _read(raw);
      if (raw != null && cloud == null)
        throw const FormatException('Bulut profili okunamadı.');
      final next = await _serialize<String?>(() async {
        if (_account != id || play.playerId != id) return null;
        final prefs = await SharedPreferences.getInstance();
        if (cloud == null && !prefs.containsKey(_adoptedKey)) {
          final guest = _read(prefs.getString(_guestKey));
          final legacy = prefs.getString(_legacyKey);
          final profile =
              guest?.profile ?? (legacy == null ? null : _decodeLegacy(legacy));
          if (profile != null &&
              _profile.gamesPlayed == 0 &&
              _profile.xp == 0 &&
              _profile.coins == 0) {
            _profile = profile;
            _results = guest?.results ?? {};
            _retiredThrough = guest?.retiredThrough ?? 0;
            await _persist(upload: false);
            await prefs.setString(_adoptedKey, id);
            await prefs.remove(_guestKey);
          }
        }
        if (cloud != null) {
          final before = _encode();
          _merge(cloud);
          if (_encode() != before) await _persist(upload: false);
        }
        return _encode(cloud: true);
      });
      if (next == null || play.playerId != id) return;
      if (next != raw) await play.saveProfile(id, next);
      if (play.playerId == id) {
        _setCloudStatus(ProfileCloudStatus.synced);
        unawaited(_publishMilestones(id));
      }
    } catch (error) {
      if (play.playerId == id) _setCloudStatus(ProfileCloudStatus.unavailable);
      debugPrint('[ProfileService] bulut eşitleme bekliyor: $error');
    } finally {
      _syncing = false;
      if (_syncRequested || play.playerId != id) _scheduleSync();
    }
  }

  bool _preferCloud(PlayerProfile remote) {
    if (remote.gamesPlayed != _profile.gamesPlayed)
      return remote.gamesPlayed > _profile.gamesPlayed;
    if (remote.xp != _profile.xp) return remote.xp > _profile.xp;
    if (remote.wins != _profile.wins) return remote.wins > _profile.wins;
    return true;
  }

  void _merge(_Progress cloud) {
    final local = _progress;
    final useCloud = _preferCloud(cloud.profile);
    final alternative = useCloud ? local : cloud;
    if (useCloud) {
      _restore(cloud);
      _profile = _profile.copyWith(coins: local.profile.coins);
    }
    final missing = alternative.results.entries
        .where(
          (entry) =>
              !_results.containsKey(entry.key) &&
              entry.value.at > _retiredThrough,
        )
        .toList()
      ..sort(_byDate);
    for (final entry in missing) {
      _addMatch(entry.value, coins: 0);
      _results[entry.key] = entry.value;
    }
    _retiredThrough = max(_retiredThrough, alternative.retiredThrough);
    if (_profile.gamesPlayed == _results.length && _results.isNotEmpty) {
      final ordered = _results.entries.toList()..sort(_byDate);
      var streak = 0;
      var best = 0;
      for (final entry in ordered) {
        streak = entry.value.won ? streak + 1 : 0;
        best = max(best, streak);
      }
      _profile = _profile.copyWith(
        winStreak: streak,
        bestWinStreak: max(best,
            max(local.profile.bestWinStreak, cloud.profile.bestWinStreak)),
      );
    }
    _trimResults();
    _applyEarnedBadges();
  }

  static int _byDate(
    MapEntry<String, _MatchResult> a,
    MapEntry<String, _MatchResult> b,
  ) {
    final comparison = a.value.at.compareTo(b.value.at);
    return comparison == 0 ? a.key.compareTo(b.key) : comparison;
  }

  void _trimResults() {
    if (_results.length <= _maxResults) return;
    final ordered = _results.entries.toList()..sort(_byDate);
    for (final entry in ordered.take(_results.length - _maxResults)) {
      _results.remove(entry.key);
      _retiredThrough = max(_retiredThrough, entry.value.at);
    }
  }

  void _setCloudStatus(ProfileCloudStatus status) {
    if (_cloudStatus == status) return;
    _cloudStatus = status;
    notifyListeners();
  }

  Future<void> _publishMilestones(String id) async {
    final play = PlayGamesService.instance;
    final profile = _profile;
    for (final badge in profile.unlockedAchievementIds) {
      if (play.playerId != id) return;
      await play.unlockAchievement(badge);
    }
    if (play.playerId == id) await play.submitProfileXp(profile.xp);
  }

  Future<GameRewardResult> reportGameResult({
    required String gameId,
    required bool won,
    String? resultId,
  }) =>
      _serialize(() async {
        final at = DateTime.now().millisecondsSinceEpoch;
        final id = resultId == null
            ? 'local:$at:${_random.nextInt(1 << 31)}:${_random.nextInt(1 << 31)}'
            : '$gameId:$resultId';
        if (_results.containsKey(id)) {
          return GameRewardResult(
            earnedXp: 0,
            earnedCoins: 0,
            leveledUp: false,
            newLevel: _profile.level,
            granted: false,
          );
        }
        final earnedXp = _baseXp + (won ? _winXp : 0);
        final earnedCoins = _baseCoin + (won ? _winCoin : 0);
        final prevLevel = _profile.level;
        final result = (game: gameId, won: won, at: at);
        _addMatch(result, coins: earnedCoins);
        _results[id] = result;
        _trimResults();
        final badges = _applyEarnedBadges();
        await _persist();
        unawaited(
            AnalyticsService.instance.logGameEnd(gameId: gameId, won: won));
        if (_profile.level > prevLevel)
          unawaited(AnalyticsService.instance.logLevelUp(_profile.level));
        return GameRewardResult(
          earnedXp: earnedXp,
          earnedCoins: earnedCoins,
          leveledUp: _profile.level > prevLevel,
          newLevel: _profile.level,
          unlockedAchievements: badges,
        );
      });

  void _addMatch(_MatchResult result, {required int coins}) {
    final streak = result.won ? _profile.winStreak + 1 : 0;
    _profile = _profile.copyWith(
      xp: _profile.xp + _baseXp + (result.won ? _winXp : 0),
      coins: _profile.coins + coins,
      gamesPlayed: _profile.gamesPlayed + 1,
      wins: _profile.wins + (result.won ? 1 : 0),
      winStreak: streak,
      bestWinStreak: max(_profile.bestWinStreak, streak),
      playedGameIds: {..._profile.playedGameIds, result.game},
    );
  }

  Future<List<AchievementDef>> reconcileAchievements() => _serialize(() async {
        final badges = _applyEarnedBadges();
        if (badges.isNotEmpty) await _persist();
        return badges;
      });

  List<AchievementDef> _applyEarnedBadges() {
    final badges = kAchievements
        .where((def) =>
            !_profile.unlockedAchievementIds.contains(def.id) &&
            def.isMetBy(_profile))
        .toList(growable: false);
    if (badges.isEmpty) return badges;
    _profile = _profile.copyWith(
      unlockedAchievementIds: {
        ..._profile.unlockedAchievementIds,
        ...badges.map((def) => def.id)
      },
      xp: _profile.xp + badges.fold(0, (sum, def) => sum + def.xpReward),
    );
    for (final def in badges)
      unawaited(AnalyticsService.instance.logAchievementUnlocked(def.id));
    return badges;
  }

  Future<void> addCoins(int amount) => _serialize(() async {
        _profile = _profile.copyWith(coins: _profile.coins + amount);
        await _persist(upload: false);
      });

  Future<void> reset() => _serialize(() async {
        _profile = PlayerProfile.initial();
        _results = {};
        _retiredThrough = 0;
        await _persist(upload: false);
      });
}
