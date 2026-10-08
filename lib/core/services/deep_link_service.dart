import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

typedef DeepLinkHandler = void Function(Uri uri);

/// `azoyun://` özel şemasıyla gelen bağlantıları dinler.
///
/// Desteklenen biçim: `azoyun://join/<oyun>/<kod>` — ör.
/// `azoyun://join/vampire/AB12CD`. Şu an için tam otomatik oda-doldurma
/// yapmıyor (her oyunun kendi oda kodu alanına otomatik yazdırmak, 12 online
/// oyunun lobi ekranını da güncellemeyi gerektirir — bkz. ROADMAP 7.3);
/// bunun yerine kullanıcıyı uygulamaya yönlendirip kodu gösteren bir geri
/// bildirim üretir, dışarıdaki [onLink] bunu işler (ör. bir SnackBar/dialog
/// gösterip kullanıcıyı doğru lobiye yönlendirebilir).
///
/// ⚠️ Gerçek `https://azoyun.app/...` Universal/App Links için barındırılan
/// bir domain + doğrulama dosyası gerekir (bkz. ROADMAP 7.3). Bu, henüz bir
/// domain olmadığı için kapsam dışı; sadece `azoyun://` özel şeması aktif.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  DeepLinkHandler? _handler;

  Future<void> initialize({required DeepLinkHandler onLink}) async {
    _handler = onLink;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handler?.call(initial);
    } catch (e) {
      debugPrint('[DeepLinkService] ilk link okunamadı: $e');
    }
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handler?.call(uri),
      onError: (Object e) => debugPrint('[DeepLinkService] link akışı hatası: $e'),
    );
  }

  static String webInvite(String game, String code) =>
      'https://azoyun.web.app/?join=$game&code=${code.toUpperCase()}';

  static String appInvite(String game, String code) =>
      'azoyun://join/$game/${code.toUpperCase()}';

  /// `azoyun://join/<oyun>/<kod>`, `https://azoyun.web.app/join/<oyun>/<kod>`
  /// ve `?join=<oyun>&code=<kod>` bağlantılarını ayrıştırır.
  static ({String game, String code})? parseJoinLink(Uri uri) {
    final queryCode = uri.queryParameters['code'];
    final queryGame = uri.queryParameters['join'] ?? uri.queryParameters['game'];
    if (queryGame != null && queryGame.isNotEmpty && queryCode != null && queryCode.isNotEmpty) {
      return (game: queryGame, code: queryCode.toUpperCase());
    }
    if (uri.host == 'join' && uri.pathSegments.length >= 2) {
      return (game: uri.pathSegments[0], code: uri.pathSegments[1].toUpperCase());
    }
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    final joinAt = segments.indexOf('join');
    if (joinAt >= 0 && segments.length >= joinAt + 3) {
      return (game: segments[joinAt + 1], code: segments[joinAt + 2].toUpperCase());
    }
    return null;
  }

  void dispose() => _sub?.cancel();
}
