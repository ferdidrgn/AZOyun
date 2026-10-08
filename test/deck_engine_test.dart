import 'dart:math';

import 'package:AZOyun/core/services/deep_link_service.dart';
import 'package:AZOyun/features/deck/deck_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eşleşen kart pişti olur ve sırayı devreder', () {
    final game = PistiGame(
      deck: const [],
      hands: {
        'p1': ['hA', 'c2'],
        'p2': ['dK'],
      },
      table: ['cA'],
      captured: {
        'p1': [],
        'p2': [],
      },
      pisti: {'p1': 0, 'p2': 0},
      seats: const ['p1', 'p2'],
      turn: 'p1',
      lastCapture: '',
      phase: 'play',
      scores: {'p1': 0, 'p2': 0},
    );

    expect(game.play('p2', 'dK'), 'Sıra sende değil');
    expect(game.play('p1', 'hA'), isNull);
    expect(game.table, isEmpty);
    expect(game.pisti['p1'], 1);
    expect(game.captured['p1'], ['cA', 'hA']);
    expect(game.turn, 'p2');
  });

  test('vale desteyi alır, tek kart değilse pişti sayılmaz', () {
    final game = PistiGame(
      deck: const [],
      hands: {
        'p1': ['cJ'],
        'p2': ['d2'],
      },
      table: ['h5', 's9'],
      captured: {
        'p1': [],
        'p2': [],
      },
      pisti: {'p1': 0, 'p2': 0},
      seats: const ['p1', 'p2'],
      turn: 'p1',
      lastCapture: '',
      phase: 'play',
      scores: {'p1': 0, 'p2': 0},
    );

    expect(game.play('p1', 'cJ'), isNull);
    expect(game.table, isEmpty);
    expect(game.pisti['p1'], 0);
    expect(game.captured['p1'], ['h5', 's9', 'cJ']);
  });

  test('puan: pişti, as, sinek vale ve sinek ikili', () {
    expect(
      scoreCaptured(cards: const ['cJ', 'c2', 'hA', 'd5'], pistiCount: 1, mostCards: true),
      10 + 2 + 2 + 1 + 3,
    );
    expect(
      scoreCaptured(cards: const ['hA'], pistiCount: 0, mostCards: false),
      1,
    );
  });

  test('dağıtım 52 kartı böler ve masa vale ile açılmaz', () {
    final game = PistiGame.deal(const ['p1', 'p2'], Random(7));
    final seen = <String>{
      ...game.deck,
      ...game.table,
      ...game.hands['p1']!,
      ...game.hands['p2']!,
    };
    expect(seen, hasLength(52));
    expect(game.hands['p1'], hasLength(4));
    expect(game.table, hasLength(4));
    expect(cardRank(game.table.last), isNot('J'));
    expect(game.turn, 'p1');
  });

  test('davet adresi kod ve oyunu taşır', () {
    final web = Uri.parse(DeepLinkService.webInvite('deck', 'ab12cd'));
    final app = Uri.parse(DeepLinkService.appInvite('golf', 'zz99kk'));
    expect(DeepLinkService.parseJoinLink(web), (game: 'deck', code: 'AB12CD'));
    expect(DeepLinkService.parseJoinLink(app), (game: 'golf', code: 'ZZ99KK'));
    expect(
      DeepLinkService.parseJoinLink(Uri.parse('https://azoyun.web.app/join/okey/mn34pq')),
      (game: 'okey', code: 'MN34PQ'),
    );
  });
}
