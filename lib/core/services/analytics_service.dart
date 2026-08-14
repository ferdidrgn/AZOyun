import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics köprüsü. Kullanıcı davranışını anlamak için: hangi
/// oyunlar ne kadar oynanıyor, satın alma hunisi nerede kırılıyor, dil/tema
/// tercihleri neler vb. Tek bir yerden — [ProfileService.reportGameResult]
/// üzerinden — çağrıldığı için 30+ oyunun tamamı otomatik olarak
/// kapsanıyor; her oyun dosyasına ayrı ayrı analytics kodu eklemeye gerek
/// kalmadı.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get navigatorObserver => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logAppOpen() => _safe(() => _analytics.logAppOpen());

  /// Bir maç bitince çağrılır — [ProfileService.reportGameResult] içinden
  /// tetiklenir, tüm oyunları tek noktadan kapsar.
  Future<void> logGameEnd({required String gameId, required bool won}) => _safe(
        () => _analytics.logEvent(
          name: 'game_end',
          parameters: {'game_id': gameId, 'won': won},
        ),
      );

  Future<void> logLevelUp(int newLevel) =>
      _safe(() => _analytics.logLevelUp(level: newLevel));

  Future<void> logAchievementUnlocked(String achievementId) => _safe(
        () => _analytics.logUnlockAchievement(id: achievementId),
      );

  Future<void> logPurchase({required String productId, required double? value}) => _safe(
        () => _analytics.logEvent(
          name: 'iap_purchase',
          parameters: {'product_id': productId, if (value != null) 'value': value},
        ),
      );

  Future<void> logShare(String contentType) => _safe(
        () => _analytics.logShare(contentType: contentType, itemId: 'app', method: 'share_sheet'),
      );

  Future<void> setLanguage(String languageCode) =>
      _safe(() => _analytics.setUserProperty(name: 'app_language', value: languageCode));

  Future<void> setThemePreference(String preference) =>
      _safe(() => _analytics.setUserProperty(name: 'theme_preference', value: preference));

  /// Firebase çağrıları ağ/izin sorunlarıyla başarısız olabilir — analytics
  /// asla uygulamanın geri kalanını etkilememeli, o yüzden tüm hatalar
  /// sessizce yutuluyor.
  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[AnalyticsService] event gönderilemedi: $e');
    }
  }
}
