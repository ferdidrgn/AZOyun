import 'dart:async';

<<<<<<< Updated upstream
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

=======
import 'package:flutter/material.dart';

import 'football_catalog_repository.dart';
>>>>>>> Stashed changes
import 'football_chemistry_rules.dart';

class FootballChemistryScreen extends StatefulWidget {
  const FootballChemistryScreen({super.key});

  @override
  State<FootballChemistryScreen> createState() =>
      _FootballChemistryScreenState();
}

class _FootballChemistryScreenState extends State<FootballChemistryScreen> {
  static const _formation = <String>[
    'GK',
    'DF',
    'DF',
    'DF',
    'DF',
    'MF',
    'MF',
    'MF',
    'FW',
    'FW',
    'FW',
  ];

  final _search = TextEditingController();
  final Map<int, ChemistryPlayer> _squad = {};
  List<ChemistryPlayer> _catalog = const [];
  int _activeSlot = 0;
  bool _loading = true;
  String? _error;
  String _datasetVersion = '—';
<<<<<<< Updated upstream
=======
  String _datasetSource = '';
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

<<<<<<< Updated upstream
  List<String> _strings(Object? raw) {
=======
  List<String> _positionValues(Object? raw) {
>>>>>>> Stashed changes
    final values = raw is Iterable
        ? raw
        : raw is Map
            ? raw.values
            : const [];
<<<<<<< Updated upstream
    return values.whereType<String>().toList(growable: false);
=======
    return values
        .map((value) {
          if (value is String) return value;
          if (value is Map) {
            final id = value['id']?.toString();
            final label = value['label']?.toString();
            return [if (id != null) id, if (label != null) label].join(' ');
          }
          return '';
        })
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _normalizePlayerName(String value) {
    var normalized = value.toLowerCase();
    const replacements = {
      'ı': 'i',
      'İ': 'i',
      'ş': 's',
      'ğ': 'g',
      'ü': 'u',
      'ö': 'o',
      'ç': 'c',
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ñ': 'n',
      'ý': 'y',
      'æ': 'ae',
      'œ': 'oe',
      'ø': 'o',
      'ß': 'ss',
    };
    replacements
        .forEach((from, to) => normalized = normalized.replaceAll(from, to));
    return normalized
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizePosition(String value) => _normalizePlayerName(value);

  Set<String> _positionGroups(String rawPosition) {
    final position = ' ${_normalizePosition(rawPosition)} ';
    final groups = <String>{};
    bool hasAny(Iterable<String> aliases) => aliases.any((alias) {
          final normalized = _normalizePosition(alias);
          return position.contains(' $normalized ');
        });

    if (hasAny(const [
      'GK',
      'GKP',
      'goalkeeper',
      'goal keeper',
      'goalie',
      'keeper',
      'kaleci',
      'portero',
      'gardien de but',
    ])) {
      groups.add('GK');
    }
    if (hasAny(const [
      'DF',
      'DEF',
      'D',
      'CB',
      'LCB',
      'RCB',
      'LB',
      'RB',
      'LWB',
      'RWB',
      'defender',
      'defence',
      'defense',
      'centre back',
      'center back',
      'full back',
      'fullback',
      'wing back',
      'wingback',
      'bek',
      'defans',
      'defensa',
      'defenseur',
      'lateral',
    ])) {
      groups.add('DF');
    }
    if (hasAny(const [
      'MF',
      'MID',
      'M',
      'CM',
      'CDM',
      'DM',
      'CAM',
      'AM',
      'LM',
      'RM',
      'midfielder',
      'midfield',
      'defensive midfielder',
      'central midfielder',
      'attacking midfielder',
      'orta saha',
      'mediocampista',
      'milieu de terrain',
    ])) {
      groups.add('MF');
    }
    if (hasAny(const [
      'FW',
      'FWD',
      'ST',
      'CF',
      'SS',
      'LW',
      'RW',
      'LF',
      'RF',
      'forward',
      'striker',
      'winger',
      'attacker',
      'centre forward',
      'center forward',
      'santrafor',
      'forvet',
      'hucumcu',
      'delantero',
      'atacante',
      'ailier',
    ])) {
      groups.add('FW');
    }
    return groups;
>>>>>>> Stashed changes
  }

  List<FootballCareerSpell> _careers(Object? raw) => _maps(raw)
      .map((spell) => FootballCareerSpell(
            clubId: '${spell['id'] ?? ''}',
            clubName: '${spell['label'] ?? spell['id'] ?? ''}',
            startYear: spell['startYear'] is num
                ? (spell['startYear'] as num).toInt()
                : null,
            endYear: spell['endYear'] is num
                ? (spell['endYear'] as num).toInt()
                : null,
          ))
      .where((spell) => spell.clubId.isNotEmpty)
      .toList();

  Future<void> _load() async {
<<<<<<< Updated upstream
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('footballCatalog/current')
          .get()
          .timeout(const Duration(seconds: 12));
      final root = snapshot.value;
      if (root is! Map)
        throw StateError('Dinamik futbol kataloğu yayınlanmadı.');
      final data = Map<String, dynamic>.from(root);
=======
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final loaded = await FootballCatalogRepository.load();
      final data = loaded.data;
>>>>>>> Stashed changes
      final catalog = _maps(data['players'])
          .map((raw) {
            return ChemistryPlayer(
              id: '${raw['id'] ?? ''}',
              name: '${raw['name'] ?? ''}',
<<<<<<< Updated upstream
              position: _strings(raw['positions']).join(', '),
=======
              position: _positionValues(raw['positions']).join(', '),
>>>>>>> Stashed changes
              careers: _careers(raw['careers']),
              sportNationalityId: raw['sportNationalityId']?.toString(),
            );
          })
          .where((player) => player.id.isNotEmpty && player.name.isNotEmpty)
          .toList();
      if (catalog.isEmpty) throw StateError('Oyuncu kataloğu boş.');
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _datasetVersion = '${data['datasetVersion'] ?? 'unknown'}';
<<<<<<< Updated upstream
=======
        _datasetSource = loaded.sourceLabel;
>>>>>>> Stashed changes
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  bool _fits(ChemistryPlayer player, String role) {
    if (player.position.isEmpty) return true;
<<<<<<< Updated upstream
    final position = player.position.toLowerCase();
    return switch (role) {
      'GK' => position.contains('goalkeeper'),
      'DF' => position.contains('defender') || position.contains('back'),
      'MF' => position.contains('midfielder'),
      'FW' => position.contains('forward') ||
          position.contains('striker') ||
          position.contains('winger'),
      _ => true,
    };
  }

  List<ChemistryPlayer> get _suggestions {
    final query = _search.text.trim().toLowerCase();
=======
    final groups = _positionGroups(player.position);
    // Wikidata's P413 labels are multilingual and can be absent or unusual.
    // Keep unclassified records available instead of silently treating a
    // translated/unknown label as proof that the player cannot fill the slot.
    return groups.isEmpty || groups.contains(role);
  }

  List<ChemistryPlayer> get _suggestions {
    final query = _normalizePlayerName(_search.text);
>>>>>>> Stashed changes
    if (query.length < 2) return const [];
    final used = _squad.values.map((player) => player.id).toSet();
    return _catalog
        .where((player) =>
            !used.contains(player.id) &&
            _fits(player, _formation[_activeSlot]) &&
<<<<<<< Updated upstream
            player.name.toLowerCase().contains(query))
=======
            _normalizePlayerName(player.name).contains(query))
>>>>>>> Stashed changes
        .take(8)
        .toList(growable: false);
  }

  void _assign(ChemistryPlayer player) {
    setState(() {
      _squad[_activeSlot] = player;
      _search.clear();
      _error = null;
      final next = List<int>.generate(_formation.length, (index) => index)
          .firstWhere((index) => !_squad.containsKey(index),
              orElse: () => _activeSlot);
      _activeSlot = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Kimya XI')),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_catalog.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kimya XI')),
<<<<<<< Updated upstream
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_download_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('Futbol kataloğu hazır değil',
                        style: theme.textTheme.titleLarge),
                    Text(
                        _error ??
                            'İlk Wikidata paketi yayımlandığında kadro kurabileceksin.',
                        textAlign: TextAlign.center),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          unawaited(_load());
                        },
                        child: const Text('Yeniden dene')),
                  ],
                ))),
