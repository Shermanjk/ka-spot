import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'kaspot_service.dart';

/// Top-level handler required by Firebase for messages received while
/// the app is fully terminated or in the background.
/// Must be a top-level (non-class) function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this runs, but we call
  // ensureInitialized defensively in case the isolate is fresh.
  await Firebase.initializeApp();
  // flutter_local_notifications handles display on Android automatically
  // when the app is in background/terminated via the high-priority channel,
  // so no extra work is needed here.
  debugPrint('[FCM background] ${message.notification?.title}: ${message.notification?.body}');
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'kaspot_messages';
  static const _channelName = 'Circle Messages';
  static const _channelDesc = 'Notifications for new messages from your circle';

  /// Initialise Firebase, request permission, configure local notification
  /// channel, and register the device token with Supabase.
  static Future<void> initialize() async {
    // 1. Register the top-level background message handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 2. Create the Android notification channel (required on Android 8+).
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 3. Initialise flutter_local_notifications for foreground display.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
    );

    // 4. Ask Android 13+ for notification permission.
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 5. Show foreground messages as local notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 6. Register (or refresh) the FCM token with Supabase.
    await _registerToken();

    // Re-register whenever FCM rotates the token.
    messaging.onTokenRefresh.listen((newToken) {
      unawaited(KaSpotService.registerFcmToken(newToken));
    });
  }

  static Future<void> _registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await KaSpotService.registerFcmToken(token);
        debugPrint('[FCM] Token registered.');
      }
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }
}
