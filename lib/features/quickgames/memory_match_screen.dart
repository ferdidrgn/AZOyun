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

class _MemoryCardFace extends StatelessWidget {
  const _MemoryCardFace({
    super.key,
    required this.label,
    required this.open,
    required this.matched,
  });

  final String label;
  final bool open;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final colors = matched
        ? const [Color(0xFFD9FFE8), Color(0xFFA7F2C2), Color(0xFF67D996)]
        : open
            ? const [Color(0xFFFFFFFF), Color(0xFFFFF4FC), Color(0xFFEBD8F8)]
            : const [Color(0xFFFF9CD7), Color(0xFFDC5AAF), Color(0xFF9C3288)];
    final edge = matched
        ? const Color(0xFF2D9F63)
        : open
            ? const Color(0xFFB184C9)
            : const Color(0xFF702469);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(AZRadius.md),
        border: Border.all(
          color: open || matched ? Colors.white : const Color(0xFFFFC6EA),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: edge.withAlpha(open ? 85 : 135),
            blurRadius: matched ? 10 : 7,
            spreadRadius: matched ? 1 : 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withAlpha(open || matched ? 150 : 80),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 3,
            left: 7,
            right: 7,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(0),
                    Colors.white.withAlpha(185),
                    Colors.white.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: open
                ? Text(
                    label,
                    style: TextStyle(
                      fontSize: 30,
                      color: matched ? const Color(0xFF157A47) : null,
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 1)),
                        Shadow(color: Color(0x559A689E), blurRadius: 3, offset: Offset(0, 3)),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 18, color: Colors.white.withAlpha(205)),
                      const SizedBox(height: 1),
                      const Text(
                        '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Color(0x995D1558), blurRadius: 4,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final turn = Tween<double>(begin: pi / 2, end: 0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      );
                      return AnimatedBuilder(
                        animation: turn,
                        child: child,
                        builder: (context, child) => Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .0018)
                            ..rotateY(turn.value),
                          child: child,
                        ),
                      );
                    },
                    child: _MemoryCardFace(
                      key: ValueKey(open),
                      label: open ? _cards[i] : '?',
                      open: open,
                      matched: _matched[i],
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
