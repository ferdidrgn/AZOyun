import 'package:flutter/material.dart';

const _roleNames = {
  'enemy': 'Sabotajcı',
  'seer': 'Gözcü',
  'guardian': 'Koruyucu',
  'villager': 'Köylü'
};

class PartyTable extends StatefulWidget {
  const PartyTable(
      {super.key,
      required this.room,
      required this.host,
      required this.busy,
      required this.onAction});
  final Map<String, dynamic> room;
  final bool host, busy;
  final Future<void> Function(String, Map<String, dynamic>) onAction;
  @override
  State<PartyTable> createState() => _PartyTableState();
}

class _PartyTableState extends State<PartyTable> {
  final _word = TextEditingController();
  int _cell = 60;
  bool _vertical = false;
  int? _target;
  Map get _room => widget.room;
  List<Map> get _players => (_room['players'] as List).cast<Map>();
  int get _seat => _room['seat'] as int? ?? -1;
  Map get _private => _room['private'] as Map? ?? {};
  bool get _playing => _room['status'] == 'playing';
  String _name(Object? seat) =>
      seat is int && seat >= 0 && seat < _players.length
          ? _players[seat]['name'] as String
          : 'Pas';

  @override
  void didUpdateWidget(covariant PartyTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room['phase'] != _room['phase'] ||
        oldWidget.room['round'] != _room['round']) {
      _target = null;
    }
  }

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _room['game'] == 'words' ? _words() : _roles();

  Widget _words() {
    final board = _room['board'] as List? ?? List.filled(121, null);
    final mine = !widget.host && _playing && _room['turn'] == _seat;
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          'Torba ${_room['stockCount'] ?? 0} harf · Tur ${_room['round'] ?? 1}',
          style: theme.textTheme.titleMedium),
      Wrap(spacing: 7, children: [
        for (final player in _players)
          Chip(label: Text('${player['name']} · ${player['score'] ?? 0} puan'))
      ]),
      if (_room['status'] == 'finished' &&
          (_room['winners'] as List? ?? []).isNotEmpty)
        Text(
            'Kazanan · ${(_room['winners'] as List? ?? []).map(_name).join(', ')}',
            style: theme.textTheme.titleLarge),
      Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 121,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 11,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2),
                  itemBuilder: (context, index) {
                    final selected = index == _cell && mine;
                    return Semantics(
                        label:
                            '${index ~/ 11 + 1}. satır ${index % 11 + 1}. sütun ${board[index] ?? 'boş'}',
                        selected: selected,
                        child: Material(
                            color: selected
                                ? theme.colorScheme.primaryContainer
                                : board[index] != null
                                    ? theme.colorScheme.secondaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(3),
                            child: InkWell(
                                onTap: mine && !widget.busy
                                    ? () => setState(() => _cell = index)
                                    : null,
                                child: Center(
                                    child: FittedBox(
                                        child: Text(
                                            '${board[index] ?? (index == 60 ? '★' : '')}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: selected
                                                    ? theme.colorScheme
                                                        .onPrimaryContainer
                                                    : theme.colorScheme
                                                        .onSurface)))))));
                  }))),
      if (!widget.host && _playing) ...[
        const SizedBox(height: 14),
        const Text('Elindeki harfler'),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final letter in _private['hand'] as List? ?? [])
            ActionChip(
                label: Text('$letter'),
                onPressed: mine && !widget.busy
                    ? () => setState(() => _word.text += letter as String)
                    : null)
        ]),
        TextField(
            controller: _word,
            enabled: mine && !widget.busy,
            maxLength: 11,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Yerleştirilecek kelime',
                helperText: 'Tahtadaki ortak harfleri de kelimeye yaz.')),
        Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text('Başlangıç ${_cell ~/ 11 + 1}, ${_cell % 11 + 1}'),
              FilterChip(
                  label: Text(_vertical ? 'Dikey ↓' : 'Yatay →'),
                  selected: _vertical,
                  onSelected: mine && !widget.busy
                      ? (value) => setState(() => _vertical = value)
                      : null),
            ]),
        FilledButton(
            onPressed: mine && !widget.busy
                ? () => widget.onAction('placeWord', {
                      'word': _word.text,
                      'row': _cell ~/ 11,
                      'col': _cell % 11,
                      'vertical': _vertical,
                    })
                : null,
            child: const Text('Kelimeyi onayla')),
        Wrap(spacing: 8, children: [
          TextButton(
              onPressed: mine && !widget.busy
                  ? () => widget.onAction('swapLetters', {})
                  : null,
              child: const Text('Harfleri değiştir ve geç')),
          TextButton(
              onPressed: mine && !widget.busy
                  ? () => widget.onAction('passWord', {})
                  : null,
              child: const Text('Pas')),
          TextButton(
              onPressed: () => _word.clear(),
              child: const Text('Yazıyı temizle')),
        ]),
      ],
      const Text(
          'İlk kelime yıldızdan geçer ve iki kat puan alır. Yeni kelimeler mevcut harflere bağlanır. Yedi harfle +20 puan. 40 hamle veya art arda iki tur pas sonunda oyun biter.'),
      ExpansionTile(title: const Text('Aile sözlüğü'), children: [
        Text((_room['dictionary'] as List? ?? []).join(' · ')),
      ]),
    ]);
  }

  Widget _roles() {
    final phase = _room['phase'];
    final role = _private['role'];
    final submitted = _private['submitted'] == true;
    final living = _players.indexed
        .where((entry) => entry.$2['out'] != true)
        .map((entry) => entry.$1)
        .toList();
    final me =
        _seat >= 0 && _seat < _players.length && _players[_seat]['out'] != true;
    final night = phase == 'night';
    final choosing = _playing && me && !submitted && (night || phase == 'vote');
    final activeRole = ['enemy', 'seer', 'guardian'].contains(role);
    final allies = _private['allies'] as List? ?? [];
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
          color: night
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.primaryContainer,
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Icon(night ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    size: 48),
                Text(
                    '${_room['round'] ?? 1}. gün · ${switch (phase) {
                      'night' => 'Gece',
                      'discussion' => 'Tartışma',
                      'vote' => 'Oylama',
                      _ => 'Gün sonu'
                    }}',
                    style: theme.textTheme.headlineSmall),
                if (_playing && (night || phase == 'vote'))
                  Text(
                      '${_room['submitted'] ?? 0}/${living.length} seçim tamamlandı'),
              ]))),
      if (_room['status'] == 'finished' && _room['teamWinner'] != null)
        Text(
            _room['teamWinner'] == 'enemy'
                ? 'Sabotajcılar kazandı'
                : 'Köy kazandı',
            style: theme.textTheme.headlineSmall),
      if (!widget.host && role != null) ...[
        ExpansionTile(title: const Text('Gizli rolünü göster'), children: [
          Text(_roleNames[role] ?? '$role',
              style: theme.textTheme.headlineSmall),
          Text(switch (role) {
            'enemy' =>
              'Geceleri köyden birini seç. Sabotajcı sayısı diğer oyunculara ulaşınca takımın kazanır.',
            'seer' => 'Her gece bir oyuncunun sabotajcı olup olmadığını öğren.',
            'guardian' =>
              'Her gece bir oyuncuyu gece saldırısından koru. Kendini de koruyabilirsin.',
            _ =>
              'Geceleri dinlen. Gündüz konuşmaları ve oyları takip ederek sabotajcıları bul.',
          }),
          if (allies.length > 1)
            Text('Takımın · ${allies.map(_name).join(', ')}'),
        ]),
        if (!me) const Text('Elendin. Ortak masayı izleyebilirsin.'),
        if (submitted)
          const Text('Seçimin alındı. Diğer oyuncular bekleniyor.'),
        if (choosing) ...[
          Text(night
              ? activeRole
                  ? 'Gece görevin için bir oyuncu seç.'
                  : 'Geceyi tamamlamak için dinlen.'
              : 'Oyunu seç ve onayla. Eşitlikte kimse elenmez.'),
          if (!night || activeRole)
            Wrap(spacing: 8, runSpacing: 5, children: [
              for (final id in living)
                if ((night || id != _seat) &&
                    (role != 'enemy' || !night || !allies.contains(id)))
                  ChoiceChip(
                      label: Text(_name(id)),
                      selected: _target == id,
                      onSelected: widget.busy
                          ? null
                          : (_) => setState(() => _target = id)),
              if (!night)
                ChoiceChip(
                    label: const Text('Çekimser'),
                    selected: _target == null,
                    onSelected: widget.busy
                        ? null
                        : (_) => setState(() => _target = null)),
            ]),
          FilledButton(
              onPressed: widget.busy || (night && activeRole && _target == null)
                  ? null
                  : () => widget.onAction(night ? 'nightChoice' : 'roleVote',
                      {'target': night && !activeRole ? null : _target}),
              child: Text(night
                  ? activeRole
                      ? 'Görevi onayla'
                      : 'Dinlen'
                  : 'Oyu onayla')),
        ],
        for (final result in _private['investigations'] as List? ?? [])
          Text(
              '${result['day']}. gece · ${_name(result['target'])} · ${result['enemy'] == true ? 'Sabotajcı' : 'Köyden'}'),
      ],
      if (widget.host && _playing && (phase == 'discussion' || phase == 'dusk'))
        FilledButton(
            onPressed: widget.busy
                ? null
                : () => widget.onAction(
                    phase == 'discussion' ? 'openVote' : 'nextNight', {}),
            child: Text(phase == 'discussion'
                ? 'Tartışma bitti · Oylamayı aç'
                : 'Sonraki gece')),
      if ((_room['lastVotes'] as List? ?? []).isNotEmpty) ...[
        Text('Açıklanan oylar', style: theme.textTheme.titleMedium),
        for (final vote in _room['lastVotes'] as List)
          Text('${_name(vote['voter'])} → ${_name(vote['target'])}'),
      ],
      for (final event in _room['events'] as List? ?? [])
        Text(
            '${event['day']}. gün · ${event['phase'] == 'night' ? 'Gece' : 'Oylama'} · '
            '${event['eliminated'] == null ? 'Kimse elenmedi' : '${_name(event['eliminated'])} elendi'}'),
      if (_room['revealedRoles'] case final List roles)
        for (final (index, value) in roles.indexed)
          Text('${_name(index)} · ${_roleNames[value]}'),
    ]);
  }
}
