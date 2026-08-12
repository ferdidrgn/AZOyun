import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class TriviaLobbyScreen extends StatelessWidget {
  const TriviaLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Kim Bilir?',
        emoji: '🧠❓',
        gradient: AZColors.gradCyan,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Cihazı sırayla birbirinize verin. Her oyuncuya 5 soru sorulur, '
            'doğru cevap 20 puan kazandırır. En yüksek puan kazanır!',
      );
}

class TriviaQuestion {
  const TriviaQuestion(this.q, this.options, this.correctIndex);
  final String q;
  final List<String> options;
  final int correctIndex;
}

const _kQuestions = [
  TriviaQuestion('Türkiye\'nin başkenti neresidir?', ['İstanbul', 'Ankara', 'İzmir', 'Bursa'], 1),
  TriviaQuestion('En büyük gezegen hangisidir?', ['Dünya', 'Mars', 'Jüpiter', 'Satürn'], 2),
  TriviaQuestion('Bir futbol takımı sahada kaç kişidir?', ['9', '10', '11', '12'], 2),
  TriviaQuestion('İnsan vücudundaki en büyük organ hangisidir?', ['Karaciğer', 'Deri', 'Akciğer', 'Kalp'], 1),
  TriviaQuestion('Dünyanın en uzun nehri hangisidir?', ['Amazon', 'Nil', 'Tuna', 'Ganj'], 1),
  TriviaQuestion('Bir üçgenin iç açıları toplamı kaç derecedir?', ['90', '180', '270', '360'], 1),
  TriviaQuestion('Mona Lisa tablosunu kim yapmıştır?', ['Picasso', 'Van Gogh', 'Leonardo da Vinci', 'Michelangelo'], 2),
  TriviaQuestion('Suyun kimyasal formülü nedir?', ['CO2', 'H2O', 'O2', 'NaCl'], 1),
  TriviaQuestion('Türkiye kaç ilden oluşur?', ['71', '81', '91', '61'], 1),
  TriviaQuestion('En hızlı kara hayvanı hangisidir?', ['Aslan', 'Çita', 'At', 'Antilop'], 1),
  TriviaQuestion('Bir olimpiyat kaç yılda bir düzenlenir?', ['2', '3', '4', '5'], 2),
  TriviaQuestion('Piramitler hangi ülkededir?', ['Meksika', 'Mısır', 'Peru', 'Yunanistan'], 1),
  TriviaQuestion('İnsan kaç kromozom çiftine sahiptir?', ['21', '23', '25', '46'], 1),
  TriviaQuestion('Dünyanın en büyük okyanusu hangisidir?', ['Atlas', 'Hint', 'Pasifik', 'Arktik'], 2),
  TriviaQuestion('Bir basketbol maçında bir takım sahada kaç kişidir?', ['4', '5', '6', '7'], 1),
  TriviaQuestion('Ay Dünya etrafında yaklaşık kaç günde döner?', ['7', '14', '27-28', '60'], 2),
  TriviaQuestion('İlk insanlı ay inişi hangi yıl gerçekleşti?', ['1959', '1965', '1969', '1972'], 2),
  TriviaQuestion('Kaç kıta vardır?', ['5', '6', '7', '8'], 2),
  TriviaQuestion('Bal arıları hangi böcek takımına aittir?', ['Kelebek', 'Zar kanatlılar', 'Böcek', 'Örümcek'], 1),
  TriviaQuestion('Bir yılda kaç mevsim vardır?', ['2', '3', '4', '5'], 2),
  TriviaQuestion('Dünyanın en yüksek dağı hangisidir?', ['K2', 'Everest', 'Kilimanjaro', 'Elbrus'], 1),
  TriviaQuestion('Satrançta kaç taş vardır (bir oyuncu için)?', ['12', '14', '16', '18'], 2),
  TriviaQuestion('Bir haftada kaç gün vardır?', ['5', '6', '7', '8'], 2),
  TriviaQuestion('İstanbul Boğazı hangi iki denizi birbirine bağlar?', ['Ege-Akdeniz', 'Karadeniz-Marmara', 'Marmara-Ege', 'Karadeniz-Akdeniz'], 1),
  TriviaQuestion('Bir insanın kalbi kaç odacıklıdır?', ['2', '3', '4', '5'], 2),
  TriviaQuestion('Dünyanın en küçük ülkesi hangisidir?', ['Monako', 'Vatikan', 'San Marino', 'Malta'], 1),
  TriviaQuestion('Ses en hızlı hangi ortamda yayılır?', ['Havada', 'Suda', 'Katılarda', 'Boşlukta'], 2),
  TriviaQuestion('Bir metre kaç santimetredir?', ['10', '100', '1000', '10000'], 1),
  TriviaQuestion('Türkiye\'nin en büyük gölü hangisidir?', ['Tuz Gölü', 'Van Gölü', 'Beyşehir Gölü', 'Eğirdir Gölü'], 1),
  TriviaQuestion('Voleybolda bir takım sahada kaç kişidir?', ['5', '6', '7', '8'], 1),
];

class TriviaGameScreen extends StatelessWidget {
  const TriviaGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'trivia',
        gradient: AZColors.gradCyan,
        title: 'Kim Bilir?',
        emoji: '🧠',
        handoffHint: 'Diğer oyuncular bakmasın, kendi bilgin ile cevapla!',
        sessionBuilder: (context, player, onFinished) =>
            _TriviaSession(player: player, onFinished: onFinished),
      );
}

class _TriviaSession extends StatefulWidget {
  const _TriviaSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_TriviaSession> createState() => _TriviaSessionState();
}

class _TriviaSessionState extends State<_TriviaSession> {
  static const _questionsPerSession = 5;

  late final List<TriviaQuestion> _questions;
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    final pool = List<TriviaQuestion>.of(_kQuestions)..shuffle();
    _questions = pool.take(_questionsPerSession).toList();
  }

  void _select(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (i == _questions[_index].correctIndex) _score += 20;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_index < _questions.length - 1) {
        setState(() {
          _index++;
          _selected = null;
          _answered = false;
        });
      } else {
        widget.onFinished(_score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    return Column(children: [
      AZFrostCard(
        child: Text(
            '${widget.player.name} · Soru ${_index + 1}/${_questions.length} · $_score puan',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 20),
      AZFrostCard(
        opacity: 0.12,
        child: Text(q.q,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 20),
      Expanded(
        child: ListView.separated(
          itemCount: q.options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            Color? bg;
            if (_answered) {
              if (i == q.correctIndex) {
                bg = AZColors.success;
              } else if (i == _selected) {
                bg = AZColors.error;
              }
            }
            return GestureDetector(
              onTap: () => _select(i),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg ?? const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(AZRadius.md),
                ),
                child: Text(q.options[i],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
