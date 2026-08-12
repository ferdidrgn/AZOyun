import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

/// Google Play Games Services (Android) / Game Center (iOS) köprüsü.
///
/// ÖNEMLİ: Liderlik tablosu ve başarım ID'leri aşağıda placeholder olarak
/// duruyor. Google Play Console'da:
///   1. Uygulamanı oluştur → "Play Games Services" özelliğini etkinleştir.
///   2. Liderlik tablosu ve başarım tanımlarını oluştur (her hızlı oyun için
///      bir liderlik tablosu önerilir: skorId aşağıdaki [_leaderboardIds]).
///   3. Oluşan ID'leri aşağıya yapıştır.
///   4. `android/app/src/main/AndroidManifest.xml` içine Play Games
///      meta-data'sını ekle (Play Console kurulum sihirbazı adım adım
///      gösterir).
///
/// ID girilene kadar bu servis tüm çağrılarda sessizce no-op çalışır —
/// uygulama Play Games olmadan da tamamen sorunsuz çalışmaya devam eder.
/// Bu dosya `games_services` paketinin API'sine göre yazıldı; paket
/// sürümü güncellenirse (`flutter pub get` sonrası) derleme hatası
/// çıkarsa yalnız bu dosyanın güncellenmesi yeterlidir.
class PlayGamesService {
  PlayGamesService._();
  static final PlayGamesService instance = PlayGamesService._();

  bool _signedIn = false;
  bool get isSignedIn => _signedIn;

  /// Her hızlı oyun için Play Console'da oluşturulacak liderlik tablosu ID'si.
  /// Boş string = henüz yapılandırılmadı → o oyun için skor gönderilmez.
  static const Map<String, String> _leaderboardIds = {
    'snake': '', // TODO: Play Console'dan CgkI... ID'sini yapıştır
    '2048': '', // TODO
    'reflex': '', // TODO
  };

  /// Başarım ID eşlemesi (AchievementDef.id -> Play Games achievement ID).
  static const Map<String, String> _achievementIds = {
    // TODO: Play Console'da oluşturulan başarım ID'leriyle doldur.
    // 'first_step': 'CgkI...',
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
    final leaderboardId = _leaderboardIds[gameId];
    if (leaderboardId == null || leaderboardId.isEmpty) return;
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
    final leaderboardId = _leaderboardIds[gameId];
    if (leaderboardId == null || leaderboardId.isEmpty) return;
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
