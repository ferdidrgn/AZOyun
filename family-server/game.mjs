import { randomInt } from 'node:crypto';

export const games = ['okey', 'okey101', 'city'];
const districts = [
  ['Başlangıç'], ['Çınar Sokak', 80, 14, 1], ['Pazar Kartı'], ['Fırın Yolu', 100, 17, 1],
  ['Belediye'], ['Sahil Parkı', 120, 21, 2], ['Vapur İskelesi', 140, 24, 2], ['Pazar Kartı'],
  ['Dinlenme'], ['Sanat Sokağı', 160, 27, 3], ['Atölye Meydanı', 180, 30, 3], ['Belediye'],
  ['Pazar Kartı'], ['Yel Değirmeni', 200, 35, 4], ['Kıyı Meydanı', 220, 38, 4], ['Dinlenme'],
];
const check = (ok, message) => { if (!ok) throw new Error(message); };
const next = (room, from) => {
  for (let step = 1; step <= room.players.length; step++) {
    const index = (from + step) % room.players.length;
    if (!room.players[index].out) return index;
  }
  return from;
};

function shuffled(deck, random) {
  for (let index = deck.length - 1; index > 0; index--) {
    const swap = random(index + 1);
    [deck[index], deck[swap]] = [deck[swap], deck[index]];
  }
  return deck;
}

function start(room, random) {
  room.status = 'playing';
  room.turn = 0;
  room.round = 1;
  if (room.game === 'city') {
    room.phase = 'roll';
    room.deeds = {};
    room.players.forEach((player) => Object.assign(player, { money: 500, position: 0 }));
    room.message = 'İlk oyuncu zar atıyor.';
    return;
  }
  const stock = [];
  for (let copy = 0; copy < 2; copy++) {
    for (let color = 0; color < 4; color++) {
      for (let value = 1; value <= 13; value++) {
        stock.push({ id: stock.length, color, value });
      }
    }
  }
  stock.push({ id: 104, fake: true }, { id: 105, fake: true });
  shuffled(stock, random);
  const indicatorIndex = stock.findIndex((tile) => !tile.fake);
  room.indicator = stock.splice(indicatorIndex, 1)[0];
  room.stock = stock;
  room.discards = room.players.map(() => null);
  room.melds = [];
  const count = room.game === 'okey101' ? 21 : 14;
  room.players.forEach((player, index) => {
    player.hand = stock.splice(0, count + (index === 0 ? 1 : 0));
    player.opened = false;
  });
  room.phase = 'discard';
  room.message = 'Taşlar dağıtıldı.';
}

export function okeyTile(tile, indicator) {
  const value = indicator.value % 13 + 1;
  if (tile.fake) return { ...tile, color: indicator.color, value, wild: false };
  return { ...tile, wild: tile.color === indicator.color && tile.value === value };
}

export function meldScore(raw, indicator) {
  if (raw.length < 3 || raw.length > 13) return 0;
  const tiles = raw.map((tile) => okeyTile(tile, indicator));
  const fixed = tiles.filter((tile) => !tile.wild);
  if (!fixed.length) return 0;
  const value = fixed[0].value;
  let best = 0;
  if (tiles.length <= 4 && fixed.every((tile) => tile.value === value) &&
      new Set(fixed.map((tile) => tile.color)).size === fixed.length) {
    best = tiles.length * value;
  }
  if (fixed.every((tile) => tile.color === fixed[0].color) &&
      new Set(fixed.map((tile) => tile.value)).size === fixed.length) {
    const low = Math.min(...fixed.map((tile) => tile.value));
    const high = Math.max(...fixed.map((tile) => tile.value));
    const start = Math.min(low, 14 - tiles.length);
    if (high < start + tiles.length) best = Math.max(best, tiles.length * (2 * start + tiles.length - 1) / 2);
    if (tiles.length === 3 && fixed.every((tile) => [12, 13, 1].includes(tile.value))) {
      best = Math.max(best, 26);
    }
  }
  return best;
}

