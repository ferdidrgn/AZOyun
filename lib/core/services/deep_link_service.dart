import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../navigation/room_invite.dart';

typedef DeepLinkHandler = void Function(Uri uri);

/// Uygulama ve HTTPS oda davetlerini dinler.
///
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> initialize({required DeepLinkHandler onLink}) async {
    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      onLink,
      onError: (Object e) => debugPrint('[DeepLinkService] link akışı hatası: $e'),
    );
  }

  static String webInvite(String game, String code) =>
      Uri(
        scheme: 'https',
        host: 'azoyun.web.app',
        pathSegments: ['join', game, code.toUpperCase()],
      ).toString();

  static String appInvite(String game, String code) =>
      'azoyun://join/$game/${code.toUpperCase()}';

  static RoomInvite? parseJoinLink(Uri uri) => parseRoomInvite(uri);

  void dispose() => _sub?.cancel();
}