=======
        body: FootballCatalogUnavailableView(
          title: 'Futbol kataloğu açılamadı',
          details: _error ?? 'Bağlantını kontrol edip yeniden dene.',
          retrying: _loading,
          onRetry: () => unawaited(_load()),
        ),
>>>>>>> Stashed changes
      );
    }
    final report = FootballChemistryRules.calculate(_squad.values);
    return Scaffold(
      appBar: AppBar(title: const Text('Kimya XI · 4-3-3')),
      body: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(
                child: Text(
<<<<<<< Updated upstream
                    'Veri $_datasetVersion · ${_squad.length}/11 oyuncu',
=======
                    'Veri $_datasetVersion · $_datasetSource · ${_squad.length}/11 oyuncu',
>>>>>>> Stashed changes
                    style: theme.textTheme.titleSmall)),
            Text('${report.totalPoints} KİMYA',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_formation.length, (index) {
                final player = _squad[index];
                final selected = index == _activeSlot;
                return SizedBox(
                    width: 112,
                    child: InkWell(
                      onTap: () => setState(() {
                        _activeSlot = index;
                        _error = null;
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant),
                          ),
                          child: Column(children: [
                            Text(_formation[index],
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(player?.name ?? 'Seç',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ])),
                    ));
              })),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
                labelText:
                    '${_formation[_activeSlot]} pozisyonu için futbolcu ara',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder()),
          ),
          for (final player in _suggestions)
            ListTile(
                dense: true,
                title: Text(player.name),
                subtitle: Text(player.position.isEmpty
                    ? 'Pozisyon bilgisi yok'
                    : player.position),
                onTap: () => _assign(player)),
          if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          Text('Kulüp başına oyuncu',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          for (final club in report.clubCounts.take(6))
            ListTile(
                dense: true,
                title: Text(club.clubName),
                trailing: Text('${club.playerCount} oyuncu')),
          Text(
              'Kimya, ortak kulüp geçmişi ve tarih çakışmasıyla artar; eksik tarihler kulüp bağlantısını korur fakat üst üste oynama bonusu vermez.',
              style: theme.textTheme.bodySmall),
        ]),
      )),
    );
  }
}
