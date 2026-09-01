import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../theme/az_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STANDARD BANNER
// ─────────────────────────────────────────────────────────────────────────────

/// Sabit boyutlu banner (AdSize.banner = 320×50).
/// Oyun ekranlarının altında kullanılır.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.adSize  = AdSize.banner,
    this.padding = const EdgeInsets.all(4),
  });

  final AdSize     adSize;
  final EdgeInsets padding;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded   = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
          debugPrint('[BannerAd] loaded');
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('[BannerAd] load failed: $err');
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
          // 60 sn sonra tekrar dene
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted && !_disposed) _load();
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _disposed = true;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null || !AdService.instance.adsEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      padding:   widget.padding,
      alignment: Alignment.center,
      color:     Colors.grey.shade100,
      child: SizedBox(
        width:  _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child:  AdWidget(ad: _ad!),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADAPTIVE BANNER
// ─────────────────────────────────────────────────────────────────────────────

/// Ekran genişliğine uyum sağlayan banner.
/// Ana menü ve lobby ekranlarının altında kullanılır.
class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final EdgeInsets padding;

  @override
  State<AdaptiveBannerAdWidget> createState() =>
      _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _ad;
  bool _loaded   = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AdService.instance.isInitialized || !AdService.instance.adsEnabled) return;
    // Widget layout tamamlanmadan önce context boyutuna erişemeyiz
    await Future.delayed(const Duration(milliseconds: 200));
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
          debugPrint('[AdaptiveBanner] loaded');
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('[AdaptiveBanner] load failed: $err');
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
  void dispose() {
    _disposed = true;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null || !AdService.instance.adsEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      padding:   widget.padding,
      alignment: Alignment.center,
      color:     Colors.grey.shade100,
      child: SizedBox(
        width:  _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child:  AdWidget(ad: _ad!),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARDED AD BUTTON
// ─────────────────────────────────────────────────────────────────────────────

/// Ödüllü reklam izle butonu.
/// Oyun içinde "ekstra ipucu" veya "devam et" için kullanılır.
///
/// Örnek kullanım:
/// ```dart
/// RewardedAdButton(
///   label: 'Ekstra İpucu Al',
///   icon: Icons.lightbulb_outline,
///   onRewarded: (_) => setState(() => _extraHint = true),
/// )
/// ```
class RewardedAdButton extends StatelessWidget {
  const RewardedAdButton({
    super.key,
    required this.label,
    required this.onRewarded,
    this.icon         = Icons.play_circle_outline_rounded,
    this.color        = AZColors.purple,
    this.onNotReady,
  });

  final String        label;
  final IconData      icon;
  final Color         color;
  final void Function(RewardItem reward) onRewarded;
  final VoidCallback? onNotReady;

  @override
  Widget build(BuildContext context) {
    final ready = AdService.instance.rewardedReady;
    return ElevatedButton.icon(
      onPressed: ready
          ? () => AdService.instance.showRewarded(
                onRewarded: onRewarded,
                onNotReady: onNotReady ??
                    () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reklam henüz hazır değil, lütfen bekleyin...')),
                        ),
              )
          : null,
      icon:  Icon(icon, size: 20),
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color:        Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('📺 Reklam İzle',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
      style: ElevatedButton.styleFrom(
        backgroundColor: ready ? color : Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding:         const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
