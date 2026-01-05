import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';

/// 📢 Banner reklam widget'ı
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsets padding;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // AdManager başlatılmış mı kontrol et
    if (!AdManager().isInitialized) {
      debugPrint('⚠️ AdManager not initialized, skipping banner ad');
      return;
    }

    // Reklamlar kapalı mı kontrol et
    if (!AdManager().areAdsEnabled) {
      debugPrint('⚠️ Ads are disabled, skipping banner ad');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_isDisposed) {
            ad.dispose();
            return;
          }

          if (mounted) setState(() => _isLoaded = true);

          debugPrint('✅ Banner reklam yüklendi');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner reklam hatası: $error');
          ad.dispose();

          if (mounted) setState(() => _isLoaded = false);

          // 60 saniye sonra tekrar dene
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted && !_isDisposed) {
              _loadAd();
            }
          });
        },
        onAdOpened: (ad) {
          debugPrint('📱 Banner reklam açıldı');
        },
        onAdClosed: (ad) {
          debugPrint('📱 Banner reklam kapandı');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reklam yüklenmemiş veya gösterilmeyecekse boş widget döndür
    if (!_isLoaded || _bannerAd == null || !AdManager().areAdsEnabled)
      return const SizedBox.shrink();

    return Container(
      padding: widget.padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

/// 📢 Adaptive banner widget (Ekran genişliğine göre)
class AdaptiveBannerAdWidget extends StatefulWidget {
  final EdgeInsets padding;

  const AdaptiveBannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!AdManager().isInitialized || !AdManager().areAdsEnabled) {
      return;
    }

    // Ekran genişliğini al
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted || _isDisposed) return;

    final size = MediaQuery.of(context).size;
    final adWidth = size.width.toInt();

    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);

    if (adaptiveSize == null) {
      debugPrint('❌ Adaptive banner size alınamadı');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: adaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_isDisposed) {
            ad.dispose();
            return;
          }

          if (mounted) {
            setState(() => _isLoaded = true);
          }
          debugPrint('✅ Adaptive banner yüklendi');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Adaptive banner hatası: $error');
          ad.dispose();

          if (mounted) {
            setState(() => _isLoaded = false);
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null || !AdManager().areAdsEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: widget.padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
