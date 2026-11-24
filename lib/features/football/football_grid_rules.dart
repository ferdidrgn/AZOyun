/// Pure rules for category-intersection football grids (Box2Box style).
/// Data is supplied by the versioned catalogue; rules contain no player bank.
class FootballGridCriterion {
  const FootballGridCriterion({
    required this.id,
    required this.label,
    required this.tag,
  });

  final String id;
  final String label;
  final String tag;
}

class FootballGridPlayer {
  const FootballGridPlayer({
    required this.id,
    required this.name,
    required this.tags,
  });

  final String id;
  final String name;

  /// Criterion tags such as `club:juventus`, `country:argentina` or
  /// `competition:uefa-champions-league`.
  final Set<String> tags;
}

class FootballGridRules {
  const FootballGridRules._();

  static bool accepts({
    required FootballGridPlayer player,
    required FootballGridCriterion row,
    required FootballGridCriterion column,
  }) =>
      player.tags.contains(row.tag) && player.tags.contains(column.tag);

  static List<FootballGridPlayer> candidates({
    required Iterable<FootballGridPlayer> players,
    required FootballGridCriterion row,
    required FootballGridCriterion column,
  }) =>
      players
          .where((p) => accepts(player: p, row: row, column: column))
          .toList(growable: false);

  static int filledBoxes(Iterable<Set<String>> boxes) =>
      boxes.where((players) => players.isNotEmpty).length;
}
