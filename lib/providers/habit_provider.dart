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

  Future<void> resetData() async {
    await NativeAlarmService().stopAlarm();

    final habitBox = Hive.box<Habit>('habits');
    await habitBox.clear();
    _habits = [];

    final taskBox = Hive.box<Task>('tasks');
    await taskBox.clear();
    _tasks = [];

    await NotificationService().cancelAll();

    notifyListeners();
  }

  List<Habit> get todayHabits {
    final today = DateTime.now();
    return _habits.where((h) => h.isScheduledOn(today)).toList();
  }

  List<Habit> get completedToday {
    final today = DateTime.now();
    return _habits.where((h) => h.isCompletedOn(today)).toList();
  }

  List<Habit> get pendingToday {
    final today = DateTime.now();
    final list = _habits
        .where((h) => h.isScheduledOn(today) && !h.isCompletedOn(today))
        .toList();

    list.sort((a, b) {
      int getMinutes(Habit h) {
        if (h.isAlarmEnabled && h.alarmTime != null) {
          return h.alarmTime!.hour * 60 + h.alarmTime!.minute;
        }
        if (h.isReminderOn && h.reminderTime != null) {
          return h.reminderTime!.hour * 60 + h.reminderTime!.minute;
        }
        return 24 * 60;
      }

      int timeA = getMinutes(a);
      int timeB = getMinutes(b);
      if (timeA != timeB) return timeA.compareTo(timeB);
      return a.name.compareTo(b.name);
    });

    return list;
  }

  List<Task> get pendingTasks {
    return _tasks.where((t) => !t.isCompleted).toList();
  }

  List<Task> get tasksForToday {
    final today = DateTime.now();
    return _tasks.where((t) {
      if (t.isCompleted) {
        if (t.completedAt == null) return false;
        return t.completedAt!.year == today.year &&
            t.completedAt!.month == today.month &&
            t.completedAt!.day == today.day;
      } else {
        if (t.deadline == null) {
          return true;
        }
        final deadline = t.deadline!;
        final isFuture = DateTime(deadline.year, deadline.month, deadline.day)
            .isAfter(DateTime(today.year, today.month, today.day));
        return !isFuture;
      }
    }).toList();
  }

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

  int? _cachedTotalActiveDays;

  int get totalActiveDays {
    if (_cachedTotalActiveDays != null) return _cachedTotalActiveDays!;

    final completionCounts = <DateTime, int>{};
    final relevantDates = <DateTime>{};

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
      if (scheduledCount > 0 &&
          (completionCounts[date] ?? 0) >= scheduledCount) {
        fullDaysCount++;
      }
    }

    _cachedTotalActiveDays = fullDaysCount;
    return fullDaysCount;
  }

  int get totalStreaks {
    return _habits.fold(0, (sum, h) => sum + h.currentStreak);
  }

  Map<int, DayProgress> getWeeklyProgress() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return getProgressForRange(startOfWeek, endOfWeek);
  }

  Map<int, DayProgress> getProgressForRange(DateTime start, DateTime end) {
    final Map<int, DayProgress> rangeProgress = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysCount = end.difference(start).inDays + 1;

    final Map<DateTime, List<Task>> tasksByDate = {};
    for (final task in _tasks) {
      final date = task.deadline ?? task.createdAt;
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (tasksByDate[normalizedDate] == null) {
        tasksByDate[normalizedDate] = [];
      }
      tasksByDate[normalizedDate]!.add(task);
    }

    for (int i = 0; i < daysCount; i++) {
      final day = start.add(Duration(days: i));
      final dayKey = i;
      final checkDate = DateTime(day.year, day.month, day.day);

      int scheduledCount = 0;
      int completedCount = 0;

      for (final h in _habits) {
        if (h.isScheduledOn(day)) {
          scheduledCount++;
          if (h.isCompletedOn(day)) {
            completedCount++;
          }
        }
      }

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

  Future<void> addHabit(Habit habit) async {
    final box = Hive.box<Habit>('habits');
    box.put(habit.id, habit);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    _scheduleHabitReminders(habit);

    notifyListeners();
  }

  void _scheduleHabitReminders(Habit habit) {
    // Schedule generic reminder if list is empty but toggle is on (legacy/simple mode)
    if (habit.isReminderOn) {
      if (habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty) {
        for (int i = 0; i < habit.reminderTimes!.length; i++) {
          DateTime scheduledTime =
              _getNextReminderTime(habit.reminderTimes![i]);
          NativeAlarmService().scheduleTask(
            id: (habit.id + "_reminder_$i").hashCode,
            time: scheduledTime,
            title: "Time for ${habit.name}!",
            body: "Target ${i + 1}/${habit.dailyTarget}: Keep it up!",
            isAlarm: false,
            audio: true,
            vibrate: true,
            frequency: 'daily',
          );
        }
      } else if (habit.reminderTime != null) {
        DateTime scheduledTime = _getNextReminderTime(habit.reminderTime!);
        NativeAlarmService().scheduleTask(
          id: (habit.id + "_reminder").hashCode,
          time: scheduledTime,
          title: "Time for ${habit.name}!",
          body: "Don't break the chain! Complete your habit now.",
          isAlarm: false,
          audio: true,
          vibrate: true,
          frequency: 'daily',
        );
      }
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
        frequency: 'daily',
      );
    }
  }

  void _cancelHabitReminders(Habit habit) {
    // Cancel single reminder
    NativeAlarmService().cancelTask((habit.id + "_reminder").hashCode);
    // Cancel potential multiple reminders (assuming max 20 for safety)
    for (int i = 0; i < 20; i++) {
      NativeAlarmService().cancelTask((habit.id + "_reminder_$i").hashCode);
    }
    // Cancel alarm
    NativeAlarmService().cancelTask(habit.id.hashCode);
  }

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

  Future<void> updateHabit(Habit habit) async {
    final box = Hive.box<Habit>('habits');
    box.put(habit.id, habit);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    _cancelHabitReminders(habit);
    _scheduleHabitReminders(habit);

    notifyListeners();
  }

  Future<void> removeHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _cancelHabitReminders(_habits[index]);
    }

    final box = Hive.box<Habit>('habits');
    box.delete(id);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    notifyListeners();
  }

  Future<void> incrementHabitProgress(String id, DateTime date) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    final currentCount = habit.getCompletionCountOn(date);
    if (currentCount >= habit.dailyTarget) return; // Already maxed out

    // Add completion timestamp
    final newCompletedDates = [...habit.completedDates, date];

    // Check if we just finished it
    final isNowFullyCompleted = newCompletedDates
            .where((d) =>
                d.year == date.year &&
                d.month == date.month &&
                d.day == date.day)
            .length >=
        habit.dailyTarget;

    if (isNowFullyCompleted && isToday) {
      // Cancel alarms if checking for today and fully done
      _cancelHabitReminders(habit);
    }

    final updatedHabit = habit.copyWith(completedDates: newCompletedDates);
    final box = Hive.box<Habit>('habits');
    box.put(habit.id, updatedHabit);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    notifyListeners();
  }

  Future<void> decrementHabitProgress(String id, DateTime date) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final currentCount = habit.getCompletionCountOn(date);
    if (currentCount == 0) return; // Nothing to remove

    // Remove ONE instance of completion for this date
    // We need to find the specific DateTime object or just remove one matching date
    List<DateTime> newCompletedDates = List.from(habit.completedDates);
    final dateToRemoveIndex = newCompletedDates.lastIndexWhere((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);

    if (dateToRemoveIndex != -1) {
      newCompletedDates.removeAt(dateToRemoveIndex);
    }

    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    // Restore alarms if we dropped below target
    if (isToday) {
      final isNowIncomplete = newCompletedDates
              .where((d) =>
                  d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day)
              .length <
          habit.dailyTarget;

      if (isNowIncomplete) {
        _scheduleHabitReminders(habit);
      }
    }

    final updatedHabit = habit.copyWith(completedDates: newCompletedDates);
    final box = Hive.box<Habit>('habits');
    box.put(habit.id, updatedHabit);
    await box.flush();
    _habits = box.values.toList();
    _invalidateCache();

    notifyListeners();
  }

  // Legacy wrapper for toggle compatibility
  Future<void> toggleHabitCompletion(String id, DateTime date) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    final habit = _habits[index];

    // If fully completed, decrement (toggle off). Else increment (toggle on).
    if (habit.isCompletedOn(date)) {
      // Logic decision: Do we clear ALL progress or just one step?
      // Standard toggle usually clears all if "unchecking".
      // But for multi-step, maybe we just decrement?
      // "click on the plus symbol then increse to 4"
      // User likely wants granular control.
      // But toggle button on home screen usually means "do next step".
      // If fully done, maybe it does nothing or resets?
      // Let's make toggle behave like: Increment if < target.
      // If >= target, maybe Reset? Or Decrement?
      // Safe bet: Decrement checks.
      await decrementHabitProgress(id, date);
    } else {
      await incrementHabitProgress(id, date);
    }
  }

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
    final isCompleting = !task.isCompleted;

    final updatedTask = task.copyWith(
      isCompleted: isCompleting,
      completedAt: isCompleting ? completionDate : null,
    );

    // Alarm Logic
    if (isCompleting) {
      // Cancel pending alarms if task is done
      NativeAlarmService().cancelTask((task.id + "_reminder").hashCode);
      NativeAlarmService().cancelTask(task.id.hashCode);
    } else {
      // Restore alarms if task is undone (and time is in future)
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
    }

    final box = Hive.box<Task>('tasks');
    box.put(task.id, updatedTask);
    await box.flush();
    _tasks = box.values.toList();

    notifyListeners();
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

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
