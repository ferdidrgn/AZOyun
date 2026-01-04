import 'package:a_z_oyun/core/services/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
          print('✅ Banner reklam yüklendi');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner reklam hatası: $error');
          ad.dispose();
          setState(() => _isLoaded = false);
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ============================================
// OYUNLARA BANNER EKLEMEK İÇİN ÖRNEK
// ============================================

// quick_math_game.dart içinde kullanım:
/*
import '../../../core/widgets/banner_ad_widget.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(...),
    body: Column(
      children: [
        // OYUN İÇERİĞİ
        Expanded(child: ...),

        // BANNER REKLAM (EN ALTTA)
        const BannerAdWidget(),
      ],
    ),
  );
}
*/