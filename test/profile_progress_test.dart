import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/core/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('concurrent result retry grants the match and first badge once',
      () async {
    SharedPreferences.setMockInitialValues({
      'az_player_profile_v1': jsonEncode({'xp': 20, 'coins': 4}),
    });
    final service = ProfileService.instance;
    final results = await Future.wait([
      service.reportGameResult(gameId: 'deck', won: true, resultId: 'room-1'),
      service.reportGameResult(gameId: 'deck', won: true, resultId: 'room-1'),
    ]);

    expect(results.where((result) => result.granted), hasLength(1));
    expect(results.first.earnedXp, 5);
    expect(results.first.unlockedAchievements.single.id, 'first_step');
    expect(results.last.earnedXp, 0);
    expect(await service.reconcileAchievements(), isEmpty);
    expect(service.profile.gamesPlayed, 1);
    expect(service.profile.wins, 1);
    expect(service.profile.xp, 35);
    expect(service.profile.coins, 7);

    final prefs = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(prefs.getString('az_player_progress_guest_v2')!) as Map;
    expect(saved['profile']['unlockedAchievementIds'], contains('first_step'));
    expect(saved['results'], contains('deck:room-1'));
  });
}
