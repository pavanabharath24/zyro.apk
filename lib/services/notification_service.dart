import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

// Top-level function for handling notification responses in background/terminated state
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint(
      '[NotificationService] Background response: actionId=${response.actionId}');
  // Notification is auto-canceled when STOP is pressed (cancelNotification: true)
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final dynamic timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      debugPrint('[NotificationService] Timezone Init Error: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    // Create Notification Channels
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // 1. Reminder Channel (Standard)
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_reminders',
          'Habit Reminders',
          description: 'Standard reminders for habits',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );

      // 2. Alarm Channel (High Priority with ALARM sound)
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_alarms',
          'Habit Alarms',
          description: 'Alarm notifications for habits',
          importance: Importance.max,
          playSound: true, // Play the default alarm sound
          enableVibration: true,
          sound:
              RawResourceAndroidNotificationSound('alarm'), // Uses system alarm
        ),
      );
    }

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  @pragma('vm:entry-point')
  static void onNotificationResponse(NotificationResponse response) {
    debugPrint(
        '[NotificationService] Response: actionId=${response.actionId}, payload=${response.payload}');

    // STOP action - notification auto-cancels (cancelNotification: true)
    if (response.actionId == 'STOP_ACTION') {
      debugPrint('[NotificationService] STOP_ACTION pressed');
      return;
    }

    if (response.payload == 'ALARM_SCREEN') {
      selectNotificationStream.add(response.payload);
    }
  }

  Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // --- STANDARD REMINDER (Notification + Vibrate) ---
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? overrideId,
  }) async {
    // Skip if in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('[NotificationService] Skipped reminder - time in past');
      return;
    }

    final int reminderId = overrideId ?? (id + 100000);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      reminderId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Standard reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint(
        '[NotificationService] Scheduled Reminder $reminderId for $scheduledDate');
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await scheduleReminder(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );

    // Optional: Early reminder
    final earlyDate = scheduledDate.subtract(const Duration(minutes: 10));
    if (earlyDate.isAfter(DateTime.now())) {
      await scheduleReminder(
        id: id,
        title: "Upcoming: $title",
        body: "$body (in 10 mins)",
        scheduledDate: earlyDate,
        overrideId: id + 200000,
      );
    }
  }

  Future<void> showInstantNotification() async {
    await flutterLocalNotificationsPlugin.show(
      888888,
      'Test Reminder',
      'This is a test reminder.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  // --- ALARM NOTIFICATION (High Priority with sound) ---
  Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_alarms',
          'Habit Alarms',
          channelDescription: 'Alarm notifications',
          importance: Importance.max,
          priority: Priority.max,
          // NO fullScreenIntent - prevents app from auto-opening
          fullScreenIntent: false,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ongoing: false, // Can be dismissed
          autoCancel: true, // Auto dismiss when tapped
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'STOP_ACTION',
              'Dismiss',
              showsUserInterface: false,
              cancelNotification:
                  true, // This dismisses notification and stops sound
            ),
          ],
        ),
      ),
      payload: 'ALARM_NOTIFICATION',
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelReminder(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id + 100000);
    await flutterLocalNotificationsPlugin.cancel(id + 200000);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
