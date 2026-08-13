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
        const options = [
          (AppLanguage.tr, 'language_tr', '🇹🇷'),
          (AppLanguage.en, 'language_en', '🇬🇧'),
          (AppLanguage.de, 'language_de', '🇩🇪'),
          (AppLanguage.fr, 'language_fr', '🇫🇷'),
          (AppLanguage.es, 'language_es', '🇪🇸'),
          (AppLanguage.ru, 'language_ru', '🇷🇺'),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (lang, key, flag) in options)
              _tile(context,
                  label: t(key),
                  flag: flag,
                  selected: current == lang,
                  onTap: () => LanguageService.instance.setLanguage(lang)),
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
