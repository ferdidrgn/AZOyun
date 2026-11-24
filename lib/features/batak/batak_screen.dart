import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/az_online_lobby.dart';
import '../../core/widgets/landscape_table_page.dart';
import '../../core/widgets/az_widgets.dart';
import 'batak_match.dart';
import 'batak_table.dart';

// Separate invitations inside the existing, provisioned card-game collection.
const _path = GamePaths.deck;
const _prefix = 'batak:';

class BatakLobbyScreen extends StatefulWidget {
  const BatakLobbyScreen({super.key, this.initialCode, this.table = false});
  final String? initialCode;
  final bool table;

  @override
  State<BatakLobbyScreen> createState() => _BatakLobbyState();
}

class _BatakLobbyState extends State<BatakLobbyScreen> {
  final _rooms = RoomService.instance;
  final _code = TextEditingController();
  String? _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    seedRoomCode(_code, widget.initialCode);
    if (!widget.table) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final stored = await StorageService.instance.getPlayerName();
      if (!mounted) return;
      if (_name == null) setState(() => _name = stored);
      if (widget.initialCode != null) await _connect(create: false);
    } catch (_) {
      // The player can still enter a name manually.
    }
  }

  Future<void> _rename() async {
    final chosen = await showNameDialog(context,
        current: _name, accentColor: Theme.of(context).colorScheme.primary);
    if (!mounted || chosen == null) return;
    setState(() => _name = chosen);
    try {
      await StorageService.instance.setPlayerName(chosen);
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
      final token = await StorageService.instance.getPlayerToken();
      if (!mounted) return;
      final String id;
      String? seat;
      if (create) {
        seat = widget.table ? 'table' : 'p1';
        id = await _rooms.createRoom(gamePath: _path, data: {
          'kind': 'batak',
          'status': 'waiting',
          'host': seat,
          'code': '$_prefix${_rooms.generateCode()}',
          'createdAt': ServerValue.timestamp,
          'players': {
            seat: {'name': widget.table ? 'Ortak ekran' : _name, 'token': token}
          },
        }).timeout(const Duration(seconds: 10));
      } else {
        final found = await _rooms
            .findByCode(gamePath: _path, code: '$_prefix$code')
            .timeout(const Duration(seconds: 9));
        if (!mounted) return;
        if (found == null) {
          context.snack('Batak odası bulunamadı.');
          return;
        }
        id = found.id;
        final result = await _rooms
            .transactRoom(
                gamePath: _path,
                roomId: id,
                update: (current) {
                  final next = joinBatak(current, _name!, token: token);
                  seat = next == null ? null : batakSeatForToken(next, token);
                  return next;
                })
            .timeout(const Duration(seconds: 10));
        if (!mounted) return;
        if (!result.committed || !result.snapshot.exists || seat == null) {
          context.snack('Oda dolu, kapanmış veya oyun başlamış.');
          return;
        }
      }
      if (!mounted || seat == null) return;
      final localSeat = seat!;
      await Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => LandscapeTablePage(
              child: _BatakRoomScreen(id: id, seat: localSeat))));
    } catch (error) {
      debugPrint('Batak oda bağlantısı: $error');
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
          appBar: AppBar(title: const Text('Batak · Ortak ekran')),
          body: Center(
              child: FilledButton.icon(
                  autofocus: true,
                  onPressed: _busy ? null : () => _connect(create: true),
                  icon: const Icon(Icons.tv_rounded),
                  label: Text(_busy ? 'Masa kuruluyor…' : 'Batak masası kur'))))
      : AZOnlineLobby(
          title: 'İhaleli Batak',
          icon: Icons.style_rounded,
          summary: '4 oyuncu · Eşsiz · 4 dağıtım',
          instructions:
              '52 kart, kişi başı 13 kart. İhale 5 ile açılır. Herkes pas derse '
              'ilk oyuncuya 4 kalır. İhaleci kozu seçer. Renge uyma, büyütme ve koz '
              'atma zorunludur. Koz kırılmadan kozla açılamaz. Hedefini tutturamayan '
              'ihaleci ve hiç el alamayan oyuncu ihale kadar eksi alır. Diğerleri '
              'aldıkları el kadar puan alır. Dört dağıtım sonunda en yüksek puan kazanır.',
          playerName: _name,
          codeController: _code,
          loading: _busy,
          onRename: _rename,
          onCreate: () => _connect(create: true),
          onJoin: () => _connect(create: false));
}

class _BatakRoomScreen extends StatefulWidget {
  const _BatakRoomScreen({required this.id, required this.seat});
  final String id, seat;
  @override
  State<_BatakRoomScreen> createState() => _BatakRoomState();
}

