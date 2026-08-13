import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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

  static const Set<String> productIds = {
    removeAdsId,
    coinsSmallId,
    coinsMediumId,
    donationSmallId,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> products = [];
  bool available = false;
  bool _initialized = false;

  Future<void> initialize({
    required void Function(PurchaseDetails purchase) onPurchase,
  }) async {
    if (_initialized) return;
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

  Future<void> buyConsumable(ProductDetails product) =>
      _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));

  Future<void> buyNonConsumable(ProductDetails product) => _iap
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  Future<void> restorePurchases() => _iap.restorePurchases();

  void dispose() => _sub?.cancel();
}
