import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

/// Google Play Games Services (Android) / Game Center (iOS) köprüsü.
///
/// Play Console tarafında (proje kimliği 517819561284) şu an:
///   - 1 genel liderlik tablosu ("Skorboard") — bkz. [_defaultLeaderboardId]
///   - 1 başarım ("İlk" / first_step) — bkz. [_achievementIds]
///   - 1 etkinlik ("Hoşgeldin") — Events API henüz bu serviste
///     uygulanmadı, ileride eklenebilir.
/// Yeni oyuna özel liderlik tablosu/başarım oluşturulunca ilgili ID
/// [_leaderboardIds]/[_achievementIds] haritalarına eklenmesi yeterli.
///
/// ID'ler boş/eksikse bu servis tüm çağrılarda sessizce no-op çalışır —
/// uygulama Play Games olmadan da tamamen sorunsuz çalışmaya devam eder.
/// Bu dosya `games_services` paketinin API'sine göre yazıldı; paket
/// sürümü güncellenirse (`flutter pub get` sonrası) derleme hatası
/// çıkarsa yalnız bu dosyanın güncellenmesi yeterlidir.
class PlayGamesService {
  PlayGamesService._();
  static final PlayGamesService instance = PlayGamesService._();

  bool _signedIn = false;
  bool get isSignedIn => _signedIn;

  /// Play Console'da şimdilik tek bir genel skor tablosu ("Skorboard")
  /// oluşturuldu — oyuna özel bir ID tanımlanmamış tüm hızlı oyunların
  /// skoru buraya gider. İleride her oyun için ayrı tablo açılırsa
  /// [_leaderboardIds]'e o oyunun ID'si eklenmesi yeterli, bu satır
  /// değişmeden kalabilir.
  static const String _defaultLeaderboardId = 'CgkIxOrNg4kPEAIQAQ'; // Skorboard

  /// Oyuna özel liderlik tablosu ID'si (varsa [_defaultLeaderboardId]'nin
  /// önüne geçer).
  static const Map<String, String> _leaderboardIds = {};

  String _leaderboardIdFor(String gameId) =>
      _leaderboardIds[gameId]?.isNotEmpty == true
          ? _leaderboardIds[gameId]!
          : _defaultLeaderboardId;

  /// Başarım ID eşlemesi (AchievementDef.id -> Play Games achievement ID).
  /// Play Console'da şimdilik sadece "İlk" (first_step) başarımı oluşturuldu.
  static const Map<String, String> _achievementIds = {
    'first_step': 'CgkIxOrNg4kPEAIQAw', // "İlk" — ilk maçını oyna
  };

  Future<void> signIn() async {
    if (_signedIn) return;
    try {
      await GamesServices.signIn();
      _signedIn = await GamesServices.isSignedIn;
    } catch (e) {
      debugPrint('[PlayGamesService] sign-in atlandı: $e');
      _signedIn = false;
    }
  }

  Future<void> submitScore({required String gameId, required int score}) async {
    if (!_signedIn) return;
    final leaderboardId = _leaderboardIdFor(gameId);
    try {
      await GamesServices.submitScore(
        score: Score(androidLeaderboardID: leaderboardId, value: score),
      );
    } catch (e) {
      debugPrint('[PlayGamesService] skor gönderilemedi: $e');
    }
  }

  Future<void> unlockAchievement(String achievementDefId) async {
    if (!_signedIn) return;
    final playGamesId = _achievementIds[achievementDefId];
    if (playGamesId == null || playGamesId.isEmpty) return;
    try {
      await GamesServices.unlock(
        achievement: Achievement(androidID: playGamesId, percentComplete: 100),
      );
    } catch (e) {
      debugPrint('[PlayGamesService] başarım açılamadı: $e');
    }
  }

  Future<void> showLeaderboard(String gameId) async {
    if (!_signedIn) return;
    final leaderboardId = _leaderboardIdFor(gameId);
    try {
      await GamesServices.showLeaderboards(androidLeaderboardID: leaderboardId);
    } catch (e) {
      debugPrint('[PlayGamesService] liderlik tablosu açılamadı: $e');
    }
  }

  Future<void> showAchievements() async {
    if (!_signedIn) return;
    try {
      await GamesServices.showAchievements();
    } catch (e) {
      debugPrint('[PlayGamesService] başarımlar açılamadı: $e');
    }
  }
}