class _BatakRoomState extends State<_BatakRoomScreen> {
  final _rooms = RoomService.instance;
  BatakRoom _room = {};
  StreamSubscription<BatakRoom?>? _watch;
  Timer? _collectTimer;
  int? _collectRevision;
  bool _busy = false, _leaving = false;
  String? _error;
  bool get _isTable => widget.seat == 'table';
  bool get _host => _room['host'] == widget.seat;
  String _name(Object? seat) =>
      batakMap(batakMap(_room['players'])[seat])['name'] as String? ?? 'Oyuncu';

  @override
  void initState() {
    super.initState();
    _watch = _rooms
        .watchRoom(gamePath: _path, roomId: widget.id)
        .listen(_onRoom, onError: (Object _) {
      if (mounted) setState(() => _error = 'Masa bağlantısı kesildi.');
    });
    unawaited(_rooms.registerPresence(
        gamePath: _path,
        roomId: widget.id,
        playerKey: widget.seat,
        isHost: false));
  }

  void _onRoom(BatakRoom? snapshot) {
    if (!mounted || _leaving) return;
    if (snapshot == null) {
      context.snack('Masa kapatıldı.');
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _room = snapshot;
      _error = null;
    });
    // Only the winning seat advances the trick. Revision checks make timer and
    // manual recovery safe even if both reach Firebase together.
    final revision = snapshot['revision'] as int?;
    if (snapshot['phase'] == 'collect' &&
        snapshot['turn'] == widget.seat &&
        revision != _collectRevision) {
      _collectRevision = revision;
      _collectTimer?.cancel();
      _collectTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && !_leaving && _room['revision'] == revision && !_busy) {
          _play('collect');
        }
      });
    }
  }

  @override
  void dispose() {
    _collectTimer?.cancel();
    unawaited(_watch?.cancel());
    unawaited(_rooms.unregisterPresence(
        gamePath: _path, roomId: widget.id, playerKey: widget.seat));
    super.dispose();
  }

  Future<void> _update(BatakRoom? Function(BatakRoom) move) async {
    if (_busy || _leaving) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _rooms
          .transactRoom(gamePath: _path, roomId: widget.id, update: move)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (!result.committed || !result.snapshot.exists) {
        setState(() => _error =
            'Masa değişti veya bu hamle geçersiz. Sıranı ve kartını kontrol et.');
      }
    } catch (error) {
      debugPrint('Batak hamlesi: $error');
      if (mounted)
        setState(() => _error = 'Hamle gönderilemedi. Yeniden dene.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _play(String action, {int? bid, int? trump, int? card}) {
    final revision = _room['revision'];
    if (revision is! int) return;
    unawaited(_update((room) => playBatak(room, widget.seat, revision, action,
        bid: bid, trump: trump, card: card)));
  }

  void _deal() {
    final seed = Random.secure().nextInt(1 << 30);
    final revision = _room['revision'];
    unawaited(_update((room) => room['revision'] == revision
        ? dealBatak(room, widget.seat, seed)
        : null));
  }

  Future<void> _leave() async {
    if (_busy || _leaving) return;
    _leaving = true;
    try {
      if (_room['status'] == 'waiting') {
        await _rooms.leaveRoom(
            gamePath: _path,
            roomId: widget.id,
            playerKey: widget.seat,
            isHost: _host);
      } else if (_room['status'] == 'playing') {
        await _rooms
            .transactRoom(
                gamePath: _path,
                roomId: widget.id,
                update: (room) => room['status'] == 'playing'
                    ? {...room, 'status': 'finished', 'abandoned': true}
                    : null)
            .timeout(const Duration(seconds: 10));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _leaving = false;
      if (mounted)
        setState(() => _error = 'Masadan ayrılamadın. Yeniden dene.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _room['status'];
    final phase = _room['phase'];
    final playing = status == 'playing';
    final active = playing && _room['turn'] == widget.seat && !_isTable;
    final seats = batakSeats(_room);
    final theme = Theme.of(context);
    final trump = _room['trump'] as int?;
    return AZLeaveGuard(
        onLeave: _leave,
        child: Scaffold(
          appBar: AppBar(
              title: Text(_isTable ? 'Batak · Masa' : 'İhaleli Batak'),
              leading: BackButton(onPressed: _leave)),
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _isTable ? 760 : 600),
            child: Column(children: [
              if (_busy || status == null) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error))),
              Expanded(
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                if (status == 'waiting') ...[
                  AZRoomCode(
                      code: (_room['code'] as String).split(':').last,
                      accentColor: theme.colorScheme.primary,
                      inviteGame: 'batak'),
                  const SizedBox(height: 12),
                  Text('${seats.length}/4 oyuncu · Dört kişiyle başlar',
                      style: theme.textTheme.titleMedium),
                  for (final id in seats)
                    ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_rounded),
                        title: Text(
                            '${_name(id)}${id == widget.seat ? ' · Sen' : ''}')),
                  if (_host)
                    FilledButton(
                        onPressed: _busy || seats.length != 4 ? null : _deal,
                        autofocus: true,
                        child: const Text('Kartları dağıt')),
                ],
                if (playing || status == 'finished') ...[
                  if (playing)
                    Text(
                        phase == 'roundEnd'
                            ? 'Dağıtım tamamlandı'
                            : 'Sıra ${_name(_room['turn'])} oyuncusunda',
                        style: theme.textTheme.titleLarge),
                  if (status == 'finished')
                    Text(
                        _room['abandoned'] == true
                            ? 'Masa kapandı.'
                            : 'Kazanan · ${batakMap(_room['winners']).keys.map(_name).join(', ')}',
                        style: theme.textTheme.titleLarge),
                  Text(
                      'Dağıtım ${_room['round']}/4 · İhale ${_room['contract'] ?? 0}'
                      '${_room['bidder'] == null ? '' : ' · ${_name(_room['bidder'])}'}'
                      '${trump == null ? '' : ' · Koz ${batakSuitNames[trump]}'}'),
                  if (_room['message'] case final String message) Text(message),
                  const SizedBox(height: 10),
                  BatakTable(
                      room: _room,
                      seat: widget.seat,
                      canPlay: !_busy && active,
                      onPlay: (card) => _play('card', card: card)),
                  const SizedBox(height: 12),
                  if (active && phase == 'bid') ...[
                    Text('İhaleyi yükselt veya pas de',
                        style: theme.textTheme.titleMedium),
                    Wrap(spacing: 6, children: [
                      for (var bid = max(5, (_room['contract'] as int) + 1);
                          bid <= 13;
                          bid++)
                        FilledButton.tonal(
                            onPressed:
                                _busy ? null : () => _play('bid', bid: bid),
                            child: Text('$bid')),
                      OutlinedButton(
                          onPressed: _busy ? null : () => _play('pass'),
                          child: const Text('Pas')),
                    ]),
                  ],
                  if (active && phase == 'trump') ...[
                    Text('Koz seç', style: theme.textTheme.titleMedium),
                    Wrap(spacing: 6, children: [
                      for (var suit = 0; suit < 4; suit++)
                        FilledButton.tonal(
                            onPressed: _busy
                                ? null
                                : () => _play('trump', trump: suit),
                            child: Text(
                                '${batakSuits[suit]} ${batakSuitNames[suit]}'))
                    ]),
                  ],
                  if (active && phase == 'collect')
                    TextButton(
                        onPressed: _busy ? null : () => _play('collect'),
                        child: const Text('Eli topla ve devam et')),
                  if (phase == 'roundEnd' || status == 'finished') _scores(),
                  if (_host && playing && phase == 'roundEnd')
                    FilledButton(
                        onPressed: _busy ? null : _deal,
                        child: const Text('Sonraki dağıtım')),
                  if (batakTrick(_room['lastTrick']).isNotEmpty)
                    ExpansionTile(
                        title: const Text('Son alınan el'),
                        children: [
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            for (final play in batakTrick(_room['lastTrick']))
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                SizedBox(
                                    width: 65,
                                    child: Text(_name(play['seat']),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center)),
                                BatakCard(card: play['card'] as int, width: 45),
                              ]),
                          ]),
                          const SizedBox(height: 12),
                        ]),
                ],
              ])),
              if (!_isTable && playing && phase != 'roundEnd')
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        border: Border(
                            top: BorderSide(
                                color: theme.colorScheme.outlineVariant))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (phase == 'play')
                        Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Text(batakPlayHint(_room, widget.seat),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center)),
                      BatakHand(
                          room: _room,
                          seat: widget.seat,
                          busy: _busy,
                          onPlay: (card) => _play('card', card: card)),
                    ])),
            ]),
          ))),
        ));
  }

  Widget _scores() {
    final players = batakMap(_room['players']);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Text('Yazboz', style: Theme.of(context).textTheme.titleLarge),
      for (final entry in batakMap(_room['history']).entries) ...[
        const Divider(),
        Text(
            '${entry.key.substring(1)}. dağıtım · ${_name(batakMap(entry.value)['bidder'])}'
            ' · ${batakMap(entry.value)['contract']} ihale'),
        for (final id in batakPlayerSeats)
          Row(children: [
            Expanded(
                child: Text(_name(id),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${batakMap(batakMap(entry.value)['taken'])[id]} el   '
                '${batakMap(batakMap(entry.value)['delta'])[id]} p'),
          ]),
      ],
      const Divider(),
      for (final id in batakPlayerSeats)
        Row(children: [
          Expanded(
              child: Text(_name(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Text('Toplam ${batakMap(players[id])['score']} p',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
    ]);
  }
}
