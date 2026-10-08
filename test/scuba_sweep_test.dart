import 'package:AZOyun/features/quickgames/scuba_sweep_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dalgıç yakınındaki plastik çarpışır', () {
    expect(scubaOverlap(0.5, 0.74, 0.52, 0.75, 0.07), isTrue);
    expect(scubaOverlap(0.5, 0.74, 0.9, 0.1, 0.07), isFalse);
  });
}
