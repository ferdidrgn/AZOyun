import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kName            = 'player_name';
  static const _kGameEnterCount  = 'game_enter_count';

  // ── Player Name ───────────────────────────────────────────────────────────

  Future<String?> getPlayerName() => _storage.read(key: _kName);

  Future<void> setPlayerName(String name) =>
      _storage.write(key: _kName, value: name);

  // ── Ad Counters ───────────────────────────────────────────────────────────

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
}
