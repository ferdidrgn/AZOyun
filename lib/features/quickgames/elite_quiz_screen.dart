import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class EliteQuizLobbyScreen extends StatelessWidget {
  const EliteQuizLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Quiz Eliti',
        emoji: '🎯',
        gradient: AZColors.gradOrange,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Altı soru. Doğru cevap 10 puan. '
            'Bir kez yarı yarıya, bir kez pas kullanabilirsin.',
      );
}

class _Q {
  const _Q(this.category, this.prompt, this.options, this.answer);
  final String category;
  final String prompt;
  final List<String> options;
  final int answer;
}

const _bank = [
  _Q('Bilim', 'Işığı prizmada ayıran bilim insanı kimdir?', ['Newton', 'Edison', 'Tesla', 'Faraday'], 0),
  _Q('Tarih', 'İstanbul\'un fethi hangi yıldır?', ['1071', '1453', '1923', '1299'], 1),
  _Q('Coğrafya', 'Nil nehri hangi kıtadadır?', ['Asya', 'Avrupa', 'Afrika', 'Amerika'], 2),
  _Q('Spor', 'Teniste bir set en az kaç oyunla alınır?', ['4', '5', '6', '7'], 2),
  _Q('Sanat', 'Hamam tablosuyla bilinen Türk ressam kimdir?', ['Abidin Dino', 'Osman Hamdi', 'İbrahim Çallı', 'Nuri İyem'], 1),
  _Q('Doğa', 'Bir arı kolonisinin başındaki dişi hangisidir?', ['İşçi', 'Kraliçe', 'Erkek', 'Larva'], 1),
  _Q('Matematik', 'Bir düzine kaç tanedir?', ['6', '10', '12', '20'], 2),
  _Q('Müzik', 'Piyanonun beyaz tuşları hangi diziyi çalar?', ['Majör', 'Minör', 'Blues', 'Pentatonik'], 0),
  _Q('Uzay', 'Güneş sistemindeki en sıcak gezegen hangisidir?', ['Merkür', 'Venüs', 'Mars', 'Jüpiter'], 1),
  _Q('Dil', 'Türkçede kaç ünlü harf vardır?', ['6', '7', '8', '9'], 2),
];

class EliteQuizGameScreen extends StatelessWidget {
  const EliteQuizGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'elitequiz',
        gradient: AZColors.gradOrange,
        title: 'Quiz Eliti',
        emoji: '🎯',
        sessionBuilder: (context, player, onFinished) =>
            _EliteSession(player: player, onFinished: onFinished),
      );
}

class _EliteSession extends StatefulWidget {
  const _EliteSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_EliteSession> createState() => _EliteSessionState();
}

class _EliteSessionState extends State<_EliteSession> {
  late final List<_Q> _round = (List<_Q>.of(_bank)..shuffle()).take(6).toList();
  final Set<int> _hidden = {};
  int _index = 0;
  int _score = 0;
  bool _fifty = true;
  bool _skip = true;
  bool _locked = false;

  void _answer(int option) {
    if (_locked || _hidden.contains(option)) {
      return;
    }
    _locked = true;
    if (option == _round[_index].answer) {
      _score += 10;
    }
    _advance();
  }

  void _useFifty() {
    if (!_fifty || _locked) {
      return;
    }
    _fifty = false;
    final wrong = <int>[
      for (var i = 0; i < 4; i++)
        if (i != _round[_index].answer) i,
    ]..shuffle(Random());
    setState(() {
      _hidden.add(wrong[0]);
      _hidden.add(wrong[1]);
    });
  }

  void _useSkip() {
    if (!_skip || _locked) {
      return;
    }
    _skip = false;
    _locked = true;
    _advance();
  }

  void _advance() {
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) {
        return;
      }
      if (_index == _round.length - 1) {
        widget.onFinished(_score);
        return;
      }
      setState(() {
        _index++;
        _hidden.clear();
        _locked = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _round[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  ${_index + 1}/6  $_score puan',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        Text(question.category, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: AZSpacing.sm),
        Text(
          question.prompt,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AZSpacing.md),
        for (var i = 0; i < 4; i++)
          if (!_hidden.contains(i))
            Padding(
              padding: const EdgeInsets.only(bottom: AZSpacing.sm),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => _answer(i),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AZColors.textPrimary,
                  ),
                  child: Text(question.options[i]),
                ),
              ),
            ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _fifty ? _useFifty : null,
                  child: const Text('Yarı yarıya'),
                ),
              ),
            ),
            const SizedBox(width: AZSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _skip ? _useSkip : null,
                  child: const Text('Pas'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
