import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/az_online_lobby.dart';
import '../../core/widgets/az_widgets.dart';
import 'mahalle_board.dart';
import 'mahalle_match.dart';

// Use the already provisioned Firebase collection. The prefix keeps the
// word-based city game's six-character invitations separate.
const _path = GamePaths.cityPuzzle;
const _prefix = 'mahalle:';

class MahalleLobbyScreen extends StatefulWidget {
  const MahalleLobbyScreen({super.key, this.initialCode, this.table = false});
  final String? initialCode;
  final bool table;

  @override
  State<MahalleLobbyScreen> createState() => _MahalleLobbyState();
}

class _MahalleLobbyState extends State<MahalleLobbyScreen> {
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
      // Manual setup remains available if device storage is unavailable.
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
      final String id;
      String? seat;
      if (create) {
        seat = widget.table ? 'table' : 'p1';
        id = await _rooms.createRoom(gamePath: _path, data: {
          'kind': 'mahalle',
          'code': '$_prefix${_rooms.generateCode()}',
          'status': 'waiting',
          'host': seat,
          'createdAt': ServerValue.timestamp,
          'players': {
            seat: {'name': widget.table ? 'Ortak ekran' : _name}
          },
        });
      } else {
        final room = await _rooms
            .findByCode(gamePath: _path, code: '$_prefix$code')
            .timeout(const Duration(seconds: 9));
        if (!mounted) return;
        if (room == null) {
          context.snack('Mahalleler odası bulunamadı.');
          return;
        }
        id = room.id;
        final result = await _rooms.transactRoom(
            gamePath: _path,
            roomId: id,
            update: (current) {
              final next = joinMahalle(current, _name!);
              final before = mahalleSeats(current);
              seat = next == null
                  ? null
                  : mahalleSeats(next).firstWhere((id) => !before.contains(id));
              return next;
            });
        if (!mounted) return;
        if (!result.committed || !result.snapshot.exists || seat == null) {
          context.snack('Oda dolu, kapanmış veya oyun başlamış.');
          return;
        }
      }
      if (!mounted || seat == null) return;
      final localSeat = seat!;
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => _MahalleRoomScreen(id: id, seat: localSeat),
      ));
    } catch (error) {
      debugPrint('Mahalleler oda bağlantısı: $error');
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
          appBar: AppBar(title: const Text('Mahalleler · Ortak ekran')),
          body: Center(
              child: FilledButton.icon(
            autofocus: true,
            onPressed: _busy ? null : () => _connect(create: true),
            icon: const Icon(Icons.tv_rounded),
            label: Text(_busy ? 'Masa kuruluyor…' : 'Mahalleler masası kur'),
          )),
        )
      : AZOnlineLobby(
          title: 'Mahalleler',
          icon: Icons.location_city_rounded,
          summary: '2–4 oyuncu · Zar, mülk ve kira',
          instructions:
              'Mahalleleri tamamla, mülklerini geliştir. On tur sonunda en yüksek servet kazanır.',
          playerName: _name,
          codeController: _code,
          loading: _busy,
          onRename: _rename,
          onCreate: () => _connect(create: true),
          onJoin: () => _connect(create: false),
        );
}

class _MahalleRoomScreen extends StatefulWidget {
  const _MahalleRoomScreen({required this.id, required this.seat});
  final String id, seat;
  @override
  State<_MahalleRoomScreen> createState() => _MahalleRoomState();
}

class _MahalleRoomState extends State<_MahalleRoomScreen> {
  final _rooms = RoomService.instance;
  MahalleRoom _room = {};
  StreamSubscription<MahalleRoom?>? _watch;
  bool _busy = false;
  bool _leaving = false;
  bool _reported = false;
  String? _error;
  int _selected = 0;

  bool get _isTable => widget.seat == 'table';
  MahalleRoom get _players => mahalleMap(_room['players']);

  @override
  void initState() {
    super.initState();
    _watch = _rooms.watchRoom(gamePath: _path, roomId: widget.id).listen(
      _onRoom,
      onError: (Object _) {
        if (mounted) setState(() => _error = 'Masa bağlantısı kesildi.');
      },
    );
    unawaited(_rooms.registerPresence(
        gamePath: _path,
        roomId: widget.id,
        playerKey: widget.seat,
        isHost: false));
  }

