/// Career facts used by the chemistry XI and player-link puzzle modes.
class FootballCareerSpell {
  const FootballCareerSpell({
    required this.clubId,
    required this.clubName,
    this.startYear,
    this.endYear,
  });

  final String clubId;
  final String clubName;
  final int? startYear;
  final int? endYear;
}

class ChemistryPlayer {
  const ChemistryPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.careers,
    this.sportNationalityId,
  });

  final String id;
  final String name;
  final String position;
  final List<FootballCareerSpell> careers;
  final String? sportNationalityId;
}

class ClubChemistryCount {
  const ClubChemistryCount(
      {required this.clubId,
      required this.clubName,
      required this.playerCount});

  final String clubId;
  final String clubName;
  final int playerCount;
}

class ChemistryPair {
  const ChemistryPair({
    required this.firstPlayerId,
    required this.secondPlayerId,
    required this.sharedClubs,
    required this.points,
    required this.sharedNation,
  });

  final String firstPlayerId;
  final String secondPlayerId;
  final List<String> sharedClubs;
  final int points;
  final bool sharedNation;
}

class ChemistryReport {
  const ChemistryReport({
    required this.clubCounts,
    required this.pairs,
    required this.totalPoints,
  });

  final List<ClubChemistryCount> clubCounts;
  final List<ChemistryPair> pairs;
  final int totalPoints;
}

class FootballChemistryRules {
  const FootballChemistryRules._();

  /// Shared clubs create links; overlapping first-team years make each link
  /// stronger. Missing dates still count as a club connection, but do not get
  /// the overlap bonus. A shared Wikidata sports nationality is counted as
  /// one extra connection; it does not claim both players played for a team.
  static ChemistryReport calculate(Iterable<ChemistryPlayer> squad) {
    final players = squad.toList(growable: false);
    final clubPlayers = <String, Set<String>>{};
    final clubNames = <String, String>{};
    for (final player in players) {
      for (final club in player.careers.map((spell) => spell.clubId).toSet()) {
        clubPlayers.putIfAbsent(club, () => <String>{}).add(player.id);
      }
      for (final spell in player.careers) {
        clubNames[spell.clubId] = spell.clubName;
      }
    }

    final pairs = <ChemistryPair>[];
    for (var i = 0; i < players.length; i++) {
      for (var j = i + 1; j < players.length; j++) {
        final first = players[i];
        final second = players[j];
        final shared = first.careers
            .map((spell) => spell.clubId)
            .toSet()
            .intersection(second.careers.map((spell) => spell.clubId).toSet());
        final sameNation = first.sportNationalityId != null &&
            first.sportNationalityId == second.sportNationalityId;
        if (shared.isEmpty && !sameNation) continue;

        var points = sameNation ? 1 : 0;
        for (final clubId in shared) {
          points += _overlapBonus(
            first.careers.where((spell) => spell.clubId == clubId),
            second.careers.where((spell) => spell.clubId == clubId),
          );
        }
        pairs.add(ChemistryPair(
          firstPlayerId: first.id,
          secondPlayerId: second.id,
          sharedClubs: shared.toList()..sort(),
          points: points,
          sharedNation: sameNation,
        ));
      }
    }

    final counts = clubPlayers.entries
        .map((entry) => ClubChemistryCount(
              clubId: entry.key,
              clubName: clubNames[entry.key] ?? entry.key,
              playerCount: entry.value.length,
            ))
        .toList()
      ..sort((a, b) {
        final byCount = b.playerCount.compareTo(a.playerCount);
        return byCount != 0 ? byCount : a.clubId.compareTo(b.clubId);
      });
    pairs.sort((a, b) => b.points.compareTo(a.points));
    return ChemistryReport(
      clubCounts: counts,
      pairs: pairs,
      totalPoints: pairs.fold(0, (total, pair) => total + pair.points),
    );
  }

  static int _overlapBonus(
    Iterable<FootballCareerSpell> first,
    Iterable<FootballCareerSpell> second,
  ) {
    var overlap = false;
    for (final a in first) {
      for (final b in second) {
        if (a.startYear == null ||
            a.endYear == null ||
            b.startYear == null ||
            b.endYear == null) {
          continue;
        }
        if (a.startYear! <= b.endYear! && b.startYear! <= a.endYear!) {
          overlap = true;
        }
      }
    }
    return overlap ? 2 : 1;
  }
}
