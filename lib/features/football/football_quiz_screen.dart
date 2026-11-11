import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum FootballQuizMode {
  player('Futbolcuyu Bil'),
  club('Takımı Bul');

  const FootballQuizMode(this.title);
  final String title;
}

class FootballQuizScreen extends StatefulWidget {
  const FootballQuizScreen({super.key, required this.mode});
  final FootballQuizMode mode;

  @override
  State<FootballQuizScreen> createState() => _FootballQuizScreenState();
}

typedef FootballEntry = ({String name, String article, List<String> clues});

const _players = <FootballEntry>[
  (
    name: 'Lionel Messi',
    article: 'Lionel Messi',
    clues: [
      '2022 Dünya Kupası’nda Altın Top ödülünü kazandı.',
      'Barcelona’dan ayrıldıktan sonra Paris Saint-Germain’de oynadı.',
      'Arjantin’in 2022 finalinde iki gol attı.'
    ]
  ),
  (
    name: 'Cristiano Ronaldo',
    article: 'Cristiano Ronaldo',
    clues: [
      'Portekiz ile EURO 2016 şampiyonluğu yaşadı.',
      'Sporting’den Manchester United’a transfer oldu.',
      'Real Madrid’de dokuz sezon forma giydi.'
    ]
  ),
  (
    name: 'Luka Modrić',
    article: 'Luka Modrić',
    clues: [
      '2018 Dünya Kupası’nın Altın Top ödülünü aldı.',
      'Tottenham’dan Real Madrid’e geçti.',
      '2018 Ballon d’Or ödülünü kazanan Hırvat orta saha.'
    ]
  ),
  (
    name: 'Kylian Mbappé',
    article: 'Kylian Mbappé',
    clues: [
      '2022 Dünya Kupası finalinde hat-trick yaptı.',
      'Monaco’da çıkış yaptı.',
      'Fransa ile 2018 Dünya Kupası’nı kazandı.'
    ]
  ),
  (
    name: 'Mohamed Salah',
    article: 'Mohamed Salah',
    clues: [
      '2017’de Roma’dan Liverpool’a transfer oldu.',
      'Basel ve Chelsea’de de forma giydi.',
      '2019 Şampiyonlar Ligi finalinde penaltıdan gol attı.'
    ]
  ),
  (
    name: 'Erling Haaland',
    article: 'Erling Haaland',
    clues: [
      '2022-23 Premier League sezonunda 36 gol attı.',
      'Salzburg ve Borussia Dortmund’da oynadı.',
      'Norveçli bir santrfor.'
    ]
  ),
  (
    name: 'Zinedine Zidane',
    article: 'Zinedine Zidane',
    clues: [
      '1998 Dünya Kupası finalinde iki kafa golü attı.',
      'Bordeaux ve Juventus’ta forma giydi.',
      '2002 Şampiyonlar Ligi finalindeki vole golünü attı.'
    ]
  ),
  (
    name: 'Didier Drogba',
    article: 'Didier Drogba',
    clues: [
      '2012 Şampiyonlar Ligi finalinde eşitliği getiren golü attı.',
      'Marsilya’dan Chelsea’ye transfer oldu.',
      'Galatasaray’da oynayan Fildişi Sahilli santrfor.'
    ]
  ),
  (
    name: 'Marta',
    article: 'Marta (footballer)',
    clues: [
      'Kadınlar Dünya Kupası’nda 17 gol attı.',
      'İsveç’te Umeå IK ve Rosengård forması giydi.',
      'Brezilyalı futbolcu altı kez FIFA’nın yılın en iyi kadın oyuncusu ödülünü aldı.'
    ]
  ),
  (
    name: 'Alexia Putellas',
    article: 'Alexia Putellas',
    clues: [
      '2021 ve 2022 Ballon d’Or Féminin ödüllerini kazandı.',
      'Barcelona’nın 2021 Şampiyonlar Ligi finalinde gol attı.',
      '2023 Dünya Kupası’nı kazanan İspanya kadrosundaydı.'
    ]
  ),
  (
    name: 'Andrés Iniesta',
    article: 'Andrés Iniesta',
    clues: [
      '2010 Dünya Kupası finalinin tek golünü attı.',
      'Barcelona’dan sonra Vissel Kobe’de oynadı.',
      'İspanyol orta saha La Masia’da yetişti.'
    ]
  ),
  (
    name: 'Samuel Eto’o',
    article: 'Samuel Eto\'o',
    clues: [
      'Barcelona ve Inter ile art arda üç kupa kazandı.',
      'Mallorca’da forma giydikten sonra Barcelona’ya geçti.',
      'Kamerun ile 2000 Olimpiyatları’nda altın madalya kazandı.'
    ]
  ),
];