  void _onRoom(MahalleRoom? snapshot) {
    if (!mounted || _leaving) return;
    if (snapshot == null) {
      context.snack('Masa kapatıldı.');
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      final before = mahalleMap(_players[widget.seat])['position'];
      _room = snapshot;
      final after = mahalleMap(_players[widget.seat])['position'];
      if (after is int && before != after) _selected = after;
    });
    if (!_isTable &&
        !_reported &&
        snapshot['status'] == 'finished' &&
        snapshot['abandoned'] != true) {
      _reported = true;
      unawaited(ProfileService.instance
          .reportGameResult(
            gameId: 'family_city',
            resultId: widget.id,
            won: snapshot['winner'] == widget.seat,
          )
          .then<void>((_) {}, onError: (Object _) {}));
    }
  }

  @override
  void dispose() {
    unawaited(_watch?.cancel());
    unawaited(_rooms.unregisterPresence(
        gamePath: _path, roomId: widget.id, playerKey: widget.seat));
    super.dispose();
  }

  Future<void> _update(MahalleRoom? Function(MahalleRoom) move) async {
    if (_busy || _leaving) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? rejection;
    try {
      final result = await _rooms
          .transactRoom(
            gamePath: _path,
            roomId: widget.id,
            update: (current) {
              rejection = null;
              try {
                return move(current);
              } on MahalleMoveError catch (error) {
                rejection = error.message;
                return null;
              }
            },
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (!result.committed || !result.snapshot.exists) {
        setState(() => _error = rejection ?? 'Masa değişti. Yeniden dene.');
      }
    } catch (error) {
      debugPrint('Mahalleler hamlesi: $error');
      if (mounted)
        setState(() => _error = 'Hamle gönderilemedi. Bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _play(String action, {int? square, String? buyer, int? price}) {
    final revision = _room['revision'];
    if (revision is! int) return;
    final seed = Random.secure().nextInt(1 << 30);
    unawaited(_update((current) => playMahalle(
        current, widget.seat, revision, action,
        random: Random(seed), square: square, buyer: buyer, price: price)));
  }

  Future<void> _leave() async {
    if (_busy || _leaving) return;
    _leaving = true;
    try {
      if (_room['status'] == 'waiting' ||
          (_isTable && _room['status'] == 'playing')) {
        await _rooms.leaveRoom(
            gamePath: _path,
            roomId: widget.id,
            playerKey: widget.seat,
            isHost: _room['host'] == widget.seat);
      } else if (_room['status'] == 'playing') {
        await _rooms
            .transactRoom(
              gamePath: _path,
              roomId: widget.id,
              update: (current) => current['status'] == 'playing'
                  ? {...current, 'status': 'finished', 'abandoned': true}
                  : null,
            )
            .timeout(const Duration(seconds: 10));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _leaving = false;
      if (mounted)
        setState(() => _error = 'Masadan ayrılamadın. Yeniden dene.');
    }
  }

  Future<void> _trade(int square, List<String> buyers) async {
    final price = TextEditingController(text: '${districts[square].price}');
    var buyer = buyers.first;
    final offer = await showDialog<({String buyer, int price})>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, change) => AlertDialog(
                title: Text('${districts[square].name} · Satış teklifi'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButton<String>(
                      value: buyer,
                      isExpanded: true,
                      items: [
                        for (final id in buyers)
                          DropdownMenuItem(value: id, child: Text(_name(id)))
                      ],
                      onChanged: (id) {
                        if (id != null) change(() => buyer = id);
                      }),
                  TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Satış fiyatı')),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Vazgeç')),
                  FilledButton(
                      onPressed: () => Navigator.of(context).pop((
                            buyer: buyer,
                            price: int.tryParse(price.text) ?? 0,
                          )),
                      child: const Text('Teklif ver')),
                ],
              )),
    );
    price.dispose();
    if (mounted && offer != null)
      _play('trade', square: square, buyer: offer.buyer, price: offer.price);
  }

  String _name(Object? seat) =>
      mahalleMap(_players[seat])['name'] as String? ?? 'Oyuncu';

  @override
  Widget build(BuildContext context) {
    final status = _room['status'];
    final seats = mahalleSeats(_room);
    final theme = Theme.of(context);
    return AZLeaveGuard(
      onLeave: _leave,
      child: Scaffold(
        appBar: AppBar(
            title: Text(_isTable ? 'Mahalleler · Masa' : 'Mahalleler'),
            leading: BackButton(onPressed: _leave)),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _isTable ? 700 : 530),
          child: ListView(padding: const EdgeInsets.all(14), children: [
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            if (_busy || status == null) const LinearProgressIndicator(),
            if (status == 'waiting') ...[
              AZRoomCode(
                  code: (_room['code'] as String).split(':').last,
                  accentColor: theme.colorScheme.primary,
                  inviteGame: 'mahalle'),
              const SizedBox(height: 12),
              Text('${seats.length}/4 koltuk · Başlamak için en az 2 oyuncu'),
              if (_room['host'] == widget.seat)
                FilledButton(
                  autofocus: true,
                  onPressed: _busy || seats.length < 2
                      ? null
                      : () => _update(
                          (current) => startMahalle(current, widget.seat)),
                  child: const Text('Oyunu başlat'),
                ),
            ],
            Wrap(spacing: 6, children: [
              for (final id in seats)
                Chip(
                  avatar: CircleAvatar(backgroundColor: mahalleSeatColor(id)),
                  label: Text('${_name(id)}'
                      '${id == widget.seat ? ' (sen)' : ''}'
                      '${_players[id]['out'] == true ? ' · İflas' : _players[id]['money'] == null ? '' : ' · ${_players[id]['money']}'}'),
                ),
            ]),
            if (status == 'playing' || status == 'finished') ...[
              if (status == 'playing')
                Text(
                    'Sıra ${_name(mahalleMap(_room['auction'])['bidder'] ?? _room['turn'])} oyuncusunda',
                    style: theme.textTheme.titleLarge),
              if (status == 'finished')
                Text(
                    _room['abandoned'] == true
                        ? 'Masa kapandı.'
                        : _room['winner'] == null
                            ? 'Berabere'
                            : 'Kazanan · ${_name(_room['winner'])}',
                    style: theme.textTheme.titleLarge),
              if (_room['message'] case final String message) Text(message),
              const SizedBox(height: 8),
              MahalleBoard(
                  room: _room,
                  selected: _selected,
                  highlight: (square) => setState(() => _selected = square)),
              const SizedBox(height: 12),
              if (!_isTable && status == 'playing') ..._controls(seats),
            ],
          ]),
        ))),
      ),
    );
  }

  List<Widget> _controls(List<String> seats) {
    final phase = _room['phase'];
    final mine = _room['turn'] == widget.seat;
    final me = mahalleMap(_players[widget.seat]);
    final deeds = mahalleMap(_room['deeds']);
    final deed = mahalleMap(deeds['d$_selected']);
    final district = districts[_selected];
    final trade = mahalleMap(_room['trade']);
    final auction = mahalleMap(_room['auction']);
    final buyers = seats
        .where((id) => id != widget.seat && _players[id]['out'] != true)
        .toList();
    Widget action(String label, String type) => FilledButton.tonal(
        onPressed: _busy ? null : () => _play(type), child: Text(label));
    return [
      if (trade['buyer'] == widget.seat || trade['seller'] == widget.seat)
        Text(
            '${_name(trade['seller'])} → ${_name(trade['buyer'])} · ${trade['price']} para',
            style: Theme.of(context).textTheme.titleMedium),
      Wrap(spacing: 8, runSpacing: 4, children: [
        if (trade['buyer'] == widget.seat) ...[
          action('Teklifi kabul et', 'accept'),
          action('Reddet', 'reject'),
        ],
        if (trade['seller'] == widget.seat && mine)
          action('Teklifi iptal et', 'cancelTrade'),
        if (phase == 'auction' && auction['bidder'] == widget.seat) ...[
          action('${(auction['amount'] as int) + 10} teklif et', 'bid'),
          action('İhalede pas', 'pass'),
        ],
        if (mine && phase == 'roll') action('Zar at', 'roll'),
        if (mine && phase == 'property') ...[
          action('Satın al · ${districts[me['position'] as int].price}', 'buy'),
          action('İhaleye çıkar', 'auction'),
        ],
        if (mine && phase == 'end') action('Turu bitir', 'end'),
      ]),
      const SizedBox(height: 8),
      Text(district.name, style: Theme.of(context).textTheme.titleMedium),
      if (district.price > 0)
        Text(deed['owner'] == null
            ? '${district.price} para · Kira ${district.rent}'
            : '${_name(deed['owner'])} · Seviye ${deed['level']} · Kira ${district.rent * ((deed['level'] as int) + 1)}'),
      if (mine &&
          (phase == 'roll' || phase == 'end') &&
          deed['owner'] == widget.seat)
        Wrap(spacing: 8, children: [
          OutlinedButton(
              onPressed: _busy ? null : () => _play('build', square: _selected),
              child: const Text('Geliştir · 60')),
          OutlinedButton(
              onPressed: _busy || buyers.isEmpty || trade.isNotEmpty
                  ? null
                  : () => _trade(_selected, buyers),
              child: const Text('Satış teklif et')),
        ]),
    ];
  }
}
