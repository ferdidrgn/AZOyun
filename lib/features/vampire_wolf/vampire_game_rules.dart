/// Public, deterministic vote resolution used by the Vampire Village round flow.
/// A tied top score yields no elimination instead of depending on map order.
class VampireVoteTally {
  const VampireVoteTally({
    required this.counts,
    required this.maxVotes,
    required this.leaders,
  });

  final Map<String, int> counts;
  final int maxVotes;
  final List<String> leaders;

  bool get isTie => leaders.length > 1;
  String? get winnerKey => leaders.length == 1 ? leaders.single : null;

  factory VampireVoteTally.fromCounts(Map<String, int> rawCounts) {
    final counts = <String, int>{
      for (final entry in rawCounts.entries)
        if (entry.key.isNotEmpty && entry.value > 0) entry.key: entry.value,
    };
    final maxVotes = counts.values.fold<int>(0, (max, count) => count > max ? count : max);
    final leaders = <String>[];
    if (maxVotes > 0) {
      leaders.addAll(
        counts.entries
            .where((entry) => entry.value == maxVotes)
            .map((entry) => entry.key),
      );
      leaders.sort();
    }
    return VampireVoteTally(counts: counts, maxVotes: maxVotes, leaders: leaders);
  }
}
