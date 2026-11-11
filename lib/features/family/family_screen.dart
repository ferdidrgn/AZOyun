import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _configuredApi = String.fromEnvironment('FAMILY_API_URL');
const _configuredWeb = String.fromEnvironment('FAMILY_WEB_URL');
const _games = {
  'okey': 'Klasik Okey',
  'okey101': '101 Okey',
  'city': 'Mahalleler'
};
const _seatColors = [
  Color(0xFFF4C576),
  Color(0xFF83DDD6),
  Color(0xFFF8A5A0),
  Color(0xFFBEB6FA)
];
typedef _Data = Map<String, dynamic>;

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key, required this.host, this.code});

  final bool host;
  final String? code;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AZ Oyun · Aile Masası',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF4C576),
            surface: Color(0xFF1D302B),
          ),
        ),
        home: FamilyScreen(host: host, initialCode: code),
      );
}

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key, required this.host, this.initialCode});

  final bool host;
  final String? initialCode;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _http = http.Client();
  final _name = TextEditingController();
  final _codeInput = TextEditingController();
  final _server = TextEditingController(
    text: _configuredApi.isNotEmpty
        ? _configuredApi
        : kIsWeb
            ? Uri.base.origin
            : '',
  );
  final _price = TextEditingController(text: '100');
  final _selected = <int>[];
  final _groups = <List<int>>[];
  final _rack = <int>[];
  _Data? _room;
  Timer? _timer;
  String? _code;
  String? _token;
  String? _error;
  bool _busy = false;
  bool _polling = false;
  bool _pairs = false;
  int? _saleSquare;
  int? _buyer;
  int? _meldIndex;

  bool get _host => widget.host;
  String get _sessionKey =>
      'az_family_${_host ? 'host' : 'player'}_${_server.text.trim()}_$_code';
  bool get _city => _room?['game'] == 'city';

  @override
  void initState() {
    super.initState();
    _codeInput.text = widget.initialCode ?? '';
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _busy || _code != null) return;
      if (!kIsWeb && _configuredApi.isEmpty) {
        _server.text = prefs.getString('az_family_server') ?? '';
      }
      final code = widget.initialCode ??
          (_host
              ? prefs.getString('az_family_last_host_${_server.text.trim()}')
              : null);
      if (code == null || _server.text.isEmpty) return;
      _code = code;
      _token = prefs.getString(_sessionKey);
      if (_token == null) {
        _code = null;
        return;
      }
      await _refresh();
      if (mounted && _room != null) _beginPolling();
      if (mounted && _room == null) {
        _code = null;
        _token = null;
      }
    } catch (_) {
      // The player can enter the room code manually.
    }
  }

  Uri _url(String path) {
    final base = Uri.tryParse(_server.text.trim());
    if (base == null ||
        !base.hasAuthority ||
        !['http', 'https'].contains(base.scheme) ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const FormatException('Geçerli bir sunucu adresi gir.');
    }
    return base.replace(path: path);
  }

  Future<_Data> _request(String path, {_Data? payload}) async {
    final headers = {
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (payload != null) 'Content-Type': 'application/json',
    };
    final uri = _url('/api/family/$path');
    final result = await (payload == null
            ? _http.get(uri, headers: headers)
            : _http.post(uri, headers: headers, body: jsonEncode(payload)))
        .timeout(const Duration(seconds: 7));
    if (!(result.headers['content-type'] ?? '').contains('application/json')) {
      throw const FormatException(
          'Bu adreste Aile Masası sunucusu bulunamadı.');
    }
    final data = jsonDecode(utf8.decode(result.bodyBytes));
    if (data is! Map<String, dynamic>)
      throw const FormatException('Sunucu yanıtı okunamadı.');
    if (result.statusCode >= 400)
      throw FormatException(data['error'] as String? ?? 'Masa açılamadı.');
    return data;
  }

  void _accept(_Data data) {
    if (!mounted ||
        data['code'] != _code ||
        (data['revision'] as int) < (_room?['revision'] as int? ?? -1)) return;
    final private = data['private'] as Map?;
    final tiles = (private?['hand'] as List? ?? []).cast<Map>();
    final ids = tiles.map((tile) => tile['id'] as int).toSet();
    setState(() {
      _room = data;
      _error = null;
      _rack.removeWhere((id) => !ids.contains(id));
      _rack.addAll(ids.where((id) => !_rack.contains(id)));
      _selected.removeWhere((id) => !ids.contains(id));
      _groups.removeWhere((group) => !group.every(ids.contains));
    });
  }

  Future<void> _refresh() async {
    if (_polling || _code == null) return;
    _polling = true;
    final code = _code;
    try {
      _accept(await _request('rooms/$code'));
    } catch (error) {
      if (mounted && _code == code) setState(() => _error = _message(error));
    } finally {
      _polling = false;
    }
  }

  String _message(Object error) =>
      error is FormatException && error.message is String
          ? error.message as String
          : 'Masaya bağlanılamadı. Sunucu adresini ve bağlantıyı kontrol et.';

  void _beginPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!_busy) unawaited(_refresh());
    });
  }

  Future<void> _connect({String? game}) async {
    if (_busy) return;
    final code = _codeInput.text.trim().toUpperCase();
    final name = _name.text.trim();
    if (game == null &&
        (!RegExp(r'^[A-Z2-9]{6}$').hasMatch(code) || name.isEmpty)) {
      setState(
          () => _error = 'Oyuncu adını ve altı karakterli masa kodunu gir.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (game == null) {
        _code = code;
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString(_sessionKey);
        if (_token != null) {
          await _refresh();
          if (_room != null) {
            _beginPolling();
            return;
          }
          _token = null;
        }
      }
      final data = await _request(game != null ? 'rooms' : 'rooms/$code/join',
          payload: game != null ? {'game': game} : {'name': name});
      if (!mounted) return;
      _code = data['code'] as String;
      _token = data['token'] as String;
      await _refresh();
      _beginPolling();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, _token!);
      await prefs.setString('az_family_server', _server.text.trim());
      if (_host)
        await prefs.setString(
            'az_family_last_host_${_server.text.trim()}', _code!);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _act(String type, [_Data fields = const {}]) async {
    final room = _room;
    if (room == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await _request('rooms/$_code/action', payload: {
        'type': type,
        'revision': room['revision'],
        ...fields,
      });
      _accept(updated);
      if (mounted && type == 'leave') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_sessionKey);
        if (mounted) _reset();
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    _timer?.cancel();
    if (_host) unawaited(_forgetHost());
    setState(() {
      _code = null;
      _token = null;
      _room = null;
      _selected.clear();
      _groups.clear();
      _rack.clear();
      _saleSquare = null;
      _buyer = null;
      _meldIndex = null;
      _pairs = false;
    });
  }

  Future<void> _forgetHost() async {
    final server = _server.text.trim();
    final session = _sessionKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('az_family_last_host_$server');
    await prefs.remove(session);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _http.close();
    _name.dispose();
    _codeInput.dispose();
    _server.dispose();
    _price.dispose();
    super.dispose();
  }

  String get _invite {
    final base = Uri.parse(_configuredWeb.isNotEmpty
        ? _configuredWeb
        : kIsWeb
            ? Uri.base.origin
            : _server.text.trim());
    return base
        .replace(path: '/', queryParameters: {'family': _code!}).toString();
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    return Scaffold(
      appBar: AppBar(title: Text(_host ? 'Aile Masası · TV' : 'Aile Masası')),
      body: SafeArea(child: LayoutBuilder(builder: (context, bounds) {
        final content = room == null
            ? _setup()
            : _match(room, wide: _host && bounds.maxWidth >= 850);
        return Center(
            child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: room == null ? 640 : 1440),
          child: ListView(
            padding: EdgeInsets.all(bounds.maxWidth > 800 ? 28 : 16),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              ...content,
            ],
          ),
        ));
      })),
    );
  }

  List<Widget> _setup() => [
        Text(_host ? 'Ortak masayı aç' : 'Masaya otur',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(_host
            ? 'Bir oyun seç. Oyuncular TV’deki QR kodunu telefonuyla okutsun.'
            : 'Bu ekran elini, bakiyeni ve hamlelerini gösterir.'),
        const SizedBox(height: 20),
        if (!kIsWeb && _configuredApi.isEmpty)
          TextField(
              controller: _server,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Masa sunucusu', hintText: 'https://…')),
        if (_host)
          for (final (index, entry) in _games.entries.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.tonal(
                autofocus: index == 0,
                onPressed: _busy ? null : () => _connect(game: entry.key),
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(entry.value)),
              ),
            )
        else ...[
          TextField(
              controller: _name,
              maxLength: 24,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Oyuncu adı')),
          TextField(
              controller: _codeInput,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z2-9]'))
              ],
              decoration: const InputDecoration(labelText: 'Masa kodu')),
          FilledButton(
              onPressed: _busy ? null : _connect, child: const Text('Katıl')),
        ],
        if (_busy) const LinearProgressIndicator(),
      ];

  List<Widget> _match(_Data room, {required bool wide}) {
    final players = (room['players'] as List).cast<Map>();
    final seat = room['seat'] as int? ?? -1;
    final turn = room['turn'] as int?;
    final lobby = room['status'] == 'lobby';
    final playing = room['status'] == 'playing';
    final private = room['private'] as Map? ?? {};
    final shared =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_games[room['game']]!,
          style: Theme.of(context).textTheme.headlineLarge),
      if (playing && turn != null)
        Text('Sıra ${players[turn]['name']} oyuncusunda',
            style: Theme.of(context).textTheme.titleLarge),
      if (room['status'] == 'finished' && turn != null)
        Text(
            room['winner'] == null
                ? 'Berabere'
                : '${players[room['winner'] as int]['name']} kazandı',
            style: Theme.of(context).textTheme.headlineSmall),
      if (room['message'] case final String message) Text(message),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (index, player) in players.indexed)
          Chip(
            avatar: CircleAvatar(
                backgroundColor: _seatColors[index],
                child: Text('${index + 1}',
                    style: const TextStyle(color: Colors.black))),
            label: Text('${player['name']}${seat == index ? ' · Sen' : ''}'
                '${player['count'] == null ? '' : ' · ${player['count']} taş'}'
                '${player['out'] == true ? ' · İflas' : ''}'),
          ),
      ]),
      const SizedBox(height: 12),
      if (_city && (_host || !lobby)) _board(room, players, wide),
      if (!_city && turn != null) ..._tileTable(room, players),
    ]);
    final lobbyControls =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_host) ...[
        Center(
            child: ColoredBox(
                color: Colors.white,
                child: QrImageView(data: _invite, size: 230))),
        const SizedBox(height: 10),
        Text(_code!,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(letterSpacing: 5)),
        TextButton(
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: _invite));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Katılım bağlantısı kopyalandı.')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Katılım bağlantısı'),
                      content: SelectableText(_invite),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Katılım bağlantısını kopyala')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy || players.length < (_city ? 2 : 4)
              ? null
              : () => _act('start'),
          child: Text('Başlat · ${players.length}/4 oyuncu'),
        ),
      ] else
        const Text('TV’de masanın başlatılmasını bekle.'),
      TextButton(
          onPressed: _busy ? null : () => _act(_host ? 'close' : 'leave'),
          child: Text(_host ? 'Masayı kapat' : 'Masadan ayrıl')),
    ]);
    return [
      if (lobby && wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: shared),
          const SizedBox(width: 28),
          SizedBox(width: 300, child: lobbyControls),
        ])
      else ...[
        shared,
        if (lobby) lobbyControls,
      ],
      if (!_host && playing && seat >= 0)
        ...(_city
            ? _cityControls(room, private, players, seat)
            : _rackControls(room, private, seat)),
      if (_host && playing)
        TextButton(
            onPressed: _busy ? null : () => _act('close'),
            child: const Text('Masayı kapat')),
      if (!lobby && !playing)
        FilledButton(onPressed: _reset, child: const Text('Masa seçimine dön')),
    ];
  }

  Widget _board(_Data room, List<Map> players, bool wide) {
    final board = (room['board'] as List).cast<Map>();
    final dice = room['dice'] as List?;
    final auction = room['auction'] as Map?;
    final wealth = room['wealth'] as List?;
    const path = [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (dice != null)
        Text('Zarlar ${dice.join(' + ')}  ·  Tur ${room['round']}/10',
            style: Theme.of(context).textTheme.titleLarge),
      if (auction != null)
        Text(
            'Açık artırma · ${board[auction['square'] as int]['name']} · ${auction['bid']} para'),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: wide ? 2.5 : 1.06,
        children: [
          for (final index in path)
            Builder(builder: (context) {
              final square = board[index];
              final owner = square['owner'] as int?;
              return Card(
                margin: EdgeInsets.zero,
                color: owner == null
                    ? null
                    : _seatColors[owner].withValues(alpha: .21),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            child: Text(square['name'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: wide ? 17 : 11,
                                    fontWeight: FontWeight.w700))),
                        if (square['price'] != null)
                          Text(
                              owner == null
                                  ? '${square['price']} para'
                                  : '${players[owner]['name']} · ${square['level']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: wide ? 14 : 9)),
                        Wrap(spacing: 3, children: [
                          for (final (seat, player) in players.indexed)
                            if (player['position'] == index &&
                                player['out'] != true)
                              Semantics(
                                  label: player['name'] as String,
                                  child: Icon(Icons.circle,
                                      color: _seatColors[seat],
                                      size: wide ? 17 : 10)),
                        ]),
                      ]),
                ),
              );
            }),
        ],
      ),
      if (wealth != null)
        for (final (index, value) in wealth.indexed)
          Text('${players[index]['name']} · $value toplam varlık'),
    ]);
  }

  List<Widget> _tileTable(_Data room, List<Map> players) {
    final indicator = room['indicator'] as Map?;
    final discards = room['discards'] as List? ?? [];
    final melds = (room['melds'] as List? ?? []).cast<Map>();
    return [
      Wrap(
          spacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (indicator != null) ...[
              const Text('Gösterge'),
              _tile(indicator),
              Text('Okey · ${(indicator['value'] as int) % 13 + 1}'),
            ],
            Text('Deste · ${room['stockCount']} taş'),
          ]),
      const SizedBox(height: 10),
      Wrap(spacing: 12, runSpacing: 8, children: [
        for (final (index, tile) in discards.indexed)
          if (tile != null)
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(players[index]['name'] as String),
              _tile(tile as Map),
            ]),
      ]),
      if (melds.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Açılan gruplar', style: Theme.of(context).textTheme.titleLarge),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (index, group) in melds.indexed)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            '${index + 1}. grup · ${players[group['seat'] as int]['name']}'),
                        Wrap(spacing: 2, runSpacing: 2, children: [
                          for (final tile
                              in (group['tiles'] as List).cast<Map>())
                            _tile(tile),
                        ]),
                      ],
                    ))),
        ]),
      ],
    ];
  }

  Widget _tile(Map tile, {bool picked = false, VoidCallback? onTap}) {
    final color = const [
      Color(0xFF775209),
      Color(0xFF184BC0),
      Color(0xFFB1222A),
      Color(0xFF202326)
    ][tile['color'] as int];
    final value = tile['wild'] == true ? '★' : '${tile['value']}';
    final name =
        const ['Sarı', 'Mavi', 'Kırmızı', 'Siyah'][tile['color'] as int];
    final label = tile['wild'] == true ? 'Okey taşı' : '$name $value';
    final face = Container(
      alignment: Alignment.center,
      width: onTap == null ? 38 : 44,
      height: 48,
      decoration: BoxDecoration(
        color: picked ? const Color(0xFFFFCC73) : const Color(0xFFF3EEE4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: picked ? 3 : 1),
      ),
      child: Text(value,
          style: TextStyle(
              color: color, fontSize: 21, fontWeight: FontWeight.w800)),
    );
    return onTap == null
        ? Semantics(label: label, child: face)
        : Semantics(
            label: label,
            selected: picked,
            button: true,
            child: InkWell(onTap: onTap, child: face));
  }

  List<Widget> _rackControls(_Data room, Map private, int seat) {
    final hand = (private['hand'] as List? ?? []).cast<Map>();
    final byId = {for (final tile in hand) tile['id'] as int: tile};
    final mine = room['turn'] == seat;
    final phase = room['phase'];
    final is101 = room['game'] == 'okey101';
    final melds = room['melds'] as List? ?? [];
    final players = (room['players'] as List).cast<Map>();
    final discards = room['discards'] as List? ?? [];
    final previous = (seat + players.length - 1) % players.length;
    final opened = players[seat]['opened'] == true;
    final pairs = opened ? players[seat]['pairs'] == true : _pairs;
    return [
      const SizedBox(height: 22),
      Text('Istakan', style: Theme.of(context).textTheme.headlineSmall),
      if (private['requiredTile'] != null)
        const Text('Yerden aldığın taşı bu tur bir grupta kullan.'),
      Wrap(spacing: 5, runSpacing: 6, children: [
        for (final id in _rack)
          if (byId[id] case final Map tile)
            _tile(tile,
                picked: _selected.contains(id),
                onTap: () => setState(() {
                      if (_selected.contains(id)) {
                        _selected.remove(id);
                      } else if (!_groups.any((group) => group.contains(id))) {
                        _selected.add(id);
                      }
                    })),
      ]),
      Wrap(spacing: 8, children: [
        TextButton(
            onPressed: () => setState(() {
                  _rack.sort((a, b) {
                    final left = byId[a]!;
                    final right = byId[b]!;
                    return ((left['color'] as int) * 14 +
                            (left['value'] as int))
                        .compareTo((right['color'] as int) * 14 +
                            (right['value'] as int));
                  });
                }),
            child: const Text('Renge göre diz')),
        TextButton(
            onPressed: _selected.length == 1 ? () => _moveTile(-1) : null,
            child: const Text('Sola taşı')),
        TextButton(
            onPressed: _selected.length == 1 ? () => _moveTile(1) : null,
            child: const Text('Sağa taşı')),
      ]),
      if (mine && phase == 'draw') ...[
        FilledButton(
            onPressed: _busy ? null : () => _act('draw'),
            child: const Text('Desteden çek')),
        OutlinedButton(
          onPressed: _busy || discards[previous] == null
              ? null
              : () => _act('draw', {'source': 'discard'}),
          child: const Text('Önceki taşı al'),
        ),
      ],
      if (mine && phase == 'discard') ...[
        if (private['requiredTile'] != null)
          OutlinedButton(
              onPressed: _busy ? null : () => _act('returnDiscard'),
              child: const Text('Aldığın taşı geri bırak')),
        FilledButton(
          onPressed:
              _busy || _selected.length != 1 || private['requiredTile'] != null
                  ? null
                  : () => _act('discard', {'tile': _selected.single}),
          child: const Text('Taşı masaya at'),
        ),
        if (!is101)
          OutlinedButton(
            onPressed: _busy || _selected.length != 1
                ? null
                : () => _act('win', {'tile': _selected.single}),
            child: const Text('Seçili taşı at ve bitir'),
          )
        else ...[
          if (!opened)
            SwitchListTile(
              title: const Text('Çift aç'),
              value: _pairs,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        _pairs = value;
                        _groups.clear();
                      }),
            ),
          Text(
              '${_groups.length} grup hazır · ${pairs ? 'İlk açılış en az beş çift' : 'İlk açılış en az 101 puan'}'),
          Wrap(spacing: 8, children: [
            OutlinedButton(
              onPressed: (pairs ? _selected.length != 2 : _selected.length < 3)
                  ? null
                  : () => setState(() {
                        _groups.add(_selected.toList());
                        _selected.clear();
                      }),
              child: const Text('Seçimi gruba ekle'),
            ),
            OutlinedButton(
              onPressed: _groups.isEmpty ? null : () => setState(_groups.clear),
              child: const Text('Grupları geri al'),
            ),
          ]),
          FilledButton(
            onPressed: _busy || _groups.isEmpty
                ? null
                : () => _act('meld', {'groups': _groups, 'pairs': pairs}),
            child: const Text('Grupları masaya aç'),
          ),
          if (players[seat]['opened'] == true && melds.isNotEmpty)
            Wrap(spacing: 8, children: [
              DropdownButton<int>(
                hint: const Text('Masadaki grup'),
                value: _meldIndex,
                items: [
                  for (var i = 0; i < melds.length; i++)
                    DropdownMenuItem(value: i, child: Text('${i + 1}. grup'))
                ],
                onChanged: (value) => setState(() => _meldIndex = value),
              ),
              OutlinedButton(
                onPressed: _busy || _meldIndex == null || _selected.length != 1
                    ? null
                    : () => _act('extend',
                        {'tile': _selected.single, 'index': _meldIndex}),
                child: const Text('Gruba işle'),
              ),
            ]),
        ],
      ],
    ];
  }

  void _moveTile(int direction) {
    final id = _selected.single;
    final from = _rack.indexOf(id);
    final to = from + direction;
    if (from < 0 || to < 0 || to >= _rack.length) return;
    setState(() {
      _rack.removeAt(from);
      _rack.insert(to, id);
    });
  }

  List<Widget> _cityControls(
      _Data room, Map private, List<Map> players, int seat) {
    final board = (room['board'] as List).cast<Map>();
    final auction = room['auction'] as Map?;
    final trade = private['trade'] as Map?;
    final phase = room['phase'];
    final myTurn = room['turn'] == seat;
    final owned = [
      for (final (index, square) in board.indexed)
        if (square['owner'] == seat) index
    ];
    final active = players[seat]['out'] != true;
    final mySquare = board[players[seat]['position'] as int];
    return [
      const SizedBox(height: 18),
      Text('Cüzdanın · ${private['money']} para',
          style: Theme.of(context).textTheme.headlineSmall),
      if (private['card'] case final String card) Text('Pazar kartın · $card'),
      if (owned.isNotEmpty)
        Text(
            'Tapuların · ${owned.map((index) => board[index]['name']).join(', ')}'),
      if (trade != null)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text(
                      '${board[trade['square'] as int]['name']} · ${trade['price']} para'),
                  if (trade['to'] == seat)
                    Wrap(spacing: 8, children: [
                      FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _act('tradeReply', {'accept': true}),
                          child: const Text('Teklifi kabul et')),
                      OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _act('tradeReply', {'accept': false}),
                          child: const Text('Reddet')),
                    ])
                  else
                    TextButton(
                        onPressed: _busy ? null : () => _act('cancelTrade'),
                        child: const Text('Teklifi geri çek')),
                ]))),
      if (active && auction?['bidder'] == seat)
        Wrap(spacing: 8, children: [
          FilledButton(
              onPressed: _busy ? null : () => _act('bid'),
              child: Text('${(auction!['bid'] as int) + 10} teklif ver')),
          OutlinedButton(
              onPressed: _busy ? null : () => _act('passBid'),
              child: const Text('Pas geç')),
        ]),
      if (active && myTurn && phase == 'roll')
        FilledButton(
            onPressed: _busy ? null : () => _act('roll'),
            child: const Text('Zar at')),
      if (active && myTurn && phase == 'property')
        Wrap(spacing: 8, children: [
          FilledButton(
              onPressed: _busy ? null : () => _act('buy'),
              child: Text('${mySquare['price']} paraya al')),
          OutlinedButton(
              onPressed: _busy ? null : () => _act('auction'),
              child: const Text('Açık artırmaya çıkar')),
        ]),
      if (active && myTurn && phase == 'end')
        FilledButton(
            onPressed: _busy ? null : () => _act('end'),
            child: const Text('Sırayı bitir')),
      if (active &&
          myTurn &&
          (phase == 'roll' || phase == 'end') &&
          owned.isNotEmpty) ...[
        const SizedBox(height: 12),
        DropdownButton<int>(
          hint: const Text('Tapu seç'),
          value: owned.contains(_saleSquare) ? _saleSquare : null,
          items: [
            for (final index in owned)
              DropdownMenuItem(
                  value: index, child: Text(board[index]['name'] as String))
          ],
          onChanged: (value) => setState(() => _saleSquare = value),
        ),
        OutlinedButton(
          onPressed: _busy || !owned.contains(_saleSquare)
              ? null
              : () => _act('build', {'square': _saleSquare}),
          child: const Text('Mahalle geliştir · 60 para'),
        ),
        DropdownButton<int>(
          hint: const Text('Teklif alıcısı'),
          value: _buyer,
          items: [
            for (final (index, player) in players.indexed)
              if (index != seat)
                DropdownMenuItem(
                    value: index, child: Text(player['name'] as String))
          ],
          onChanged: (value) => setState(() => _buyer = value),
        ),
        TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Satış fiyatı')),
        OutlinedButton(
          onPressed: _busy ||
                  trade != null ||
                  !owned.contains(_saleSquare) ||
                  _buyer == null
              ? null
              : () => _act('trade', {
                    'square': _saleSquare,
                    'to': _buyer,
                    'price': int.tryParse(_price.text)
                  }),
          child: const Text('Özel teklif gönder'),
        ),
      ],
    ];
  }
}