const _clubs = <FootballEntry>[
  (
    name: 'Galatasaray',
    article: 'Galatasaray S.K. (football)',
    clues: [
      '2000 UEFA Kupası finalinde Arsenal’i penaltılarla geçti.',
      'Kurucularından biri Ali Sami Yen’di.',
      'İstanbul kulübünün renkleri sarı ve kırmızı.'
    ]
  ),
  (
    name: 'Fenerbahçe',
    article: 'Fenerbahçe S.K. (football)',
    clues: [
      '2012-13 UEFA Avrupa Ligi’nde yarı finale çıktı.',
      '1907’de kuruldu.',
      'İstanbul’un Kadıköy ilçesiyle özdeşleşen sarı-lacivertli kulüp.'
    ]
  ),
  (
    name: 'Beşiktaş',
    article: 'Beşiktaş J.K.',
    clues: [
      '2017-18 Şampiyonlar Ligi grubunu yenilgisiz lider bitirdi.',
      '1903’te kuruldu.',
      'Kara Kartal lakabıyla tanınır.'
    ]
  ),
  (
    name: 'Trabzonspor',
    article: 'Trabzonspor',
    clues: [
      '1975-76’da Türkiye’nin en üst ligini kazandı.',
      '1967’de kuruldu.',
      'Bordo-mavili kulübün şehri Trabzon.'
    ]
  ),
  (
    name: 'Barcelona',
    article: 'FC Barcelona',
    clues: [
      '2009’da takvim yılı içinde altı kupa kazandı.',
      'Altyapısı La Masia adıyla bilinir.',
      'Katalonya derbisinde Espanyol ile karşılaşır.'
    ]
  ),
  (
    name: 'Real Madrid',
    article: 'Real Madrid CF',
    clues: [
      'Avrupa Şampiyon Kulüpler Kupası’nın ilk beş sezonunu kazandı.',
      '2014 Şampiyonlar Ligi zaferi La Décima olarak anılır.',
      'Santiago Bernabéu’da oynar.'
    ]
  ),
  (
    name: 'Liverpool',
    article: 'Liverpool F.C.',
    clues: [
      '2005 Şampiyonlar Ligi finalinde 3-0 geriden geldi.',
      'Şehir derbisinde Everton ile karşılaşır.',
      'Anfield’da oynar.'
    ]
  ),
  (
    name: 'AC Milan',
    article: 'AC Milan',
    clues: [
      '1989 ve 1990 Avrupa Şampiyon Kulüpler Kupası’nı kazandı.',
      'Paolo Maldini kariyerini bu kulüpte geçirdi.',
      'Rossoneri lakabıyla bilinir.'
    ]
  ),
  (
    name: 'Ajax',
    article: 'AFC Ajax',
    clues: [
      '1995 Şampiyonlar Ligi finalinde Milan’ı 1-0 yendi.',
      'Johan Cruyff bu kulüpte yetişti.',
      'Amsterdam merkezli kulüp.'
    ]
  ),
  (
    name: 'Bayern Münih',
    article: 'FC Bayern Munich',
    clues: [
      '2020 Şampiyonlar Ligi finalinde Paris Saint-Germain’i yendi.',
      'Thomas Müller bu kulüpte yetişti.',
      'Allianz Arena’da oynar.'
    ]
  ),
  (
    name: 'Manchester City',
    article: 'Manchester City F.C.',
    clues: [
      '2023 Şampiyonlar Ligi finalini İstanbul’da kazandı.',
      '2011-12 lig şampiyonluğunu Agüero’nun son dakika golüyle aldı.',
      'Etihad Stadyumu’nda oynar.'
    ]
  ),
  (
    name: 'Borussia Dortmund',
    article: 'Borussia Dortmund',
    clues: [
      '1997 Şampiyonlar Ligi finalinde Juventus’u yendi.',
      'Taraftar tribünü Sarı Duvar adıyla bilinir.',
      'Almanya’da Ruhr derbisinde Schalke ile karşılaşır.'
    ]
  ),
];

