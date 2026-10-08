import 'dart:math';

const deckSuits = ['c', 'd', 'h', 's'];
const deckRanks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

String cardRank(String card) => card.substring(1);

bool cardIsRed(String card) => card.startsWith('h') || card.startsWith('d');

String cardSuitSymbol(String card) {
  switch (card.substring(0, 1)) {
    case 'h':
      return '♥';
    case 'd':
      return '♦';
    case 's':
      return '♠';
    default:
      return '♣';
  }
}

String cardLabel(String card) {
  const suits = {'c': 'sinek', 'd': 'karo', 'h': 'kupa', 's': 'maça'};
  const faces = {
    'A': 'as',
    'J': 'vale',
    'Q': 'kız',
    'K': 'papaz',
  };
  final rank = cardRank(card);
  final rankName = faces[rank] ?? rank;
  return '${suits[card.substring(0, 1)] ?? 'kart'} $rankName';
}

List<String> freshDeck() {
  final cards = <String>[];
  for (final suit in deckSuits) {
    for (final rank in deckRanks) {
      cards.add('$suit$rank');
    }
  }
  return cards;
}

int scoreCaptured({
  required List<String> cards,
  required int pistiCount,
  required bool mostCards,
}) {
  var score = pistiCount * 10;
  for (final card in cards) {
    if (cardRank(card) == 'A') {
      score += 1;
    }
    if (card == 'cJ' || card == 'c2') {
      score += 2;
    }
  }
  if (mostCards) {
    score += 3;
  }
  return score;
}

class PistiGame {
  PistiGame({
    required this.deck,
    required this.hands,
    required this.table,
    required this.captured,
    required this.pisti,
    required this.seats,
    required this.turn,
    required this.lastCapture,
    required this.phase,
    required this.scores,
  });

  factory PistiGame.deal(List<String> seats, Random random) {
    final deck = freshDeck()..shuffle(random);
    final hands = <String, List<String>>{
      for (final seat in seats) seat: <String>[],
    };
    final captured = <String, List<String>>{
      for (final seat in seats) seat: <String>[],
    };
    final pisti = <String, int>{
      for (final seat in seats) seat: 0,
    };
    for (var round = 0; round < 4; round++) {
      for (final seat in seats) {
        hands[seat]!.add(deck.removeLast());
      }
    }
    final table = <String>[];
    for (var i = 0; i < 4; i++) {
      table.add(deck.removeLast());
    }
    var guard = 0;
    while (table.isNotEmpty &&
        cardRank(table.last) == 'J' &&
        deck.isNotEmpty &&
        guard < 8) {
      final jack = table.removeLast();
      deck.insert(random.nextInt(deck.length + 1), jack);
      table.add(deck.removeLast());
      guard++;
    }
    return PistiGame(
      deck: deck,
      hands: hands,
      table: table,
      captured: captured,
      pisti: pisti,
      seats: List<String>.of(seats),
      turn: seats.first,
      lastCapture: '',
      phase: 'play',
      scores: {for (final seat in seats) seat: 0},
    );
  }

  factory PistiGame.fromMap(Map<dynamic, dynamic> raw) {
    final seats = _strings(raw['seats']);
    final hands = _stringMap(raw['hands']);
    final captured = _stringMap(raw['captured']);
    final pisti = _intMap(raw['pisti']);
    final scores = _intMap(raw['scores']);
    for (final seat in seats) {
      hands.putIfAbsent(seat, () => <String>[]);
      captured.putIfAbsent(seat, () => <String>[]);
      pisti.putIfAbsent(seat, () => 0);
      scores.putIfAbsent(seat, () => 0);
    }
    return PistiGame(
      deck: _strings(raw['deck']),
      hands: hands,
      table: _strings(raw['table']),
      captured: captured,
      pisti: pisti,
      seats: seats,
      turn: raw['turn']?.toString() ?? (seats.isEmpty ? '' : seats.first),
      lastCapture: raw['lastCapture']?.toString() ?? '',
      phase: raw['phase']?.toString() ?? 'play',
      scores: scores,
    );
  }

  final List<String> deck;
  final Map<String, List<String>> hands;
  final List<String> table;
  final Map<String, List<String>> captured;
  final Map<String, int> pisti;
  final List<String> seats;
  String turn;
  String lastCapture;
  String phase;
  final Map<String, int> scores;

  /// Başarılıysa null. Aksi halde oyuncuya gösterilecek kısa neden.
  String? play(String player, String card) {
    if (phase != 'play') {
      return 'El bitti';
    }
    if (player != turn) {
      return 'Sıra sende değil';
    }
    final hand = hands[player];
    if (hand == null || !hand.contains(card)) {
      return 'Bu kart elinde yok';
    }
    hand.remove(card);
    final top = table.isEmpty ? null : table.last;
    final captures = top != null && (cardRank(card) == cardRank(top) || cardRank(card) == 'J');
    if (captures) {
      final pishti = table.length == 1;
      captured[player]!.addAll(table);
      captured[player]!.add(card);
      table.clear();
      if (pishti) {
        pisti[player] = (pisti[player] ?? 0) + 1;
      }
      lastCapture = player;
    } else {
      table.add(card);
    }
    _advanceTurn();
    if (_handsEmpty()) {
      if (deck.isEmpty) {
        _finish();
      } else {
        _redeal();
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'deck': deck,
        'hands': hands,
        'table': table,
        'captured': captured,
        'pisti': pisti,
        'seats': seats,
        'turn': turn,
        'lastCapture': lastCapture,
        'phase': phase,
        'scores': scores,
      };

  void _advanceTurn() {
    if (seats.isEmpty) {
      return;
    }
    final start = seats.indexOf(turn);
    final from = start < 0 ? 0 : start;
    for (var step = 1; step <= seats.length; step++) {
      final next = seats[(from + step) % seats.length];
      if ((hands[next] ?? const <String>[]).isNotEmpty || _handsEmpty()) {
        turn = next;
        return;
      }
    }
  }

  bool _handsEmpty() => seats.every((seat) => (hands[seat] ?? const <String>[]).isEmpty);

  void _redeal() {
    for (var round = 0; round < 4; round++) {
      for (final seat in seats) {
        if (deck.isEmpty) {
          return;
        }
        hands[seat]!.add(deck.removeLast());
      }
    }
  }

  void _finish() {
    if (lastCapture.isNotEmpty && table.isNotEmpty) {
      captured[lastCapture]!.addAll(table);
      table.clear();
    }
    var best = -1;
    var leaders = 0;
    for (final seat in seats) {
      final count = captured[seat]!.length;
      if (count > best) {
        best = count;
        leaders = 1;
      } else if (count == best) {
        leaders += 1;
      }
    }
    final mostSeat = leaders == 1 && best > 0
        ? seats.firstWhere((seat) => captured[seat]!.length == best)
        : '';
    for (final seat in seats) {
      scores[seat] = scoreCaptured(
        cards: captured[seat]!,
        pistiCount: pisti[seat] ?? 0,
        mostCards: seat == mostSeat,
      );
    }
    phase = 'scored';
  }

  static List<String> _strings(Object? raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toList();
    }
    return <String>[];
  }

  static Map<String, List<String>> _stringMap(Object? raw) {
    final out = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        out[key.toString()] = _strings(value);
      });
    }
    return out;
  }

  static Map<String, int> _intMap(Object? raw) {
    final out = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        out[key.toString()] = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
      });
    }
    return out;
  }
}
