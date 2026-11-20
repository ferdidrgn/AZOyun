import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Unified local storage — replaces both SecureLocalStorage and old StorageService.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kName           = 'player_name';
  static const _kGameEnterCount = 'game_enter_count';
  static const _kPremiumUntil   = 'premium_until';
  static const _kAdsRemoved     = 'ads_removed';

  // ── Player name ───────────────────────────────────────────────────────────

  Future<String?> getPlayerName() => _storage.read(key: _kName);

  Future<void> setPlayerName(String name) =>
      _storage.write(key: _kName, value: name);

  Future<String>? _playerTokenTask;

  Future<String> getPlayerToken() => _playerTokenTask ??= _loadPlayerToken();

  Future<String> _loadPlayerToken() async {
    try {
      final saved = await _storage.read(key: 'player_token');
      if (saved != null && saved.isNotEmpty) return saved;
      final random = Random.secure();
      final token = List.generate(4,
          (_) => random.nextInt(1 << 30).toRadixString(16).padLeft(8, '0')).join();
      await _storage.write(key: 'player_token', value: token);
      return token;
    } catch (_) {
      _playerTokenTask = null;
      rethrow;
    }
  }

  // ── Ad counters ───────────────────────────────────────────────────────────

  Future<int> getGameEnterCount() async {
    final v = await _storage.read(key: _kGameEnterCount);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> incrementGameEnterCount() async {
    final count = await getGameEnterCount();
    await _storage.write(key: _kGameEnterCount, value: '${count + 1}');
  }

  Future<bool> isRewardedShownForRoom(String roomId) async {
    final v = await _storage.read(key: 'rewarded_$roomId');
    return v == 'true';
  }

  Future<void> markRewardedShownForRoom(String roomId) =>
      _storage.write(key: 'rewarded_$roomId', value: 'true');

  // ── Premium (reklamsız süre) ─────────────────────────────────────────────

  Future<DateTime?> getPremiumUntil() async {
    final v = await _storage.read(key: _kPremiumUntil);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  /// Satın alma anında çağrılır. Zaten aktif bir premium süresi varsa
  /// üzerine eklenir (erken satın alan mağdur olmasın), yoksa şimdiden
  /// itibaren başlar.
  Future<void> extendPremium(Duration extra) async {
    final current = await getPremiumUntil();
    final base = (current != null && current.isAfter(DateTime.now()))
        ? current
        : DateTime.now();
    await _storage.write(
        key: _kPremiumUntil, value: base.add(extra).toIso8601String());
  }

  Future<bool> isPremiumActive() async {
    final until = await getPremiumUntil();
    return until != null && until.isAfter(DateTime.now());
  }

  Future<void> setAdsRemoved() => _storage.write(key: _kAdsRemoved, value: 'true');

  Future<bool> adsRemoved() async => (await _storage.read(key: _kAdsRemoved)) == 'true';

  Future<void> clearAll() async {
    await _storage.deleteAll();
    _playerTokenTask = null;
  }
}
