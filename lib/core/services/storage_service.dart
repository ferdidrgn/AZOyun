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

  // ── Player name ───────────────────────────────────────────────────────────

  Future<String?> getPlayerName() => _storage.read(key: _kName);

  Future<void> setPlayerName(String name) =>
      _storage.write(key: _kName, value: name);

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

  Future<void> clearAll() => _storage.deleteAll();
}
