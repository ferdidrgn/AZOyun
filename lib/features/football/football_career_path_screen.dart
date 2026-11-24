import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class _CareerPlayer {
  const _CareerPlayer(
      {required this.id, required this.name, required this.clubs});
  final String id;
  final String name;
  final List<({String club, int year})> clubs;
}

class FootballCareerPathScreen extends StatefulWidget {
  const FootballCareerPathScreen({super.key});

  @override
  State<FootballCareerPathScreen> createState() =>
      _FootballCareerPathScreenState();
}

class _FootballCareerPathScreenState extends State<FootballCareerPathScreen> {
  final _random = Random();
  final _query = TextEditingController();
  List<_CareerPlayer> _players = const [];
  _CareerPlayer? _answer;
  int _visibleClues = 1;
  int _tries = 6;
  bool _loading = true;
  bool _finished = false;
  bool _won = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is List)
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    if (raw is Map)
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    return const [];
  }

  Future<void> _load() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('footballCatalog/current/players')
          .get()
          .timeout(const Duration(seconds: 12));
      final players = _maps(snapshot.value)
          .map((raw) {
            final clubs = _maps(raw['careers'])
                .where((spell) =>
                    spell['startYear'] is num && spell['label'] is String)
                .map((spell) => (
                      club: spell['label'] as String,
                      year: (spell['startYear'] as num).toInt()
                    ))
                .toList()
              ..sort((a, b) => a.year.compareTo(b.year));
            return _CareerPlayer(
                id: '${raw['id'] ?? ''}',
                name: '${raw['name'] ?? ''}',
                clubs: clubs);
          })
          .where((player) =>
              player.id.isNotEmpty &&
              player.name.isNotEmpty &&
              player.clubs.length >= 3)
          .toList();
      if (players.length < 20)
        throw StateError('Kariyer rotası kurmak için tarihli kulüp verisi az.');
      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
      _newRound();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = '$error';
      });
    }
  }

  void _newRound() {
    if (_players.isEmpty) return;
    setState(() {
      _answer = _players[_random.nextInt(_players.length)];
      _visibleClues = 1;
      _tries = 6;
      _finished = false;
      _won = false;
      _message = null;
      _query.clear();
    });
  }

  List<_CareerPlayer> get _suggestions {
    final query = _query.text.trim().toLowerCase();
    if (query.length < 2) return const [];
    return _players
        .where((player) => player.name.toLowerCase().contains(query))
        .take(8)
        .toList(growable: false);
  }

  void _guess(_CareerPlayer player) {
    final answer = _answer;
    if (_finished || answer == null) return;
    setState(() {
      _query.clear();
      if (player.id == answer.id) {
        _won = true;
        _finished = true;
        _message = 'Doğru tahmin! ${answer.name}';
        return;
      }
      _tries--;
      if (_tries == 0) {
        _finished = true;
        _message = 'Cevap: ${answer.name}';
      } else {
        _visibleClues = min(answer.clubs.length, _visibleClues + 1);
        _message = 'Olmadı. Bir sonraki kulüp rotası açıldı.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kariyer Rotası')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _answer == null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_message ?? 'Dinamik kariyer verisi yok.',
                          textAlign: TextAlign.center)))
              : Center(
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Text('Bu futbolcunun kulüp rotasını takip et ve adını bul.',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _tries / 6),
                    const SizedBox(height: 8),
                    Text(
                        'Kalan tahmin: $_tries · İpucu ${_visibleClues}/${_answer!.clubs.length}'),
                    const SizedBox(height: 16),
                    for (final clue in _answer!.clubs.take(_visibleClues))
                      Card(
                          child: ListTile(
                              leading: const Icon(Icons.shield_outlined),
                              title: Text(clue.club),
                              trailing: Text('${clue.year}'))),
                    if (!_finished) ...[
                      const SizedBox(height: 12),
                      TextField(
                          controller: _query,
                          onChanged: (_) => setState(() {}),
                          enabled: !_finished,
                          decoration: const InputDecoration(
                              labelText: 'Futbolcu ara',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder())),
                      for (final player in _suggestions)
                        ListTile(
                            dense: true,
                            title: Text(player.name),
                            subtitle: _players
                                        .where((other) =>
                                            other.name == player.name)
                                        .length >
                                    1
                                ? Text('Kimlik ${player.id}')
                                : null,
                            onTap: () => _guess(player)),
                    ],
                    if (_message != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(_message!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: _won
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface))),
                    if (_finished)
                      FilledButton.icon(
                          onPressed: _newRound,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Yeni futbolcu')),
                  ]),
                )),
    );
  }
}
