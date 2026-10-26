import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }
  }

  Future<bool> requestPermission() async {
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
    const androidDetails = AndroidNotificationDetails(
      'rise_reminders_channel',
      'RISE Reminders',
      channelDescription: 'Daily planning, focus sessions, and reflection reminders',
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
