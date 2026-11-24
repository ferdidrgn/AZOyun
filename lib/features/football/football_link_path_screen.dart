import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class _LinkPlayer {
  const _LinkPlayer(
      {required this.id, required this.name, required this.clubs});
  final String id;
  final String name;
  final Map<String, String> clubs;
}

class _LinkStep {
  const _LinkStep(this.player, this.club);
  final _LinkPlayer player;
  final String club;
}

class FootballLinkPathScreen extends StatefulWidget {
  const FootballLinkPathScreen({super.key});

  @override
  State<FootballLinkPathScreen> createState() => _FootballLinkPathScreenState();
}

class _FootballLinkPathScreenState extends State<FootballLinkPathScreen> {
  final _firstInput = TextEditingController();
  final _secondInput = TextEditingController();
  List<_LinkPlayer> _players = const [];
  _LinkPlayer? _first;
  _LinkPlayer? _second;
  List<_LinkStep> _path = const [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _firstInput.dispose();
    _secondInput.dispose();
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
            final clubs = <String, String>{};
            for (final spell in _maps(raw['careers'])) {
              final id = '${spell['id'] ?? ''}';
              if (id.isNotEmpty) clubs[id] = '${spell['label'] ?? id}';
            }
            return _LinkPlayer(
                id: '${raw['id'] ?? ''}',
                name: '${raw['name'] ?? ''}',
                clubs: clubs);
          })
          .where((player) => player.id.isNotEmpty && player.clubs.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = '$error';
      });
    }
  }

  List<_LinkPlayer> _suggestions(String text, _LinkPlayer? excluded) {
    final query = text.trim().toLowerCase();
    if (query.length < 2) return const [];
    return _players
        .where(
            (p) => p.id != excluded?.id && p.name.toLowerCase().contains(query))
        .take(8)
        .toList(growable: false);
  }

  void _findPath() {
    final source = _first;
    final destination = _second;
    if (source == null || destination == null) {
      setState(() => _message = 'İki futbolcuyu da seç.');
      return;
    }
    if (source.id == destination.id) {
      setState(() => _message = 'Farklı futbolcular seç.');
      return;
    }

    final playersByClub = <String, List<_LinkPlayer>>{};
    for (final player in _players) {
      for (final club in player.clubs.keys) {
        playersByClub.putIfAbsent(club, () => []).add(player);
      }
    }
    final queue = <_LinkPlayer>[source];
    final seen = <String>{source.id};
    final previous = <String, ({String playerId, String clubId})>{};
    for (var cursor = 0;
        cursor < queue.length && !seen.contains(destination.id);
        cursor++) {
      final current = queue[cursor];
      for (final clubId in current.clubs.keys) {
        for (final neighbor in playersByClub[clubId] ?? const <_LinkPlayer>[]) {
          if (!seen.add(neighbor.id)) continue;
          previous[neighbor.id] = (playerId: current.id, clubId: clubId);
          queue.add(neighbor);
          if (neighbor.id == destination.id) break;
        }
        if (seen.contains(destination.id)) break;
      }
    }
    if (!seen.contains(destination.id)) {
      setState(() {
        _path = const [];
        _message = 'Bu veri sürümünde aralarında doğrulanmış kulüp yolu yok.';
      });
      return;
    }
    final playerById = {for (final player in _players) player.id: player};
    final reversed = <_LinkStep>[];
    var cursor = destination.id;
    while (cursor != source.id) {
      final edge = previous[cursor]!;
      reversed.add(_LinkStep(
          playerById[cursor]!, playerById[cursor]!.clubs[edge.clubId]!));
      cursor = edge.playerId;
    }
    setState(() {
      _path = reversed.reversed.toList();
      _message = '${_path.length} kulüp bağlantısı bulundu.';
    });
  }

  Widget _playerPicker(
      {required String label,
      required TextEditingController controller,
      required _LinkPlayer? selected,
      required _LinkPlayer? excluded,
      required ValueChanged<_LinkPlayer> onSelect}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
          controller: controller,
          enabled: selected == null,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              labelText: selected?.name ?? label,
              prefixIcon: const Icon(Icons.person_search),
              border: const OutlineInputBorder())),
      for (final player in _suggestions(controller.text, excluded))
        ListTile(
            dense: true,
            title: Text(player.name),
            subtitle: Text('${player.clubs.length} kulüp'),
            onTap: () => onSelect(player)),
      if (selected != null)
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: () => setState(() {
                      if (identical(controller, _firstInput))
                        _first = null;
                      else
                        _second = null;
                      controller.clear();
                      _path = const [];
                    }),
                icon: const Icon(Icons.edit),
                label: Text('Değiştir: ${selected.name}'))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Oyuncu Bağlantı Yolu')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    const Text(
                        'İki futbolcu seç. Katalog, onları ortak kulüpler üzerinden en kısa doğrulanmış kariyer zinciriyle bağlasın.'),
                    const SizedBox(height: 16),
                    _playerPicker(
                        label: 'İlk futbolcu',
                        controller: _firstInput,
                        selected: _first,
                        excluded: _second,
                        onSelect: (player) => setState(() {
                              _first = player;
                              _firstInput.text = player.name;
                              _message = null;
                            })),
                    const SizedBox(height: 8),
                    _playerPicker(
                        label: 'İkinci futbolcu',
                        controller: _secondInput,
                        selected: _second,
                        excluded: _first,
                        onSelect: (player) => setState(() {
                              _second = player;
                              _secondInput.text = player.name;
                              _message = null;
                            })),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                        onPressed: _findPath,
                        icon: const Icon(Icons.route),
                        label: const Text('EN KISA YOLU BUL')),
                    if (_message != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_message!,
                              style: theme.textTheme.titleMedium)),
                    if (_path.isNotEmpty) ...[
                      Card(
                          child: ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(_first!.name))),
                      for (final step in _path) ...[
                        const Center(child: Icon(Icons.arrow_downward)),
                        Card(
                            color: theme.colorScheme.secondaryContainer,
                            child: ListTile(
                                leading: const Icon(Icons.stadium),
                                title: Text(step.club))),
                        const Center(child: Icon(Icons.arrow_downward)),
                        Card(
                            child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(step.player.name))),
                      ],
                    ],
                    if (_message == null && _players.isEmpty)
                      const Text('Katalog henüz yayınlanmadı.'),
                  ]))),
    );
  }
}
