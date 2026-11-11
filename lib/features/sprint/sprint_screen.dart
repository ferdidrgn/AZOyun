import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/room_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/az_widgets.dart';
import 'sprint_rules.dart';

class SprintScreen extends StatefulWidget {
  const SprintScreen({super.key, required this.mode, this.initialCode});

  final SprintMode mode;
  final String? initialCode;

  @override
  State<SprintScreen> createState() => _SprintScreenState();
}

class _SprintScreenState extends State<SprintScreen> {
  final _db = FirebaseDatabase.instance;
  final _name = TextEditingController();
  final _code = TextEditingController();
  StreamSubscription<DatabaseEvent>? _watch;
  StreamSubscription<DatabaseEvent>? _clock;
  Timer? _timer;
  DatabaseReference? _ref;
  SprintData _room = {};
  int _offset = 0;
  bool _busy = false;
  String? _message;
  int _sector = 0;
  late final String _me = _db.ref().push().key!;

  int get _now => DateTime.now().millisecondsSinceEpoch + _offset;
  SprintMode get _mode => widget.mode;
  String get _gamePath => switch (_mode) {
        SprintMode.bluff => GamePaths.liarCafe,
        SprintMode.station => GamePaths.impostor,
        SprintMode.penalty => GamePaths.soccer,
      };

  DatabaseReference _roomRef(String code) =>
      _db.ref(_gamePath).child('sprint_$code');

