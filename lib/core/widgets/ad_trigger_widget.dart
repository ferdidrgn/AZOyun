import 'package:flutter/material.dart';
import '../services/ad_manager.dart';
import '../services/secure_local_storage.dart';

/// 🎯 Oyun girişinde premium reklam kontrolü yapan görünmez widget
class AdTriggerWidget extends StatefulWidget {
  final String roomId;

  const AdTriggerWidget({super.key, required this.roomId});

  @override
  State<AdTriggerWidget> createState() => _AdTriggerWidgetState();
}

class _AdTriggerWidgetState extends State<AdTriggerWidget> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _handleAdLogic();
  }

  Future<void> _handleAdLogic() async {
    if (_handled) return;
    _handled = true;

    final storage = SecureLocalStorage();
    final adManager = AdManager();

    // AdManager hazır değilse çık
    if (!adManager.isInitialized || !adManager.areAdsEnabled) return;

    await storage.incrementGameEnterCount();
    final count = await storage.getGameEnterCount();

    await adManager.showPremiumAdIfNeeded(
      gameEnterCount: count,
      roomId: widget.roomId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Görünmez, sadece side-effect
    return const SizedBox.shrink();
  }
}
