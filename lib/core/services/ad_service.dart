import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

/// Single ad service — replaces both AdManager and old AdService.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized  = false;
  bool _adsEnabled   = true;
  int  _sessionAds   = 0;

  static const _gamesBeforeInterstitial = 5;
  static const _maxAdsPerSession        = 8;

  InterstitialAd? _interstitial;
  RewardedAd?     _rewarded;
  bool _interstitialReady = false;
  bool _rewardedReady     = false;

  // ── Ad unit IDs ───────────────────────────────────────────────────────────

  static String get _bannerAndroid =>
      kDebugMode ? 'ca-app-pub-3940256099942544/6300978111'
                 : 'ca-app-pub-5779807348211992/4555290310';

  static String get _bannerIos =>
      kDebugMode ? 'ca-app-pub-3940256099942544/2934735716'
                 : 'YOUR_IOS_BANNER_ID';

  static String get _interstitialAndroid =>
      kDebugMode ? 'ca-app-pub-3940256099942544/1033173712'
                 : 'ca-app-pub-5779807348211992/8336524049';

  static String get _interstitialIos =>
      kDebugMode ? 'ca-app-pub-3940256099942544/4411468910'
                 : 'YOUR_IOS_INTERSTITIAL_ID';

  static String get _rewardedAndroid =>
      kDebugMode ? 'ca-app-pub-3940256099942544/5224354917'
                 : 'ca-app-pub-5779807348211992/6241661981';

  static String get _rewardedIos =>
      kDebugMode ? 'ca-app-pub-3940256099942544/1712485313'
                 : 'YOUR_IOS_REWARDED_ID';

  static String get bannerAdUnitId  =>
      Platform.isAndroid ? _bannerAndroid  : _bannerIos;

  static String get interstitialAdUnitId =>
      Platform.isAndroid ? _interstitialAndroid : _interstitialIos;

  static String get rewardedAdUnitId =>
      Platform.isAndroid ? _rewardedAndroid : _rewardedIos;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
      debugPrint('[AdService] initialized');
    } catch (e) {
      debugPrint('[AdService] init failed: $e');
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialReady = true;
          _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              ad.dispose();
              _interstitialReady = false;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (_, __) {
              ad.dispose();
              _interstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialReady = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedReady = true;
          _rewarded!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              ad.dispose();
              _rewardedReady = false;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (_, __) {
              ad.dispose();
              _rewardedReady = false;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedReady = false;
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  // ── Hooks ─────────────────────────────────────────────────────────────────

  Future<void> onGameEnter() =>
      StorageService.instance.incrementGameEnterCount();

  Future<void> onGameEnd() async {
    if (!_initialized || !_adsEnabled) return;
    if (_sessionAds >= _maxAdsPerSession) return;
    final count = await StorageService.instance.getGameEnterCount();
    if (count % _gamesBeforeInterstitial == 0 &&
        _interstitialReady &&
        _interstitial != null) {
      _sessionAds++;
      _interstitial!.show();
      _interstitialReady = false;
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isInitialized => _initialized;
  bool get adsEnabled    => _adsEnabled;
  bool get rewardedReady => _rewardedReady;

  void disableAds() => _adsEnabled = false;
  void enableAds()  => _adsEnabled = true;
  void resetSession() => _sessionAds = 0;

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
