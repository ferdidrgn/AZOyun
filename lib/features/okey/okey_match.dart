import 'dart:math';

enum TColor { sari, mavi, kirmizi, siyah }

class OTile {
  final int num;
  final TColor color;
  final bool joker;
  final String id;
  const OTile(
      {required this.num,
      required this.color,
      required this.joker,
      required this.id});

  factory OTile.fromMap(Map m) => OTile(
        num: m['n'] as int,
        color: TColor.values[m['c'] as int],
        joker: m['j'] as bool? ?? false,
        id: m['id'] as String,
      );
  Map<String, dynamic> toMap() =>
      {'n': num, 'c': color.index, 'j': joker, 'id': id};
}

// EL GEÇERLİLİĞİ — "AÇTIM" kontrolü
//
// Elindeki taşların TAMAMI, standart okey kurallarına uygun 3+ taşlık
// gruplara ayrılabiliyor mu? İki grup tipi var:
//  - PER: aynı sayı, farklı renk (3 ya da 4 taş — her renkten en fazla 1)
//  - SERİ: aynı renk, ardışık sayılar (min 3, max 13, 13'ten sonra 1'e
//    dönmez)
// Göstergeye göre belirlenen gerçek okey taşları
// eksik taşın yerine geçebilir. Backtracking ile çözülür: her adımda
// henüz kullanılmamış ilk taşı içeren olası grupları dener.
class _OkeyHandSolver {
  _OkeyHandSolver(this.normals);
  final List<OTile> normals;

  int _steps = 0;
  static const _maxSteps =
      300000; // combinatorial patlamaya karşı güvenlik sınırı

  bool solve(int jokerCount) =>
      _solve(List.filled(normals.length, false), jokerCount);

  bool _solve(List<bool> used, int jokersLeft) {
    if (++_steps > _maxSteps) return false;
    final firstIdx = used.indexOf(false);
    if (firstIdx == -1) return jokersLeft == 0;
    final first = normals[firstIdx];

    // PER dene: first.color'ı içeren 3'lü ve 4'lü renk kombinasyonları
    for (final size in [4, 3]) {
      for (final colors in _colorSubsetsContaining(first.color, size)) {
        final newUsed = List<bool>.from(used)..[firstIdx] = true;
        var need = 0;
        for (final c in colors) {
          if (c == first.color) continue;
          final idx =
              _findUnused(newUsed, (t) => t.num == first.num && t.color == c);
          if (idx != -1) {
            newUsed[idx] = true;
          } else {
            need++;
          }
        }
        if (need <= jokersLeft && _solve(newUsed, jokersLeft - need))
          return true;
      }
    }

    // SERİ dene: first.color renginde, first.num'u içeren her uzunluk/konum
    for (var length = 3; length <= 13; length++) {
      for (var offset = 0; offset < length; offset++) {
        final start =
            first.num == 1 && offset > 0 ? 14 - offset : first.num - offset;
        final end = start + length - 1;
        if (start < 1 || end > 14 || (end == 14 && start < 2)) continue;
        final newUsed = List<bool>.from(used)..[firstIdx] = true;
        var need = 0;
        for (var position = start; position <= end; position++) {
          final n = position == 14 ? 1 : position;
          if (n == first.num) continue;
          final idx =
              _findUnused(newUsed, (t) => t.num == n && t.color == first.color);
          if (idx != -1) {
            newUsed[idx] = true;
          } else {
            need++;
          }
        }
        if (need <= jokersLeft && _solve(newUsed, jokersLeft - need))
          return true;
      }
    }

    return false;
  }

  int _findUnused(List<bool> used, bool Function(OTile) test) {
    for (var i = 0; i < normals.length; i++) {
      if (!used[i] && test(normals[i])) return i;
    }
    return -1;
  }

  List<List<TColor>> _colorSubsetsContaining(TColor must, int size) {
    final others = TColor.values.where((c) => c != must).toList();
    final result = <List<TColor>>[];
    void combo(List<TColor> chosen, int start) {
      if (chosen.length == size - 1) {
        result.add([must, ...chosen]);
        return;
      }
      for (var i = start; i < others.length; i++) {
        combo([...chosen, others[i]], i + 1);
      }
    }

    combo([], 0);
    return result;
  }
}

List<Map<String, dynamic>> buildDeck(int seed) {
  final rng = Random(seed);
  final tiles = <Map<String, dynamic>>[];
  int id = 0;
  for (var copy = 0; copy < 2; copy++) {
    for (var c = 0; c < 4; c++) {
      for (var n = 1; n <= 13; n++) {
        tiles.add(
            OTile(num: n, color: TColor.values[c], joker: false, id: 't${id++}')
                .toMap());
      }
    }
  }
  tiles.add(OTile(num: 0, color: TColor.sari, joker: true, id: 'j0').toMap());
  tiles.add(OTile(num: 0, color: TColor.siyah, joker: true, id: 'j1').toMap());
  tiles.shuffle(rng);
  return tiles;
}

typedef OkeyRoom = Map<String, dynamic>;

OkeyRoom okeyMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

