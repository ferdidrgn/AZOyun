import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_keys.dart';

const _kChannelId = 'az_oyun_default_channel';
const _kChannelName = 'AZ Oyun Bildirimleri';
const _kChannelDesc = 'Sıra bilgisi, oda davetleri ve genel duyurular';

/// Arka planda (uygulama kapalı/arka planda) gelen FCM mesajları için giriş
/// noktası. Firebase, bu fonksiyonu izole bir Dart Isolate'te çalıştırır —
/// bu yüzden top-level (sınıf dışı) olmalı ve `@pragma('vm:entry-point')`
/// taşımalı. Uygulama arka plandayken/kapalıyken Android zaten otomatik
/// olarak sistem bildirimi gösteriyor — burada sadece log tutuluyor.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[NotificationService] arka plan mesajı: ${message.messageId}');
}

/// Bildirim izni + Firebase Cloud Messaging köprüsü.
///
/// ÖNEMLİ: Gerçek push bildirimi GÖNDERMEK (kampanya, hedefli mesaj) için
/// Firebase Console → Cloud Messaging kullanılır — bu, kod tarafında değil,
/// sunucu/console tarafında yapılan bir iştir. Bu servis ALICI (client)
/// tarafını hazırlar: izin ister, FCM token alır, gelen mesajları dinler —
/// VE uygulama ön plandayken (foreground) gelen mesajı gerçek bir sistem
/// bildirimi olarak gösterir. FCM'in kendisi bunu SADECE arka plan/kapalı
/// durumda otomatik yapar; ön plandayken hiçbir şey göstermez, o yüzden
/// `flutter_local_notifications` ile elle tetikliyoruz.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _token;

  String? get token => _token;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    try {
      _token = await _messaging.getToken();
      debugPrint('[NotificationService] FCM token: $_token');
    } catch (e) {
      debugPrint('[NotificationService] token alınamadı: $e');
    }

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[NotificationService] ön planda mesaj: ${message.notification?.title}');
      _showForegroundNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[NotificationService] bildirime tıklandı: ${message.data}');
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    try {
      await _localNotifications.initialize(initSettings);
      const channel = AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description: _kChannelDesc,
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('[NotificationService] yerel bildirim kurulamadı: $e');
    }
  }

  /// Uygulama açıkken gelen bir FCM mesajını, arka plandaymış gibi gerçek
  /// bir sistem bildirimi (heads-up) olarak gösterir — ayrıca oyun
  /// içindeyken kaçırmasın diye kısa bir uygulama-içi banner da gösterilir.
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId,
            _kChannelName,
            channelDescription: _kChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] bildirim gösterilemedi: $e');
    }

    final title = notification.title;
    final body = notification.body;
    final text = [title, body].where((s) => s != null && s.isNotEmpty).join(' — ');
    if (text.isEmpty) return;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 4)),
    );
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
