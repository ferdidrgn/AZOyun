import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  // Reklam birimlerini buraya tanımlıyoruz
  static String get bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-5779807348211992/4555290310';

  static String get interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-5779807348211992/6241661981';

  static String get rewardedAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-5779807348211992/8336524049';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // --- REKLAMLARI YÜKLEME FONKSİYONLARI ---
  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => _interstitialAd = null,
      ),
    );
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) => _rewardedAd = null,
      ),
    );
  }

  // --- REKLAMLARI GÖSTERME FONKSİYONLARI ---
  void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      loadInterstitial(); // Sonraki için yükle
    }
  }

  void showRewarded(Function onReward) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onReward(); // Ödülü ver
        },
      );
      _rewardedAd = null;
      loadRewarded(); // Sonraki için yükle
    }
  }
}
