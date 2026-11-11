import 'package:flutter/material.dart';

import 'three_view_native.dart'
    if (dart.library.js_interop) 'three_view_web.dart';

enum ThreeArcadeGame {
  orbit('Yörünge Pilotu'),
  maze('Kristal Labirent');

  const ThreeArcadeGame(this.title);
  final String title;
}

class ThreeArcadeScreen extends StatelessWidget {
  const ThreeArcadeScreen({super.key, required this.game});

  final ThreeArcadeGame game;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF101923),
        appBar: AppBar(title: Text(game.title)),
        body: SafeArea(child: ThreeView(game: game.name, title: game.title)),
      );
}
