import 'package:a_z_oyun/core/services/secure_local_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// 📢 Reklam yönetici servisi
///
/// Google AdMob entegrasyonu için hazır yapı
/// Şimdilik mock implementasyon, gerçek AdMob eklenebilir
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 📢 Reklam yönetici servisi - Google AdMob
class AdManager {
  static final AdManager _instance = AdManager._internal();

  factory AdManager() => _instance;

  AdManager._internal();

  bool _isInitialized = false;
  bool _showAds = true;

  // Reklam sayaçları
  int _gamesPlayedCount = 0;
  int _adsShownCount = 0;

  // Reklam ayarları
  static const int _gamesBeforeAd = 3; // Her 3 oyunda bir reklam
  static const int _maxAdsPerSession = 10; // Oturum başına max reklam

  // Interstitial ad instance
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  /// Reklam sistemini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('📢 AdManager initialized with Google AdMob');

      // İlk interstitial ad'ı yükle
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('❌ AdManager initialization failed: $e');
    }
  }

  /// Banner ad unit ID
  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Test ID'leri
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android test
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS test
    } else {
      // TODO: Gerçek AdMob ID'lerini buraya ekle
      return Platform.isAndroid
          ? 'YOUR_ANDROID_BANNER_ID'
          : 'YOUR_IOS_BANNER_ID';
    }
  }

  /// Interstitial ad unit ID
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Android test
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS test
    } else {
      return Platform.isAndroid
          ? 'YOUR_ANDROID_INTERSTITIAL_ID'
          : 'YOUR_IOS_INTERSTITIAL_ID';
    }
  }

  /// Rewarded ad unit ID
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Android test
          : 'ca-app-pub-3940256099942544/1712485313'; // iOS test
    } else {
      return Platform.isAndroid
          ? 'YOUR_ANDROID_REWARDED_ID'
          : 'YOUR_IOS_REWARDED_ID';
    }
  }

  /// Interstitial ad yükle
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('📢 Interstitial ad loaded');

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  debugPrint('📢 Interstitial ad dismissed');
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd(); // Yeni ad yükle
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('❌ Interstitial ad failed to show: $error');
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          // 30 saniye sonra tekrar dene
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Interstitial (tam ekran) reklam göster
  Future<void> showInterstitialAd() async {
    if (!_canShowAd()) return;

    _gamesPlayedCount++;

    // Her X oyunda bir reklam göster
    if (_gamesPlayedCount % _gamesBeforeAd == 0 &&
        _adsShownCount < _maxAdsPerSession &&
        _isInterstitialAdReady &&
        _interstitialAd != null) {
      debugPrint('📢 Showing interstitial ad');
      _adsShownCount++;

      await _interstitialAd!.show();
      _isInterstitialAdReady = false;
    }
  }

  /// Rewarded (ödüllü) reklam göster
  Future<bool> showRewardedAd() async {
    if (!_canShowAd()) return false;

    bool rewarded = false;

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) async {
          debugPrint('📢 Rewarded ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Rewarded ad failed to show: $error');
              ad.dispose();
            },
          );

          await ad.show(
            onUserEarnedReward: (ad, reward) {
              debugPrint(
                '🎁 User earned reward: ${reward.amount} ${reward.type}',
              );
              rewarded = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded ad failed to load: $error');
        },
      ),
    );

    return rewarded;
  }

  /// Oyun bittiğinde çağır
  Future<void> onGameEnd() async {
    await showInterstitialAd();
  }

  /// Oyun başladığında çağır
  void onGameStart() {
    debugPrint('🎮 Game started - total games: $_gamesPlayedCount');
  }

  /// Reklam gösterilip gösterilemeyeceğini kontrol et
  bool _canShowAd() {
    if (!_isInitialized) {
      debugPrint('⚠️ AdManager not initialized');
      return false;
    }

    if (!_showAds) {
      debugPrint('⚠️ Ads are disabled');
      return false;
    }

    if (_adsShownCount >= _maxAdsPerSession) {
      debugPrint('⚠️ Max ads per session reached');
      return false;
    }

    return true;
  }

  Future<void> showPremiumAdIfNeeded({
    required int gameEnterCount,
    required String roomId,
  }) async {
    final storage = SecureLocalStorage();

    if (gameEnterCount % 5 != 0) return;

    final alreadyShown = await storage.isRewardedShownForRoom(roomId);

    if (alreadyShown) return;

    debugPrint('💰 PREMIUM AD TRIGGERED');

    // Önce ödüllü dene
    final rewardedSuccess = await showRewardedAd();

    if (!rewardedSuccess) {
      // Ödüllü yoksa interstitial
      await showInterstitialAd();
    }

    await storage.markRewardedShownForRoom(roomId);
  }

  /// Reklamları kapat (premium kullanıcılar için)
  void disableAds() {
    _showAds = false;
    debugPrint('📢 Ads disabled');
  }

  /// Reklamları aç
  void enableAds() {
    _showAds = true;
    debugPrint('📢 Ads enabled');
  }

  /// İstatistikleri sıfırla
  void resetStats() {
    _gamesPlayedCount = 0;
    _adsShownCount = 0;
    debugPrint('📊 Ad stats reset');
  }

  /// Oturum bittiğinde çağır
  void dispose() {
    _interstitialAd?.dispose();
    debugPrint('📢 AdManager disposed');
  }

  // Getter'lar
  bool get isInitialized => _isInitialized;

  bool get areAdsEnabled => _showAds;

  int get gamesPlayed => _gamesPlayedCount;

  int get adsShown => _adsShownCount;
}

/// 📢 AdMob entegrasyonu için ID'ler
class AdIds {
  // Test ID'leri
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // TODO: Gerçek AdMob ID'lerini buraya ekle
  // Prodüksiyon ID'leri
  static const String prodBanner = 'ca-app-pub-5779807348211992/4555290310';
  static const String prodInterstitial =
      'ca-app-pub-5779807348211992/6241661981';
  static const String prodRewarded = 'ca-app-pub-5779807348211992/8336524049';

  // Ortama göre ID seç
  static String get bannerId => kDebugMode ? testBanner : prodBanner;

  static String get interstitialId =>
      kDebugMode ? testInterstitial : prodInterstitial;

  static String get rewardedId => kDebugMode ? testRewarded : prodRewarded;

  AdIds._();
}
