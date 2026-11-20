import 'dart:math';

typedef MahalleRoom = Map<String, dynamic>;
typedef District = ({String name, int price, int rent, int group});

const districts = <District>[
  (name: 'Başlangıç', price: 0, rent: 0, group: 0),
  (name: 'Çınar Sokak', price: 80, rent: 14, group: 1),
  (name: 'Pazar Kartı', price: 0, rent: 0, group: 0),
  (name: 'Fırın Yolu', price: 100, rent: 17, group: 1),
  (name: 'Belediye', price: 0, rent: 0, group: 0),
  (name: 'Sahil Parkı', price: 120, rent: 21, group: 2),
  (name: 'Vapur İskelesi', price: 140, rent: 24, group: 2),
  (name: 'Pazar Kartı', price: 0, rent: 0, group: 0),
  (name: 'Dinlenme', price: 0, rent: 0, group: 0),
  (name: 'Sanat Sokağı', price: 160, rent: 27, group: 3),
  (name: 'Atölye Meydanı', price: 180, rent: 30, group: 3),
  (name: 'Belediye', price: 0, rent: 0, group: 0),
  (name: 'Pazar Kartı', price: 0, rent: 0, group: 0),
  (name: 'Yel Değirmeni', price: 200, rent: 35, group: 4),
  (name: 'Kıyı Meydanı', price: 220, rent: 38, group: 4),
  (name: 'Dinlenme', price: 0, rent: 0, group: 0),
];

const districtCells = [0, 1, 2, 3, 4, 9, 14, 19, 24, 23, 22, 21, 20, 15, 10, 5];

MahalleRoom mahalleMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

List<String> mahalleSeats(MahalleRoom room) {
  final players = mahalleMap(room['players']);
  return ['p1', 'p2', 'p3', 'p4'].where(players.containsKey).toList();
}

MahalleRoom? joinMahalle(MahalleRoom room, String name) {
  if (room['kind'] != 'mahalle' || room['status'] != 'waiting') return null;
  final players = mahalleMap(room['players']);
  for (var n = 1; n <= 4; n++) {
    if (!players.containsKey('p$n')) {
      return {
        ...room,
        'players': {
          ...players,
          'p$n': {'name': name}
        }
      };
    }
  }
  return null;
}

MahalleRoom? startMahalle(MahalleRoom room, String seat) {
  final seats = mahalleSeats(room);
  if (room['status'] != 'waiting' || room['host'] != seat || seats.length < 2)
    return null;
  final players = mahalleMap(room['players']);
  return {
    ...room,
    'status': 'playing',
    'phase': 'roll',
    'turn': seats.first,
    'round': 1,
    'revision': 1,
    'players': {
      ...players,
      for (final id in seats)
        id: {...mahalleMap(players[id]), 'money': 500, 'position': 0},
    },
  };
}

class MahalleMoveError implements Exception {
  const MahalleMoveError(this.message);
  final String message;
}

