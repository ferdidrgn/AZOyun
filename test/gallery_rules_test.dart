import 'package:AZOyun/features/quickgames/carrom_screen.dart';
import 'package:AZOyun/features/quickgames/chess_rules.dart';
import 'package:AZOyun/features/quickgames/triple_match_screen.dart';
import 'package:AZOyun/features/quickgames/word_mania_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kelime işaretleri yeşil ve sarıyı ayırır', () {
    expect(wordMarks('KALEM', 'KALEM'), [2, 2, 2, 2, 2]);
    expect(wordMarks('ELMAS', 'KALEM'), [1, 1, 1, 1, 0]);
    expect(wordMarks('KEKME', 'KALEM'), [2, 1, 0, 1, 0]);
  });

  test('üç aynı taş tepside silinir', () {
    expect(clearTriples(['🍎', '🍋', '🍎', '🍎']), ['🍋']);
    expect(clearTriples(['🍎', '🍎']), ['🍎', '🍎']);
  });

  test('karambol cepleri köşededir', () {
    expect(carromNearPocket(0.08, 0.08), isTrue);
    expect(carromNearPocket(0.5, 0.5), isFalse);
  });

  test('satrançta e2-e4 yasal, şah tehdit altındaki kare değil', () {
    final start = ChessState.initial();
    final moves = chessLegalMoves(start);
    expect(moves.any((move) => move.$1 == 52 && move.$2 == 36), isTrue);
    expect(moves.any((move) => move.$1 == 52 && move.$2 == 44), isTrue);
    expect(moves.any((move) => move.$1 == 52 && move.$2 == 28), isFalse);

    final squares = List<String?>.filled(64, null);
    squares[0] = 'k';
    squares[4] = 'r';
    squares[60] = 'K';
    final threatened = ChessState(squares: squares, whiteTurn: true);
    final kingMoves = chessLegalMoves(threatened).where((move) => move.$1 == 60);
    expect(kingMoves.any((move) => move.$2 == 52), isFalse);
    expect(kingMoves.any((move) => move.$2 == 61), isTrue);
  });

  test('piyon son sırada vezir olur', () {
    final squares = List<String?>.filled(64, null);
    squares[8] = 'P';
    squares[63] = 'K';
    squares[0] = 'k';
    final state = ChessState(squares: squares, whiteTurn: true);
    final next = chessPlay(state, 8, 0);
    expect(next.squares[0], 'Q');
  });
}
