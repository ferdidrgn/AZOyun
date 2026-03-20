import 'dart:async';
import 'dart:io';
import 'package:AZOyun/core/services/secure_local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 📢 Reklam Yönetici
class AdManager {
  static final AdManager _instance = AdManager._internal();

  factory AdManager() => _instance;

  AdManager._internal();

  final SecureLocalStorage _storage = SecureLocalStorage();

  bool _isInitialized = false;
  bool _showAds = true;
  int _sessionAdsShown = 0;

  static const int _gamesBeforeInterstitial = 5;
  static const int _maxAdsPerSession = 8;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

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

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-5779807348211992/4555290310'
        : 'YOUR_IOS_BANNER_ID';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-5779807348211992/8336524049'
        : 'YOUR_IOS_INTERSTITIAL_ID';
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-5779807348211992/6241661981'
        : 'YOUR_IOS_REWARDED_ID';
  }

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

  Future<void> onGameEnter() async {
    await _storage.incrementGameEnterCount();
    final count = await _storage.getGameEnterCount();
    debugPrint('🎮 Game entered - total: $count');
  }

  Future<void> onGameEnd() async {
    if (!_canShowAd()) return;

    final gameCount = await _storage.getGameEnterCount();

    if (gameCount % _gamesBeforeInterstitial == 0 &&
        _sessionAdsShown < _maxAdsPerSession &&
        _isInterstitialAdReady &&
        _interstitialAd != null) {
      debugPrint('📢 Showing interstitial (Game: $gameCount)');
      _sessionAdsShown++;
      // FIX: show() void döndürüyor, await kaldırıldı
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    }
  }

  Future<bool> showRewardedAd({
    required final String roomId,
    required final Function(RewardItem) onRewarded,
  }) async {
    if (!_isInitialized || !_showAds) return false;

    final alreadyShown = await _storage.isRewardedShownForRoom(roomId);
    if (alreadyShown) return false;

    if (!_isRewardedAdReady || _rewardedAd == null) return false;

    bool rewardGranted = false;

    // FIX: show() void döndürüyor, await kaldırıldı
    _rewardedAd!.show(
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

  bool _canShowAd() {
    if (!_isInitialized) return false;
    if (!_showAds) return false;
    if (_sessionAdsShown >= _maxAdsPerSession) return false;
    return true;
  }

  void disableAds() => _showAds = false;
  void enableAds() => _showAds = true;
  void resetSessionStats() => _sessionAdsShown = 0;

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }

  bool get isInitialized => _isInitialized;
  bool get areAdsEnabled => _showAds;
  bool get isRewardedAdReady => _isRewardedAdReady;
  int get sessionAdsShown => _sessionAdsShown;
}
