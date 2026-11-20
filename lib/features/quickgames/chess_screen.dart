import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'chess_rules.dart';

class ChessLobbyScreen extends StatelessWidget {
  const ChessLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Satranç',
        emoji: '♟️',
        gradient: AZColors.gradPurple,
        minPlayers: 2,
        maxPlayers: 2,
        instructions:
            'Beyaz alttan başlar. Kendi taşını seç, yasal kareye dokun. '
            'Şah mat eden kazanır. Piyon son sırada vezir olur.',
      );
}

class ChessGameScreen extends StatefulWidget {
  const ChessGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  ChessState _state = ChessState.initial();
  List<(int, int)> _moves = chessLegalMoves(ChessState.initial());
  int? _selected;
  bool _done = false;

  static final _glyph = {
    'K': String.fromCharCode(0x2654),
    'Q': String.fromCharCode(0x2655),
    'R': String.fromCharCode(0x2656),
    'B': String.fromCharCode(0x2657),
    'N': String.fromCharCode(0x2658),
    'P': String.fromCharCode(0x2659),
    'k': String.fromCharCode(0x265A),
    'q': String.fromCharCode(0x265B),
    'r': String.fromCharCode(0x265C),
    'b': String.fromCharCode(0x265D),
    'n': String.fromCharCode(0x265E),
    'p': String.fromCharCode(0x265F),
  };

  void _refresh(ChessState next) {
    _state = next;
    _moves = chessLegalMoves(next);
    _selected = null;
  }

