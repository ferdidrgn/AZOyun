import 'package:shared_preferences/shared_preferences.dart';

/// Dedektif kampanyasında (Gece Ekspresi Cinayeti ve devamı) hangi vakaların
/// tamamlandığını kalıcı olarak saklar. Bir vaka tamamlanınca (suçlama
/// yapılıp sonuç ekranı gösterilince — doğru ya da yanlış fark etmez, çünkü
/// gerçek hayatta da yanlış tahmin "vakayı çözmemiş" olsa da soruşturmayı
/// bitirmiş olursun) bir sonraki vaka açılır.
class MysteryCampaignService {
  MysteryCampaignService._();
  static final MysteryCampaignService instance = MysteryCampaignService._();

  static const _key = 'az_mystery_completed_cases_v1';

  Set<String> _completed = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _completed = (prefs.getStringList(_key) ?? []).toSet();
    _loaded = true;
  }

  bool isCompleted(String caseId) => _completed.contains(caseId);

  Future<void> markCompleted(String caseId) async {
    await load();
    if (_completed.contains(caseId)) return;
    _completed = {..._completed, caseId};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _completed.toList());
  }
}
