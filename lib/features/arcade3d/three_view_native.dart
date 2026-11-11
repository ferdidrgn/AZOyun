import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ThreeView extends StatefulWidget {
  const ThreeView({super.key, required this.game, required this.title});

  final String game;
  final String title;

  @override
  State<ThreeView> createState() => _ThreeViewState();
}

class _ThreeViewState extends State<ThreeView> with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _failed = false;

  bool get _supported => switch (defaultTargetPlatform) {
        TargetPlatform.android || TargetPlatform.iOS => true,
        _ => false,
      };

  @override
  void initState() {
    super.initState();
    if (_supported) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    if (_supported) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0xFF101923));
      await controller.setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          return uri?.scheme == 'file' &&
                  uri!.path.endsWith('/arcade3d/index.html')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
        onPageFinished: (_) async {
          if (!mounted) return;
          try {
            await controller.runJavaScript('initialize("${widget.game}")');
          } catch (error) {
            _showFailure(error);
          }
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame != false) _showFailure(error.description);
        },
      ));
      await controller.loadFlutterAsset('assets/arcade3d/index.html');
      if (mounted) setState(() => _controller = controller);
    } catch (error) {
      _showFailure(error);
    }
  }

  void _showFailure(Object error) {
    debugPrint('3D arcade yükleme: $error');
    if (mounted) setState(() => _failed = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state != AppLifecycleState.resumed && controller != null) {
      unawaited(controller
          .runJavaScript('if (typeof pause === "function") pause();')
          .catchError(
              (Object error) => debugPrint('3D arcade duraklatma: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported || _failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _supported
                ? '${widget.title} açılamadı. Ekranı kapatıp yeniden aç.'
                : '${widget.title} Android, iOS ve tarayıcıda oynanabilir.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final controller = _controller;
    return controller == null
        ? const Center(child: CircularProgressIndicator())
        : WebViewWidget(controller: controller);
  }
}
