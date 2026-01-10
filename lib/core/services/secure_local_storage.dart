import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureLocalStorage {
  static final SecureLocalStorage _instance = SecureLocalStorage._internal();

  factory SecureLocalStorage() => _instance;

  SecureLocalStorage._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Keys
  static const String _gameEnterCountKey = 'game_enter_count';
  static const String _lastRewardedShownKey = 'last_rewarded_shown';

  /// Oyuna giriş sayısı
  Future<int> getGameEnterCount() async {
    final value = await _storage.read(key: _gameEnterCountKey);
    return int.tryParse(value ?? '0') ?? 0;
  }

  Future<void> incrementGameEnterCount() async {
    final count = await getGameEnterCount();
    await _storage.write(
      key: _gameEnterCountKey,
      value: (count + 1).toString(),
    );
  }

  /// Ödüllü reklam gösterildi mi (aynı odada spam olmasın)
  Future<bool> isRewardedShownForRoom(final String roomId) async {
    final value = await _storage.read(key: 'rewarded_$roomId');
    return value == 'true';
  }

  Future<void> markRewardedShownForRoom(final String roomId) =>
      _storage.write(key: 'rewarded_$roomId', value: 'true');

  /// Reset (debug veya yeni session)
  Future<void> resetCounters() => _storage.delete(key: _gameEnterCountKey);
}
