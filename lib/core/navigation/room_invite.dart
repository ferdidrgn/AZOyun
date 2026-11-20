typedef RoomInvite = ({String game, String code});

const _onlineGames = {
  'golf',
  'soccer',
  'hangman',
  'city',
  'mahalle',
  'batak',
  'word',
  'vampire',
  'liar',
  'okey',
  'okey101',
  'fighter',
  'racing',
  'dama',
  'impostor',
  'deck',
  'family',
  'sonkart',
  'istasyon90',
  'penaltiduello',
};

final _roomCode = RegExp(r'^[A-Z0-9]{6}$');

RoomInvite? parseRoomInvite(Uri uri) {
  if (uri.userInfo.isNotEmpty) return null;
  final segments = uri.pathSegments;
  if (uri.scheme == 'azoyun' && uri.host == 'join' && segments.length == 2) {
    return _invite(segments[0], segments[1]);
  }
  if (!uri.hasAuthority || !{'http', 'https'}.contains(uri.scheme)) return null;

  // Aile Masası can be served on a different host. The app uses its own
  // configured server, so scanning a link never changes the API endpoint.
  final query = uri.queryParameters;
  if (uri.path.isEmpty || uri.path == '/') {
    final family = query['family'];
    if (family != null) return _invite('family', family);
  }
  if (uri.scheme != 'https' || uri.host != 'azoyun.web.app') return null;
  if (segments.length == 3 && segments.first == 'join') {
    return _invite(segments[1], segments[2]);
  }
  if (uri.path.isEmpty || uri.path == '/' || uri.path == '/join/') {
    return _invite(query['join'] ?? query['game'], query['code']);
  }
  return null;
}

RoomInvite? _invite(String? game, String? rawCode) {
  final code = rawCode?.toUpperCase();
  if (game == null ||
      !_onlineGames.contains(game) ||
      code == null ||
      !_roomCode.hasMatch(code)) {
    return null;
  }
  return (game: game, code: code);
}
