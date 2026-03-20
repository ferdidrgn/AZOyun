import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared secure storage for player name and game counters.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kName = 'player_name';

  Future<String?> getPlayerName() => _storage.read(key: _kName);

  Future<void> setPlayerName(String name) =>
      _storage.write(key: _kName, value: name);
}
