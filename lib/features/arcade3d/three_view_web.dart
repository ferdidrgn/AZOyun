import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class ThreeView extends StatelessWidget {
  const ThreeView({super.key, required this.game, required this.title});

  final String game;
  final String title;

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: (element) {
          final frame = element as web.HTMLIFrameElement;
          frame.title = title;
          frame.style.border = '0';
          frame.style.width = '100%';
          frame.style.height = '100%';
          frame.src = 'assets/assets/arcade3d/index.html?game=$game';
        },
      );
}
