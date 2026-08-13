import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Arka planda (uygulama kapalı/arka planda) gelen FCM mesajları için giriş
/// noktası. Firebase, bu fonksiyonu izole bir Dart Isolate'te çalıştırır —
/// bu yüzden top-level (sınıf dışı) olmalı ve `@pragma('vm:entry-point')`
/// taşımalı.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[NotificationService] arka plan mesajı: ${message.messageId}');
}

/// Bildirim izni + Firebase Cloud Messaging köprüsü.
///
/// ÖNEMLİ: Gerçek push bildirimi GÖNDERMEK (kampanya, hedefli mesaj) için
/// Firebase Console → Cloud Messaging kullanılır — bu, kod tarafında değil,
/// sunucu/console tarafında yapılan bir iştir. Bu servis sadece ALICI
/// (client) tarafını hazırlar: izin ister, FCM token alır, gelen mesajları
/// dinler.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _token;

  String? get token => _token;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _token = await _messaging.getToken();
      debugPrint('[NotificationService] FCM token: $_token');
    } catch (e) {
      debugPrint('[NotificationService] token alınamadı: $e');
    }

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[NotificationService] ön planda mesaj: ${message.notification?.title}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[NotificationService] bildirime tıklandı: ${message.data}');
    });
  }

  /// Bildirim izni ister (Android 13+ / iOS). Kullanıcının verdiği kararı
  /// döner.
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('[NotificationService] izin istenemedi: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }

  /// Sistem bildirim ayarları ekranını açar (kullanıcı izni sonradan
  /// değiştirmek isterse).
  Future<void> openSystemSettings() => openAppSettings();
}
