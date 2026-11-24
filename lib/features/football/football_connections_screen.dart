import 'dart:async';

<<<<<<< Updated upstream
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

=======
import 'package:flutter/material.dart';

import 'football_catalog_repository.dart';

>>>>>>> Stashed changes
class _ConnectionPlayer {
  const _ConnectionPlayer(this.id, this.name);
  final String id;
  final String name;
}

class _ConnectionGroup {
  const _ConnectionGroup(this.tag, this.label, this.playerIds);
  final String tag;
  final String label;
  final Set<String> playerIds;
}

class FootballConnectionsScreen extends StatefulWidget {
  const FootballConnectionsScreen({super.key});

  @override
  State<FootballConnectionsScreen> createState() =>
      _FootballConnectionsScreenState();
}

class _FootballConnectionsScreenState extends State<FootballConnectionsScreen> {
  final Set<String> _selected = {};
  final Set<String> _solvedTags = {};
  List<_ConnectionPlayer> _board = const [];
  List<_ConnectionGroup> _groups = const [];
  bool _loading = true;
  String? _error;
  int _mistakes = 5;
  String? _datasetVersion;
<<<<<<< Updated upstream
=======
  String? _datasetSource;
>>>>>>> Stashed changes

  int _dailyRank(String value, int seed) {
    var hash = seed;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0xFFFFFFFF;
    }
    return hash;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
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

  Future<void> _load() async {
<<<<<<< Updated upstream
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('footballCatalog/current')
          .get()
          .timeout(const Duration(seconds: 12));
      if (snapshot.value is! Map) {
        throw StateError('Dinamik futbol kataloğu henüz yayınlanmadı.');
      }
      final data = Map<String, dynamic>.from(snapshot.value as Map);
=======
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _board = const [];
        _groups = const [];
      });
    }
    try {
      final loaded = await FootballCatalogRepository.load(requireConnections: true);
      final data = loaded.data;
>>>>>>> Stashed changes
      final players = _maps(data['players']).map((raw) {
        return _ConnectionPlayer(
          '${raw['id'] ?? ''}',
          '${raw['name'] ?? ''}',
        );
      }).where((player) => player.id.isNotEmpty && player.name.isNotEmpty).toList();
      final playerById = {for (final player in players) player.id: player};
      final grids = data['grids'];
      final connections = grids is Map ? grids['connections'] : null;
      final pack = connections is Map && connections['current'] is Map
          ? Map<String, dynamic>.from(connections['current'] as Map)
          : <String, dynamic>{};
      final groups = _maps(pack['groups']).map((raw) {
        final ids = raw['playerIds'] is Iterable
            ? (raw['playerIds'] as Iterable).whereType<String>().toSet()
            : raw['playerIds'] is Map
                ? (raw['playerIds'] as Map).values.whereType<String>().toSet()
                : <String>{};
        return _ConnectionGroup(
          '${raw['id'] ?? ''}',
          '${raw['label'] ?? ''}',
          ids,
        );
      }).toList();
      if (groups.length != 4 ||
          groups.any((group) => group.playerIds.length != 4 ||
              group.playerIds.any((id) => !playerById.containsKey(id))) ||
          groups.expand((group) => group.playerIds).toSet().length != 16) {
        throw StateError('Connections günlük oyun paketi henüz yayınlanmadı.');
      }
      final board = groups
          .expand((group) => group.playerIds)
          .map((id) => playerById[id]!)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      // The backend publishes a stable answer set. This day-specific order is
      // deterministic so all Android installs see the same shuffled board.
      final daySeed = '${pack['gameId'] ?? ''}'.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
      board.sort((a, b) {
        final aRank = _dailyRank(a.id, daySeed);
        final bRank = _dailyRank(b.id, daySeed);
        return aRank.compareTo(bRank);
      });
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _board = board;
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

  void _toggle(String playerId) {
    if (_mistakes == 0 || _solvedTags.length == 4) return;
    setState(() {
      if (_selected.contains(playerId)) {
        _selected.remove(playerId);
      } else if (_selected.length < 4) {
        _selected.add(playerId);
      }
    });
  }

  void _submit() {
    if (_selected.length != 4) return;
    final group = _groups.where((candidate) =>
        !_solvedTags.contains(candidate.tag) &&
        candidate.playerIds.length == _selected.length &&
        candidate.playerIds.containsAll(_selected));
    setState(() {
      if (group.isNotEmpty) {
        _solvedTags.add(group.first.tag);
        _error = _solvedTags.length == 4 ? 'Harika, tüm grupları buldun!' : null;
      } else {
        _mistakes--;
        _error = _mistakes == 0
            ? 'Hakların bitti. Kalan grupları inceleyebilirsin.'
            : 'Bu dört futbolcunun ortak kategorisi yok.';
      }
      _selected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Futbol Connections · 4×4')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_board.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Futbol Connections · 4×4')),
<<<<<<< Updated upstream
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_download_outlined, size: 48),
              const SizedBox(height: 12),
              Text(_error ?? 'Oyun paketi hazır değil.', textAlign: TextAlign.center),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  unawaited(_load());
                },
                child: const Text('Yeniden dene'),
              ),
            ]),
          ),
=======
        body: FootballCatalogUnavailableView(
          title: 'Connections oyunu açılamadı',
          details: _error ?? 'Günlük oyuncu grupları henüz yayınlanmadı.',
          retrying: _loading,
          onRetry: () => unawaited(_load()),
>>>>>>> Stashed changes
        ),
      );
    }
    final ended = _mistakes == 0 || _solvedTags.length == 4;
    return Scaffold(
      appBar: AppBar(title: const Text('Futbol Connections · 4×4')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.all(16), children: [
<<<<<<< Updated upstream
            Text('Veri $_datasetVersion · 4 ortak kategori bul',
=======
            Text('Veri $_datasetVersion · $_datasetSource · 4 ortak kategori bul',
>>>>>>> Stashed changes
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
                'Hata hakkı: ${List.filled(_mistakes, '●').join(' ')} ${List.filled(5 - _mistakes, '○').join(' ')}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final group in _groups.where((item) => _solvedTags.contains(item.tag) || _mistakes == 0))
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text(group.label.toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    Text(group.playerIds.map((id) => _board.firstWhere((p) => p.id == id).name).join(' · '),
                        textAlign: TextAlign.center),
                  ]),
                ),
              ),
            LayoutBuilder(builder: (context, constraints) {
              final gap = 6.0;
              final width = (constraints.maxWidth - gap * 3) / 4;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _board
                    .where((player) => !_solvedTags.any((tag) =>
                        _groups.any((group) => group.tag == tag && group.playerIds.contains(player.id))))
                    .map((player) {
                  final selected = _selected.contains(player.id);
                  return SizedBox(
                    width: width,
                    height: 78,
                    child: FilterChip(
                      showCheckmark: false,
                      selected: selected,
                      onSelected: ended ? null : (_) => _toggle(player.id),
                      label: SizedBox(
                        width: width - 28,
                        child: Text(player.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      padding: const EdgeInsets.all(6),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _selected.length == 4 && !ended ? _submit : null,
              child: Text('GRUBU DENE · ${_selected.length}/4'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 8),
            const Text('Her gün futbolcu kariyer kataloğundan yeni bir 4×4 tahta oluşturulur.',
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
