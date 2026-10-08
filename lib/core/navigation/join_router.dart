import 'package:flutter/material.dart';

import '../../features/checkers/dama_screens.dart';
import '../../features/city/city_screens.dart';
import '../../features/deck/deck_lobby_screen.dart';
import '../../features/fighter/fighter_screens.dart';
import '../../features/golf/golf_lobby_screen.dart';
import '../../features/hangman/hangman_lobby_screen.dart';
import '../../features/impostor/impostor_screens.dart';
import '../../features/liar/liar_screens.dart';
import '../../features/okey/okey_screens.dart';
import '../../features/racing/racing_screens.dart';
import '../../features/soccer/soccer_lobby_screen.dart';
import '../../features/vampire_wolf/vampire_screens.dart';
import '../../features/word/word_screens.dart';
import '../services/app_keys.dart';

class PendingJoin extends ChangeNotifier {
  PendingJoin._();

  static final PendingJoin instance = PendingJoin._();

  ({String game, String code})? _invite;

  void offer(String game, String code) {
    _invite = (game: game, code: code.toUpperCase());
    notifyListeners();
  }

  ({String game, String code})? take() {
    final invite = _invite;
    _invite = null;
    return invite;
  }
}

void openGameInvite(BuildContext context, String game, String code) {
  final normalized = code.toUpperCase();
  final Widget? screen = switch (game) {
    'golf' => GolfLobbyScreen(initialCode: normalized),
    'soccer' => SoccerLobbyScreen(initialCode: normalized),
    'hangman' => HangmanLobbyScreen(initialCode: normalized),
    'city' => CityLobbyScreen(initialCode: normalized),
    'word' => WordLobbyScreen(initialCode: normalized),
    'vampire' => VampireLobbyScreen(initialCode: normalized),
    'liar' => LiarLobbyScreen(initialCode: normalized),
    'okey' => OkeyLobbyScreen(initialCode: normalized),
    'okey101' => OkeyLobbyScreen(mode: '101', initialCode: normalized),
    'fighter' => FighterLobbyScreen(initialCode: normalized),
    'racing' => RacingLobbyScreen(initialCode: normalized),
    'dama' => DamaLobbyScreen(initialCode: normalized),
    'impostor' => ImpostorLobbyScreen(initialCode: normalized),
    'deck' => DeckLobbyScreen(initialCode: normalized),
    _ => null,
  };
  if (screen == null) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Davet açılmadı: $game')),
    );
    return;
  }
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}
