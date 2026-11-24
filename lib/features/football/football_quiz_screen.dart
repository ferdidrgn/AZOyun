import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'football_catalog_repository.dart';

enum FootballQuizMode {
  player('Futbolcuyu Bil'),
  club('Takımı Bul');

  const FootballQuizMode(this.title);
  final String title;
}

class FootballQuizScreen extends StatefulWidget {
  const FootballQuizScreen({super.key, required this.mode});
  final FootballQuizMode mode;

  @override
  State<FootballQuizScreen> createState() => _FootballQuizScreenState();
}

typedef FootballEntry = ({String id, String name, List<String> clues});

class _FootballQuizScreenState extends State<FootballQuizScreen> {
  final _random = Random();
  List<FootballEntry> _bank = const [];
  List<FootballEntry> _rounds = const [];
  List<FootballEntry> _options = const [];
  int _index = 0;
  int _visible = 1;
  int _points = 0;
  FootballEntry? _choice;
  final Set<FootballEntry> _eliminated = {};
  FootballEntry? _lastWrong;
  bool _clubFinished = false;
  bool _loading = true;
  String? _error;

  FootballEntry? get _answer =>
      _rounds.isNotEmpty && _index < _rounds.length ? _rounds[_index] : null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCatalog());
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

  List<FootballEntry> _playerEntries(Map<String, dynamic> catalog) {
    final players = _maps(catalog['players']);
    final entries = <FootballEntry>[];
    for (final player in players) {
      final id = player['id']?.toString() ?? '';
      final name = player['name']?.toString().trim() ?? '';
      if (id.isEmpty || name.isEmpty) continue;

      final clues = <String>{};
      for (final career in _maps(player['careers'])) {
        final club = career['label']?.toString().trim() ?? '';
        if (club.isNotEmpty) {
          clues.add('Kariyer kataloğunda $club kulübüyle ilişkili.');
        }
      }
      for (final country in _maps(player['countries'])) {
        final label = country['label']?.toString().trim() ?? '';
        if (label.isNotEmpty) {
          clues.add('Katalogdaki ülke kaydı: $label.');
        }
      }
      if (clues.isEmpty) continue;
      entries.add((id: id, name: name, clues: clues.take(3).toList()));
    }

    // Same display name with different entity IDs would make a multiple-choice
    // answer ambiguous, so omit those names until the UI can disambiguate them.
    final nameCounts = <String, int>{};
    for (final entry in entries) {
      final key = entry.name.toLowerCase();
      nameCounts[key] = (nameCounts[key] ?? 0) + 1;
    }
    return entries
        .where((entry) => nameCounts[entry.name.toLowerCase()] == 1)
        .toList(growable: false);
  }

  List<FootballEntry> _clubEntries(Map<String, dynamic> catalog) {
    final clubs = <String, ({String name, Set<String> playerNames, List<int> years})>{};
    for (final player in _maps(catalog['players'])) {
      final playerId = player['id']?.toString() ?? '';
      final playerName = player['name']?.toString().trim() ?? '';
      if (playerId.isEmpty || playerName.isEmpty) continue;
      for (final career in _maps(player['careers'])) {
        final clubId = career['id']?.toString() ?? '';
        final clubName = career['label']?.toString().trim() ?? '';
        if (clubId.isEmpty || clubName.isEmpty) continue;
        final club = clubs.putIfAbsent(
          clubId,
          () => (name: clubName, playerNames: <String>{}, years: <int>[]),
        );
        club.playerNames.add(playerName);
        if (career['startYear'] is num) {
          club.years.add((career['startYear'] as num).toInt());
        }
      }
    }

    final entries = <FootballEntry>[];
    for (final record in clubs.entries) {
      final playerNames = record.value.playerNames.toList()..sort();
      final years = record.value.years;
      final clues = <String>[
        'Katalogdaki ${playerNames.length} futbolcunun kariyer kaydında bu kulüp yer alıyor.',
        if (years.isNotEmpty)
          'Bu kulüple ilişkili kayıtlarda görülen en erken başlangıç yılı ${years.reduce(min)}.',
        if (playerNames.isNotEmpty)
          'Kayıtlı oyunculardan biri: ${playerNames.first}.',
      ];
      entries.add((id: record.key, name: record.value.name, clues: clues));
    }

    final nameCounts = <String, int>{};
    for (final entry in entries) {
      final key = entry.name.toLowerCase();
      nameCounts[key] = (nameCounts[key] ?? 0) + 1;
    }
    return entries
        .where((entry) => nameCounts[entry.name.toLowerCase()] == 1)
        .toList(growable: false);
  }

  Future<void> _loadCatalog() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _bank = const [];
        _rounds = const [];
      });
    }
    try {
      final snapshot = await FootballCatalogRepository.load();
      final bank = widget.mode == FootballQuizMode.player
          ? _playerEntries(snapshot.data)
          : _clubEntries(snapshot.data);
      if (bank.length < 6) {
        throw StateError(
          widget.mode == FootballQuizMode.player
              ? 'Futbolcu quiz’i için yeterli benzersiz oyuncu ve doğrulanabilir kariyer/ülke bilgisi yok.'
              : 'Takım quiz’i için yeterli benzersiz kulüp kariyer kaydı yok.',
        );
      }
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _loading = false;
        _restart();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  void _restart() {
    final shuffled = _bank.toList()..shuffle(_random);
    _rounds = shuffled.take(6).toList();
    _index = 0;
    _points = 0;
    _setQuestion();
  }

  void _setQuestion() {
    final other = _bank.where((entry) => entry != _answer).toList()
      ..shuffle(_random);
    _options = [_answer, ...other.take(3)]..shuffle(_random);
    _choice = null;
    _visible = 1;
    _eliminated.clear();
    _lastWrong = null;
    _clubFinished = false;
  }

  void _guess(FootballEntry entry) => setState(() {
        if (widget.mode == FootballQuizMode.player) {
          _choice = entry;
          if (entry == _answer) _points += 4 - _visible;
          return;
        }

        if (entry == _answer) {
          _choice = entry;
          _clubFinished = true;
          _points += 4 - _visible;
          return;
        }

        _eliminated.add(entry);
        _lastWrong = entry;
        if (_eliminated.length == _options.length - 1) {
          _clubFinished = true;
        } else {
          _visible = min(3, _visible + 1);
        }
      });

  Color _clubAccent(FootballEntry entry) => switch (entry.name) {
        'Galatasaray' => const Color(0xFFE3A329),
        'Fenerbahçe' => const Color(0xFF174EAF),
        'Beşiktaş' => const Color(0xFF343943),
        'Trabzonspor' => const Color(0xFF762E4A),
        'Barcelona' => const Color(0xFF8C203D),
        'Real Madrid' => const Color(0xFF5576B8),
        'Liverpool' => const Color(0xFFC6283D),
        'AC Milan' => const Color(0xFF9D2639),
        'Ajax' => const Color(0xFFCF3642),
        'Bayern Münih' => const Color(0xFFC72C45),
        'Manchester City' => const Color(0xFF5597BB),
        _ => const Color(0xFFE0B52E),
      };

  Widget _clubOption(FootballEntry entry, bool disabled) {
    final theme = Theme.of(context);
    final accent = _clubAccent(entry);
    final initials = entry.name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    final eliminated = _eliminated.contains(entry);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(110),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: disabled || eliminated ? null : () => _guess(entry),
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: eliminated ? theme.disabledColor.withAlpha(90) : accent.withAlpha(150),
              ),
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withAlpha(175)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: accent.withAlpha(65), blurRadius: 8, offset: const Offset(0, 3),
                  )],
                ),
                child: Text(initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (eliminated)
                Icon(Icons.close_rounded, color: theme.disabledColor)
              else
                Icon(Icons.sports_soccer_rounded, color: accent),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index + 1 == _rounds.length;
    final hint = _descriptions[_answer.article];
    final playerMode = widget.mode == FootballQuizMode.player;
    final answered = playerMode ? _choice != null : _clubFinished;
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.title)),
      body: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(padding: const EdgeInsets.all(22), children: [
          Text('Soru ${_index + 1}/${_rounds.length}  ·  $_points puan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: (_index + (answered ? 1 : 0)) / _rounds.length),
          const SizedBox(height: 24),
          if (!playerMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(110),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.shield_outlined),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'İpuçlarını incele, doğru kulüp kartını seç. Yanlış seçim yeni ipucunu açar.',
                )),
              ]),
            ),
          for (final clue in _answer.clues.take(answered ? 3 : _visible))
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(clue,
                  style: playerMode
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4))),
          if (playerMode && !answered && _visible < 3)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _visible++),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Ek ipucu · Doğru cevap ${3 - _visible} puan'),
                )),
          const SizedBox(height: 14),
          for (final option in _options)
            if (playerMode)
              Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: FilledButton.tonal(
                      onPressed: answered ? null : () => _guess(option),
                      child: Text(option.name)))
            else
              _clubOption(option, answered),
          if (!playerMode && _lastWrong != null && !answered)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text('Bu kulüp değil. Yeni ipucu açıldı; tekrar dene.',
                style: TextStyle(color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600)),
            ),
          if (answered) ...[
            const SizedBox(height: 16),
            Text(_choice == _answer ? 'Doğru!' : 'Doğru cevap: ${_answer.name}',
                style: Theme.of(context).textTheme.titleLarge),
            if (hint != null) Text('$hint · Wikidata'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(() {
                if (last) {
                  _restart();
                } else {
                  _index++;
                  _setQuestion();
                }
              }),
              child: Text(last ? '$_points puan · Yeni seri' : 'Sıradaki soru'),
            ),
          ],
        ]),
      )),
    );
  }
}
