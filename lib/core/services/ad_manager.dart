import 'dart:async';
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
  static const int _gamesBeforeInterstitial =
      3; // Her 3 oyunda bir interstitial
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
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android test
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS test
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-5779807348211992/4555290310' // Android prod
          : 'YOUR_IOS_BANNER_ID'; // iOS prod
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
          ? 'ca-app-pub-5779807348211992/6241661981' // Android prod
          : 'YOUR_IOS_INTERSTITIAL_ID'; // iOS prod
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
          ? 'ca-app-pub-5779807348211992/8336524049' // Android prod
          : 'YOUR_IOS_REWARDED_ID'; // iOS prod
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
    if (_gamesPlayedCount % _gamesBeforeInterstitial == 0 &&
        _adsShownCount < _maxAdsPerSession &&
        _isInterstitialAdReady &&
        _interstitialAd != null) {
      debugPrint('📢 Showing interstitial ad (Game: $_gamesPlayedCount)');
      _adsShownCount++;

      await _interstitialAd!.show();
      _isInterstitialAdReady = false;
    }
  }

  /// Rewarded (ödüllü) reklam göster
  Future<bool> showRewardedAd() async {
    if (!_canShowAd()) return false;

    bool rewarded = false;
    final completer = Completer<bool>();

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) async {
          debugPrint('📢 Rewarded ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(rewarded);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Rewarded ad failed to show: $error');
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
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
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Premium reklam mantığı (her 5 oyunda bir)
  Future<void> showPremiumAdIfNeeded({
    required int gameEnterCount,
    required String roomId,
  }) async {
    // Her 5 oyunda bir göster
    if (gameEnterCount % 5 != 0) return;

    debugPrint(
      '💰 PREMIUM AD TRIGGERED (Game: $gameEnterCount, Room: $roomId)',
    );

    // Önce rewarded dene
    final rewardedSuccess = await showRewardedAd();

    if (!rewardedSuccess) {
      // Rewarded yoksa interstitial
      await showInterstitialAd();
    }
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
