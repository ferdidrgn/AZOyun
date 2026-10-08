import 'package:AZOyun/features/quickgames/kid_party_screens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kaşık yalnızca kasedeyken durur', () {
    expect(soupInBowl(0.66), isTrue);
    expect(soupInBowl(0.2), isFalse);
  });

  test('yaprak yuvada kalır, fazla üfleme kaçırır', () {
    expect(leafLanding(0.4), LeafLanding.early);
    expect(leafLanding(0.7), LeafLanding.landed);
    expect(leafLanding(0.9), LeafLanding.over);
  });

  test('hık yalnızca geniş halkada sayılır', () {
    expect(hiccupOnBeat(0.8), isTrue);
    expect(hiccupOnBeat(0.2), isFalse);
  });

  test('terlik eşinin üstüne oturur', () {
    expect(slipperSeated(10), isTrue);
    expect(slipperSeated(370), isTrue);
    expect(slipperSeated(90), isFalse);
  });
}
