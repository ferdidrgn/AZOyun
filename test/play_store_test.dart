import 'package:AZOyun/core/services/cosmetic_service.dart';
import 'package:AZOyun/core/services/iap_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coin paketleri sabit miktar ekler', () {
    expect(IAPService.instance.coinsFor(IAPService.coinsSmallId), 250);
    expect(IAPService.instance.coinsFor(IAPService.coinsMediumId), 800);
    expect(IAPService.instance.coinsFor(IAPService.removeAdsId), isNull);
  });

  test('masa örtüsü coin yetmezse alınmaz, sahip olunan giyilir', () {
    expect(canAffordCloth(coins: 100, cost: 120, owned: false), isFalse);
    expect(canAffordCloth(coins: 120, cost: 120, owned: false), isTrue);
    expect(canAffordCloth(coins: 0, cost: 180, owned: true), isTrue);
  });
}