MahalleRoom? playMahalle(
    MahalleRoom room, String seat, int revision, String action,
    {required Random random, int? square, String? buyer, int? price}) {
  final seats = mahalleSeats(room);
  if (room['status'] != 'playing' ||
      room['revision'] != revision ||
      !seats.contains(seat)) {
    return null;
  }
  final players = mahalleMap(room['players'])
      .map((key, value) => MapEntry(key, mahalleMap(value)));
  final player = players[seat]!;
  if (player['out'] == true) return null;
  final deeds = mahalleMap(room['deeds'])
      .map((key, value) => MapEntry(key, mahalleMap(value)));
  final next = {
    ...room,
    'players': players,
    'deeds': deeds,
    'revision': revision + 1
  };
  final phase = room['phase'];
  final name = player['name'] as String? ?? 'Oyuncu';
  final money = player['money'] as int;

  void completeGame(String? winner, String message) {
    next.addAll({
      'status': 'finished',
      'winner': winner,
      'message': message,
      'trade': null,
      'auction': null
    });
  }

  void endTurn() {
    next['trade'] = null;
    final remaining = seats.where((id) => players[id]!['out'] != true).toList();
    if (remaining.length <= 1) {
      completeGame(remaining.firstOrNull, 'Masada tek oyuncu kaldı.');
      return;
    }
    final current = seats.indexOf(seat);
    final following = remaining.firstWhere((id) => seats.indexOf(id) > current,
        orElse: () => remaining.first);
    final round =
        (room['round'] as int) + (seats.indexOf(following) <= current ? 1 : 0);
    if (round > 10) {
      final wealth = {
        for (final id in remaining)
          id: (players[id]!['money'] as int) +
              deeds.entries
                  .where((entry) => entry.value['owner'] == id)
                  .fold<int>(
                      0,
                      (sum, entry) =>
                          sum +
                          districts[int.parse(entry.key.substring(1))].price +
                          (entry.value['level'] as int) * 60),
      };
      final best = wealth.values.reduce(max);
      final leaders = remaining.where((id) => wealth[id] == best).toList();
      next['wealth'] = wealth;
      completeGame(
          leaders.length == 1 ? leaders.single : null, 'On tur tamamlandı.');
    } else {
      next.addAll({
        'turn': following,
        'round': round,
        'phase': 'roll',
        'message': 'Sıra ${players[following]!['name']} oyuncusunda.'
      });
    }
  }

  if (action == 'accept' || action == 'reject') {
    final trade = mahalleMap(room['trade']);
    if (trade['buyer'] != seat) return null;
    if (action == 'accept') {
      final dealPrice = trade['price'] as int;
      final seller = players[trade['seller']];
      final deed = deeds[trade['deed']];
      if (seller == null ||
          deed?['owner'] != trade['seller'] ||
          money < dealPrice) {
        throw const MahalleMoveError('Teklif artık geçerli değil.');
      }
      deed!['owner'] = seat;
      player['money'] = money - dealPrice;
      seller['money'] = (seller['money'] as int) + dealPrice;
      next['message'] = '$name bir mülk satın aldı.';
    }
    next['trade'] = null;
    return next;
  }

  if (phase == 'auction') {
    final auction = mahalleMap(room['auction']);
    if (auction['bidder'] != seat || (action != 'bid' && action != 'pass'))
      return null;
    final passed = (auction['passed'] as List? ?? []).cast<String>().toList();
    if (action == 'bid') {
      final amount = (auction['amount'] as int) + 10;
      if (money < amount)
        throw const MahalleMoveError('Teklif için bakiye yetersiz.');
      auction.addAll({'amount': amount, 'leader': seat});
    } else {
      passed.add(seat);
      auction['passed'] = passed;
    }
    final remaining = seats
        .where((id) =>
            players[id]!['out'] != true &&
            id != auction['leader'] &&
            !passed.contains(id))
        .toList();
    if (remaining.isEmpty) {
      final leader = auction['leader'] as String?;
      if (leader != null) {
        players[leader]!['money'] =
            (players[leader]!['money'] as int) - (auction['amount'] as int);
        deeds['d${auction['square']}'] = {'owner': leader, 'level': 0};
      }
      next.addAll({
        'phase': 'end',
        'auction': null,
        'message': leader == null
            ? 'Mülk satılmadı.'
            : '${players[leader]!['name']} ihaleyi kazandı.'
      });
    } else {
      auction['bidder'] = remaining.firstWhere(
          (id) => seats.indexOf(id) > seats.indexOf(seat),
          orElse: () => remaining.first);
      next['auction'] = auction;
    }
    return next;
  }
  if (room['turn'] != seat) return null;
  final position = player['position'] as int;
  switch (action) {
    case 'roll':
      if (phase != 'roll') return null;
      final dice = [random.nextInt(6) + 1, random.nextInt(6) + 1];
      final distance = position + dice[0] + dice[1];
      final arrived = distance % districts.length;
      final district = districts[arrived];
      var balance = money + (distance >= districts.length ? 100 : 0);
      player['position'] = arrived;
      next.addAll({
        'dice': dice,
        'phase': 'end',
        'trade': null,
        'message': '$name · ${district.name}'
      });
      final deed = deeds['d$arrived'];
      var amount = 0;
      final owner = deed?['owner'];
      if (district.price > 0 && deed == null) {
        next['phase'] = 'property';
      } else if (deed != null && owner != seat) {
        amount = district.rent * (1 + (deed['level'] as int));
      } else if (district.name == 'Belediye') {
        amount = 35;
      } else if (district.name == 'Pazar Kartı') {
        final bonus = [60, -35, 25, -20][random.nextInt(4)];
        next['message'] = '$name · Pazar Kartı · ${bonus > 0 ? '+' : ''}$bonus';
        if (bonus >= 0) {
          balance += bonus;
        } else {
          amount = -bonus;
        }
      }
      final paid = min(balance, amount);
      player['money'] = balance - paid;
      if (amount > 0) {
        next['message'] = '${next['message']} · $paid ödeme';
        if (owner != null)
          players[owner]!['money'] = (players[owner]!['money'] as int) + paid;
      }
      if (paid < amount) {
        player['out'] = true;
        if (owner == null) {
          deeds.removeWhere((_, deed) => deed['owner'] == seat);
        } else {
          for (final deed
              in deeds.values.where((deed) => deed['owner'] == seat)) {
            deed['owner'] = owner;
          }
        }
        endTurn();
      }
    case 'buy':
    case 'auction':
      if (phase != 'property') return null;
      final district = districts[position];
      if (action == 'buy') {
        if (money < district.price)
          throw const MahalleMoveError('Bakiyen yetersiz.');
        player['money'] = money - district.price;
        deeds['d$position'] = {'owner': seat, 'level': 0};
        next.addAll({
          'phase': 'end',
          'message': '$name · ${district.name} satın alındı.'
        });
      } else {
        next.addAll({
          'phase': 'auction',
          'auction': {'square': position, 'bidder': seat, 'amount': 0}
        });
      }
    case 'end':
      if (phase != 'end') return null;
      endTurn();
    case 'build':
    case 'trade':
      if ((phase != 'roll' && phase != 'end') || square == null) return null;
      final deed = deeds['d$square'];
      if (deed?['owner'] != seat) return null;
      if (action == 'build') {
        final group = districts[square].group;
        final ownsGroup = districts.indexed.every((entry) =>
            entry.$2.group != group || deeds['d${entry.$1}']?['owner'] == seat);
        final level = deed!['level'] as int;
        if (!ownsGroup || level >= 3 || money < 60) {
          throw const MahalleMoveError(
              'İki mülk de sende olmalı. Geliştirme 60 para, en çok üç seviye.');
        }
        player['money'] = money - 60;
        deed['level'] = level + 1;
        next['message'] = '$name · ${districts[square].name} geliştirildi.';
      } else {
        if (room['trade'] != null ||
            !seats.contains(buyer) ||
            buyer == seat ||
            players[buyer]!['out'] == true ||
            price == null ||
            price < 1 ||
            price > 2000) {
          throw const MahalleMoveError(
              'Oyuncuyu, fiyatı ve bekleyen teklifi kontrol et.');
        }
        next['trade'] = {
          'seller': seat,
          'buyer': buyer,
          'deed': 'd$square',
          'price': price
        };
      }
    case 'cancelTrade':
      if (mahalleMap(room['trade'])['seller'] != seat) return null;
      next['trade'] = null;
    default:
      return null;
  }
  return next;
}
