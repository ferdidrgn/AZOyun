import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize    adSize;
  final EdgeInsets padding;

  const BannerAdWidget({
    super.key,
    this.adSize  = AdSize.banner,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded   = false;
  bool _disposed = false;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    if (!AdService.instance.isInitialized || !AdService.instance.adsEnabled) return;
    _ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size:     widget.adSize,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (_disposed) { _ad?.dispose(); return; }
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted && !_disposed) _load();
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() { _disposed = true; _ad?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null || !AdService.instance.adsEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: widget.padding,
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: SizedBox(
        width:  _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child:  AdWidget(ad: _ad!),
      ),
    );
  }
}

class AdaptiveBannerAdWidget extends StatefulWidget {
  final EdgeInsets padding;
  const AdaptiveBannerAdWidget(
      {super.key, this.padding = const EdgeInsets.all(8)});

  @override
  State<AdaptiveBannerAdWidget> createState() =>
      _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState
    extends State<AdaptiveBannerAdWidget> {
  BannerAd? _ad;
  bool _loaded   = false;
  bool _disposed = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!AdService.instance.isInitialized ||
        !AdService.instance.adsEnabled) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted || _disposed) return;

    final width = MediaQuery.of(context).size.width.toInt();
    final size  = await AdSize
        .getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted || _disposed) return;

    _ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size:     size,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (_disposed) { _ad?.dispose(); return; }
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() { _disposed = true; _ad?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null || !AdService.instance.adsEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: widget.padding,
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: SizedBox(
        width:  _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child:  AdWidget(ad: _ad!),
      ),
    );
  }
}
