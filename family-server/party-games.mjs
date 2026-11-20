// Original family-table rules, with a deliberately bounded Turkish word bank.
export const familyWords = new Set(`AİLE ANNE BABA ABİ ABLA KARDEŞ EV EL ELİ ELE AL ALİ ALMA ELMA ARMUT ERİK KİRA KARE KARA KAR KART KAPI KAP KUPA KULE KUM KÖY KÖPEK KEDİ KALEM KALE KİTAP KİL KİLİM KİMLİK KİM KİR KİRLİ KİMSE BİR BİZ BİLE BİLİM BİLGİ BİLET BİNA BİSİKLET BAL BALIK BAHAR BAHÇE BARDAK BAYRAK BEBEK BEYAZ BEŞ BİBER BOL BOŞ BU BULUT BURUN CAM CAN CANLI CEVİZ CUMA ÇAM ÇAY ÇİÇEK ÇİLEK ÇİZGİ ÇOK DAĞ DAL DAR DARBE DEDE DENİZ DERE DERİ DERT DEV DEVAM DİL DİŞ DOLU DOST DÖRT DÜN DÜNYA EK EKİM EKMEK EKRAN ELBİSE EMEK EN ERKEN ESKİ EŞ EŞİK ET EVET FARE FARK FİL FİLM FİLE FİŞ GAZ GEMİ GENÇ GECE GELİN GERİ GİBİ GİTAR GÖL GÖZ GÜÇ GÜL GÜNEŞ GÜN GÜZEL HALI HALKA HAVA HAYAL HEDİYE HIZ IRMAK ISI IŞIK İKİ İLERİ İNEK İNSAN İP İPEK İRİ İŞ İŞÇİ İYİ İZ KADIN KALP KANAT KAN KARDEŞ KARTAL KASA KAVUN KAYA KAZ KEK KELİME KEMAN KENT KIRMIZI KISA KIŞ KIZ KOCA KOL KOLAY KONU KORU KOŞU KOYUN KÖK KÖPRÜ KÖŞE KULAK KURT KUŞ KUTU LALE LİMAN LİMON LİRA LİSE MASA MASAL MAVİ MEKTUP MERAK MEVSİM MİDE MİSAFİR MOR MOTOR MUMLUK MUZ MUTLU NAR NE NEHİR NEREDE NESNE ODA ODUN OĞUL OK OKUL OLAN ON ORMAN ORTA OT OTOBÜS OY OYUN ÖDEV ÖDÜL ÖLÇÜ ÖN ÖRDEK ÖRNEK ÖRTÜ ÖZEL PARK PASTA PAZAR PEK PENCERE PERDE PİL PİLOT PİYANO POSTA PUAN RENK RESİM ROL ROMAN RÜZGAR SAAT SAÇ SADE SAHİL SAKİN SALI SARI SAYI SAZ SEL SEN SENE SERİ SES SICAK SINIF SIRA SİLGİ SİMİT SİNEK SİYAH SON SORU SÖZ SU SULU SÜT ŞAKA ŞAPKA ŞARKI ŞEKER ŞEHİR ŞİİR ŞİŞE TABAK TAHTA TAKIM TARLA TAŞ TAT TATİL TAVAN TAVA TAVUK TEL TELEFON TEMİZ TENİS TER TERE TİP TOP TOPRAK TUR TURP TURUNCU TUZ UÇ UÇAK UFAK USTA UYKU UZAK UZUN ÜÇ ÜLKE ÜRÜN ÜST ÜZÜM VAR VAZO VERİ YAKIN YALIN YAN YARIN YAŞ YATAK YAZ YEDİ YEL YEMEK YENİ YER YEŞİL YIL YILDIZ YOL YUMURTA YUNUS YÜZ ZAMAN ZAR ZEBRA ZEMİN ZEYTİN ZİL`.split(/\s+/));
export const partyLimits = { words: [2, 4], roles: [4, 8] };
const check = (ok, message) => { if (!ok) throw new Error(message); };
const alive = (room) => room.players.flatMap((player, seat) => player.out ? [] : [seat]);
const shuffle = (items, random) => {
  for (let i = items.length - 1; i > 0; i--) {
    const j = random(i + 1);
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
};
const letterPoints = (letter) => 'AİEKLMNRT'.includes(letter) ? 1
  : 'IOUÜSBDY'.includes(letter) ? 2 : 'CÇGĞHÖPŞ'.includes(letter) ? 3 : 4;
const finish = (room, winners, message) => {
  room.status = 'finished'; room.winners = winners;
  room.winner = winners.length === 1 ? winners[0] : null;
  room.message = message;
};

export function startParty(room, random) {
  room.status = 'playing'; room.round = 1; room.turn = 0;
  if (room.game === 'words') {
    room.board = Array(121).fill(null); room.phase = 'place';
    // Turkish vowel frequency is represented in the bag, without blanks.
    room.bag = shuffle(Array.from('AAAAAAAEEEEEEEİİİİİİIIIIIOOOOÖÖUUUUÜÜBBCCÇÇDDFFGGĞHHJJKKKKLLLLMMMMNNNNPPPRRRRRSSSSŞŞTTTTTVVYYZZ'), random);
    room.players.forEach((player) => { player.hand = room.bag.splice(-7); player.score = 0; });
    room.passes = 0; room.moves = 0;
    room.message = 'İlk kelime ortadaki yıldızdan geçmeli. Aile sözlüğüyle oynanır.';
  } else {
    const roles = ['seer', 'guardian', 'enemy',
      ...Array(room.players.length - 3).fill('villager')];
    if (room.players.length >= 7) roles[roles.length - 1] = 'enemy';
    shuffle(roles, random);
    room.players.forEach((player, seat) => Object.assign(player, {
      role: roles[seat], out: false, investigations: [],
    }));
    room.phase = 'night'; room.nightActions = {}; room.votes = {};
    room.lastVotes = []; room.events = [];
    room.message = 'Gece başladı. Herkes telefonundaki gizli görevi tamamlasın.';
  }
}

function advanceWords(room) {
  room.moves++;
  if ((!room.bag.length && room.players.some((player) => !player.hand.length)) ||
      room.passes >= room.players.length * 2 || room.moves >= 40) {
    const best = Math.max(...room.players.map((player) => player.score));
    finish(room, room.players.flatMap((player, seat) => player.score === best ? [seat] : []), 'Kelime tahtası tamamlandı.');
    return;
  }
  room.turn = (room.turn + 1) % room.players.length;
  room.round = 1 + Math.floor(room.moves / room.players.length);
}

export function wordAction(room, seat, action, random) {
  check(room.turn === seat, 'Sıra başka oyuncuda.');
  const player = room.players[seat];
  if (action.type === 'passWord' || action.type === 'swapLetters') {
    if (action.type === 'swapLetters') {
      check(room.bag.length >= player.hand.length, 'Torbada değişim için yeterli harf yok.');
      const old = player.hand;
      player.hand = room.bag.splice(-old.length);
      room.bag.push(...old); shuffle(room.bag, random);
    }
    room.passes++; room.message = player.name + ' sırasını geçirdi.';
    advanceWords(room); return;
  }
  check(action.type === 'placeWord', 'Geçersiz kelime hamlesi.');
  const word = typeof action.word === 'string' ? action.word.trim().toLocaleUpperCase('tr-TR') : '';
  check(/^[A-ZÇĞİÖŞÜ]{2,11}$/.test(word) && familyWords.has(word), 'Kelime aile sözlüğünde bulunamadı.');
  check(Number.isInteger(action.row) && action.row >= 0 && action.row < 11 &&
    Number.isInteger(action.col) && action.col >= 0 && action.col < 11 &&
    typeof action.vertical === 'boolean', 'Tahtada bir başlangıç karesi ve yön seç.');
  const dr = action.vertical ? 1 : 0, dc = action.vertical ? 0 : 1;
  check(action.row + dr * (word.length - 1) < 11 && action.col + dc * (word.length - 1) < 11, 'Kelime tahtanın dışına taşıyor.');
  const board = room.board.slice(), hand = player.hand.slice(), added = [];
  for (let i = 0; i < word.length; i++) {
    const index = (action.row + dr * i) * 11 + action.col + dc * i;
    if (board[index] != null) { check(board[index] === word[i], 'Tahtadaki harfle uyuşmuyor.'); continue; }
    const found = hand.indexOf(word[i]); check(found >= 0, 'Elinde gereken harfler yok.');
    hand.splice(found, 1); board[index] = word[i]; added.push(index);
  }
  check(added.length > 0 && added.length <= 7, 'En az bir yeni harf yerleştir.');
  const empty = room.board.every((cell) => cell == null);
  check(empty ? added.includes(60) : added.some((index) =>
    [[-1,0],[1,0],[0,-1],[0,1]].some(([r,c]) => {
      const row = Math.floor(index / 11) + r, col = index % 11 + c;
      return row >= 0 && row < 11 && col >= 0 && col < 11 && room.board[row * 11 + col] != null;
    })), 'İlk kelime yıldızdan geçmeli. Sonraki kelimeler mevcut harflere bağlanmalı.');
  const words = new Map();
  for (const index of added) {
    for (const [r, c] of [[0,1],[1,0]]) {
      let row = Math.floor(index / 11), col = index % 11;
      while (row - r >= 0 && col - c >= 0 && board[(row-r)*11+col-c] != null) { row -= r; col -= c; }
      const start = row * 11 + col, cells = [];
      while (row < 11 && col < 11 && board[row*11+col] != null) { cells.push(row*11+col); row += r; col += c; }
      if (cells.length > 1) words.set(start + ':' + r, cells);
    }
  }
  let score = 0;
  for (const cells of words.values()) {
    const formed = cells.map((index) => board[index]).join('');
    check(familyWords.has(formed), 'Oluşan çapraz kelime aile sözlüğünde yok.');
    score += cells.reduce((sum, index) => sum + letterPoints(board[index]), 0) * (added.includes(60) && cells.includes(60) ? 2 : 1);
  }
  if (added.length === 7) score += 20;
  room.board = board; player.hand = hand; player.score += score;
  player.hand.push(...room.bag.splice(-Math.min(7 - hand.length, room.bag.length)));
  room.passes = 0; room.lastWord = word;
  room.message = player.name + ' ' + word + ' yazdı · ' + score + ' puan.';
  advanceWords(room);
}

function checkTeams(room) {
  const remaining = alive(room), enemies = remaining.filter((id) => room.players[id].role === 'enemy');
  if (!enemies.length || enemies.length * 2 >= remaining.length) {
    room.teamWinner = enemies.length ? 'enemy' : 'village';
    finish(room, room.players.flatMap((player, seat) =>
      (player.role === 'enemy') === (room.teamWinner === 'enemy') ? [seat] : []),
    room.teamWinner === 'enemy' ? 'Sabotajcılar kazandı.' : 'Köy kazandı.');
  }
}

export function roleAction(room, seat, action) {
  if (action.type === 'openVote' || action.type === 'nextNight') {
    check(seat === -1, 'Bu aşamayı ortak ekran ilerletir.');
    check(action.type === 'openVote' ? room.phase === 'discussion' : room.phase === 'dusk', 'Bu aşama henüz açılmadı.');
    room.phase = action.type === 'openVote' ? 'vote' : 'night';
    if (room.phase === 'night') { room.round++; room.nightActions = {}; }
    room.votes = {};
    room.message = room.phase === 'night' ? 'Yeni gece başladı.' : 'Oylar telefonlardan gizli veriliyor.';
    return;
  }
  const player = room.players[seat];
  check(player && !player.out, 'Bu oyuncu artık izleyici.');
  const target = action.target;
  check(target === null || (Number.isInteger(target) && alive(room).includes(target)), 'Geçerli bir oyuncu seç.');
  if (action.type === 'nightChoice') {
    check(room.phase === 'night' && !(seat in room.nightActions), 'Gece görevin tamamlandı veya gündüz başladı.');
    const active = ['enemy', 'guardian', 'seer'].includes(player.role);
    check(!active || target != null, 'Görevin için oyuncu seç.');
    check(player.role !== 'enemy' || room.players[target].role !== 'enemy', 'Takım arkadaşını hedef alamazsın.');
    room.nightActions[seat] = active ? target : null;
    if (Object.keys(room.nightActions).length !== alive(room).length) return;
    const tally = {};
    for (const id of alive(room)) {
      const role = room.players[id].role, chosen = room.nightActions[id];
      if (role === 'enemy') tally[chosen] = (tally[chosen] ?? 0) + 1;
      if (role === 'seer') room.players[id].investigations.push({ day: room.round, target: chosen, enemy: room.players[chosen].role === 'enemy' });
    }
    const ordered = Object.keys(tally).map(Number).sort((a,b) => tally[b] - tally[a]);
    const victim = ordered.length && (ordered.length === 1 || tally[ordered[0]] > tally[ordered[1]]) ? ordered[0] : null;
    const saved = alive(room).some((id) => room.players[id].role === 'guardian' && room.nightActions[id] === victim);
    if (victim != null && !saved) room.players[victim].out = true;
    room.events.push({ day: room.round, phase: 'night', eliminated: victim != null && !saved ? victim : null });
    room.phase = 'discussion';
    room.message = victim != null && !saved ? room.players[victim].name + ' gece elendi.' : 'Gece kimse elenmedi.';
    checkTeams(room); return;
  }
  check(action.type === 'roleVote' && room.phase === 'vote', 'Şu an oy kullanılamıyor.');
  check(!(seat in room.votes) && target !== seat, 'Oyunu zaten verdin veya kendini seçtin.');
  room.votes[seat] = target;
  if (Object.keys(room.votes).length !== alive(room).length) return;
  const tally = {};
  for (const chosen of Object.values(room.votes)) if (chosen != null) tally[chosen] = (tally[chosen] ?? 0) + 1;
  const ordered = Object.keys(tally).map(Number).sort((a,b) => tally[b] - tally[a]);
  const removed = ordered.length && (ordered.length === 1 || tally[ordered[0]] > tally[ordered[1]]) ? ordered[0] : null;
  room.lastVotes = Object.entries(room.votes).map(([voter, choice]) => ({ voter: Number(voter), target: choice }));
  if (removed != null) room.players[removed].out = true;
  room.events.push({ day: room.round, phase: 'vote', eliminated: removed });
  room.phase = 'dusk'; room.message = removed == null ? 'Oylamada kimse elenmedi.' : room.players[removed].name + ' oylamada elendi.';
  checkTeams(room);
}

export function partyView(room, seat) {
  const output = { game: room.game, status: room.status, revision: room.revision,
    round: room.round, turn: room.game === 'words' ? room.turn : undefined,
    phase: room.phase, message: room.message, winner: room.winner, winners: room.winners,
    minPlayers: partyLimits[room.game][0], maxPlayers: partyLimits[room.game][1],
    players: room.players.map(({name, hand, score, out}) => ({name, count: hand?.length, score, out})),
  };
  const player = room.players[seat];
  if (room.game === 'words') {
    Object.assign(output, {board: room.board, stockCount: room.bag?.length,
      dictionary: [...familyWords], lastWord: room.lastWord});
    if (player) output.private = {hand: player.hand};
  } else {
    Object.assign(output, {events: room.events, lastVotes: room.lastVotes,
      submitted: Object.keys(room.phase === 'night' ? room.nightActions ?? {} : room.votes ?? {}).length,
      teamWinner: room.teamWinner});
    if (room.status === 'finished') output.revealedRoles = room.players.map((p) => p.role);
    if (player) output.private = {role: player.role, investigations: player.investigations,
      submitted: seat in (room.phase === 'night' ? room.nightActions ?? {} : room.votes ?? {}),
      allies: player.role === 'enemy' ? room.players.flatMap((p, id) => p.role === 'enemy' ? [id] : []) : [],
    };
  }
  return output;
}
