import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/app_strings.dart';
import '../../core/services/iap_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/play_games_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/theme/az_theme.dart';
import 'language_screen.dart';
import 'legal_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _connectingPlayGames = false;
  bool _donating = false;
  bool _buyingPremium = false;
  DateTime? _premiumUntil;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadPremiumStatus();
    IAPService.instance.initialize(onPurchase: _onPurchase);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {
      // Sürüm bilgisi alınamazsa sessizce geç, kritik değil.
    }
  }

  Future<void> _loadPremiumStatus() async {
    final until = await StorageService.instance.getPremiumUntil();
    if (!mounted) return;
    setState(() => _premiumUntil = until);
  }

  void _onPurchase(PurchaseDetails purchase) {
    if (!mounted) return;
    if (purchase.productID == IAPService.donationSmallId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('donate_thanks'))));
    } else if (purchase.productID == IAPService.premium6mId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('premium_thanks'))));
      _loadPremiumStatus();
    }
  }

  Future<void> _connectPlayGames() async {
    setState(() => _connectingPlayGames = true);
    await PlayGamesService.instance.signIn();
    if (!mounted) return;
    setState(() => _connectingPlayGames = false);
  }

  Future<void> _donate() async {
    setState(() => _donating = true);
    final started = await IAPService.instance.buyDonationSmall();
    if (!mounted) return;
    setState(() => _donating = false);
    if (!started) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bağış ürünü şu an kullanılamıyor.')));
    }
  }

  bool get _premiumActive =>
      _premiumUntil != null && _premiumUntil!.isAfter(DateTime.now());

  Future<void> _buyPremium() async {
    setState(() => _buyingPremium = true);
    final started = await IAPService.instance.buyPremium6Months();
    if (!mounted) return;
    setState(() => _buyingPremium = false);
    if (!started) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Premium ürünü şu an kullanılamıyor.')));
    }
  }

  Future<void> _share() async {
    await Share.share(
      'AZ Oyun\'u indir, arkadaşlarınla 31 farklı oyun oyna! 🎮',
      subject: 'AZ Oyun',
    );
  }

  Future<void> _rate() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('settings_title'))),
      body: ListenableBuilder(
        listenable: Listenable.merge([ThemeService.instance, LanguageService.instance]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel(context, t('settings_appearance')),
            _themeCard(context),
            const SizedBox(height: 10),
            _tile(
              context,
              icon: Icons.language_rounded,
              title: t('settings_language'),
              subtitle: LanguageService.instance.language == AppLanguage.tr
                  ? t('language_tr')
                  : t('language_en'),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, t('settings_account')),
            _tile(
              context,
              icon: Icons.notifications_active_rounded,
              title: t('settings_notifications'),
              subtitle: t('settings_notifications_subtitle'),
              onTap: () => NotificationService.instance.openSystemSettings(),
            ),
            _tile(
              context,
              icon: Icons.videogame_asset_rounded,
              title: t('settings_play_games'),
              subtitle: PlayGamesService.instance.isSignedIn
                  ? t('settings_play_games_connected')
                  : t('settings_play_games_connect'),
              trailing: _connectingPlayGames
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : (PlayGamesService.instance.isSignedIn
                      ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                      : null),
              onTap: PlayGamesService.instance.isSignedIn ? null : _connectPlayGames,
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, t('settings_support')),
            _tile(
              context,
              icon: Icons.workspace_premium_rounded,
              title: t('settings_premium'),
              subtitle: _premiumActive
                  ? '${t('settings_premium_active')} · ${_premiumUntil!.difference(DateTime.now()).inDays} gün kaldı'
                  : t('settings_premium_subtitle_buy'),
              trailing: _buyingPremium
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : (_premiumActive ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null),
              onTap: (_buyingPremium || _premiumActive) ? null : _buyPremium,
            ),
            _tile(
              context,
              icon: Icons.coffee_rounded,
              title: t('settings_donate'),
              subtitle: t('settings_donate_subtitle'),
              trailing: _donating
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _donating ? null : _donate,
            ),
            _tile(
              context,
              icon: Icons.share_rounded,
              title: t('settings_share'),
              subtitle: t('settings_share_subtitle'),
              onTap: _share,
            ),
            _tile(
              context,
              icon: Icons.star_rounded,
              title: t('settings_rate'),
              subtitle: t('settings_rate_subtitle'),
              onTap: _rate,
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, t('settings_legal')),
            _tile(
              context,
              icon: Icons.privacy_tip_rounded,
              title: t('settings_privacy'),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            ),
            _tile(
              context,
              icon: Icons.description_rounded,
              title: t('settings_terms'),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
            ),
            const SizedBox(height: 24),
            if (_version.isNotEmpty)
              Center(
                child: Text('${t('settings_version')} $_version',
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
    child: Text(label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.primary)),
  );

  Widget _themeCard(BuildContext context) {
    final options = [
      (AppThemePreference.system, t('settings_theme_system'), Icons.brightness_auto_rounded),
      (AppThemePreference.light, t('settings_theme_light'), Icons.light_mode_rounded),
      (AppThemePreference.dark, t('settings_theme_dark'), Icons.dark_mode_rounded),
    ];
    final isCustom = ThemeService.instance.preference == AppThemePreference.custom;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          Row(
            children: [
              for (final (pref, label, icon) in options)
                Expanded(child: _themeOptionTile(context, pref, label, icon)),
              Expanded(
                child: InkWell(
                  onTap: () => _pickCustomColor(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(children: [
                      isCustom
                          ? CircleAvatar(radius: 12, backgroundColor: ThemeService.instance.customColor)
                          : Icon(Icons.palette_rounded,
                              color: Theme.of(context).hintColor),
                      const SizedBox(height: 6),
                      Text(t('settings_theme_custom'),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
                              color: isCustom
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).hintColor)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _themeOptionTile(BuildContext context, AppThemePreference pref, String label, IconData icon) {
    final selected = ThemeService.instance.preference == pref;
    return InkWell(
      onTap: () => ThemeService.instance.setPreference(pref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomColor(BuildContext context) async {
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('settings_theme_custom_pick')),
        content: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final c in AZTheme.customColorSwatches)
              GestureDetector(
                onTap: () => Navigator.pop(context, c),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: c,
                  child: ThemeService.instance.preference == AppThemePreference.custom &&
                          ThemeService.instance.customColor.value == c.value
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('common_cancel'))),
        ],
      ),
    );
    if (chosen != null) await ThemeService.instance.setCustomColor(chosen);
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
          onTap: onTap,
        ),
      );
}