  @override
  void initState() {
    super.initState();
    seedRoomCode(_code, widget.initialCode);
    unawaited(_loadName());
    _clock = _db.ref('.info/serverTimeOffset').onValue.listen((event) {
      _offset = (event.snapshot.value as num?)?.toInt() ?? 0;
    }, onError: (Object _) {});
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      final deadline = _room['deadline'] as int? ?? 0;
      if (deadline <= 0 || !mounted) return;
      setState(() {});
      if (_now >= deadline && !_busy) unawaited(_action('tick'));
    });
  }

  Future<void> _loadName() async {
    try {
      final name = await StorageService.instance.getPlayerName();
      if (mounted && _name.text.isEmpty) _name.text = name ?? '';
    } catch (_) {
      // A name can still be entered when local storage is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_watch?.cancel());
    unawaited(_clock?.cancel());
    final roomId = _ref?.key;
    if (roomId != null) {
      unawaited(_unregisterPresence(roomId));
    }
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _connect({required bool create}) async {
    if (_busy) return;
    final name = _name.text.trim();
    final code = create
        ? RoomService.instance.generateCode()
        : _code.text.trim().toUpperCase();
    if (name.isEmpty || !RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      setState(() => _message = name.isEmpty
          ? 'Oyuncu adını gir.'
          : 'Altı karakterli oda kodunu gir.');
      return;
    }
    setState(() {
      _message = null;
      _busy = true;
    });
    final ref = _roomRef(code);
    StreamSubscription<DatabaseEvent>? warmup;
    try {
      if (!create) {
        // Keep the room subscribed so the transaction starts from a loaded snapshot.
        final ready = Completer<bool>();
        warmup = ref.onValue.listen((event) {
          if (!ready.isCompleted) ready.complete(event.snapshot.exists);
        }, onError: (Object error) {
          if (!ready.isCompleted) ready.completeError(error);
        });
        if (!await ready.future.timeout(const Duration(seconds: 8))) {
          if (mounted) setState(() => _message = 'Oda bulunamadı.');
          return;
        }
      }
      final seed = Random.secure().nextInt(1 << 30);
      final now = _now;
      final result = await ref.runTransaction((value) {
        final next = create
            ? value == null
                ? sprintRoom(_mode, _me, name, seed, now)
                : null
            : joinSprint(_mode, sprintMap(value), _me, name, now);
        return next == null ? Transaction.abort() : Transaction.success(next);
      }, applyLocally: false).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (!result.committed) {
        setState(() => _message = create
            ? 'Kod kullanılıyor. Yeniden oda kur.'
            : 'Oda dolu, kapanmış veya maç başlamış.');
        return;
      }
      setState(() {
        _ref = ref;
        _code.text = code;
        _room = sprintMap(result.snapshot.value);
      });
      unawaited(RoomService.instance.registerPresence(
        gamePath: _gamePath,
        roomId: ref.key!,
        playerKey: _me,
        isHost: create,
      ));
      _watch = ref.onValue.listen((event) {
        if (!mounted || _ref != ref) return;
        final next = sprintMap(event.snapshot.value);
        setState(() {
          if (next['epoch'] != _room['epoch']) _sector = 0;
          _room = next;
          if (next.isEmpty) _message = 'Oda kapatıldı.';
        });
        _recordFinishedMatch(next, code);
      }, onError: (Object _) {
        if (mounted) setState(() => _message = 'Oda bağlantısı kesildi.');
      });
      unawaited(StorageService.instance
          .setPlayerName(name)
          .catchError((Object _) {}));
    } catch (error) {
      debugPrint('Sprint bağlantısı: $error');
      if (mounted)
        setState(() =>
            _message = 'Odaya bağlanılamadı. İnternet bağlantını kontrol et.');
    } finally {
      unawaited(warmup?.cancel());
      if (mounted) setState(() => _busy = false);
    }
  }

  void _recordFinishedMatch(SprintData state, String code) {
    final winner = state['winner'];
    final createdAt = state['createdAt'];
    if (state['phase'] != 'finished' ||
        winner == null ||
        winner == 'left' ||
        createdAt is! num ||
        !sprintPlayers(state).contains(_me)) {
      return;
    }
    final won = switch (winner) {
      'crew' => _me != state['saboteur'],
      'saboteur' => _me == state['saboteur'],
      _ => winner == _me,
    };
    unawaited(ProfileService.instance.reportGameResult(
      gameId: _mode.invite,
      resultId: '$code:$createdAt',
      won: won,
    ));
  }

  Future<void> _action(String type, [int? choice]) async {
    final ref = _ref;
    final epoch = _room['epoch'] as int?;
    if (ref == null || epoch == null || _busy) return;
    setState(() {
      _busy = true;
      if (type != 'tick') _message = null;
    });
    try {
      final now = _now;
      final result = await ref.runTransaction((value) {
        final next = updateSprint(_mode, sprintMap(value), _me, epoch,
            (type: type, choice: choice), now);
        return next == null
            ? Transaction.abort()
            : Transaction.success(next.isEmpty ? null : next);
      }, applyLocally: false).timeout(const Duration(seconds: 8));
      if (mounted &&
          _ref == ref &&
          result.committed &&
          (sprintMap(result.snapshot.value)['epoch'] as int? ?? -1) >=
              (_room['epoch'] as int? ?? -1)) {
        setState(() => _room = sprintMap(result.snapshot.value));
      }
    } catch (error) {
      debugPrint('Sprint işlemi: $error');
      if (mounted)
        setState(
            () => _message = 'Bağlantı bekleniyor. Yeniden deneyebilirsin.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    if (_busy) return;
    final roomId = _ref?.key;
    if (_ref != null) await _action('leave');
    if (roomId != null) {
      unawaited(_unregisterPresence(roomId));
    }
    if (!mounted) return;
    unawaited(_watch?.cancel());
    setState(() {
      _ref = null;
      _room = {};
      _message = null;
    });
  }

  Future<void> _unregisterPresence(String roomId) =>
      RoomService.instance.unregisterPresence(
        gamePath: _gamePath,
        roomId: roomId,
        playerKey: _me,
      );

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _ref == null && !_busy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _ref != null) unawaited(_leave());
        },
        child: Scaffold(
          appBar: AppBar(title: Text(_mode.title)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_message != null) ...[
                    Text(_message!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                  ],
                  if (_ref == null)
                    ..._joinForm()
                  else if (_room.isEmpty)
                    FilledButton(
                        onPressed: _leave, child: const Text('Lobiye dön'))
                  else
                    ..._game(context),
                ],
              ),
            ),
          ),
        ),
      );

  List<Widget> _joinForm() => [
        Text(_mode.description, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        TextField(
            controller: _name,
            maxLength: 20,
            decoration: const InputDecoration(labelText: 'Oyuncu adı')),
        FilledButton(
          onPressed: _busy ? null : () => _connect(create: true),
          child: const Text('Oda kur'),
        ),
        const SizedBox(height: 16),
        TextField(
            controller: _code,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))
            ],
            decoration: const InputDecoration(labelText: 'Oda kodu')),
        OutlinedButton(
          onPressed: _busy ? null : () => _connect(create: false),
          child: Text(_busy ? 'Bağlanıyor…' : 'Odaya katıl'),
        ),
      ];

  List<Widget> _game(BuildContext context) {
    final roster = sprintMap(_room['players']);
    final players = sprintPlayers(_room);
    final phase = _room['phase'] as String;
    final round = _room['round'] as int;
    final scores = sprintMap(_room['score']);
    final out = sprintMap(_room['out']);
    final result = _room['result'] as String?;
    final waiting = phase == 'lobby';
    final finished = phase == 'finished';
    final remaining =
        max(0, (((_room['deadline'] as int? ?? 0) - _now) / 1000).ceil());
    return [
      if (waiting)
        AZRoomCode(
            code: _code.text,
            accentColor: Theme.of(context).colorScheme.primary,
            inviteGame: _mode.invite)
      else
        Text(finished ? 'Maç bitti' : 'Tur $round  ·  $remaining sn',
            style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final id in players)
            Chip(
                label: Text('${roster[id]}${id == _me ? ' (sen)' : ''}'
                    '${out.containsKey(id) ? ' · elendi' : ''}'
                    '${!waiting && _mode != SprintMode.station ? ' · ${scores[id] ?? 0}' : ''}')),
        ],
      ),
      const SizedBox(height: 12),
      if (waiting) ...[
        Text(
            '${players.length} / ${_mode.maximum} oyuncu · Başlamak için en az ${_mode.minimum}'),
        if (_room['host'] == _me)
          FilledButton(
              onPressed: _busy || players.length < _mode.minimum
                  ? null
                  : () => _action('start'),
              child: const Text('Maçı başlat'))
        else
          const Text('Oda sahibinin maçı başlatması bekleniyor.'),
      ] else if (finished) ...[
        Text(_winner(roster), style: Theme.of(context).textTheme.titleLarge),
        if (result != null && _room['winner'] != 'left') Text(result),
      ] else ...[
        if (result != null)
          Text(result, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ..._round(phase, players, roster, out),
      ],
      const SizedBox(height: 20),
      OutlinedButton(
          onPressed: _busy ? null : _leave,
          child: Text(finished ? 'Lobiye dön' : 'Odadan ayrıl')),
    ];
  }

  String _winner(SprintData roster) => switch (_room['winner']) {
        'left' => 'Bir oyuncu ayrıldığı için maç kapandı.',
        'draw' => 'Berabere',
        'crew' =>
          'Mürettebat kazandı · Sabotajcı: ${roster[_room['saboteur']]}',
        'saboteur' => 'Sabotajcı kazandı · ${roster[_room['saboteur']]}',
        final id => 'Kazanan: ${roster[id]}',
      };

  Widget _choice(String label, String phase, int value) => FilledButton.tonal(
        onPressed: _busy ? null : () => _action(phase, value),
        child: Text(label),
      );

  List<Widget> _round(
      String phase, List<String> players, SprintData roster, SprintData out) {
    final submitted = sprintMap(_room['moves']).containsKey(_me);
    if (phase == 'reveal') return [const Text('Sıradaki tur hazırlanıyor.')];
    if (submitted)
      return [const Text('Seçimin kilitlendi. Diğer oyuncular bekleniyor.')];
    if (out.containsKey(_me))
      return [const Text('Elendin. Sonucu izleyebilirsin.')];
    if (_mode == SprintMode.bluff) {
      final actor = sprintActor(_room);
      final target = sprintSymbols[bluffTarget(_room)];
      return [
        Text('Masadaki iddia: $target'),
        if (phase == 'declare' && actor == _me) ...[
          const Text(
              'Kapalı oynayacağın kartı seç. İddian hedef simge olacak.'),
          for (final (i, card) in bluffHand(_room).indexed)
            _choice(sprintSymbols[card], phase, i),
        ] else if (phase == 'bluffVote' && actor != _me) ...[
          Text('${roster[actor]} bir $target oynadığını söylüyor.'),
          _choice('Doğru söylüyor', phase, 0),
          _choice('Blöf yapıyor', phase, 1),
        ] else
          Text('${roster[actor]} kartı oynuyor veya oyları bekliyor.'),
      ];
    }
    if (_mode == SprintMode.penalty) {
      final striker = sprintActor(_room);
      return [
        Text(striker == _me
            ? 'Vuracağın köşeyi seç.'
            : '${roster[striker]} vuracak. Atlayacağın köşeyi seç.'),
        for (final (i, zone) in penaltyZones.indexed) _choice(zone, phase, i),
      ];
    }
    final sabotage = _room['saboteur'] == _me;
    final puzzle = stationPuzzles[stationPuzzleIndex(_room, _sector)];
    return [
      Text(
          'Rolün: ${sabotage ? 'Sabotajcı' : 'Mürettebat'}  ·  Onarım: ${_room['repairs'] ?? 0}/5'),
      if (phase == 'stationVote') ...[
        const Text('Kimi çıkaracaksınız? En az iki ortak oy gerekir.'),
        for (final (i, id) in players.indexed)
          if (id != _me && !out.containsKey(id))
            _choice(roster[id] as String, phase, i),
        _choice('Pas geç', phase, players.length),
      ] else if (sabotage) ...[
        const Text(
            'Bir terminali sabote et. Orada onarım için iki doğru cevap gerekecek.'),
        for (final (i, name) in stationNames.indexed) _choice(name, phase, i),
      ] else ...[
        Wrap(spacing: 8, children: [
          for (final (i, name) in stationNames.indexed)
            ChoiceChip(
                label: Text(name),
                selected: _sector == i,
                onSelected: _busy ? null : (_) => setState(() => _sector = i)),
        ]),
        const SizedBox(height: 12),
        Text('Sıradaki sayı: ${puzzle.prompt}',
            style: Theme.of(context).textTheme.titleLarge),
        for (final (i, answer) in puzzle.choices.indexed)
          _choice(answer, phase, _sector * 3 + i),
      ],
    ];
  }
}
