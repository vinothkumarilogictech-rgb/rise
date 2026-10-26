import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isLocalInitialized = false;
  bool _isFcmInitialized = false;
  String? _currentFcmToken;

  String? get currentFcmToken => _currentFcmToken;

  /// Initializes local notifications plugin
  Future<void> initialize() async {
    if (_isLocalInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      _isLocalInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }
  }

  /// Safely initializes Firebase and FCM token registration with backend.
  /// If Firebase credentials/config files are not yet generated, fails gracefully.
  Future<void> initFcm({required ApiClient apiClient}) async {
    if (_isFcmInitialized) return;

    try {
      // Check if FirebaseCore is available
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase has not been initialized with platform options. Skipping FCM token retrieval.');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      // 1. Request remote notification permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM permission authorization status: ${settings.authorizationStatus}');

      // 2. Obtain registration token
      _currentFcmToken = await messaging.getToken();
      if (_currentFcmToken != null && _currentFcmToken!.isNotEmpty) {
        debugPrint('FCM registration token acquired: ${_currentFcmToken!.substring(0, 12)}...');
        
        // 3. Register token with RISE FastAPI backend
        await _registerTokenWithBackend(apiClient, _currentFcmToken!);

        // 4. Listen for token refreshes
        messaging.onTokenRefresh.listen((newToken) {
          _currentFcmToken = newToken;
          _registerTokenWithBackend(apiClient, newToken);
        });

        // 5. Handle foreground push delivery with local notification banner
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showInstantReminder(
              title: notification.title ?? 'RISE Reminder',
              body: notification.body ?? 'You have a scheduled study session starting soon.',
            );
          }
        });

        _isFcmInitialized = true;
      }
    } catch (e) {
      debugPrint('Firebase Cloud Messaging init notice: $e');
    }
  }

  Future<void> _registerTokenWithBackend(ApiClient apiClient, String token) async {
    try {
      String platform = 'android';
      if (kIsWeb) {
        platform = 'web';
      } else {
        try {
          if (Platform.isIOS) platform = 'ios';
        } catch (_) {}
      }

      await apiClient.post('/notifications/fcm-token', body: {
        'token': token,
        'platform': platform,
        'device_info': kIsWeb ? 'Flutter Web Browser' : 'Android Device',
      });
      debugPrint('Successfully registered FCM token with RISE backend.');
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
    }
  }

  Future<void> deactivateCurrentToken({required ApiClient apiClient}) async {
    if (_currentFcmToken == null) return;
    try {
      await apiClient.delete('/notifications/fcm-token');
      _currentFcmToken = null;
      _isFcmInitialized = false;
    } catch (_) {}
  }

  Future<bool> requestPermission() async {
    await initialize();
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
    return false;
  }

  Future<void> showInstantReminder({
    required String title,
    required String body,
  }) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'rise_study_reminders',
      'RISE Study Reminders',
      channelDescription: 'Upcoming timetable sessions, AI daily study plans, and focus nudges',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }
}