class _FootballQuizScreenState extends State<FootballQuizScreen> {
  final _random = Random();
  final _descriptions = <String, String>{};
  late List<FootballEntry> _rounds;
  late List<FootballEntry> _options;
  int _index = 0;
  int _visible = 1;
  int _points = 0;
  FootballEntry? _choice;

  List<FootballEntry> get _bank =>
      widget.mode == FootballQuizMode.player ? _players : _clubs;
  FootballEntry get _answer => _rounds[_index];

  @override
  void initState() {
    super.initState();
    _restart();
    unawaited(_loadDescriptions());
  }

  void _restart() {
    final shuffled = _bank.toList()..shuffle(_random);
    _rounds = shuffled.take(6).toList();
    _index = 0;
    _points = 0;
    _setQuestion();
  }

  void _setQuestion() {
    final other = _bank.where((entry) => entry != _answer).toList()
      ..shuffle(_random);
    _options = [_answer, ...other.take(3)]..shuffle(_random);
    _choice = null;
    _visible = 1;
  }

  Future<void> _loadDescriptions() async {
    final client = http.Client();
    try {
      final uri = Uri.https('www.wikidata.org', '/w/api.php', {
        'action': 'wbgetentities',
        'sites': 'enwiki',
        'titles': _bank.map((entry) => entry.article).join('|'),
        'props': 'descriptions|sitelinks',
        'sitefilter': 'enwiki',
        'languages': 'tr',
        'format': 'json',
        'origin': '*',
      });
      final response = await client.get(uri, headers: const {
        'Api-User-Agent': 'AZOyun Football Quiz/1.0 (https://azoyun.web.app/)',
      }).timeout(const Duration(seconds: 5));
      if (!mounted || response.statusCode != 200) return;
      final raw =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final entities = raw['entities'];
      if (entities is! Map) return;
      final descriptions = <String, String>{};
      for (final entity in entities.values.whereType<Map>()) {
        final title = (entity['sitelinks'] as Map?)?['enwiki'];
        final summary = (entity['descriptions'] as Map?)?['tr'];
        if (title is Map &&
            title['title'] is String &&
            summary is Map &&
            summary['value'] is String) {
          descriptions[title['title'] as String] = summary['value'] as String;
        }
      }
      setState(() => _descriptions.addAll(descriptions));
    } catch (_) {
      // The bundled quiz runs without a network connection.
    } finally {
      client.close();
    }
  }

  void _guess(FootballEntry entry) => setState(() {
        _choice = entry;
        if (entry == _answer) _points += 4 - _visible;
      });

  @override
  Widget build(BuildContext context) {
    final last = _index + 1 == _rounds.length;
    final hint = _descriptions[_answer.article];
    final answered = _choice != null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.title)),
      body: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(padding: const EdgeInsets.all(22), children: [
          Text('Soru ${_index + 1}/${_rounds.length}  ·  $_points puan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: (_index + (answered ? 1 : 0)) / _rounds.length),
          const SizedBox(height: 24),
          for (final clue in _answer.clues.take(answered ? 3 : _visible))
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    Text(clue, style: Theme.of(context).textTheme.titleLarge)),
          if (!answered && _visible < 3)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _visible++),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Ek ipucu · Doğru cevap ${3 - _visible} puan'),
                )),
          const SizedBox(height: 14),
          for (final option in _options)
            Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: FilledButton.tonal(
                    onPressed: answered ? null : () => _guess(option),
                    child: Text(option.name))),
          if (answered) ...[
            const SizedBox(height: 16),
            Text(_choice == _answer ? 'Doğru!' : 'Doğru cevap: ${_answer.name}',
                style: Theme.of(context).textTheme.titleLarge),
            if (hint != null) Text('$hint · Wikidata'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(() {
                if (last) {
                  _restart();
                } else {
                  _index++;
                  _setQuestion();
                }
              }),
              child: Text(last ? '$_points puan · Yeni seri' : 'Sıradaki soru'),
            ),
          ],
        ]),
      )),
    );
  }
}
