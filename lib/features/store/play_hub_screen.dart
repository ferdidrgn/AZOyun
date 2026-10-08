import 'package:flutter/material.dart';

import '../../core/services/cosmetic_service.dart';
import '../../core/services/iap_service.dart';
import '../../core/services/play_games_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';

class PlayHubScreen extends StatefulWidget {
  const PlayHubScreen({super.key});

  @override
  State<PlayHubScreen> createState() => _PlayHubScreenState();
}

class _PlayHubScreenState extends State<PlayHubScreen> {
  String? _busyId;
  bool _playBusy = false;

  static const _catalog = [
    (IAPService.coinsSmallId, '250 coin', 'Kozmetik masa örtüsü için. Oyun gücü vermez.'),
    (IAPService.coinsMediumId, '800 coin', 'Aynı coin, daha büyük paket.'),
    (IAPService.removeAdsId, 'Reklamları kapat', 'Banner ve geçiş reklamları kalıcı kapanır.'),
    (IAPService.premium6mId, '6 ay reklamsız', 'Süre bitince reklamlar geri gelir.'),
    (IAPService.donationSmallId, 'Kahve ısmarla', 'Gönüllü destek. Oyun içi etkisi yok.'),
  ];

  Future<void> _buy(String id) async {
    setState(() => _busyId = id);
    final started = await IAPService.instance.buy(id);
    if (!mounted) return;
    setState(() => _busyId = null);
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ürün Play Console listesinde yok.')),
      );
    }
  }

  Future<void> _play(Future<void> Function() action) async {
    setState(() => _playBusy = true);
    await action();
    if (!mounted) return;
    setState(() => _playBusy = false);
    if (!PlayGamesService.instance.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Play Games oturumu açılmadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FeltBackdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              IAPService.instance,
              ProfileService.instance,
              CosmeticService.instance,
              PlayGamesService.instance,
            ]),
            builder: (context, _) {
              final coins = ProfileService.instance.profile.coins;
              final play = PlayGamesService.instance;
              final iap = IAPService.instance;
              return ListView(
                padding: const EdgeInsets.fromLTRB(AZSpacing.md, AZSpacing.md, AZSpacing.md, AZSpacing.xl),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Geri',
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: palette.ink),
                      ),
                      Expanded(child: Text('Play', style: feltDisplay(palette.ink, 32))),
                    ],
                  ),
                  Text(
                    'Google Play Games ve Play satın alma. Coin yalnızca masa örtüsü alır.',
                    style: feltUi(palette.muted, 14),
                  ),
                  const SizedBox(height: AZSpacing.lg),
                  Text('Play Games', style: feltUi(palette.ink, 18, weight: FontWeight.w700)),
                  const SizedBox(height: AZSpacing.sm),
                  Text(
                    play.isSignedIn ? 'Hesap bağlı. Skorlar Skorboard tablosuna gider.' : 'Henüz bağlı değil.',
                    style: feltUi(palette.muted, 14),
                  ),
                  const SizedBox(height: AZSpacing.sm),
                  _action(
                    label: play.isSignedIn ? 'Liderlik tablosu' : 'Play Games bağla',
                    busy: _playBusy,
                    onPressed: () => _play(
                      play.isSignedIn
                          ? () => play.showLeaderboard('skor')
                          : play.signIn,
                    ),
                  ),
                  const SizedBox(height: AZSpacing.sm),
                  _action(
                    label: 'Başarımlar',
                    busy: _playBusy,
                    onPressed: () => _play(play.showAchievements),
                  ),
                  const SizedBox(height: AZSpacing.lg),
                  Text('Coin $coins', style: feltUi(palette.ink, 18, weight: FontWeight.w700)),
                  const SizedBox(height: AZSpacing.sm),
                  Text('Masa örtüsü', style: feltUi(palette.muted, 14)),
                  const SizedBox(height: AZSpacing.sm),
                  for (final cloth in kTableCloths)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AZSpacing.sm),
                      child: _ClothTile(cloth: cloth, coins: coins),
                    ),
                  const SizedBox(height: AZSpacing.md),
                  Text('Play ürünleri', style: feltUi(palette.ink, 18, weight: FontWeight.w700)),
                  const SizedBox(height: AZSpacing.sm),
                  if (!iap.available)
                    Text(
                      'Bu cihazda Play Billing yok. Satın alma Android mağaza sürümünde açılır.',
                      style: feltUi(palette.muted, 14),
                    ),
                  for (final item in _catalog)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AZSpacing.sm),
                      child: _ProductTile(
                        title: item.$2,
                        detail: item.$3,
                        price: iap.productById(item.$1)?.price ?? item.$1,
                        busy: _busyId == item.$1,
                        onBuy: iap.productById(item.$1) == null ? null : () => _buy(item.$1),
                      ),
                    ),
                  const SizedBox(height: AZSpacing.sm),
                  _action(
                    label: 'Satın almaları geri yükle',
                    busy: false,
                    onPressed: iap.restorePurchases,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _action({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: FeltColors.felt,
          foregroundColor: FeltColors.ivory,
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: FeltColors.ivory),
              )
            : Text(label),
      ),
    );
  }
}

class _ClothTile extends StatelessWidget {
  const _ClothTile({required this.cloth, required this.coins});

  final TableCloth cloth;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final owned = CosmeticService.instance.owned.contains(cloth.id);
    final equipped = CosmeticService.instance.equippedId == cloth.id;
    final afford = canAffordCloth(coins: coins, cost: cloth.cost, owned: owned);
    final label = equipped
        ? 'Takılı'
        : owned
            ? 'Giy'
            : '${cloth.cost} coin';
    return Material(
      color: FeltPalette.of(context).surface,
      borderRadius: BorderRadius.circular(AZRadius.md),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AZRadius.sm),
            gradient: LinearGradient(colors: [cloth.top, cloth.bottom]),
          ),
        ),
        title: Text(cloth.title),
        subtitle: Text(owned ? 'Sende var' : 'Coin ile alınır'),
        trailing: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: equipped || !afford
                ? null
                : () async {
                    final ok = await CosmeticService.instance.choose(cloth.id);
                    if (!context.mounted || ok) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coin yetmiyor.')),
                    );
                  },
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.title,
    required this.detail,
    required this.price,
    required this.busy,
    required this.onBuy,
  });

  final String title;
  final String detail;
  final String price;
  final bool busy;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FeltPalette.of(context).surface,
      borderRadius: BorderRadius.circular(AZRadius.md),
      child: ListTile(
        title: Text(title),
        subtitle: Text('$detail\n$price'),
        isThreeLine: true,
        trailing: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: busy ? null : onBuy,
            child: Text(onBuy == null ? 'Yok' : 'Al'),
          ),
        ),
      ),
    );
  }
}
