import 'package:flutter/material.dart';

import '../../core/services/app_strings.dart';
import '../../core/services/language_service.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(t('language_title'))),
    body: ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final current = LanguageService.instance.language;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile(context, label: t('language_tr'), flag: '🇹🇷', selected: current == AppLanguage.tr, onTap: () => LanguageService.instance.setLanguage(AppLanguage.tr)),
            _tile(context, label: t('language_en'), flag: '🇬🇧', selected: current == AppLanguage.en, onTap: () => LanguageService.instance.setLanguage(AppLanguage.en)),
          ],
        );
      },
    ),
  );

  Widget _tile(
    BuildContext context, {
    required String label,
    required String flag,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Text(flag, style: const TextStyle(fontSize: 24)),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: selected ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null,
          onTap: onTap,
        ),
      );
}
