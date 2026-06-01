import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // Set default location to Vietnam
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      debugPrint('Could not set local location to Asia/Ho_Chi_Minh: $e');
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Create a high importance channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'parking_reminders',
      'Parking Reminders',
      description: 'Notifications for parking updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions for Android 13+
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      // Only available on Android 12+ (API 31+)
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Exact alarm permission request failed (likely on older Android): $e');
      }
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'parking_reminders',
          'Parking Reminders',
          channelDescription: 'Notifications for parking updates',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
    );
  }

  Future<void> scheduleBookingReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // If the reminder time is in the past, or too close (within 10 seconds), don't schedule
    if (scheduledDate.isBefore(DateTime.now().add(const Duration(seconds: 10)))) {
      return;
    }

    try {
      final vietnam = tz.getLocation('Asia/Ho_Chi_Minh');
      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, vietnam);

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTZDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'parking_reminders',
            'Parking Reminders',
            channelDescription: 'Notifications for parking booking updates',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Notification scheduling failed: $e');
      // Final fallback to immediate if scheduling fails for some reason
    }
  }

  Future<void> showOngoingBookingTimer({
    required int id,
    required String title,
    required String body,
    required DateTime endTime,
  }) async {
    final now = DateTime.now();
    if (endTime.isBefore(now)) return;

    final androidDetails = AndroidNotificationDetails(
      'parking_active_session',
      'Active Parking Session',
      channelDescription: 'Ongoing notification for your active parking',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      usesChronometer: true,
      chronometerCountDown: true,
      when: endTime.millisecondsSinceEpoch,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
      icon: '@mipmap/ic_launcher',
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<int> pendingCount() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.length;
  }
}
