import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 📢 Reklam yönetici servisi - SAYAÇ KONTROLLÜ
class AdManager {
  static final AdManager _instance = AdManager._internal();

  factory AdManager() => _instance;

  AdManager._internal();

  bool _isInitialized = false;
  bool _showAds = true;

  // Reklam sayaçları
  int _gamesPlayedCount = 0;
  int _adsShownCount = 0;

  // Reklam ayarları - DAHA AZ REKLAM
  static const int _gamesBeforeInterstitial = 5; // Her 5 oyunda bir
  static const int _maxAdsPerSession = 6; // Oturum başına max 6 reklam

  // Interstitial ad instance
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  /// Reklam sistemini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('📢 AdManager initialized');
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('❌ AdManager initialization failed: $e');
    }
  }

  /// Banner ad unit ID
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-5779807348211992/4555290310'
          : 'YOUR_IOS_BANNER_ID';
    }
  }

  /// Interstitial ad unit ID
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-5779807348211992/6241661981'
          : 'YOUR_IOS_INTERSTITIAL_ID';
    }
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
          debugPrint('📢 Interstitial ad loaded');

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

  /// Interstitial reklam göster - SAYAÇ KONTROLLÜ
  Future<void> showInterstitialAd() async {
    if (!_canShowAd()) return;

    _gamesPlayedCount++;

    // SADECE HER 5 OYUNDA BİR GÖSTER
    if (_gamesPlayedCount % _gamesBeforeInterstitial == 0 &&
        _adsShownCount < _maxAdsPerSession &&
        _isInterstitialAdReady &&
        _interstitialAd != null) {
      debugPrint('📢 Showing interstitial (Game: $_gamesPlayedCount)');
      _adsShownCount++;

      await _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      debugPrint(
        '⏭️ Skipping ad (Game: $_gamesPlayedCount / Next at: ${(_gamesPlayedCount ~/ _gamesBeforeInterstitial + 1) * _gamesBeforeInterstitial})',
      );
    }
  }

  /// Oyun başladığında çağır
  void onGameStart() {
    debugPrint('🎮 Game started - total: $_gamesPlayedCount');
  }

  /// Oyun bittiğinde çağır - SAYAÇ KONTROLLÜ
  Future<void> onGameEnd() async {
    await showInterstitialAd();
  }

  /// Reklam gösterilip gösterilemeyeceğini kontrol et
  bool _canShowAd() {
    if (!_isInitialized) {
      debugPrint('⚠️ AdManager not initialized');
      return false;
    }

    if (!_showAds) {
      debugPrint('⚠️ Ads disabled');
      return false;
    }

    if (_adsShownCount >= _maxAdsPerSession) {
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
