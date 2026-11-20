import 'dart:math';

typedef BatakRoom = Map<String, dynamic>;

const batakSuits = ['♣', '♦', '♥', '♠'];
const batakSuitNames = ['Sinek', 'Karo', 'Kupa', 'Maça'];
const batakPlayerSeats = ['p1', 'p2', 'p3', 'p4'];

BatakRoom batakMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

List<int> batakHand(Object? value) =>
    value is List ? value.map((card) => (card as num).toInt()).toList() : [];

List<BatakRoom> batakTrick(Object? value) =>
    value is List ? value.map(batakMap).toList() : [];

List<String> batakSeats(BatakRoom room) {
  final players = batakMap(room['players']);
  return batakPlayerSeats.where(players.containsKey).toList();
}

int batakSuit(int card) => card ~/ 13;
int batakRank(int card) => card % 13 + 2;
String batakCardLabel(int card) {
  final rank = batakRank(card);
  return '${switch (rank) {
    11 => 'J',
    12 => 'Q',
    13 => 'K',
    14 => 'A',
    _ => '$rank'
  }}${batakSuits[batakSuit(card)]}';
}

String batakNextSeat(String seat) =>
    batakPlayerSeats[(batakPlayerSeats.indexOf(seat) + 1) % 4];

String? batakSeatForToken(BatakRoom room, String token) {
  if (token.isEmpty) return null;
  for (final entry in batakMap(room['players']).entries) {
    if (batakMap(entry.value)['token'] == token) return entry.key;
  }
  return null;
}

BatakRoom? joinBatak(BatakRoom room, String name, {String? token}) {
  if (room['kind'] != 'batak') return null;
  if (token != null && batakSeatForToken(room, token) != null) return room;
  if (room['status'] != 'waiting') return null;
  final players = batakMap(room['players']);
  for (final seat in batakPlayerSeats) {
    if (!players.containsKey(seat)) {
      return {
        ...room,
        'players': {
          ...players,
          seat: {'name': name, if (token != null) 'token': token}
        }
      };
    }
  }
  return null;
}

BatakRoom? dealBatak(BatakRoom room, String actor, int seed) {
  if (room['kind'] != 'batak' ||
      room['host'] != actor ||
      batakSeats(room).length != 4 ||
      !(room['status'] == 'waiting' ||
          (room['status'] == 'playing' && room['phase'] == 'roundEnd'))) {
    return null;
  }
  final round = ((room['round'] as int?) ?? 0) + 1;
  if (round > 4) return null;
  final dealer = batakPlayerSeats[(round - 1) % 4];
  final first = batakNextSeat(dealer);
  final deck = List.generate(52, (card) => card)..shuffle(Random(seed));
  final players = batakMap(room['players']);
  return {
    ...room,
    'status': 'playing',
    'phase': 'bid',
    'revision': ((room['revision'] as int?) ?? 0) + 1,
    'round': round,
    'dealer': dealer,
    'firstBidder': first,
    'turn': first,
    'contract': 0,
    'bidder': null,
    'passed': null,
    'bids': null,
    'trump': null,
    'trumpBroken': false,
    'trick': null,
    'lastTrick': null,
    'trickWinner': null,
    'trickNumber': 1,
    'players': {
      ...players,
      for (final (index, seat) in batakPlayerSeats.indexed)
        seat: {
          ...batakMap(players[seat]),
          'hand': [for (var n = index; n < 52; n += 4) deck[n]]..sort(),
          'taken': 0,
          'score': batakMap(players[seat])['score'] ?? 0,
        }
    },
    'message': 'Dağıtım $round/4 · İhale 5 ile açılır.',
  };
}

// Leading-suit cards outrank other non-trumps. Among trumps, rank decides.
BatakRoom batakWinningPlay(List<BatakRoom> trick, int trump) {
  var best = trick.first;
  for (final play in trick.skip(1)) {
    final card = play['card'] as int;
    final current = best['card'] as int;
    if ((batakSuit(card) == batakSuit(current) &&
            batakRank(card) > batakRank(current)) ||
        (batakSuit(card) == trump && batakSuit(current) != trump)) {
      best = play;
    }
  }
  return best;
}

/// Legal choices are shared by the table UI and the transaction reducer.
List<int> batakLegalCards(BatakRoom room, String seat) {
  if (room['status'] != 'playing' ||
      room['phase'] != 'play' ||
      room['turn'] != seat) return [];
  final hand = batakHand(batakMap(batakMap(room['players'])[seat])['hand']);
  final trump = room['trump'] as int;
  final trick = batakTrick(room['trick']);
  if (trick.isEmpty) {
    final ordinary = hand.where((card) => batakSuit(card) != trump).toList();
    return room['trumpBroken'] == true || ordinary.isEmpty ? hand : ordinary;
  }
  final lead = batakSuit(trick.first['card'] as int);
  final following = hand.where((card) => batakSuit(card) == lead).toList();
  final winner = batakWinningPlay(trick, trump)['card'] as int;
  final candidates = following.isNotEmpty
      ? following
      : hand.where((card) => batakSuit(card) == trump).toList();
  if (candidates.isEmpty) return hand;
  final higher = candidates
      .where((card) =>
          (batakSuit(card) == batakSuit(winner) &&
              batakRank(card) > batakRank(winner)) ||
          (batakSuit(card) == trump && batakSuit(winner) != trump))
      .toList();
  return higher.isNotEmpty ? higher : candidates;
}

