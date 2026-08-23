import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

/// Unified ad service — banner, interstitial, rewarded.
/// Debug modda test ID'leri, release'de gerçek ID'ler kullanılır.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized      = false;
  bool _adsEnabled       = true;
  int  _sessionAds       = 0;

  static const _gamesBeforeInterstitial = 5; // kaç oyun sonra interstitial (kullanıcıyı boğmamak için)
  static const _maxAdsPerSession        = 10;

  InterstitialAd? _interstitial;
  RewardedAd?     _rewarded;
  bool _interstitialReady = false;
  bool _rewardedReady     = false;

  // ─────────────────────────────────────────────────────────────────────────
  // AD UNIT IDs
  // ─────────────────────────────────────────────────────────────────────────

  // Banner
  static String get _bannerAndroid =>
      kDebugMode ? 'ca-app-pub-3940256099942544/6300978111'
                 : 'ca-app-pub-5779807348211992/4555290310';

  static String get _bannerIos =>
      kDebugMode ? 'ca-app-pub-3940256099942544/2934735716'
                 : 'YOUR_IOS_BANNER_ID'; // iOS'a geçince değiştir

  // Interstitial
  static String get _interstitialAndroid =>
      kDebugMode ? 'ca-app-pub-3940256099942544/1033173712'
                 : 'ca-app-pub-5779807348211992/8336524049';

  static String get _interstitialIos =>
      kDebugMode ? 'ca-app-pub-3940256099942544/4411468910'
                 : 'YOUR_IOS_INTERSTITIAL_ID';

  // Rewarded
  static String get _rewardedAndroid =>
      kDebugMode ? 'ca-app-pub-3940256099942544/5224354917'
                 : 'ca-app-pub-5779807348211992/6241661981';

  static String get _rewardedIos =>
      kDebugMode ? 'ca-app-pub-3940256099942544/1712485313'
                 : 'YOUR_IOS_REWARDED_ID';

  // `dart:io`'nun `Platform.isAndroid`'i WEB'de derlenmez (dart:io web'de
  // hiç mevcut değil) — bunun yerine her platformda güvenli çalışan
  // `defaultTargetPlatform` kullanılıyor.
  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static String get bannerAdUnitId =>
      _isAndroid ? _bannerAndroid : _bannerIos;

  static String get interstitialAdUnitId =>
      _isAndroid ? _interstitialAndroid : _interstitialIos;

  static String get rewardedAdUnitId =>
      _isAndroid ? _rewardedAndroid : _rewardedIos;

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────

  /// Google Mobile Ads SDK'sı sadece Android/iOS'ta çalışır — Web'de bu
  /// paketin native köprüsü hiç yok, çağrılırsa `MissingPluginException`
  /// fırlatır. Bu yüzden Web'de tüm reklam altyapısı sessizce no-op'tur;
  /// uygulama reklamsız (ve hatasız) çalışmaya devam eder.
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdService] ✅ initialized');
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('[AdService] ❌ init failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INTERSTITIAL
  // ─────────────────────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (!_initialized) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request:  const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial      = ad;
          _interstitialReady = true;
          debugPrint('[AdService] interstitial loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              ad.dispose();
              _interstitial      = null;
              _interstitialReady = false;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (_, err) {
              debugPrint('[AdService] interstitial show failed: $err');
              ad.dispose();
              _interstitial      = null;
              _interstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdService] interstitial load failed: $err');
          _interstitialReady = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Oyun bitişinde çağır — her [_gamesBeforeInterstitial] oyunda 1 kez gösterir.
  Future<void> onGameEnd() async {
    if (!_initialized || !_adsEnabled) return;
    if (_sessionAds >= _maxAdsPerSession) return;

    await StorageService.instance.incrementGameEnterCount();
    final count = await StorageService.instance.getGameEnterCount();

    if (count % _gamesBeforeInterstitial == 0 &&
        _interstitialReady &&
        _interstitial != null) {
      _sessionAds++;
      _interstitial!.show();
      _interstitialReady = false;
      debugPrint('[AdService] interstitial shown (game #$count)');
    }
  }

  /// Doğrudan göstermek istersen kullan (lobby → game geçişinde vb.)
  Future<void> showInterstitialIfReady() async {
    if (!_initialized || !_adsEnabled) return;
    if (!_interstitialReady || _interstitial == null) return;
    if (_sessionAds >= _maxAdsPerSession) return;
    _sessionAds++;
    _interstitial!.show();
    _interstitialReady = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REWARDED
  // ─────────────────────────────────────────────────────────────────────────

  void _loadRewarded() {
    if (!_initialized) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request:  const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded      = ad;
          _rewardedReady = true;
          debugPrint('[AdService] rewarded loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              ad.dispose();
              _rewarded      = null;
              _rewardedReady = false;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (_, err) {
              debugPrint('[AdService] rewarded show failed: $err');
              ad.dispose();
              _rewarded      = null;
              _rewardedReady = false;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdService] rewarded load failed: $err');
          _rewardedReady = false;
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  /// Ödüllü reklam göster.
  /// [onRewarded] callback'i kullanıcı ödülü hak ettiğinde çağrılır.
  Future<void> showRewarded({
    required void Function(RewardItem reward) onRewarded,
    VoidCallback? onNotReady,
  }) async {
    if (!_initialized || !_adsEnabled || !_rewardedReady || _rewarded == null) {
      debugPrint('[AdService] rewarded not ready');
      onNotReady?.call();
      return;
    }
    _rewarded!.show(onUserEarnedReward: (_, reward) {
      debugPrint('[AdService] reward earned: ${reward.type} x${reward.amount}');
      onRewarded(reward);
    });
    _rewardedReady = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS / CONTROLS
  // ─────────────────────────────────────────────────────────────────────────

  bool get isInitialized   => _initialized;
  bool get adsEnabled      => _adsEnabled;
  bool get interstitialReady => _interstitialReady;
  bool get rewardedReady   => _rewardedReady;

  void disableAds()   => _adsEnabled = false;
  void enableAds()    => _adsEnabled = true;
  void resetSession() => _sessionAds = 0;

  /// `main()` içinde `initialize()`'dan hemen sonra çağrılır: daha önce
  /// satın alınmış bir premium süresi hâlâ geçerliyse reklamları kapalı
  /// başlatır (aksi halde her açılışta varsayılan olarak reklamlar açık
  /// başlar).
  Future<void> applyPremiumStateIfActive() async {
    if (await StorageService.instance.isPremiumActive()) {
      disableAds();
      debugPrint('[AdService] premium aktif, reklamlar kapalı başladı');
    }
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