List<OTile> okeyTiles(Object? data) =>
    data is List ? data.whereType<Map>().map(OTile.fromMap).toList() : [];

List<String> okeySeats(OkeyRoom room) {
  final players = okeyMap(room['players']);
  return ['p1', 'p2', 'p3', 'p4'].where(players.containsKey).toList();
}

bool isWildTile(OTile tile, OkeyRoom room) =>
    !tile.joker &&
    tile.num == room['okeyN'] &&
    tile.color.index == room['okeyC'];

OTile effectiveOkeyTile(OTile tile, OkeyRoom room) => tile.joker
    ? OTile(
        id: tile.id,
        num: room['okeyN'] as int,
        color: TColor.values[room['okeyC'] as int],
        joker: false)
    : tile;

OkeyRoom? joinOkeyRoom(OkeyRoom room, String name) {
  if (room['status'] != 'waiting' || room['rulesVersion'] != 2) return null;
  final players = okeyMap(room['players']);
  for (var i = 1; i <= 4; i++) {
    final key = 'p$i';
    if (players.containsKey(key)) continue;
    return {
      ...room,
      'players': {
        ...players,
        key: {'name': name, 'score': 0}
      }
    };
  }
  return null;
}

OkeyRoom? dealOkeyRoom(OkeyRoom room, String host, int seed) {
  final seats = okeySeats(room);
  if (room['status'] != 'waiting' ||
      room['rulesVersion'] != 2 ||
      room['host'] != host ||
      seats.length < (host == 'table' ? 4 : 2)) return null;
  final stock = buildDeck(seed);
  final indicator =
      stock.removeAt(stock.indexWhere((tile) => tile['j'] != true));
  final players = okeyMap(room['players']);
  final count = room['mode'] == '101' ? 21 : 14;
  for (final (index, seat) in seats.indexed) {
    players[seat] = {
      ...okeyMap(players[seat]),
      'hand': stock.sublist(0, count + (index == 0 ? 1 : 0)),
    };
    stock.removeRange(0, count + (index == 0 ? 1 : 0));
  }
  return {
    ...room,
    'players': players,
    'status': 'playing',
    'phase': 'discard',
    'turn': seats.first,
    'round': 1,
    'revision': 1,
    'deck': stock,
    'indicator': indicator,
    'okeyN': (indicator['n'] as int) % 13 + 1,
    'okeyC': indicator['c'],
  };
}

String previousOkeySeat(OkeyRoom room, String seat) {
  final seats = okeySeats(room);
  return seats[(seats.indexOf(seat) + seats.length - 1) % seats.length];
}

int okeyMeldScore(List<OTile> tiles, OkeyRoom room, {bool pairs = false}) {
  final fixed = tiles
      .where((tile) => !isWildTile(tile, room))
      .map((tile) => effectiveOkeyTile(tile, room))
      .toList();
  if (pairs) {
    if (tiles.length != 2) return 0;
    return fixed.length < 2 ||
            (fixed.first.num == fixed.last.num &&
                fixed.first.color == fixed.last.color)
        ? 1
        : 0;
  }
  final count = tiles.length;
  if (count < 3 || count > 13 || fixed.isEmpty) return 0;
  final first = fixed.first;
  var score = 0;
  if (count <= 4 &&
      fixed.every((tile) => tile.num == first.num) &&
      fixed.map((tile) => tile.color).toSet().length == fixed.length) {
    score = count * first.num;
  }
  if (fixed.every((tile) => tile.color == first.color) &&
      fixed.map((tile) => tile.num).toSet().length == fixed.length) {
    for (var start = 1; start + count <= 14; start++) {
      if (fixed
          .every((tile) => tile.num >= start && tile.num < start + count)) {
        score = max(score, count * (2 * start + count - 1) ~/ 2);
      }
    }
    if (count == 3 && fixed.every((tile) => [12, 13, 1].contains(tile.num))) {
      score = max(score, 26);
    }
  }
  return score;
}

bool winningOkeyHand(List<OTile> hand, OkeyRoom room) {
  if (hand.length != 14) return false;
  final counts = <(TColor, int), int>{};
  var jokers = 0;
  for (final tile in hand) {
    if (isWildTile(tile, room)) {
      jokers++;
    } else {
      final value = effectiveOkeyTile(tile, room);
      counts.update((value.color, value.num), (old) => old + 1,
          ifAbsent: () => 1);
    }
  }
  if (counts.values.where((count) => count.isOdd).length <= jokers) return true;
  return _OkeyHandSolver(hand
          .where((tile) => !isWildTile(tile, room))
          .map((tile) => effectiveOkeyTile(tile, room))
          .toList())
      .solve(jokers);
}

class OkeyMoveError implements Exception {
  const OkeyMoveError(this.message);
  final String message;
}

