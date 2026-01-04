import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';

class AdHelper {
  // 1. BANNER WIDGET (Global Kullanım)
  static Widget bannerAdWidget() {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: 50,
      child: AdWidget(
        ad: BannerAd(
          adUnitId: AdManager.bannerAdUnitId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
              print('Banner reklam yüklenemedi: $error');
            },
          ),
        )..load(),
      ),
    );
  }

  // 2. GEÇİŞ REKLAMI TETİKLEYİCİ
  static void showInterstitial(AdManager manager) {
    manager.showInterstitial();
  }

  // 3. ÖDÜLLÜ REKLAM TETİKLEYİCİ
  static void showRewarded(AdManager manager, VoidCallback onReward) {
    manager.showRewarded(onReward);
  }
}
