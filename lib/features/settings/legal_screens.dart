import 'package:flutter/material.dart';

import '../../core/services/app_strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GİZLİLİK POLİTİKASI + KULLANIM ŞARTLARI
//
// Metinler app_strings.dart içinde 'privacy_body' / 'terms_body' anahtarlarıyla
// tutulur (şu an TR + EN dolu, diğer diller TR'ye düşer). Google AdMob/AdSense,
// Firebase (Analytics, Crashlytics, Realtime Database, Cloud Messaging),
// Google Play Games Services ve uygulama içi satın alma (in_app_purchase) ile
// uyumlu, AZ Oyun'un gerçek veri işleme pratiğine göre yazılmıştır. Web sürümü
// (azoyun.web.app/privacy-policy.html ve /terms.html) ile aynı içeriği taşır —
// biri değişirse diğeri de güncellenmelidir.
// ═══════════════════════════════════════════════════════════════════════════

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalScreen(title: t('privacy_title'), body: t('privacy_body'));
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalScreen(title: t('terms_title'), body: t('terms_body'));
}

class _LegalScreen extends StatelessWidget {
  const _LegalScreen({required this.title, required this.body});

  final String title, body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: const TextStyle(fontSize: 14, height: 1.7)),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