OkeyRoom? playOkeyMove(OkeyRoom room, String seat, int revision, String move,
    {String? tile,
    List<List<String>> groups = const [],
    bool pairs = false,
    int? meldIndex}) {
  if (room['status'] != 'playing' ||
      room['turn'] != seat ||
      room['revision'] != revision ||
      !okeySeats(room).contains(seat)) return null;
  final next = {...room, 'revision': revision + 1};
  final players = okeyMap(room['players']);
  final player = okeyMap(players[seat]);
  final hand = okeyTiles(player['hand']);
  final discards = okeyMap(room['discards']);
  final previous = previousOkeySeat(room, seat);
  final is101 = room['mode'] == '101';
  final requiredTile = room['requiredTile'];
  final byId = {for (final item in hand) item.id: item};
  final melds = <OkeyRoom>[
    for (final group in (room['melds'] as List? ?? [])) okeyMap(group)
  ];

  switch (move) {
    case 'stock':
    case 'discardDraw':
      if (room['phase'] != 'draw') return null;
      if (move == 'stock') {
        final stock = okeyTiles(room['deck']);
        if (stock.isEmpty)
          return {...next, 'status': 'finished', 'winner': null};
        hand.add(stock.removeLast());
        next['deck'] = stock.map((item) => item.toMap()).toList();
      } else {
        final prior = discards.remove(previous);
        if (prior is! Map) return null;
        final drawn = OTile.fromMap(prior);
        hand.add(drawn);
        if (is101) next['requiredTile'] = drawn.id;
      }
      next['phase'] = 'discard';
    case 'return':
      if (room['phase'] != 'discard' ||
          requiredTile == null ||
          !byId.containsKey(requiredTile)) return null;
      discards[previous] = byId[requiredTile]!.toMap();
      hand.removeWhere((item) => item.id == requiredTile);
      next['requiredTile'] = null;
      next['phase'] = 'draw';
    case 'meld':
    case 'extend':
      if (!is101 || room['phase'] != 'discard') return null;
      final ids = move == 'extend'
          ? [if (tile != null) tile]
          : groups.expand((group) => group).toList();
      if (ids.isEmpty ||
          ids.length >= hand.length ||
          ids.toSet().length != ids.length ||
          !ids.every(byId.containsKey)) {
        throw const OkeyMoveError(
            'Grupları kontrol et ve atmak için bir taş bırak.');
      }
      if (requiredTile != null && !ids.contains(requiredTile)) {
        throw const OkeyMoveError('Yerden aldığın taşı bu hamlede kullan.');
      }
      if (move == 'extend') {
        if (player['opened'] != true ||
            meldIndex == null ||
            meldIndex < 0 ||
            meldIndex >= melds.length) return null;
        final group = melds[meldIndex];
        final tiles = [...okeyTiles(group['tiles']), byId[ids.single]!];
        if (group['pairs'] == true || okeyMeldScore(tiles, room) == 0) {
          throw const OkeyMoveError('Bu taş masadaki gruba uymuyor.');
        }
        group['tiles'] = tiles.map((item) => item.toMap()).toList();
      } else {
        if (player['opened'] == true && player['pairs'] != pairs) {
          throw const OkeyMoveError('Açtığın grup türüyle devam et.');
        }
        final sets = groups
            .map((group) => group.map((id) => byId[id]!).toList())
            .toList();
        final scores = sets
            .map((group) => okeyMeldScore(group, room, pairs: pairs))
            .toList();
        if (scores.any((score) => score == 0))
          throw const OkeyMoveError('Geçersiz seri, per veya çift var.');
        if (player['opened'] != true &&
            scores.fold<int>(0, (sum, score) => sum + score) <
                (pairs ? 5 : 101)) {
          throw OkeyMoveError(pairs
              ? 'Açmak için en az beş çift gerekiyor.'
              : 'Açmak için en az 101 puan gerekiyor.');
        }
        for (final set in sets) {
          melds.add({
            'seat': seat,
            'pairs': pairs,
            'tiles': set.map((item) => item.toMap()).toList()
          });
        }
        player['opened'] = true;
        player['pairs'] = pairs;
      }
      hand.removeWhere((item) => ids.contains(item.id));
      next['melds'] = melds;
      next['requiredTile'] = null;
    case 'discard':
    case 'win':
      if (room['phase'] != 'discard' || !byId.containsKey(tile)) return null;
      if (requiredTile != null)
        throw const OkeyMoveError('Yerden aldığın taşı işle veya geri bırak.');
      hand.removeWhere((item) => item.id == tile);
      if (move == 'win' && (is101 || !winningOkeyHand(hand, room))) {
        throw const OkeyMoveError(
            'Bu taş atıldığında elin bitişe uygun değil.');
      }
      discards[seat] = byId[tile]!.toMap();
      next['lastDiscardSeat'] = seat;
      if (move == 'win' ||
          (is101 && player['opened'] == true && hand.isEmpty)) {
        next['status'] = 'finished';
        next['winner'] = seat;
      } else {
        final seats = okeySeats(room);
        next['turn'] = seats[(seats.indexOf(seat) + 1) % seats.length];
        next['phase'] = 'draw';
        next['round'] = (room['round'] as int) + 1;
      }
    default:
      return null;
  }
  player['hand'] = hand.map((item) => item.toMap()).toList();
  return {
    ...next,
    'players': {...players, seat: player},
    'discards': discards
  };
}
