import 'package:shared_preferences/shared_preferences.dart';

/// Dedektif kampanyalarında doğru çıkarımla kapanan bölümleri saklar.
class MysteryCampaignService {
  MysteryCampaignService._();
  static final MysteryCampaignService instance = MysteryCampaignService._();

  static const _key = 'az_mystery_completed_cases_v1';

  Set<String> _completed = {};
  bool _loaded = false;
  Future<void> _pendingWrite = Future.value();

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _completed = (prefs.getStringList(_key) ?? []).toSet();
    _loaded = true;
  }

  bool isCompleted(String caseId) => _completed.contains(caseId);

  Future<bool> markCompleted(String caseId) {
    final write = _pendingWrite.then((_) async {
      await load();
      if (_completed.contains(caseId)) return false;
      final completed = {..._completed, caseId};
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(_key, completed.toList())) {
        throw StateError('Bölüm ilerlemesi kaydedilemedi.');
      }
      _completed = completed;
      return true;
    });
    _pendingWrite = write.then<void>((_) {}, onError: (Object _) {});
    return write;
  }
}
