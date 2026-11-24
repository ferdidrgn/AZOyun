import 'dart:async';

<<<<<<< Updated upstream
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

=======
import 'package:flutter/material.dart';

import 'football_catalog_repository.dart';
>>>>>>> Stashed changes
import 'football_grid_rules.dart';

/// Loads the current published grid and player catalogue from RTDB.
/// Expected paths: footballCatalog/current/{players,grids/box2box/current}.
class FootballGridScreen extends StatefulWidget {
  const FootballGridScreen({super.key});

  @override
  State<FootballGridScreen> createState() => _FootballGridScreenState();
}

class _FootballGridScreenState extends State<FootballGridScreen> {
  final _input = TextEditingController();
  List<FootballGridCriterion> _rows = const [];
  List<FootballGridCriterion> _columns = const [];
  List<FootballGridPlayer> _players = const [];
  final Map<int, List<FootballGridPlayer>> _answers = {};
  int? _activeCell;
  static const _timerOptions = <int>[0, 90, 60, 40];
  int _timerSeconds = 90;
  int _seconds = 90;
  Timer? _timer;
  String? _error;
  bool _loading = true;
  bool _started = false;
  bool _finished = false;
  String _datasetVersion = '—';
<<<<<<< Updated upstream
=======
  String _datasetSource = '';
>>>>>>> Stashed changes