String batakPlayHint(BatakRoom room, String seat) {
  if (room['turn'] != seat)
    return 'Sıranı bekle. Açık kartları masadan takip et.';
  final trick = batakTrick(room['trick']);
  if (trick.isEmpty) {
    return room['trumpBroken'] == true
        ? 'Eli sen açıyorsun. Bir kart seç veya masaya sürükle.'
        : 'Eli sen açıyorsun. Koz kırılana kadar diğer renklerden başla.';
  }
  return 'Renge uy, mümkünse büyüt. O renk yoksa koz at. Aydınlık kartlar oynanabilir.';
}

BatakRoom? playBatak(BatakRoom room, String seat, int revision, String action,
    {int? bid, int? trump, int? card}) {
  if (room['kind'] != 'batak' ||
      room['status'] != 'playing' ||
      room['revision'] != revision ||
      !batakSeats(room).contains(seat) ||
      room['turn'] != seat) return null;
  final next = {...room, 'revision': revision + 1};
  final phase = room['phase'];
  if (phase == 'bid' && (action == 'bid' || action == 'pass')) {
    final passed = batakMap(room['passed']);
    final bids = batakMap(room['bids']);
    if (passed[seat] == true) return null;
    if (action == 'bid') {
      if (bid == null || bid < 5 || bid > 13 || bid <= room['contract'])
        return null;
      next.addAll({'contract': bid, 'bidder': seat});
      bids[seat] = bid;
    } else {
      passed[seat] = true;
      bids[seat] = 'pass';
    }
    next.addAll({'passed': passed, 'bids': bids});
    final bidder = next['bidder'] as String?;
    final remaining = batakPlayerSeats
        .where((id) => passed[id] != true && id != bidder)
        .toList();
    if (next['contract'] == 13 || remaining.isEmpty) {
      final owner = bidder ?? room['firstBidder'] as String;
      next.addAll({
        'phase': 'trump',
        'turn': owner,
        'bidder': owner,
        'contract': bidder == null ? 4 : next['contract'],
        'message': 'İhale tamamlandı. İhaleci koz seçiyor.',
      });
    } else {
      var following = batakNextSeat(seat);
      while (!remaining.contains(following)) {
        following = batakNextSeat(following);
      }
      next['turn'] = following;
    }
    return next;
  }
  if (phase == 'trump' && action == 'trump') {
    if (trump == null || trump < 0 || trump > 3 || room['bidder'] != seat)
      return null;
    return {
      ...next,
      'phase': 'play',
      'trump': trump,
      'message': 'Koz ${batakSuitNames[trump]}. İlk eli ihaleci açar.'
    };
  }
  if (phase == 'play' && action == 'card') {
    if (card == null || !batakLegalCards(room, seat).contains(card))
      return null;
    final players = batakMap(room['players']);
    final player = batakMap(players[seat]);
    final hand = batakHand(player['hand'])..remove(card);
    final trick = [
      ...batakTrick(room['trick']),
      {'seat': seat, 'card': card}
    ];
    next.addAll({
      'players': {
        ...players,
        seat: {...player, 'hand': hand}
      },
      'trick': trick,
      'trumpBroken':
          room['trumpBroken'] == true || batakSuit(card) == room['trump'],
    });
    if (trick.length == 4) {
      final winner =
          batakWinningPlay(trick, room['trump'] as int)['seat'] as String;
      next.addAll({
        'phase': 'collect',
        'turn': winner,
        'trickWinner': winner,
        'message': '${batakMap(players[winner])['name']} eli aldı.'
      });
    } else {
      next['turn'] = batakNextSeat(seat);
    }
    return next;
  }
  if (phase == 'collect' && action == 'collect') {
    final players = batakMap(room['players'])
        .map((key, value) => MapEntry(key, batakMap(value)));
    final winner = players[seat]!;
    winner['taken'] = (winner['taken'] as int) + 1;
    next.addAll({
      'players': players,
      'lastTrick': room['trick'],
      'trick': null,
      'phase': 'play',
      'trickWinner': null,
      'trickNumber': (room['trickNumber'] as int) + 1,
      'message': '${winner['name']} yeni eli açıyor.'
    });
    if (room['trickNumber'] == 13) {
      final contract = room['contract'] as int;
      final delta = <String, int>{};
      for (final id in batakPlayerSeats) {
        final taken = players[id]!['taken'] as int;
        final target = id == room['bidder'] ? contract : 1;
        delta[id] = taken >= target ? taken : -contract;
        players[id]!['score'] = (players[id]!['score'] as int) + delta[id]!;
      }
      next.addAll({
        'phase': 'roundEnd',
        'trickNumber': 13,
        'message': 'Dağıtım bitti. Puanlar yazboza işlendi.',
        'history': {
          ...batakMap(room['history']),
          'r${room['round']}': {
            'bidder': room['bidder'],
            'contract': contract,
            'trump': room['trump'],
            'delta': delta,
            'taken': {
              for (final id in batakPlayerSeats) id: players[id]!['taken']
            },
            'scores': {
              for (final id in batakPlayerSeats) id: players[id]!['score']
            },
          }
        },
      });
      if (room['round'] == 4) {
        final best = batakPlayerSeats
            .map((id) => players[id]!['score'] as int)
            .reduce(max);
        next.addAll({
          'status': 'finished',
          'message': 'Dört dağıtım tamamlandı.',
          'winners': {
            for (final id in batakPlayerSeats)
              if (players[id]!['score'] == best) id: true
          }
        });
      }
    }
    return next;
  }
  return null;
}
