import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/native_alarm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hive_flutter/hive_flutter.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];
  List<Task> _tasks = [];

  List<Habit> get habits => List.unmodifiable(_habits);
  List<Task> get tasks => List.unmodifiable(_tasks);

  HabitProvider() {
    _loadData();
  }

  int _claimedRankIndex = -1;
  int get claimedRankIndex => _claimedRankIndex;

  void _loadData() async {
    final habitBox = Hive.box<Habit>('habits');
    _habits = habitBox.values.toList();

    final taskBox = Hive.box<Task>('tasks');
    _tasks = taskBox.values.toList();

    final prefs = await SharedPreferences.getInstance();
    _claimedRankIndex = prefs.getInt('claimedRankIndex') ?? -1;

    notifyListeners();
  }

  // Check if user has a new rank to claim
  // Note: We need to define rank thresholds here or import them to check.
  // For simplicity, we can just expose a method that the UI calls to check,
  // or duplicate the threshold logic here.
  // To keep it clean, let's just expose the index and let UI decide,
  // OR better: Move the rank calculation here.
  // Let's use the UI's calculation for now to assume "currentRankIndex" is derived elsewhere,
  // but wait, the Home Screen needs to know if there is an unclaimed rank.
  // So we MUST implement the rank logic here.

  static const List<int> _rankThresholds = [
    3,
    7,
    14,
    21,
    30,
    50,
    75,
    100,
    150,
    200,
    300,
    365,
    500
  ];

  int get currentRankIndex {
    final days = totalActiveDays;
    int rankIndex = -1;
    for (int i = _rankThresholds.length - 1; i >= 0; i--) {
      if (days >= _rankThresholds[i]) {
        rankIndex = i;
        break;
      }
    }
    return rankIndex;
  }

  bool get hasUnclaimedRank => currentRankIndex > _claimedRankIndex;

  Future<void> claimRank() async {
    _claimedRankIndex = currentRankIndex;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('claimedRankIndex', _claimedRankIndex);
  }

  /// Reset all data (Danger Zone)
  Future<void> resetData() async {
    // Note: Cannot programmatically delete alarms from System Clock via Intent
    // Users must manage old alarms manually in the Clock app if they used system alarms previously.
    // For new AlarmService, we should try cancel all.
    // For new AlarmService, we should try cancel all.
    // For new AlarmService, we should try cancel all.
    await NativeAlarmService().stopAlarm();

    final habitBox = Hive.box<Habit>('habits');
    await habitBox.clear();
    _habits = [];

    final taskBox = Hive.box<Task>('tasks');
    await taskBox.clear();
    _tasks = [];

    // Cancel all notifications
    await NotificationService().cancelAll();

    notifyListeners();
  }

  // Get habits for today
  List<Habit> get todayHabits {
    final today = DateTime.now();
    return _habits.where((h) => h.isScheduledOn(today)).toList();
  }

  // Get completed habits for today
  List<Habit> get completedToday {
    final today = DateTime.now();
    return _habits.where((h) => h.isCompletedOn(today)).toList();
  }

  // Get pending habits for today
  List<Habit> get pendingToday {
    final today = DateTime.now();
    final list = _habits
        .where((h) => h.isScheduledOn(today) && !h.isCompletedOn(today))
        .toList();

    list.sort((a, b) {
      // Helper to get minutes from midnight
      int getMinutes(Habit h) {
        if (h.isAlarmEnabled && h.alarmTime != null) {
          return h.alarmTime!.hour * 60 + h.alarmTime!.minute;
        }
        if (h.isReminderOn && h.reminderTime != null) {
          return h.reminderTime!.hour * 60 + h.reminderTime!.minute;
        }
        return 24 * 60; // No time set -> push to end
      }

      int timeA = getMinutes(a);
      int timeB = getMinutes(b);

      if (timeA != timeB) return timeA.compareTo(timeB);
      return a.name.compareTo(b.name); // Fallback to name
    });

    return list;
  }

  // Get pending tasks
  List<Task> get pendingTasks {
    return _tasks.where((t) => !t.isCompleted).toList();
  }

  // Get tasks for today (includes past incomplete tasks - Rollover)
  List<Task> get tasksForToday {
    final today = DateTime.now();
    return _tasks.where((t) {
      if (t.isCompleted) {
        // If completed, only show if completed TODAY
        if (t.completedAt == null) return false;
        return t.completedAt!.year == today.year &&
            t.completedAt!.month == today.month &&
            t.completedAt!.day == today.day;
      } else {
        // If incomplete, show if deadline is Today OR Before Today (Rollover)
        if (t.deadline == null) {
          // No deadline tasks: decide if they should show up.
          // Assuming "created today" or just always show pending?
          // Let's stick to deadline based for now as per user context.
          // If no deadline, check creation date? Or just show them.
          // Let's assume tasks with no deadline are "anytime" so show them.
          return true;
        }
        final deadline = t.deadline!;
        // Check if deadline is today or in the past
        final isFuture = DateTime(deadline.year, deadline.month, deadline.day)
            .isAfter(DateTime(today.year, today.month, today.day));
        return !isFuture;
      }
    }).toList();
  }

  // Get completed tasks for today
  List<Task> get completedTasksToday {
    final today = DateTime.now();
    return _tasks
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.year == today.year &&
            t.completedAt!.month == today.month &&
            t.completedAt!.day == today.day)
        .toList();
  }

  // Total active days (days where ALL scheduled habits were completed)
  // Cache for totalActiveDays
  int? _cachedTotalActiveDays;

  // Total active days (days where ALL scheduled habits were completed)
  int get totalActiveDays {
    if (_cachedTotalActiveDays != null) return _cachedTotalActiveDays!;

    final completionCounts = <DateTime, int>{};
    final relevantDates = <DateTime>{};

    // Pre-calculate completion counts per date
    for (final habit in _habits) {
      for (final d in habit.completedDates) {
        final date = DateTime(d.year, d.month, d.day);
        completionCounts[date] = (completionCounts[date] ?? 0) + 1;
        relevantDates.add(date);
      }
    }

    int fullDaysCount = 0;

    for (final date in relevantDates) {
      int scheduledCount = 0;
      for (final habit in _habits) {
        if (habit.isScheduledOn(date)) {
          scheduledCount++;
        }
      }

      // If scheduled habits exist and all are completed
      if (scheduledCount > 0 &&
          (completionCounts[date] ?? 0) >= scheduledCount) {
        fullDaysCount++;
      }
    }

    _cachedTotalActiveDays = fullDaysCount;
    return fullDaysCount;
  }

  // Total streak count (sum of all habit streaks)
  int get totalStreaks {
    return _habits.fold(0, (sum, h) => sum + h.currentStreak);
  }

  // Get weekly completion data (for Daily Flow)
  Map<int, DayProgress> getWeeklyProgress() {
    final now = DateTime.now();
    // Get start of week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Reuse the generic range method
    return getProgressForRange(startOfWeek, endOfWeek);
  }

  // Get progress for a specific date range
  Map<int, DayProgress> getProgressForRange(DateTime start, DateTime end) {
    final Map<int, DayProgress> rangeProgress = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int daysCount = end.difference(start).inDays + 1;

    // PRE-CALCULATION SECTION (O(N) instead of O(N^2))

    // 1. Bucket Tasks by Date
    final Map<DateTime, List<Task>> tasksByDate = {};
    for (final task in _tasks) {
      final date = task.deadline ?? task.createdAt;
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (tasksByDate[normalizedDate] == null) {
        tasksByDate[normalizedDate] = [];
      }
      tasksByDate[normalizedDate]!.add(task);
    }

    // 2. Iterate Days
    for (int i = 0; i < daysCount; i++) {
      final day = start.add(Duration(days: i));
      final dayKey = i;
      final checkDate = DateTime(day.year, day.month, day.day);

      // Constants for this day
      int scheduledCount = 0;
      int completedCount = 0;

      // Single pass over habits for this day (habits are few, usually < 20)
      for (final h in _habits) {
        if (h.isScheduledOn(day)) {
          scheduledCount++;
          if (h.isCompletedOn(day)) {
            completedCount++;
          }
        }
      }

      // Lookup Tasks from Bucket (O(1))
      final dayTasks = tasksByDate[checkDate] ?? [];
      final totalTasks = dayTasks.length;
      final completedTasks = dayTasks.where((t) => t.isCompleted).length;

      rangeProgress[dayKey] = DayProgress(
        day: day.day,
        date: day,
        scheduled: scheduledCount,
        completed: completedCount,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        isToday: checkDate.isAtSameMomentAs(today),
        isPast: checkDate.isBefore(today),
      );
    }

    return rangeProgress;
  }

  void _invalidateCache() {
    _cachedTotalActiveDays = null;
  }

  // Add a new habit
  Future<void> addHabit(Habit habit) async {
    final box = Hive.box<Habit>('habits');
    box.put(habit.id, habit);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    if (habit.isReminderOn && habit.reminderTime != null) {
      DateTime scheduledTime = _getNextReminderTime(habit.reminderTime!);
      NativeAlarmService().scheduleTask(
        id: (habit.id + "_reminder").hashCode,
        time: scheduledTime,
        title: "Time for ${habit.name}!",
        body: "Don't break the chain! Complete your habit now.",
        isAlarm: false,
        audio:
            true, // Reminders always have sound if phone is not silent, handled by system notification usually.
        // But wait, our NativeAlarmService for reminders uses system notification which respects system settings.
        // The audio/vibrate flags are mainly for the ALARM service (full screen).
        // For 'isAlarm: false', these might be ignored by Android side logic if it just posts a notification.
        // Let's pass true/true effectively for reminders as they are standard notifications.
        vibrate: true,
      );
    }

    if (habit.isAlarmEnabled && habit.alarmTime != null) {
      DateTime scheduledTime = _getNextReminderTime(habit.alarmTime!);

      NativeAlarmService().scheduleTask(
        id: habit.id.hashCode,
        time: scheduledTime,
        title: "Time for ${habit.name}!",
        body: "Don't break the chain! Complete your habit now.",
        isAlarm: true,
        audio: habit.alarmMode == AlarmMode.ring,
        vibrate: habit.alarmMode == AlarmMode.ring ||
            habit.alarmMode == AlarmMode.vibrate,
      );
    }

    notifyListeners();
  }

  // Helper to ensure reminder time is in the future
  DateTime _getNextReminderTime(DateTime time) {
    final now = DateTime.now();
    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      if (now.difference(scheduled).inMinutes < 5) {
        debugPrint("Grace period used: Scheduling $scheduled for ASAP");
      } else {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    return scheduled;
  }

  // Update a habit
  Future<void> updateHabit(Habit habit) async {
    final box = Hive.box<Habit>('habits');
    box.put(habit.id, habit);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    NativeAlarmService().cancelTask((habit.id + "_reminder").hashCode);
    if (habit.isReminderOn && habit.reminderTime != null) {
      DateTime scheduledTime = _getNextReminderTime(habit.reminderTime!);
      NativeAlarmService().scheduleTask(
        id: (habit.id + "_reminder").hashCode,
        time: scheduledTime,
        title: "Time for ${habit.name}!",
        body: "Don't break the chain! Complete your habit now.",
        isAlarm: false,
        audio: true,
        vibrate: true,
      );
    }

    NativeAlarmService().cancelTask(habit.id.hashCode);
    if (habit.isAlarmEnabled && habit.alarmTime != null) {
      DateTime scheduledTime = _getNextReminderTime(habit.alarmTime!);
      NativeAlarmService().scheduleTask(
        id: habit.id.hashCode,
        time: scheduledTime,
        title: "Time for ${habit.name}!",
        body: "Don't break the chain! Complete your habit now.",
        isAlarm: true,
        audio: habit.alarmMode == AlarmMode.ring,
        vibrate: habit.alarmMode == AlarmMode.ring ||
            habit.alarmMode == AlarmMode.vibrate,
      );
    }

    notifyListeners();
  }

  Future<void> removeHabit(String id) async {
    final box = Hive.box<Habit>('habits');
    box.delete(id);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    NativeAlarmService().cancelTask((id + "_reminder").hashCode);
    NativeAlarmService().cancelTask(id.hashCode);

    notifyListeners();
  }

  // Toggle habit completion for a date
  Future<void> toggleHabitCompletion(String id, DateTime date) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final isCompleted = habit.isCompletedOn(date);

    List<DateTime> newCompletedDates;
    if (isCompleted) {
      newCompletedDates = habit.completedDates
          .where((d) => !(d.year == date.year &&
              d.month == date.month &&
              d.day == date.day))
          .toList();
    } else {
      newCompletedDates = [...habit.completedDates, date];
    }

    final updatedHabit = habit.copyWith(completedDates: newCompletedDates);

    final box = Hive.box<Habit>('habits');
    box.put(habit.id, updatedHabit);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();
    notifyListeners();
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    final box = Hive.box<Task>('tasks');
    box.put(task.id, task);
    await box.flush();
    _tasks = box.values.toList();

    if (task.isReminderOn && task.reminderTime != null) {
      if (task.reminderTime!.isAfter(DateTime.now())) {
        NativeAlarmService().scheduleTask(
          id: (task.id + "_reminder").hashCode,
          time: task.reminderTime!,
          title: "Reminder: ${task.name}",
          body: "You have a task scheduled for now.",
          isAlarm: false,
          audio: true,
          vibrate: true,
        );
      }
    }

    if (task.isAlarmEnabled && task.alarmTime != null) {
      if (task.alarmTime!.isAfter(DateTime.now())) {
        NativeAlarmService().scheduleTask(
          id: task.id.hashCode,
          time: task.alarmTime!,
          title: "Task: ${task.name}",
          body: "It's time to work on your task!",
          isAlarm: true,
          audio: task.alarmMode == AlarmMode.ring,
          vibrate: task.alarmMode == AlarmMode.ring ||
              task.alarmMode == AlarmMode.vibrate,
        );
      }
    }

    notifyListeners();
  }

  Future<void> removeTask(String id) async {
    final box = Hive.box<Task>('tasks');
    box.delete(id);
    await box.flush();
    _tasks = box.values.toList();

    NativeAlarmService().cancelTask((id + "_reminder").hashCode);
    NativeAlarmService().cancelTask(id.hashCode);

    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final box = Hive.box<Task>('tasks');
    box.put(task.id, task);
    await box.flush();
    _tasks = box.values.toList();

    NativeAlarmService().cancelTask((task.id + "_reminder").hashCode);
    if (task.isReminderOn && task.reminderTime != null) {
      if (task.reminderTime!.isAfter(DateTime.now())) {
        NativeAlarmService().scheduleTask(
          id: (task.id + "_reminder").hashCode,
          time: task.reminderTime!,
          title: "Reminder: ${task.name}",
          body: "You have a task scheduled for now.",
          isAlarm: false,
          audio: true,
          vibrate: true,
        );
      }
    }

    NativeAlarmService().cancelTask(task.id.hashCode);
    if (task.isAlarmEnabled && task.alarmTime != null) {
      if (task.alarmTime!.isAfter(DateTime.now())) {
        NativeAlarmService().scheduleTask(
          id: task.id.hashCode,
          time: task.alarmTime!,
          title: "Task: ${task.name}",
          body: "It's time to work on your task!",
          isAlarm: true,
          audio: task.alarmMode == AlarmMode.ring,
          vibrate: task.alarmMode == AlarmMode.ring ||
              task.alarmMode == AlarmMode.vibrate,
        );
      }
    }

    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String id, {DateTime? date}) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = _tasks[index];
    final now = DateTime.now();
    final completionDate = date ?? now;

    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? completionDate : null,
    );

    final box = Hive.box<Task>('tasks');
    box.put(task.id, updatedTask);
    await box.flush();
    _tasks = box.values.toList();
    notifyListeners();
  }

  // Get habit by id
  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check and request exact alarm permission
  Future<void> checkAndRequestAlarmPermission() async {
    final hasPermission =
        await NativeAlarmService().checkExactAlarmPermission();
    if (!hasPermission) {
      await NativeAlarmService().requestExactAlarmPermission();
    }
  }
}

class DayProgress {
  final int day;
  final DateTime date;
  final int scheduled;
  final int completed;
  final int totalTasks;
  final int completedTasks;
  final bool isToday;
  final bool isPast;

  DayProgress({
    required this.day,
    required this.date,
    required this.scheduled,
    required this.completed,
    this.totalTasks = 0,
    this.completedTasks = 0,
    required this.isToday,
    required this.isPast,
  });

  double get progress => scheduled > 0 ? completed / scheduled : 0;
  double get taskProgress => totalTasks > 0 ? completedTasks / totalTasks : 0;
}
