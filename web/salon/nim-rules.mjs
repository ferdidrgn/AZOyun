export function nimApplyMove(piles, pileIndex, removeCount) {
  if (!Array.isArray(piles) || piles.length === 0 ||
      piles.some((size) => !Number.isInteger(size) || size < 0)) {
    throw new TypeError("Nim piles must be non-negative integers.");
  }
  if (!Number.isInteger(pileIndex) || pileIndex < 0 || pileIndex >= piles.length) {
    throw new RangeError("Nim pile index is out of range.");
  }
  if (!Number.isInteger(removeCount) || removeCount < 1 || removeCount > piles[pileIndex]) {
    throw new RangeError("Remove between one and the pile size.");
  }
  const nextPiles = [...piles];
  nextPiles[pileIndex] -= removeCount;
  return {
    piles: nextPiles,
    finished: nextPiles.every((size) => size === 0),
  };
}

export function nimIsFinished(piles) {
  return Array.isArray(piles) && piles.length > 0 &&
    piles.every((size) => Number.isInteger(size) && size === 0);
}