  Future<void> _tap(int index) async {
    if (_done) {
      return;
    }
    final piece = _state.squares[index];
    final mine = piece != null && chessIsWhite(piece) == _state.whiteTurn;
    if (_selected != null && _moves.any((move) => move.$1 == _selected && move.$2 == index)) {
      final next = chessPlay(_state, _selected!, index);
      setState(() => _refresh(next));
      final end = chessEnd(next);
      if (end != ChessEnd.playing) {
        _done = true;
        final draw = end == ChessEnd.stalemate;
        final winner = draw ? null : widget.players[next.whiteTurn ? 1 : 0];
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) {
          return;
        }
        await QuickPlayResult.show(
          context,
          gameId: 'chess',
          resultTitle: draw ? 'Berabere' : '${winner!.name} mat etti',
          resultMessage: draw ? 'Yasal hamle kalmadı.' : '${winner!.name} şah mat yaptı.',
          humanWon: winner != null && !winner.isAI,
          onRematch: () => setState(() {
            _done = false;
            _refresh(ChessState.initial());
          }),
        );
      }
      return;
    }
    if (mine) {
      setState(() => _selected = index);
    } else {
      setState(() => _selected = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final end = _done ? chessEnd(_state) : ChessEnd.playing;
    final check = chessInCheck(_state, _state.whiteTurn);
    final turnName = widget.players[_state.whiteTurn ? 0 : 1].name;
    final status = end == ChessEnd.checkmate
        ? 'Şah mat'
        : end == ChessEnd.stalemate
            ? 'Berabere'
            : check
                ? '$turnName şah çekiyor'
                : '$turnName sırası';
    return AZGradientScaffold(
      gradient: AZColors.gradPurple,
      child: Padding(
        padding: const EdgeInsets.all(AZSpacing.md),
        child: Column(
          children: [
            const QuickPlayTopBar(title: 'Satranç'),
            const SizedBox(height: AZSpacing.md),
            AZFrostCard(
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AZSpacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  return Center(
                    child: Container(
                      width: side,
                      height: side,
                      padding: EdgeInsets.all(side * .023),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFB9844B),
                            Color(0xFF704322),
                            Color(0xFF3D2619),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(side * .035),
                        border: Border.all(color: const Color(0xFFD9AD75), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 20,
                            offset: Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Color(0x44FFE0AF),
                            blurRadius: 8,
                            offset: Offset(-3, -3),
                          ),
                        ],
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF242019),
                          borderRadius: BorderRadius.circular(side * .018),
                          border: Border.all(color: const Color(0x88351F11), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(side * .014),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                            ),
                            itemCount: 64,
                            itemBuilder: (context, index) {
                              final light = (chessFile(index) + chessRank(index)).isEven;
                              final piece = _state.squares[index];
                              final whitePiece = piece != null && chessIsWhite(piece);
                              final selected = index == _selected;
                              final target = _selected != null &&
                                  _moves.any((move) => move.$1 == _selected && move.$2 == index);
                              return GestureDetector(
                                onTap: () => _tap(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: light
                                          ? const [Color(0xFFEAD7B2), Color(0xFFC8A875)]
                                          : const [Color(0xFF44735F), Color(0xFF244B3B)],
                                    ),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFFFD263)
                                          : target
                                              ? const Color(0xFF83E2B7)
                                              : Colors.black.withAlpha(25),
                                      width: selected || target ? 2 : .55,
                                    ),
                                    boxShadow: [
                                      if (selected)
                                        const BoxShadow(
                                          color: Color(0x88FFCA50),
                                          blurRadius: 10,
                                          spreadRadius: -2,
                                        ),
                                    ],
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (target && piece == null)
                                        Center(
                                          child: Container(
                                            width: side * .025,
                                            height: side * .025,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF155B42).withAlpha(180),
                                              shape: BoxShape.circle,
                                              boxShadow: const [
                                                BoxShadow(color: Color(0x77000000), blurRadius: 4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (piece != null)
                                        Center(
                                          child: _ChessPiece(
                                            glyph: _glyph[piece]!,
                                            white: whitePiece,
                                            size: side / 9.8,
                                          ),
                                        ),
                                      if (chessFile(index) == 0 || chessRank(index) == 0)
                                        Positioned(
                                          left: 2,
                                          bottom: 1,
                                          child: Text(
                                            chessFile(index) == 0
                                                ? '${8 - chessRank(index)}'
                                                : String.fromCharCode(97 + chessFile(index)),
                                            style: TextStyle(
                                              color: (light ? const Color(0xFF365443) : Colors.white)
                                                  .withAlpha(145),
                                              fontSize: side / 82,
                                              fontWeight: FontWeight.w800,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChessPiece extends StatelessWidget {
  const _ChessPiece({
    required this.glyph,
    required this.white,
    required this.size,
  });

  final String glyph;
  final bool white;
  final double size;

  @override
  Widget build(BuildContext context) {
    final face = white ? const Color(0xFFFFF4D9) : const Color(0xFF222A2B);
    final edge = white ? const Color(0xFFB68139) : const Color(0xFF070D10);
    final baseStart = white ? const Color(0xFFF4D59C) : const Color(0xFF596466);
    final baseEnd = white ? const Color(0xFF9B682F) : const Color(0xFF182124);

    return SizedBox(
      width: size * 1.15,
      height: size * 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * .04,
            left: size * .14,
            right: size * .14,
            child: Container(
              height: size * .22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [baseStart, baseEnd],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(size * .35, size * .12),
                  bottom: Radius.elliptical(size * .4, size * .15),
                ),
                border: Border.all(color: edge.withAlpha(180), width: .8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(130),
                    blurRadius: size * .11,
                    offset: Offset(0, size * .08),
                  ),
                  BoxShadow(
                    color: (white ? Colors.white : const Color(0xFF9EB5B4))
                        .withAlpha(90),
                    blurRadius: size * .06,
                    offset: Offset(-size * .035, -size * .035),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size * .11,
            child: Text(
              glyph,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: size * .92,
                height: 1,
                fontWeight: FontWeight.w700,
                color: face,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(190),
                    blurRadius: size * .09,
                    offset: Offset(size * .035, size * .07),
                  ),
                  Shadow(
                    color: edge.withAlpha(210),
                    blurRadius: size * .025,
                    offset: Offset(0, size * .025),
                  ),
                  Shadow(
                    color: (white ? Colors.white : const Color(0xFFBBC8C7))
                        .withAlpha(110),
                    blurRadius: size * .035,
                    offset: Offset(-size * .025, -size * .035),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