  List<FootballGridPlayer> get _suggestions {
    final query = _input.text.trim().toLowerCase();
    if (query.length < 2) return const [];
    final usedIds = _answers.values.expand((answers) => answers).map((p) => p.id).toSet();
    return _players
        .where((p) => !usedIds.contains(p.id) && p.name.toLowerCase().contains(query))
        .take(6)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
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
      final root = snapshot.value;
      if (root is! Map) throw StateError('Katalog verisi bulunamadı.');
      final data = Map<String, dynamic>.from(root);
=======
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final loaded = await FootballCatalogRepository.load(requireBox2Box: true);
      final data = loaded.data;
>>>>>>> Stashed changes
      final gridRoot = data['grids'];
      final box2box = gridRoot is Map ? gridRoot['box2box'] : null;
      final grid = box2box is Map && box2box['current'] is Map
          ? Map<String, dynamic>.from(box2box['current'] as Map)
          : <String, dynamic>{};
      final players = _maps(data['players'])
          .map((p) {
            final tags = p['tags'];
            final values = tags is List
                ? tags.whereType<String>().toSet()
                : tags is Map
                    ? tags.entries
                        .where((e) => e.value == true)
                        .map((e) => e.key.toString())
                        .toSet()
                    : <String>{};
            return FootballGridPlayer(
              id: '${p['id'] ?? ''}',
              name: '${p['name'] ?? ''}',
              tags: values,
            );
          })
          .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
          .toList();
      final rows = _maps(grid['rows']).map(_criterion).toList();
      final columns = _maps(grid['columns']).map(_criterion).toList();
      if (rows.length != 3 || columns.length != 3 || players.isEmpty) {
        throw StateError('Yayınlanan 3×3 oyun paketi henüz hazır değil.');
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _columns = columns;
        _players = players;
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
        _loading = false;
        _error = '$error';
      });
    }
  }

  FootballGridCriterion _criterion(Map<String, dynamic> raw) =>
      FootballGridCriterion(
        id: '${raw['id'] ?? ''}',
        label: '${raw['label'] ?? ''}',
        tag: '${raw['tag'] ?? ''}',
      );

  void _selectCell(int index) {
    if (!_started || _finished || (_timerSeconds > 0 && _seconds == 0)) return;
    setState(() {
      _activeCell = index;
      _error = null;
    });
  }

  void _beginGame() {
    if (_started) return;
    setState(() {
      _started = true;
      _finished = false;
      _seconds = _timerSeconds;
    });
    if (_timerSeconds == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _seconds == 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  void _submit({FootballGridPlayer? selected}) {
    if (!_started || _finished || (_timerSeconds > 0 && _seconds == 0)) return;
    final index = _activeCell;
    if (index == null) {
      setState(() => _error = 'Önce bir kutu seç.');
      return;
    }
    final query = _input.text.trim().toLowerCase();
    final matches = selected == null
        ? _players.where((p) => p.name.toLowerCase() == query).toList()
        : <FootballGridPlayer>[selected];
    if (matches.isEmpty) {
      setState(() => _error = 'Bu oyuncu katalogda bulunamadı.');
      return;
    }
    final row = _rows[index ~/ 3];
    final column = _columns[index % 3];
    final player = matches
        .where((candidate) => FootballGridRules.accepts(
            player: candidate, row: row, column: column))
        .firstOrNull;
    if (player == null) {
      setState(() => _error =
          '${matches.first.name}, ${row.label} × ${column.label} koşulunu karşılamıyor.');
      return;
    }
    if (_answers.values.any((answers) => answers.any((answer) => answer.id == player.id))) {
      setState(() => _error = 'Bu futbolcuyu tahtada zaten kullandın.');
      return;
    }
    setState(() {
      final list = _answers.putIfAbsent(index, () => []);
      list.add(player);
      _input.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = FootballGridRules.filledBoxes(
      _answers.values.map((players) => players.map((player) => player.id).toSet()),
    );
    final playerCount = _answers.values.fold<int>(0, (total, players) => total + players.length);
    final completionPercent = (filled * 100 / 9).round();
    final timeLabel = _timerSeconds == 0
        ? 'Süresiz'
        : '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Futbol Box2Box · 3×3')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _rows.isEmpty
<<<<<<< Updated upstream
                  ? _emptyState(theme)
=======
                  ? _emptyState()
>>>>>>> Stashed changes
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(
<<<<<<< Updated upstream
                                  '$_datasetVersion · 9 kutu · $filled dolu · $playerCount oyuncu · $completionPercent%',
=======
                                  '$_datasetVersion · $_datasetSource · 9 kutu · $filled dolu · $playerCount oyuncu · $completionPercent%',
>>>>>>> Stashed changes
                                  maxLines: 2,
                                  style: theme.textTheme.titleSmall)),
                          Text(timeLabel,
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900)),
                        ]),
                        const SizedBox(height: 12),
                        if (!_started)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: _timerOptions.map((seconds) {
                                  final label = seconds == 0
                                      ? 'Süresiz'
                                      : '${seconds}s';
                                  return ChoiceChip(
                                    label: Text(label),
                                    selected: _timerSeconds == seconds,
                                    onSelected: (_) => setState(() {
                                      _timerSeconds = seconds;
                                      _seconds = seconds;
                                    }),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: _beginGame,
                                icon: const Icon(Icons.sports_soccer),
                                label: const Text('OYUNU BAŞLAT'),
                              ),
                            ],
                          ),
                        Table(
                          border: TableBorder.all(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(14)),
                          children: [
                            TableRow(children: [
                              _header(''),
                              for (final column in _columns)
                                _header(column.label),
                            ]),
                            for (var row = 0; row < 3; row++)
                              TableRow(children: [
                                _header(_rows[row].label),
                                for (var col = 0; col < 3; col++)
                                  _cell(row * 3 + col, theme),
                              ]),
                          ],
                        ),
                        if (_started && filled == 9 && !_finished)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: FilledButton.icon(
                              onPressed: () => setState(() {
                                _finished = true;
                                _timer?.cancel();
                              }),
                              icon: const Icon(Icons.flag_circle_outlined),
                              label: const Text('TAMAMLA'),
                            ),
                          ),
                        if (_finished)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Grid tamamlandı · $playerCount futbolcu buldun.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _input,
                          enabled: _started &&
                              !_finished &&
                              (_timerSeconds == 0 || _seconds > 0),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: _activeCell == null
                                ? 'Önce bir kutu seç'
                                : 'Futbolcu adı',
                            suffixIcon: IconButton(
                                onPressed: _started && (_timerSeconds == 0 || _seconds > 0) ? _submit : null,
                                icon: const Icon(Icons.check_circle)),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        for (final player in _suggestions)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: Text(player.name),
                            subtitle: _players
                                        .where((candidate) =>
                                            candidate.name == player.name)
                                        .length >
                                    1
                                ? Text('Kimlik: ${player.id}')
                                : null,
                            onTap: () {
                              _input.text = player.name;
                              _submit(selected: player);
                            },
                          ),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: theme.colorScheme.error))),
                        const SizedBox(height: 8),
                        Text(
                            'Oyuncular isimle bulunur. Kutu şartları, sürümlü oyuncu-kulüp geçmişinden doğrulanır.',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800))),
      );

  Widget _cell(int index, ThemeData theme) {
    final selected = _activeCell == index;
    final names = _answers[index] ?? const <FootballGridPlayer>[];
    return InkWell(
      onTap: () => _selectCell(index),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(6),
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (names.isEmpty)
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary)
          else
            ...names.take(3).map((p) => Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12))),
          if (names.length > 3)
            Text('+${names.length - 3}', style: theme.textTheme.labelSmall),
        ]),
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _emptyState(ThemeData theme) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_download_outlined, size: 48),
          const SizedBox(height: 12),
          Text('Dinamik futbol veri paketi henüz yayınlanmadı.',
              textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'Oyun ekranı artık sabit isim listesinden çalışmıyor. Önce Wikidata’dan doğrulanmış katalog ve günlük 3×3 oyun paketi yayınlanmalı.',
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
        ]),
=======
  Widget _emptyState() => FootballCatalogUnavailableView(
        title: 'Günlük Box2Box tahtası açılamadı',
        details: _error ?? 'Katalogda geçerli 3×3 oyun paketi yok.',
        retrying: _loading,
        onRetry: () => unawaited(_load()),
>>>>>>> Stashed changes
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
