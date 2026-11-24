import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Locks shared-board games to landscape while their play surface is open.
class LandscapeTablePage extends StatefulWidget {
  const LandscapeTablePage({super.key, required this.child});

  final Widget child;

  @override
  State<LandscapeTablePage> createState() => _LandscapeTablePageState();
}

class _LandscapeTablePageState extends State<LandscapeTablePage> {
  @override
  void initState() {
    super.initState();
    _setLandscape();
  }

  Future<void> _setLandscape() async {
    try {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (error) {
      debugPrint('Masa yatay yönü ayarlanamadı: $error');
    }
  }

  @override
  void dispose() {
    _restorePortrait();
    super.dispose();
  }

  Future<void> _restorePortrait() async {
    try {
      await SystemChrome.setPreferredOrientations(
          const [DeviceOrientation.portraitUp]);
    } catch (error) {
      debugPrint('Masa sonrası dikey yön geri alınamadı: $error');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
