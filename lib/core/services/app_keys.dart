import 'package:flutter/material.dart';

/// Uygulama genelinde context'e ihtiyaç duymadan (ör. FCM arka plan geri
/// bildirimi, deep link yönlendirmesi, bildirim banner'ı) navigasyon/
/// snackbar yapabilmek için. `main.dart` ve `notification_service.dart`
/// gibi birbirini içe aktarmaması gereken dosyaların ortak bağımlılığı
/// olsun diye ayrı bir dosyada tutuluyor (döngüsel import'u önler).
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
