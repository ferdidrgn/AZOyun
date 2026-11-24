import 'package:flutter/material.dart';

import 'three_view_native.dart'
    if (dart.library.js_interop) 'three_view_web.dart';
import 'native_arcade_screen.dart';
import 'native_ferry_screen.dart';

enum ThreeArcadeGame {
  runway('Neon Pist', 'runway'),
  drones('Sinyal Avı', 'drones'),
  orbit('Yörünge Pilotu', 'orbit'),
  maze('Kristal Labirent', 'maze'),
  bowling('3D Mini Bowling', 'bowling'),
  freeKick('Frikik Ustası', 'freeKick'),
  penalty('Penaltı Antrenmanı', 'penalty'),
  ferry('Vapur 84', 'ferry', file: 'vapur-84.html');

  const ThreeArcadeGame(this.title, this.engineMode,
      {this.file = 'index.html'});
  final String file;
  final String title;

  /// Stable mode key shared with the web arcade catalog and Three.js runtime.
  final String engineMode;
}

class ThreeArcadeScreen extends StatelessWidget {
  const ThreeArcadeScreen({super.key, required this.game});

  final ThreeArcadeGame game;

  @override
  Widget build(BuildContext context) {
    // These two arcade games already have a Flutter renderer and touch input.
    // Keep them fully native instead of sending Android players through a page.
    if (game == ThreeArcadeGame.runway) {
      return const NativeArcadeScreen(game: NativeArcadeGame.runway);
    }
    if (game == ThreeArcadeGame.drones) {
      return const NativeArcadeScreen(game: NativeArcadeGame.drones);
    }
    if (game == ThreeArcadeGame.ferry) return const NativeFerryScreen();
    return Scaffold(
        backgroundColor: const Color(0xFF101923),
        appBar: AppBar(title: Text(game.title)),
        body: SafeArea(
          child: ThreeView(
              game: game.engineMode, title: game.title, file: game.file),
        ));
  }
}