export function classicWin(raw, indicator) {
  if (raw.length !== 14) return false;
  const tiles = raw.map((tile) => okeyTile(tile, indicator));
  const wild = tiles.filter((tile) => tile.wild).length;
  const fixed = tiles.filter((tile) => !tile.wild);
  const counts = new Map();
  for (const tile of fixed) {
    const key = tile.color * 13 + tile.value;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  if ([...counts.values()].filter((count) => count % 2).length <= wild) return true;
  const memo = new Map();
  function solve(left, jokers) {
    if (!left.length) return jokers === 0;
    const key = left.map((tile) => tile.color * 13 + tile.value).sort((a,b) => a-b).join(',') + ':' + jokers;
    if (memo.has(key)) return memo.get(key);
    const first = left[0];
    const patterns = [];
    for (let mask = 0; mask < 16; mask++) {
      const colors = [0, 1, 2, 3].filter((color) => mask & (1 << color));
      if (colors.length >= 3 && colors.includes(first.color)) {
        patterns.push(colors.map((color) => [color, first.value]));
      }
    }
    for (let length = 3; length <= 13; length++) {
      for (let start = Math.max(1, first.value - length + 1); start <= Math.min(first.value, 14 - length); start++) {
        patterns.push(Array.from({ length }, (_, offset) => [first.color, start + offset]));
      }
    }
    if ([12, 13, 1].includes(first.value)) patterns.push([12, 13, 1].map((value) => [first.color, value]));
    for (const pattern of patterns) {
      const remaining = left.slice(1);
      let cost = 0;
      for (const [color, value] of pattern) {
        if (color === first.color && value === first.value) continue;
        const index = remaining.findIndex((tile) => tile.color === color && tile.value === value);
        if (index < 0) cost++;
        else remaining.splice(index, 1);
      }
      if (cost <= jokers && solve(remaining, jokers - cost)) {
        memo.set(key, true);
        return true;
      }
    }
    memo.set(key, false);
    return false;
  }
  return solve(fixed, wild);
}

function finish(room, winner, message) {
  room.status = 'finished';
  room.winner = winner;
  room.message = message;
  delete room.trade;
}

function takeTiles(player, ids) {
  check(Array.isArray(ids) && ids.length > 0 && new Set(ids).size === ids.length, 'Taş seçimini kontrol et.');
  const tiles = ids.map((id) => player.hand.find((tile) => tile.id === id));
  check(tiles.every(Boolean), 'Seçilen taş elinde yok.');
  return tiles;
}

function tileAction(room, seat, action) {
  const player = room.players[seat];
  if (action.type === 'draw') {
    check(room.phase === 'draw', 'Önceki çekim tamamlandı.');
    if (action.source === 'discard') {
      const previous = (seat + room.players.length - 1) % room.players.length;
      const tile = room.discards[previous];
      check(tile, 'Önceki oyuncunun attığı taş yok.');
      player.hand.push(tile);
      room.discards[previous] = null;
      if (room.game === 'okey101') room.requiredTile = tile.id;
    } else {
      if (!room.stock.length) return finish(room, null, 'Deste bitti. El berabere.');
      player.hand.push(room.stock.pop());
    }
    room.phase = 'discard';
    room.message = player.name + ' taş çekti.';
    return;
  }
  check(room.phase === 'discard', 'Önce bir taş çek.');
  if (action.type === 'returnDiscard') {
    check(room.requiredTile != null, 'Geri bırakılacak taş yok.');
    const [tile] = takeTiles(player, [room.requiredTile]);
    const previous = (seat + room.players.length - 1) % room.players.length;
    room.discards[previous] = tile;
    player.hand = player.hand.filter((item) => item.id !== tile.id);
    delete room.requiredTile;
    room.phase = 'draw';
    room.message = player.name + ' aldığı taşı geri bıraktı.';
    return;
  }
  if (action.type === 'meld' || action.type === 'extend') {
    check(room.game === 'okey101', 'Bu hamle 101 Okey masasına ait.');
    if (action.type === 'extend') {
      check(player.opened, 'Önce el açmalısın.');
      const group = room.melds[action.index];
      const [tile] = takeTiles(player, [action.tile]);
      check(room.requiredTile == null || room.requiredTile === tile.id, 'Önce yerden aldığın taşı işle.');
      check(group && !group.pair && player.hand.length > 1 && meldScore([...group.tiles, tile], room.indicator), 'Taş bu gruba uymaz.');
      group.tiles.push(tile);
      player.hand = player.hand.filter((item) => item.id !== tile.id);
      if (room.requiredTile === tile.id) delete room.requiredTile;
    } else {
      check(Array.isArray(action.groups) && action.groups.length <= 7 &&
        action.groups.every(Array.isArray), 'Grupları kontrol et.');
      const ids = action.groups.flat();
      const selected = takeTiles(player, ids);
      check(selected.length < player.hand.length, 'Sıranın sonunda atacak bir taş bırak.');
      check(room.requiredTile == null || ids.includes(room.requiredTile), 'Yerden aldığın taşı gruba ekle.');
      const groups = action.groups.map((group) => takeTiles(player, group));
      const pairs = action.pairs === true;
      check(!player.opened || player.pairs === pairs, 'Açtığın oyun türüyle devam et.');
      if (pairs) {
        check(player.opened || groups.length >= 5, 'İlk çift açılışında en az beş çift gerekir.');
        check(groups.every((group) => {
          if (group.length !== 2) return false;
          const [a, b] = group.map((tile) => okeyTile(tile, room.indicator));
          return a.wild || b.wild || (a.color === b.color && a.value === b.value);
        }), 'Her çift aynı renk ve sayıdan oluşmalı.');
      } else {
        const scores = groups.map((group) => meldScore(group, room.indicator));
        check(scores.every((score) => score > 0), 'Geçersiz seri veya per var.');
        check(player.opened || scores.reduce((a,b) => a+b, 0) >= 101, 'İlk açılışta en az 101 puan gerekir.');
      }
      room.melds.push(...groups.map((tiles) => ({ seat, tiles, pair: pairs })));
      player.opened = true;
      player.pairs = pairs;
      player.hand = player.hand.filter((tile) => !ids.includes(tile.id));
      if (ids.includes(room.requiredTile)) delete room.requiredTile;
    }
    room.message = player.name + ' masaya taş işledi.';
    return;
  }
  check(action.type === 'discard' || action.type === 'win', 'Bu hamle geçersiz.');
  check(room.requiredTile == null, 'Yerden aldığın taşı önce bir grupta kullan.');
  const [tile] = takeTiles(player, [action.tile]);
  const remaining = player.hand.filter((item) => item.id !== tile.id);
  if (action.type === 'win') {
    check(room.game === 'okey' && classicWin(remaining, room.indicator), 'Eldeki taşlar bitişe uygun değil.');
  }
  player.hand = remaining;
  room.discards[seat] = tile;
  if (action.type === 'win' || remaining.length === 0) {
    return finish(room, seat, player.name + ' eli bitirdi.');
  }
  room.turn = next(room, seat);
  room.phase = 'draw';
  room.round++;
  room.message = player.name + ' taş attı.';
}

function charge(room, seat, amount, recipient = null) {
  const player = room.players[seat];
  const paid = Math.min(player.money, amount);
  player.money -= paid;
  if (recipient != null) room.players[recipient].money += paid;
  if (paid === amount) return;
  player.out = true;
  for (const [square, deed] of Object.entries(room.deeds)) {
    if (deed.owner !== seat) continue;
    if (recipient == null) delete room.deeds[square];
    else deed.owner = recipient;
  }
  room.message += ' ' + player.name + ' iflas etti.';
}

function cityEnd(room) {
  delete room.trade;
  delete room.eventCard;
  delete room.auction;
  const survivors = room.players.flatMap((player, index) => player.out ? [] : [index]);
  if (survivors.length <= 1) return finish(room, survivors[0] ?? null, 'Mahalleler tamamlandı.');
  const turn = next(room, room.turn);
  if (turn < room.turn) room.round++;
  if (room.round > 10) {
    room.wealth = room.players.map((player, seat) => player.out ? 0 : player.money +
      Object.entries(room.deeds).reduce((sum, [index, deed]) =>
        sum + (deed.owner === seat ? districts[index][1] + deed.level * 60 : 0), 0));
    const best = Math.max(...survivors.map((seat) => room.wealth[seat]));
    const leaders = survivors.filter((seat) => room.wealth[seat] === best);
    return finish(room, leaders.length === 1 ? leaders[0] : null, 'On tur tamamlandı.');
  }
  room.turn = turn;
  room.phase = 'roll';
  room.message = 'Sıra ' + room.players[turn].name + ' oyuncusunda.';
}

function resolveAuction(room) {
  const auction = room.auction;
  const remaining = room.players.flatMap((player, seat) =>
    !player.out && !auction.passed.includes(seat) && seat !== auction.leader ? [seat] : []);
  if (!remaining.length) {
    if (auction.leader != null) {
      const buyer = room.players[auction.leader];
      buyer.money -= auction.bid;
      room.deeds[auction.square] = { owner: auction.leader, level: 0 };
      room.message = buyer.name + ' açık artırmayı kazandı.';
    } else {
      room.message = 'Mülk satılmadı.';
    }
    room.phase = 'end';
    delete room.auction;
    return;
  }
  auction.bidder = remaining.find((seat) => seat > auction.bidder) ?? remaining[0];
}

function cityAction(room, seat, action, random) {
  const player = room.players[seat];
  check(!player.out, 'Bu oyuncu oyundan çıktı.');
  if (action.type === 'tradeReply') {
    const trade = room.trade;
    check(trade && trade.to === seat, 'Bu teklif sana ait değil.');
    if (action.accept === true) {
      const seller = room.players[trade.from];
      const deed = room.deeds[trade.square];
      check(deed?.owner === trade.from && player.money >= trade.price, 'Teklif artık geçerli değil.');
      deed.owner = seat;
      seller.money += trade.price;
      player.money -= trade.price;
      room.message = 'Bir mülk el değiştirdi.';
    }
    delete room.trade;
    return;
  }
  if (room.phase === 'auction') {
    const auction = room.auction;
    check(seat === auction.bidder, 'Teklif sırası başka oyuncuda.');
    check(action.type === 'bid' || action.type === 'passBid', 'Teklif ver veya pas geç.');
    if (action.type === 'bid') {
      const amount = auction.bid + 10;
      check(player.money >= amount, 'Bu teklif için bakiyen yetersiz.');
      auction.bid = amount;
      auction.leader = seat;
    } else {
      auction.passed.push(seat);
    }
    return resolveAuction(room);
  }
  check(room.turn === seat, 'Sıra başka oyuncuda.');
  if (action.type === 'roll') {
    check(room.phase === 'roll', 'Zar zaten atıldı.');
    delete room.trade;
    const dice = [random(6) + 1, random(6) + 1];
    const distance = player.position + dice[0] + dice[1];
    if (distance >= districts.length) player.money += 100;
    player.position = distance % districts.length;
    room.dice = dice;
    room.phase = 'end';
    const [label, price, rent] = districts[player.position];
    const deed = room.deeds[player.position];
    room.message = player.name + ' · ' + label;
    if (price && !deed) room.phase = 'property';
    if (deed && deed.owner !== seat) {
      const amount = rent * (deed.level + 1);
      room.message += ' · Kira ' + amount;
      charge(room, seat, amount, deed.owner);
    }
    if (label === 'Belediye') charge(room, seat, 35);
    if (label === 'Pazar Kartı') {
      const amount = [60, -35, 25, -20][random(4)];
      room.eventCard = { seat, text: amount > 0 ? 'Pazar geliri +' + amount : 'Bakım masrafı ' + amount };
      if (amount > 0) player.money += amount;
      else charge(room, seat, -amount);
    }
    if (player.out) cityEnd(room);
    return;
  }
  if (action.type === 'buy' || action.type === 'auction') {
    check(room.phase === 'property', 'Satışta mülk yok.');
    if (action.type === 'buy') {
      const price = districts[player.position][1];
      check(player.money >= price, 'Bakiyen yetersiz. Açık artırma başlatabilirsin.');
      player.money -= price;
      room.deeds[player.position] = { owner: seat, level: 0 };
      room.phase = 'end';
      room.message = player.name + ' mülkü satın aldı.';
    } else {
      room.phase = 'auction';
      room.auction = { square: player.position, bidder: seat, bid: 0, leader: null, passed: [] };
    }
    return;
  }
  check(room.phase === 'roll' || room.phase === 'end', 'Önce satış kararını tamamla.');
  if (action.type === 'end') {
    check(room.phase === 'end', 'Önce zar at.');
    return cityEnd(room);
  }
  if (action.type === 'cancelTrade') {
    check(room.trade?.from === seat, 'İptal edilecek teklif yok.');
    delete room.trade;
    return;
  }
  const square = action.square;
  const deed = room.deeds[square];
  check(deed?.owner === seat, 'Bu mülk sana ait değil.');
  if (action.type === 'build') {
    const group = districts[square][3];
    check(districts.every((district, index) => district[3] !== group || room.deeds[index]?.owner === seat),
      'Geliştirmek için mahallenin iki mülkü de sende olmalı.');
    check(player.money >= 60 && deed.level < 3, 'Geliştirme için 60 para gerekir. En çok üç seviye.');
    check(room.trade?.square !== square, 'Önce bu mülkün teklifini kapat.');
    player.money -= 60;
    deed.level++;
    room.message = player.name + ' mahallesini geliştirdi.';
    return;
  }
  check(action.type === 'trade', 'Bu hamle geçersiz.');
  check(!room.trade, 'Önce bekleyen teklifi kapat.');
  check(Number.isInteger(action.to) && action.to !== seat && room.players[action.to] &&
    !room.players[action.to].out, 'Geçerli bir alıcı seç.');
  check(Number.isInteger(action.price) && action.price >= 0 && action.price <= 2000, 'Geçerli bir fiyat gir.');
  room.trade = { from: seat, to: action.to, square, price: action.price };
}

export function applyAction(room, seat, action, random = randomInt) {
  if (action.type === 'close') {
    check(seat === -1 && room.status !== 'finished', 'Masayı yalnızca kurucu kapatabilir.');
    return finish(room, null, 'Masa kurucu tarafından kapatıldı.');
  }
  if (action.type === 'start') {
    check(seat === -1 && room.status === 'lobby', 'Masayı yalnızca kurucu başlatabilir.');
    check(room.players.length >= (room.game === 'city' ? 2 : 4), 'Daha fazla oyuncu gerekiyor.');
    start(room, random);
    return;
  }
  check(room.status === 'playing' && room.players[seat], 'Oyun başladıktan sonra oyuncu hamle yapabilir.');
  if (room.game === 'city') return cityAction(room, seat, action, random);
  check(room.turn === seat, 'Sıra başka oyuncuda.');
  tileAction(room, seat, action);
}

export function view(room, seat) {
  const output = {
    game: room.game, status: room.status, revision: room.revision, turn: room.turn,
    phase: room.phase, round: room.round, message: room.message, winner: room.winner,
    players: room.players.map(({ name, hand, opened, pairs, position, out }) =>
      ({ name, count: hand?.length, opened, pairs, position, out })),
  };
  const player = room.players[seat];
  if (room.game === 'city') {
    Object.assign(output, {
      board: districts.map(([name, price, rent, group], index) =>
        ({ name, price, rent, group, ...room.deeds?.[index] })),
      dice: room.dice, auction: room.auction && {
        square: room.auction.square, bidder: room.auction.bidder, bid: room.auction.bid,
        leader: room.auction.leader,
      },
      wealth: room.wealth,
    });
    if (player) {
      output.private = { money: player.money,
        card: room.eventCard?.seat === seat ? room.eventCard.text : undefined,
        trade: room.trade && [room.trade.from, room.trade.to].includes(seat) ? room.trade : undefined,
      };
    }
  } else {
    const tileView = (tile) => tile == null ? null : okeyTile(tile, room.indicator);
    Object.assign(output, {
      indicator: room.indicator, stockCount: room.stock?.length,
      discards: room.discards?.map(tileView),
      melds: room.melds?.map((group) => ({ seat: group.seat, pair: group.pair, tiles: group.tiles.map(tileView) })),
    });
    if (player) output.private = { hand: player.hand?.map(tileView),
      requiredTile: room.turn === seat ? room.requiredTile : undefined,
    };
  }
  return output;
}
