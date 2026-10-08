import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class WordManiaLobbyScreen extends StatelessWidget {
  const WordManiaLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Kelime Avı',
        emoji: '🔤',
        gradient: AZColors.gradGreen,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Beş harfli gizli kelimeyi altı denemede bul. '
            'Yeşil harf yerinde, sarı harf kelimede var.',
      );
}

const wordManiaSecrets = [
  'KALEM',
  'KİTAP',
  'DENİZ',
  'ELMAS',
  'ARABA',
  'BULUT',
  'ORMAN',
  'NEHİR',
  'PAZAR',
  'LİMON',
  'KİRAZ',
  'ÇANTA',
  'RADYO',
  'GÜNEŞ',
  'KÖPRÜ',
  'DÜNYA',
  'KÖPEK',
  'BALIK',
  'SERÇE',
  'SOKAK',
  'EKMEK',
  'ÇORBA',
  'LİMAN',
  'TAKSİ',
];

String turkishUpper(String value) =>
    value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

List<int> wordMarks(String guess, String secret) {
  final marks = List<int>.filled(5, 0);
  final left = <String, int>{};
  for (var i = 0; i < 5; i++) {
    if (guess[i] == secret[i]) {
      marks[i] = 2;
    } else {
      left[secret[i]] = (left[secret[i]] ?? 0) + 1;
    }
  }
  for (var i = 0; i < 5; i++) {
    if (marks[i] == 2) {
      continue;
    }
    final count = left[guess[i]] ?? 0;
    if (count > 0) {
      marks[i] = 1;
      left[guess[i]] = count - 1;
    }
  }
  return marks;
}

class WordManiaGameScreen extends StatelessWidget {
  const WordManiaGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'wordmania',
        gradient: AZColors.gradGreen,
        title: 'Kelime Avı',
        emoji: '🔤',
        formatScore: (score) => '$score puan',
        sessionBuilder: (context, player, onFinished) =>
            _WordSession(player: player, onFinished: onFinished),
      );
}

class _WordSession extends StatefulWidget {
  const _WordSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_WordSession> createState() => _WordSessionState();
}

class _WordSessionState extends State<_WordSession> {
  final _secret = wordManiaSecrets[Random().nextInt(wordManiaSecrets.length)];
  final _controller = TextEditingController();
  final _guesses = <String>[];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final guess = turkishUpper(_controller.text.trim());
    if (guess.length != 5) {
      setState(() => _error = 'Beş harf yaz');
      return;
    }
    _guesses.add(guess);
    _controller.clear();
    _error = null;
    if (guess == _secret || _guesses.length == 6) {
      final won = guess == _secret;
      final score = won ? (7 - _guesses.length) * 10 : 0;
      widget.onFinished(score);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AZFrostCard(
          child: Text(
            '${widget.player.name}  ${_guesses.length}/6',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AZSpacing.md),
        for (final guess in _guesses) _GuessRow(guess: guess, secret: _secret),
        const Spacer(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AZSpacing.sm),
            child: Text(_error!, style: const TextStyle(color: Colors.white)),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: 5,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(5)],
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Kelime',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AZSpacing.sm),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AZColors.greenDk,
                ),
                child: const Text('Dene'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GuessRow extends StatelessWidget {
  const _GuessRow({required this.guess, required this.secret});

  final String guess;
  final String secret;

  @override
  Widget build(BuildContext context) {
    final marks = wordMarks(guess, secret);
    return Padding(
      padding: const EdgeInsets.only(bottom: AZSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < 5; i++)
            Expanded(
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                color: marks[i] == 2
                    ? AZColors.green
                    : marks[i] == 1
                        ? AZColors.orange
                        : AZColors.surfaceDark,
                child: Text(
                  guess[i],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
