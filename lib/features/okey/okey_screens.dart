import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/az_online_lobby.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/landscape_table_page.dart';
import 'okey_match.dart';
import 'okey_table_view.dart';

const _codePrefix = 'ok2:';

class OkeyLobbyScreen extends StatefulWidget {
  const OkeyLobbyScreen(
      {super.key, this.mode = 'okey', this.initialCode, this.table = false});
  final String mode;
  final String? initialCode;
  final bool table;

  @override
  State<OkeyLobbyScreen> createState() => _OkeyLobbyState();
}

class _OkeyLobbyState extends State<OkeyLobbyScreen> {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _code = TextEditingController();
  String? _name;
  bool _busy = false;

  String get _title => widget.mode == '101' ? '101 Okey' : 'Klasik Okey';

  @override
  void initState() {
    super.initState();
    seedRoomCode(_code, widget.initialCode);
    if (!widget.table) unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final stored = await _storage.getPlayerName();
      if (!mounted) return;
      setState(() => _name = stored);
      if (widget.initialCode != null) await _connect(create: false);
    } catch (_) {
      // The player can enter a name and join manually.
    }
  }

  Future<void> _rename() async {
    final name = await showNameDialog(context,
        current: _name, accentColor: Theme.of(context).colorScheme.primary);
    if (!mounted || name == null) return;
    setState(() => _name = name);
    try {
      await _storage.setPlayerName(name);
    } catch (_) {}
  }

  Future<void> _connect({required bool create}) async {
    if (_busy) return;
    final code = _code.text.trim().toUpperCase();
    if (!create && !RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      context.snack('Altı karakterli oda kodunu gir.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (!widget.table && _name == null) await _rename();
      if (!mounted || (!widget.table && _name == null)) return;
      final String id;
      String? seat;
      if (create) {
        seat = widget.table ? 'table' : 'p1';
        id = await _rooms.createRoom(gamePath: GamePaths.okey, data: {
          'code': '$_codePrefix${_rooms.generateCode()}',
          'status': 'waiting',
          'mode': widget.mode,
          'rulesVersion': 2,
          'host': seat,
          'createdAt': ServerValue.timestamp,
          'players': {
            seat: {'name': widget.table ? 'Ortak ekran' : _name, 'isHost': true}
          },
        });
      } else {
        final found = await _rooms.findByCode(
            gamePath: GamePaths.okey, code: '$_codePrefix$code');
        if (!mounted) return;
        if (found == null) {
          context
              .snack('Oda bulunamadı. Kodu ve uygulama sürümünü kontrol et.');
          return;
        }
        if (found.data['rulesVersion'] != 2) {
          context.snack(
              'Bu oda eski sürümle açılmış. Güncel uygulamadan yeni oda kur.');
          return;
        }
        id = found.id;
        final joined = await _rooms.transactRoom(
          gamePath: GamePaths.okey,
          roomId: id,
          update: (current) {
            final next = joinOkeyRoom(current, _name!);
            final prior = okeyMap(current['players']);
            seat = next == null
                ? null
                : okeySeats(next).firstWhere((key) => !prior.containsKey(key));
            return next;
          },
        );
        if (!mounted) return;
        if (!joined.committed || !joined.snapshot.exists || seat == null) {
          context.snack('Oda dolu, kapanmış veya oyun başlamış.');
          return;
        }
      }
      if (!mounted || seat == null) return;
      final joinedSeat = seat!;
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) =>
            LandscapeTablePage(child: _OkeyTable(roomId: id, seat: joinedSeat)),
      ));
    } catch (error) {
      debugPrint('Okey oda bağlantısı: $error');
      if (mounted)
        context.snack('Odaya bağlanılamadı. İnternet bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.table
      ? Scaffold(
          appBar: AppBar(title: Text('$_title · Ortak ekran')),
          body: Center(
              child: FilledButton.icon(
            autofocus: true,
            onPressed: _busy ? null : () => _connect(create: true),
            icon: const Icon(Icons.tv_rounded),
            label: Text(_busy ? 'Masa kuruluyor…' : 'Firebase masası kur'),
          )),
        )
      : AZOnlineLobby(
          title: _title,
          icon: Icons.table_restaurant_rounded,
          summary: widget.mode == '101'
              ? '21 taş · 101 puan veya 5 çiftle aç'
              : '14 taş · Seri, per veya 7 çiftle bitir',
          instructions: 'Arkadaşların oda koduyla veya QR ile katılabilir.',
          playerName: _name,
          codeController: _code,
          loading: _busy,
          onRename: _rename,
          onCreate: () => _connect(create: true),
          onJoin: () => _connect(create: false),
        );
}

class _OkeyTable extends StatefulWidget {
  const _OkeyTable({required this.roomId, required this.seat});
  final String roomId, seat;

  @override
  State<_OkeyTable> createState() => _OkeyTableState();
}

class _OkeyTableState extends State<_OkeyTable> {
  final _rooms = RoomService.instance;
  final _rack = List<String?>.filled(22, null);
  final _selected = <String>{};
  final _groups = <List<String>>[];
  OkeyRoom _room = {};
  StreamSubscription<OkeyRoom?>? _watch;
  bool _busy = false;
  bool _leaving = false;
  bool _pairs = false;
  bool _reported = false;
  int? _arrangedPoints;
  int _arrangedGroupCount = 0;
  String? _error;
  String? _lastDraw;

  bool get _table => widget.seat == 'table';
  bool get _is101 => _room['mode'] == '101';
  bool get _host => _room['host'] == widget.seat;
  OkeyRoom get _players => okeyMap(_room['players']);
  OkeyRoom get _mine => okeyMap(_players[widget.seat]);

  @override
  void initState() {
    super.initState();
    _watch = _rooms
        .watchRoom(gamePath: GamePaths.okey, roomId: widget.roomId)
        .listen(_observe, onError: (Object _) {
      if (mounted) setState(() => _error = 'Masa bağlantısı kesildi.');
    });
    unawaited(_rooms.registerPresence(
        gamePath: GamePaths.okey,
        roomId: widget.roomId,
        playerKey: widget.seat,
        isHost: false));
  }

  void _observe(OkeyRoom? data) {
    if (!mounted || _leaving) return;
    if (data == null) {
      context.snack('Masa kapatıldı.');
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      final previous = _room;
      _room = data;
      final hand = okeyTiles(_mine['hand']);
      if (data['turn'] != widget.seat || data['phase'] == 'draw')
        _lastDraw = null;
      if (data['turn'] == widget.seat &&
          previous['phase'] == 'draw' &&
          data['phase'] == 'discard') {
        _lastDraw =
            hand.where((tile) => !_rack.contains(tile.id)).firstOrNull?.id;
      }
      final ids = hand.map((tile) => tile.id).toSet();
      for (var index = 0; index < _rack.length; index++) {
        if (!ids.contains(_rack[index])) _rack[index] = null;
      }
      for (final id in ids.where((id) => !_rack.contains(id))) {
        final slot = _rack.indexOf(null);
        if (slot != -1) _rack[slot] = id;
      }
      _selected.removeWhere((id) => !ids.contains(id));
      _groups.removeWhere((group) => !group.every(ids.contains));
    });
    if (!_table &&
        !_reported &&
        data['status'] == 'finished' &&
        data['abandoned'] != true) {
      _reported = true;
      unawaited(ProfileService.instance
          .reportGameResult(
            gameId: _is101 ? 'okey101' : 'okey',
            resultId: widget.roomId,
            won: data['winner'] == widget.seat,
          )
          .then<void>((_) {}, onError: (Object _) {}));
    }
  }

  @override
  void dispose() {
    unawaited(_watch?.cancel());
    unawaited(_unregister());
    super.dispose();
  }

  Future<void> _unregister() => _rooms.unregisterPresence(
      gamePath: GamePaths.okey, roomId: widget.roomId, playerKey: widget.seat);

  Future<void> _action(OkeyRoom? Function(OkeyRoom) update) async {
    if (_busy || _leaving) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? rejected;
    try {
      final result = await _rooms
          .transactRoom(
              gamePath: GamePaths.okey,
              roomId: widget.roomId,
              update: (current) {
                rejected = null;
                try {
                  return update(current);
                } on OkeyMoveError catch (error) {
                  rejected = error.message;
                  return null;
                }
              })
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (!result.committed) {
        setState(() =>
            _error = rejected ?? 'Hamle geçerli değil veya sıra değişti.');
      }
    } catch (error) {
      debugPrint('Okey hamlesi: $error');
      if (mounted)
        setState(() => _error = 'Hamle gönderilemedi. Yeniden dene.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _deal() {
    final seed = Random.secure().nextInt(1 << 30);
    unawaited(_action((current) => dealOkeyRoom(current, widget.seat, seed)));
  }

  void _play(String move, {String? tile, int? meldIndex}) {
    final revision = _room['revision'] as int;
    final groups = _groups.map(List<String>.of).toList();
    final pairs = _mine['opened'] == true ? _mine['pairs'] == true : _pairs;
    unawaited(_action((current) => playOkeyMove(
          current,
          widget.seat,
          revision,
          move,
          tile: tile,
          groups: groups,
          pairs: pairs,
          meldIndex: meldIndex,
        )));
  }

  Future<void> _leave() async {
    if (_busy || _leaving) return;
    _leaving = true;
    try {
      if (_room['status'] == 'waiting') {
        await _rooms.leaveRoom(
            gamePath: GamePaths.okey,
            roomId: widget.roomId,
            playerKey: widget.seat,
            isHost: _host);
      } else if (_room['status'] == 'playing') {
        await _rooms.transactRoom(
            gamePath: GamePaths.okey,
            roomId: widget.roomId,
            update: (current) => current['status'] == 'playing'
                ? {...current, 'status': 'finished', 'abandoned': true}
                : null);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _leaving = false;
      if (mounted) setState(() => _error = 'Masadan ayrılamadın. Tekrar dene.');
    }
  }

  Widget _tile(OTile tile,
      {double width = 28, bool selected = false, VoidCallback? onTap}) {
    final value = effectiveOkeyTile(tile, _room);
    const colors = [
      Color(0xff825400),
      Color(0xff155a9e),
      Color(0xffa02021),
      Color(0xff24262c)
    ];
    final wild = isWildTile(tile, _room);
    return OkeyStoneFace(
      width: width,
      label: wild
          ? '★'
          : tile.joker
              ? '${value.num}·'
              : '${value.num}',
      ink: colors[value.color.index],
      selected: selected,
      marked: tile.id == _lastDraw,
      onTap: onTap,
    );
  }

  void _moveStone(String id, int index) {
    final from = _rack.indexOf(id);
    if (from < 0 || index < 0 || index >= _rack.length) return;
    setState(() {
      _rack[from] = _rack[index];
      _rack[index] = id;
    });
  }

  void _sortRack(Map<String, OTile> hand) {
    final sorted = hand.values.toList()
      ..sort((a, b) {
        final left = effectiveOkeyTile(a, _room);
        final right = effectiveOkeyTile(b, _room);
        return (left.color.index * 14 + left.num)
            .compareTo(right.color.index * 14 + right.num);
      });
    setState(() {
      for (var index = 0; index < _rack.length; index++) {
        _rack[index] = index < sorted.length ? sorted[index].id : null;
      }
      _arrangedPoints = null;
      _arrangedGroupCount = 0;
    });
  }

  void _arrangeRack(Map<String, OTile> hand) {
    final arrangement = arrangeOkeyHand(hand.values.toList(), _room);
    setState(() {
      for (var index = 0; index < _rack.length; index++) {
        _rack[index] =
            index < arrangement.ids.length ? arrangement.ids[index] : null;
      }
      _arrangedPoints = arrangement.points;
      _arrangedGroupCount = arrangement.groups.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _is101 ? '101 Okey' : 'Klasik Okey';
    final seats = okeySeats(_room);
    final phase = _room['phase'];
    final turn = _room['turn'] as String?;
    final mine = widget.seat == turn && !_table;
    final status = _room['status'];
    final discards = okeyMap(_room['discards']);
    final hand = {for (final tile in okeyTiles(_mine['hand'])) tile.id: tile};
    final melds = (_room['melds'] as List? ?? []).map(okeyMap).toList();
    final requiredTile = _room['requiredTile'] as String?;
    final pairs = _mine['opened'] == true ? _mine['pairs'] == true : _pairs;
    final single = _selected.length == 1 ? _selected.single : null;
    final staged = _groups.expand((group) => group).toSet();
    final previous =
        mine ? discards[previousOkeySeat(_room, widget.seat)] : null;
    final needed = _room['host'] == 'table' ? 4 : 2;
    final canDraw = mine && phase == 'draw' && !_busy;
    final canDiscard =
        mine && phase == 'discard' && !_busy && requiredTile == null;
    final layoutSeats = [
      for (final seat in seats)
        (
          key: seat,
          name: _players[seat]['name'] as String? ?? seat,
          count: (_players[seat]['hand'] as List?)?.length ?? 0
        )
    ];
    final lastDiscard = _room['lastDiscardSeat'];
    final openStone = mine ? previous : discards[lastDiscard];
    return AZLeaveGuard(
      onLeave: _leave,
      child: Scaffold(
        appBar:
            AppBar(title: Text(title), leading: BackButton(onPressed: _leave)),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _table ? 1050 : 640),
          child: Column(children: [
            Expanded(
                child: ListView(padding: const EdgeInsets.all(16), children: [
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (status == null) const LinearProgressIndicator(),
              if (status == 'waiting') ...[
                AZRoomCode(
                    code: (_room['code'] as String).split(':').last,
                    accentColor: Theme.of(context).colorScheme.primary,
                    inviteGame: _is101 ? 'okey101' : 'okey'),
                const SizedBox(height: 14),
                Text(
                    '$needed oyuncuyla başlanır · ${seats.length}/4 koltuk dolu'),
              ],
              if (status != 'playing' && seats.isNotEmpty)
                Wrap(spacing: 8, children: [
                  for (final seat in seats)
                    Chip(
                        label: Text(
                            '${seat == turn ? '▶ ' : ''}${_players[seat]['name']}'
                            '${seat == widget.seat ? ' (sen)' : ''}'
                            '${status == 'waiting' ? '' : ' · ${okeyTiles(_players[seat]['hand']).length} taş'}')),
                ]),
              if (status == 'waiting' && _host)
                FilledButton.icon(
                    autofocus: true,
                    onPressed: _busy || seats.length < needed ? null : _deal,
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Taşları dağıt')),
              if (status == 'playing') ...[
                OkeyFeltBoard(
                  seats: layoutSeats,
                  local: widget.seat,
                  turn: turn,
                  status: mine
                      ? (phase == 'draw'
                          ? 'Sıra sende · Kapalı veya açık taşı çek'
                          : 'Sıra sende · Istakandan bir taş at')
                      : 'Sıra ${_players[turn]?['name'] ?? ''} oyuncusunda',
                  stock: (_room['deck'] as List?)?.length ?? 0,
                  indicator: _room['indicator'] is Map
                      ? _tile(OTile.fromMap(_room['indicator'] as Map))
                      : null,
                  openStone:
                      openStone is Map ? _tile(OTile.fromMap(openStone)) : null,
                  onStock: canDraw ? () => _play('stock') : null,
                  onOpen: canDraw && previous != null
                      ? () => _play('discardDraw')
                      : null,
                  onDrop:
                      canDiscard ? (id) => _play('discard', tile: id) : null,
                ),
                const SizedBox(height: 13),
                if (discards.isNotEmpty)
                  Wrap(spacing: 10, runSpacing: 4, children: [
                    for (final seat in seats)
                      if (discards[seat] case final Map discarded)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          _tile(OTile.fromMap(discarded), width: 20),
                          const SizedBox(width: 4),
                          Text(_players[seat]['name'] as String? ?? seat),
                        ]),
                  ]),
                if (melds.isNotEmpty) const Text('Masaya açılan gruplar'),
                for (final (index, group) in melds.indexed)
                  Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tile in okeyTiles(group['tiles']))
                          _tile(tile),
                        if (_is101 &&
                            mine &&
                            phase == 'discard' &&
                            _mine['opened'] == true &&
                            single != null &&
                            group['pairs'] != true)
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _play('extend',
                                      tile: single, meldIndex: index),
                              child: const Text('Bu gruba işle')),
                      ]),
                if (mine && phase == 'discard') ...[
                  if (_is101) ...[
                    if (_mine['opened'] != true)
                      SwitchListTile(
                          title: const Text('Çift aç'),
                          value: pairs,
                          onChanged: _busy
                              ? null
                              : (value) => setState(() {
                                    _pairs = value;
                                    _groups.clear();
                                  })),
                    for (final (index, group) in _groups.indexed)
                      Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final id in group)
                              if (hand[id] case final OTile tile) _tile(tile),
                            TextButton(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                        setState(() => _groups.removeAt(index)),
                                child: const Text('Grubu geri al')),
                          ]),
                    Text(pairs
                        ? '${_groups.length} çift hazır'
                        : '${_groups.fold<int>(0, (sum, group) => sum + okeyMeldScore(group.map((id) => hand[id]!).toList(), _room))} puan hazır'),
                  ],
                ],
              ],
              if (status == 'finished')
                Text(
                    _room['abandoned'] == true
                        ? 'Masa kapandı.'
                        : _room['winner'] == null
                            ? 'Kapalı taş kalmadı. El berabere.'
                            : '${_players[_room['winner']]['name']} eli bitirdi.',
                    style: Theme.of(context).textTheme.titleLarge),
              if (_busy) const LinearProgressIndicator(),
            ])),
            if (status == 'playing' && !_table)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Istakan · ${hand.length} taş',
                            style: Theme.of(context).textTheme.titleSmall),
                        TextButton(
                            onPressed: () => _sortRack(hand),
                            child: const Text('Renge göre diz')),
                        TextButton.icon(
                            onPressed: () => _arrangeRack(hand),
                            icon: const Icon(Icons.auto_awesome, size: 17),
                            label: const Text('En iyi seri/per')),
                      ]),
                  if (_arrangedPoints != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$_arrangedGroupCount geçerli grup · $_arrangedPoints puan. Taşları uzun basıp sürükleyerek elle de ayarlayabilirsin.',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  OkeyRack(
                    ids: [
                      for (final id in _rack)
                        if (staged.contains(id)) null else id
                    ],
                    onMove: _moveStone,
                    buildStone: (id, width, {required feedback}) => _tile(
                      hand[id]!,
                      width: width,
                      selected: _selected.contains(id),
                      onTap: feedback
                          ? null
                          : () => setState(() {
                                if (!_selected.remove(id)) {
                                  if (!_is101) _selected.clear();
                                  _selected.add(id);
                                }
                              }),
                    ),
                  ),
                  if (mine && phase == 'discard')
                    Wrap(spacing: 5, runSpacing: 2, children: [
                      if (requiredTile != null)
                        OutlinedButton(
                            onPressed: _busy ? null : () => _play('return'),
                            child: const Text('Açık taşı geri bırak')),
                      if (requiredTile == null)
                        FilledButton(
                            onPressed: !canDiscard || single == null
                                ? null
                                : () => _play('discard', tile: single),
                            child: const Text('Taşı at')),
                      if (!_is101)
                        OutlinedButton(
                            onPressed: !canDiscard || single == null
                                ? null
                                : () => _play('win', tile: single),
                            child: const Text('At ve bitir')),
                      if (_is101)
                        TextButton(
                            onPressed: _busy ||
                                    (pairs
                                        ? _selected.length != 2
                                        : _selected.length < 3)
                                ? null
                                : () => setState(() {
                                      _groups.add(_selected.toList());
                                      _selected.clear();
                                    }),
                            child: const Text('Grup ayır')),
                      if (_is101 && _groups.isNotEmpty)
                        FilledButton.tonal(
                          onPressed: _busy ? null : () => _play('meld'),
                          child: Text(_mine['opened'] == true
                              ? 'Grupları işle'
                              : 'El aç'),
                        ),
                    ]),
                ]),
              ),
          ]),
        ))),
      ),
    );
  }
}
