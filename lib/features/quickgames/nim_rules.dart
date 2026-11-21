class NimMoveResult {
  const NimMoveResult({required this.piles, required this.finished});

  final List<int> piles;
  final bool finished;
}

NimMoveResult nimApplyMove(
  List<int> piles, {
  required int pileIndex,
  required int removeCount,
}) {
  if (piles.isEmpty || piles.any((size) => size < 0)) {
    throw ArgumentError.value(
        piles, 'piles', 'Pile sizes must be non-negative');
  }
  if (pileIndex < 0 || pileIndex >= piles.length) {
    throw RangeError.index(pileIndex, piles, 'pileIndex');
  }
  final size = piles[pileIndex];
  if (removeCount < 1 || removeCount > size) {
    throw ArgumentError.value(
      removeCount,
      'removeCount',
      'Remove between 1 and the pile size',
    );
  }

  final nextPiles = List<int>.of(piles)..[pileIndex] -= removeCount;
  return NimMoveResult(
    piles: nextPiles,
    finished: nextPiles.every((size) => size == 0),
  );
}

bool nimIsFinished(List<int> piles) =>
    piles.isNotEmpty && piles.every((size) => size == 0);
