import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'ad_service.dart';
import 'analytics_service.dart';
import 'storage_service.dart';

/// Uygulama içi satın alma iskeleti.
///
/// Felsefe: "az kazan, çok eğlendir" — burada asla oyun içi avantaj
/// (pay-to-win) satılmaz. Sadece: reklamsız deneyim, kozmetik coin
/// paketleri ve gönüllü destek ürünü.
///
/// ÖNEMLİ: Aşağıdaki ürün ID'leri Google Play Console → Uygulamalar →
/// Uygulama içi ürünler bölümünde oluşturulmalı; ID'ler burada
/// tanımlananlarla birebir eşleşmeli.
class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  static const removeAdsId = 'az_oyun_remove_ads';
  static const coinsSmallId = 'az_oyun_coins_small';
  static const coinsMediumId = 'az_oyun_coins_medium';

  /// Gönüllü bağış ürünü ("Bize kahve ısmarla"). İsim, İngilizce Play
  /// Console listelerinde tanınabilir olsun diye bilinçli olarak
  /// `donation_small` (küçük bağış) şeklinde seçildi.
  static const donationSmallId = 'donation_small';

  /// 6 ay boyunca tüm reklamları (banner + geçiş) kaldıran, tek seferlik
  /// (non-consumable) premium ürün. `removeAdsId` (kalıcı reklamsız) ile
  /// aynı anda var olabilir — kullanıcı istediğini seçer.
  static const premium6mId = 'premium_6m_noads';
  static const _premium6mDuration = Duration(days: 180);

  static const Set<String> productIds = {
    removeAdsId,
    coinsSmallId,
    coinsMediumId,
    donationSmallId,
    premium6mId,
  };

  // `late`: sadece gerçekten kullanıldığında (yani kIsWeb guard'larını
  // geçtikten sonra) resolve edilir — Web'de hiç dokunulmaz.
  late final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> products = [];
  bool available = false;
  bool _initialized = false;

  /// `in_app_purchase` paketi sadece Android/iOS/macOS destekler — Web'de
  /// native mağaza köprüsü hiç yok. Web'de satın alma tamamen
  /// devre dışı: `products` boş kalır, tüm satın alma metodları no-op'tur.
  Future<void> initialize({
    required void Function(PurchaseDetails purchase) onPurchase,
  }) async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    try {
      available = await _iap.isAvailable();
      if (!available) {
        debugPrint('[IAPService] mağaza kullanılamıyor (emülatör/test olabilir)');
        return;
      }
      _sub = _iap.purchaseStream.listen((purchases) {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            if (p.productID == premium6mId) _activatePremium();
            if (p.productID == removeAdsId) AdService.instance.disableAds();
            unawaited(AnalyticsService.instance.logPurchase(
              productId: p.productID,
              value: productById(p.productID)?.rawPrice,
            ));
            onPurchase(p);
          }
          if (p.pendingCompletePurchase) {
            _iap.completePurchase(p);
          }
        }
      }, onError: (e) => debugPrint('[IAPService] purchaseStream hata: $e'));

      final response = await _iap.queryProductDetails(productIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            '[IAPService] Play Console\'da henüz oluşturulmamış ürünler: '
            '${response.notFoundIDs}');
      }
      products = response.productDetails;
    } catch (e) {
      debugPrint('[IAPService] init hatası: $e');
    }
  }

  ProductDetails? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Play Console'da tüketilebilir (consumable) olarak tanımlanmalı — bir
  /// kullanıcı bağışı birden çok kez yapabilsin diye.
  Future<bool> buyDonationSmall() async {
    final product = productById(donationSmallId);
    if (product == null) {
      debugPrint('[IAPService] donation_small ürünü bulunamadı (Play Console\'da oluşturulmamış olabilir)');
      return false;
    }
    await buyConsumable(product);
    return true;
  }

  /// Play Console'da tüketilebilir OLMAYAN (non-consumable) ürün olarak
  /// tanımlanmalı — her satın alma süreyi 6 ay uzatır (bkz. [_activatePremium]).
  Future<bool> buyPremium6Months() async {
    final product = productById(premium6mId);
    if (product == null) {
      debugPrint('[IAPService] $premium6mId ürünü bulunamadı (Play Console\'da oluşturulmamış olabilir)');
      return false;
    }
    await buyNonConsumable(product);
    return true;
  }

  Future<void> _activatePremium() async {
    await StorageService.instance.extendPremium(_premium6mDuration);
    AdService.instance.disableAds();
    debugPrint('[IAPService] premium etkinleştirildi (+${_premium6mDuration.inDays} gün)');
  }

  Future<bool> get isPremiumActive => StorageService.instance.isPremiumActive();

  Future<void> buyConsumable(ProductDetails product) {
    if (kIsWeb) return Future.value();
    return _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> buyNonConsumable(ProductDetails product) {
    if (kIsWeb) return Future.value();
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restorePurchases() {
    if (kIsWeb) return Future.value();
    return _iap.restorePurchases();
  }

  void dispose() => _sub?.cancel();
}
