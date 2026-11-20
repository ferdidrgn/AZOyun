import 'dart:math';

const penaltyZones = ['Sol üst', 'Sağ üst', 'Orta', 'Sol alt', 'Sağ alt'];
const penaltyTargets = [
  (x: .15, y: .27),
  (x: .85, y: .27),
  (x: .50, y: .56),
  (x: .15, y: .85),
  (x: .85, y: .85),
];

typedef PenaltyFlight = ({
  double x,
  double y,
  int dive,
  int curve,
  String result
});

int encodePenaltyKick(int target, int power, int curve) =>
    5 + (target * 101 + power) * 3 + curve + 1;

bool validPenaltyKick(int value) =>
    value >= 0 && value < 5 + penaltyZones.length * 101 * 3;

PenaltyFlight penaltyFlight(int? kick, int dive) {
  if (kick == null) {
    return (x: .5, y: .56, dive: dive, curve: 0, result: 'timeout');
  }
  final extended = kick >= 5;
  final packed = kick - 5;
  final target = penaltyTargets[extended ? packed ~/ (101 * 3) : kick];
  final power = extended ? packed ~/ 3 % 101 : 65;
  final curve = extended ? packed % 3 - 1 : 0;
  final x = target.x + curve * .18;
  final y = target.y + max(0, 45 - power) * .023 - max(0, power - 86) * .021;
  final hand = penaltyTargets[dive];
  final reach = .24 - max(0, power - 55) * .002;
  final distance = sqrt(pow(x - hand.x, 2) + pow((y - hand.y) * .8, 2));
  final result = x < 0 || x > 1 || y < 0 || y > 1 || power < 24
      ? 'miss'
      : distance <= reach
          ? 'save'
          : 'goal';
  return (x: x, y: y, dive: dive, curve: curve, result: result);
}
