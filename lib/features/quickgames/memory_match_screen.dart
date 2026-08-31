import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class MemoryMatchLobbyScreen extends StatelessWidget {
  const MemoryMatchLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Hafıza Kartları',
        emoji: '🧠',
        gradient: AZColors.gradPink,
        minPlayers: 2,
        maxPlayers: 6,
        instructions:
            'Sırayla iki kart aç. Eşleşirse çift senin olur ve devam edersin, '
            'eşleşmezse sıra rakibe geçer. En çok çifti bulan kazanır!',
      );
}

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  static const _emojiPool = [
    '🍎', '🍌', '🍇', '🍉', '🍓', '🍒', '🥝', '🍍', '🥥', '🍑', '🍋', '🍐'
  ];
  static const _pairCount = 8;

  late List<String> _cards;
  late List<bool> _matched;
  late List<int> _scores;
  List<int> _flipped = [];
  bool _locked = false;
  int _turn = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final chosen = (_emojiPool.toList()..shuffle()).take(_pairCount).toList();
    final deck = [...chosen, ...chosen]..shuffle();
    setState(() {
      _cards = deck;
      _matched = List.filled(deck.length, false);
      _scores = List.filled(widget.players.length, 0);
      _flipped = [];
      _locked = false;
      _turn = 0;
    });
  }

  void _tap(int i) {
    if (_locked || _matched[i] || _flipped.contains(i)) return;
    setState(() => _flipped = [..._flipped, i]);
    if (_flipped.length < 2) return;

    _locked = true;
    final a = _flipped[0], b = _flipped[1];
    final isMatch = _cards[a] == _cards[b];

    Future.delayed(Duration(milliseconds: isMatch ? 450 : 900), () {
      if (!mounted) return;
      setState(() {
        if (isMatch) {
          _matched[a] = true;
          _matched[b] = true;
          _scores[_turn]++;
        } else {
          _turn = (_turn + 1) % widget.players.length;
        }
        _flipped = [];
        _locked = false;
      });
      if (_matched.every((m) => m)) _finish();
    });
  }

  Future<void> _finish() async {
    final maxScore = _scores.reduce(max);
    final winnerIdxs = [
      for (var i = 0; i < _scores.length; i++)
        if (_scores[i] == maxScore) i
    ];
    final draw = winnerIdxs.length != 1;
    final winner = draw ? null : widget.players[winnerIdxs.first];
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'memory',
      resultTitle: draw ? 'Berabere! 🤝' : '${winner!.name} kazandı! 🎉',
      resultMessage: draw
          ? 'Birden fazla oyuncu eşit sayıda çift buldu.'
          : '${winner!.name} $maxScore çift buldu!',
      humanWon: !draw,
      onRematch: _reset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradPink,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'Hafıza Kartları'),
          const SizedBox(height: 12),
          QPTurnBadgeRow(
            players: widget.players,
            scores: _scores,
            turn: _turn,
            activeTextColor: AZColors.purple,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemBuilder: (_, i) {
                final open = _matched[i] || _flipped.contains(i);
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _matched[i]
                          ? AZColors.success.withAlpha(90)
                          : (open ? Colors.white : const Color(0x26FFFFFF)),
                      borderRadius: BorderRadius.circular(AZRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        open ? _cards[i] : '❔',
                        style: TextStyle(
                            fontSize: open ? 30 : 24,
                            color: open ? null : Colors.white38),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
