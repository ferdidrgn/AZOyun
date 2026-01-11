import 'dart:async';
import 'dart:io';
import 'package:AZOyun/core/services/secure_local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 📢 Reklam Yönetici - Secure Storage ile
class AdManager {
  static final AdManager _instance = AdManager._internal();

  factory AdManager() => _instance;

  AdManager._internal();

  final SecureLocalStorage _storage = SecureLocalStorage();

  bool _isInitialized = false;
  bool _showAds = true;

  // Reklam sayaçları (memory'de)
  int _sessionAdsShown = 0;

  // Reklam ayarları
  static const int _gamesBeforeInterstitial = 5;
  static const int _maxAdsPerSession = 8;

  // Ad instances
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  /// Reklam sistemini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('📢 AdManager initialized');
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      debugPrint('❌ AdManager initialization failed: $e');
    }
  }

  /// Banner ad unit ID
  static String get bannerAdUnitId {
    if (kDebugMode)
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    else
      return Platform.isAndroid
          ? 'ca-app-pub-5779807348211992/4555290310'
          : 'YOUR_IOS_BANNER_ID';
  }

  /// Interstitial ad unit ID
  static String get interstitialAdUnitId {
    if (kDebugMode)
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    else
      return Platform.isAndroid
          ? 'ca-app-pub-5779807348211992/8336524049'
          : 'YOUR_IOS_INTERSTITIAL_ID';
  }

  /// Rewarded ad unit ID
  static String get rewardedAdUnitId {
    if (kDebugMode)
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    else
      return Platform.isAndroid
          ? 'ca-app-pub-5779807348211992/6241661981'
          : 'YOUR_IOS_REWARDED_ID';
  }

  /// Interstitial ad yükle
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (final ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('✅ Interstitial ad loaded');

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (final ad) {
                  debugPrint('📢 Interstitial ad dismissed');
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (final ad, final error) {
                  debugPrint('❌ Interstitial ad failed: $error');
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (final error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Rewarded ad yükle
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (final ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          debugPrint('✅ Rewarded ad loaded');

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (final ad) {
              debugPrint('📢 Rewarded ad dismissed');
              ad.dispose();
              _isRewardedAdReady = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (final ad, final error) {
              debugPrint('❌ Rewarded ad failed: $error');
              ad.dispose();
              _isRewardedAdReady = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (final error) {
          debugPrint('❌ Rewarded ad failed to load: $error');
          _isRewardedAdReady = false;
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Oyuna giriş - sayaç artır
  Future<void> onGameEnter() async {
    await _storage.incrementGameEnterCount();
    final count = await _storage.getGameEnterCount();
    debugPrint('🎮 Game entered - total: $count');
  }

  /// Oyun bitişi - interstitial göster
  Future<void> onGameEnd() async {
    if (!_canShowAd()) return;

    final gameCount = await _storage.getGameEnterCount();

    // Her 5 oyunda bir göster
    if (gameCount % _gamesBeforeInterstitial == 0 &&
        _sessionAdsShown < _maxAdsPerSession &&
        _isInterstitialAdReady &&
        _interstitialAd != null) {
      debugPrint('📢 Showing interstitial (Game: $gameCount)');
      _sessionAdsShown++;

      await _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      debugPrint(
        '⏭️ Skipping ad (Game: $gameCount / Next at: ${((gameCount ~/ _gamesBeforeInterstitial) + 1) * _gamesBeforeInterstitial})',
      );
    }
  }

  /// Rewarded ad göster (bonus için)
  Future<bool> showRewardedAd({
    required final String roomId,
    required final Function(RewardItem) onRewarded,
  }) async {
    if (!_isInitialized || !_showAds) {
      debugPrint('⚠️ Ads not available');
      return false;
    }

    // Aynı odada daha önce gösterildiyse gösterme
    final alreadyShown = await _storage.isRewardedShownForRoom(roomId);
    if (alreadyShown) {
      debugPrint('⚠️ Rewarded already shown for this room');
      return false;
    }

    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad not ready');
      return false;
    }

    bool rewardGranted = false;

    await _rewardedAd!.show(
      onUserEarnedReward: (final ad, final reward) {
        debugPrint('🎁 User earned reward: ${reward.amount} ${reward.type}');
        onRewarded(reward);
        rewardGranted = true;
      },
    );

    if (rewardGranted) {
      await _storage.markRewardedShownForRoom(roomId);
    }

    _isRewardedAdReady = false;

    return rewardGranted;
  }

  /// Reklam gösterilebilir mi?
  bool _canShowAd() {
    if (!_isInitialized) {
      debugPrint('⚠️ AdManager not initialized');
      return false;
    }

    if (!_showAds) {
      debugPrint('⚠️ Ads disabled');
      return false;
    }

    if (_sessionAdsShown >= _maxAdsPerSession) {
      debugPrint('⚠️ Max ads per session reached');
      return false;
    }

    return true;
  }

  /// Reklamları kapat
  void disableAds() {
    _showAds = false;
    debugPrint('📢 Ads disabled');
  }

  /// Reklamları aç
  void enableAds() {
    _showAds = true;
    debugPrint('📢 Ads enabled');
  }

  /// Session istatistiklerini sıfırla
  void resetSessionStats() {
    _sessionAdsShown = 0;
    debugPrint('📊 Session ad stats reset');
  }

  /// Dispose
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    debugPrint('📢 AdManager disposed');
  }

  // Getters
  bool get isInitialized => _isInitialized;

  bool get areAdsEnabled => _showAds;

  bool get isRewardedAdReady => _isRewardedAdReady;

  int get sessionAdsShown => _sessionAdsShown;
}
