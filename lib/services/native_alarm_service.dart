import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class NativeAlarmService {
  static final NativeAlarmService _instance = NativeAlarmService._internal();
  final MethodChannel _channel = const MethodChannel('com.habit.app/alarm');

  final StreamController<Map<String, dynamic>> _alarmUpdateController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get alarmUpdateStream =>
      _alarmUpdateController.stream;

  factory NativeAlarmService() => _instance;
  NativeAlarmService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == "onAlarmUpdate") {
      final args = Map<String, dynamic>.from(call.arguments);
      _alarmUpdateController.add(args);
    }
  }

  /// Schedules an exact task (Alarm or Reminder).
  /// [isAlarm] true for High-Priority Alarm, false for Gentle Reminder.
  Future<void> scheduleTask({
    required int id,
    required DateTime time,
    required String title,
    required String body,
    required bool isAlarm,
    required bool audio,
    required bool vibrate,
    String frequency = 'once', // 'once' or 'daily'
  }) async {
    try {
      await _channel.invokeMethod('scheduleTask', {
        'id': id,
        'timeMs': time.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'isAlarm': isAlarm,
        'audio': audio,
        'vibrate': vibrate,
        'frequency': frequency,
      });
      debugPrint(
          '[NativeAlarmService] Scheduled task $id at $time (Alarm: $isAlarm)');
    } catch (e) {
      debugPrint('[NativeAlarmService] Failed to schedule task: $e');
    }
  }

  /// Cancels a pending task by ID.
  Future<void> cancelTask(int id) async {
    try {
      await _channel.invokeMethod('cancelTask', {'id': id});
      debugPrint('[NativeAlarmService] Canceled task $id');
    } catch (e) {
      debugPrint('[NativeAlarmService] Failed to cancel task: $e');
    }
  }

  /// Stops the currently ringing alarm service.
  Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
      debugPrint('[NativeAlarmService] Stopped alarm service');
    } catch (e) {
      debugPrint('[NativeAlarmService] Failed to stop alarm: $e');
    }
  }

  /// Checks if "Exact Alarm" permission is granted (Android 12+).
  Future<bool> checkExactAlarmPermission() async {
    try {
      final bool granted =
          await _channel.invokeMethod('checkExactAlarmPermission') ?? true;
      return granted;
    } catch (e) {
      return true; // Default to true if not on Android 12+ or error
    }
  }

  /// Requests the user to grant "Can Schedule Exact Alarms" permission.
  Future<void> requestExactAlarmPermission() async {
    try {
      await _channel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      debugPrint('[NativeAlarmService] Failed to request permission: $e');
    }
  }
}
