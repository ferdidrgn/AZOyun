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

  /// `azoyun://join/<oyun>/<kod>` bağlantısını ayrıştırır.
  /// Eşleşmezse `null` döner.
  static ({String game, String code})? parseJoinLink(Uri uri) {
    if (uri.host != 'join' && !(uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'join')) {
      return null;
    }
    final segments = uri.host == 'join'
        ? uri.pathSegments
        : uri.pathSegments.skip(1).toList();
    if (segments.length < 2) return null;
    return (game: segments[0], code: segments[1].toUpperCase());
  }

  void dispose() => _sub?.cancel();
}
