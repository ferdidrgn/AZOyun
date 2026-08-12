import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'play_games_service.dart';

class LeaderboardEntry {
  final String name;
  final int score;
  final DateTime date;

  const LeaderboardEntry(
      {required this.name, required this.score, required this.date});

  Map<String, dynamic> toJson() =>
      {'name': name, 'score': score, 'date': date.toIso8601String()};

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      LeaderboardEntry(
        name: j['name'] as String,
        score: (j['score'] as num).toInt(),
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Skor tabanlı hızlı oyunlar (Yılan, 2048, Refleks) için yerel "en iyi 10"
/// listesi. Play Games bağlıysa aynı skor resmi buluta da gönderilir.
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  static const _maxEntries = 10;

  Future<List<LeaderboardEntry>> topScores(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('lb_$gameId') ?? [];
    final list = <LeaderboardEntry>[];
    for (final s in raw) {
      try {
        list.add(LeaderboardEntry.fromJson(
            jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // bozuk kayıt atlanır
      }
    }
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// Skoru kaydeder. Yeni bir kişisel/genel rekor olup olmadığını döner.
  Future<bool> submitScore({
    required String gameId,
    required String name,
    required int score,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await topScores(gameId);
    final wasTopBefore = list.isEmpty || score > list.first.score;

    list.add(LeaderboardEntry(name: name, score: score, date: DateTime.now()));
    list.sort((a, b) => b.score.compareTo(a.score));
    final trimmed = list.take(_maxEntries).toList();

    await prefs.setStringList(
      'lb_$gameId',
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );

    unawaited(PlayGamesService.instance.submitScore(gameId: gameId, score: score));
    return wasTopBefore;
  }
}

void unawaited(Future<void> future) {}
