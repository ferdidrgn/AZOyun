import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/theme/felt.dart';
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

  static const _glyph = {
    'K': '♔',
    'Q': '♕',
    'R': '♖',
    'B': '♗',
    'N': '♘',
    'P': '♙',
    'k': '♚',
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
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
                    child: SizedBox(
                      width: side,
                      height: side,
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
                          final target = _selected != null &&
                              _moves.any((move) => move.$1 == _selected && move.$2 == index);
                          return GestureDetector(
                            onTap: () => _tap(index),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: light ? FeltColors.ivory : FeltColors.felt,
                                border: Border.all(
                                  color: index == _selected
                                      ? FeltColors.brass
                                      : target
                                          ? FeltColors.clay
                                          : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  piece == null ? '' : _glyph[piece]!,
                                  style: TextStyle(
                                    fontSize: side / 12,
                                    color: whitePiece
                                        ? FeltColors.brass
                                        : (light ? FeltColors.ink : FeltColors.ivory),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
