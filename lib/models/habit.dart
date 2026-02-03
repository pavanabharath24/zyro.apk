import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final IconType icon;
  @HiveField(4)
  final String? customEmoji;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final List<DateTime> completedDates;
  @HiveField(7)
  final String? scheduledTime;
  @HiveField(8)
  final List<int> repeatDays;
  @HiveField(9)
  final DateTime? reminderTime;
  @HiveField(10, defaultValue: false)
  final bool isReminderOn;
  @HiveField(11, defaultValue: false)
  final bool isAlarmEnabled;
  @HiveField(12)
  final DateTime? alarmTime;
  @HiveField(13, defaultValue: 'assets/alarms/default.mp3')
  final String alarmRingtone;
  @HiveField(14, defaultValue: AlarmMode.ring)
  @HiveField(14, defaultValue: AlarmMode.ring)
  final AlarmMode alarmMode;
  @HiveField(15, defaultValue: 1)
  final int dailyTarget;
  @HiveField(16)
  final List<DateTime>? reminderTimes;

  Habit({
    required this.id,
    required this.name,
    this.description,
    this.icon = IconType.star,
    this.customEmoji,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    this.scheduledTime,
    List<int>? repeatDays,
    this.reminderTime,
    this.isReminderOn = false,
    this.isAlarmEnabled = false,
    this.alarmTime,
    this.alarmRingtone = 'assets/alarms/default.mp3',
    this.alarmMode = AlarmMode.ring,
    this.dailyTarget = 1,
    this.reminderTimes,
  })  : createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? [],
        repeatDays = repeatDays ?? [1, 2, 3, 4, 5, 6, 7];

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    IconType? icon,
    String? customEmoji,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    String? scheduledTime,
    List<int>? repeatDays,
    DateTime? reminderTime,
    bool? isReminderOn,
    bool? isAlarmEnabled,
    DateTime? alarmTime,
    String? alarmRingtone,
    AlarmMode? alarmMode,
    int? dailyTarget,
    List<DateTime>? reminderTimes,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      customEmoji: customEmoji ?? this.customEmoji,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderTime: reminderTime ?? this.reminderTime,
      isReminderOn: isReminderOn ?? this.isReminderOn,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      alarmTime: alarmTime ?? this.alarmTime,
      alarmRingtone: alarmRingtone ?? this.alarmRingtone,
      alarmMode: alarmMode ?? this.alarmMode,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      reminderTimes: reminderTimes ?? this.reminderTimes,
    );
  }

  int getCompletionCountOn(DateTime date) {
    return completedDates
        .where((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day)
        .length;
  }

  bool isCompletedOn(DateTime date) {
    // Legacy support: if dailyTarget is 1, existing logic works.
    // Enhanced: check if count >= dailyTarget
    return getCompletionCountOn(date) >= dailyTarget;
  }

  bool isScheduledOn(DateTime date) {
    // Cannot be scheduled before it was created
    final checkDate = DateTime(date.year, date.month, date.day);
    final createdDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (checkDate.isBefore(createdDate)) return false;

    return repeatDays.contains(date.weekday);
  }

  int get completedDaysCount {
    if (completedDates.isEmpty) return 0;
    final uniqueDays =
        completedDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    return uniqueDays.length;
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    // Get unique days sorted descending
    final uniqueDays = completedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    // Start measuring from today (or yesterday if not completed today yet?)
    // Usually streak includes today if completed, or continues from yesterday.
    // Let's check from today.
    DateTime checkDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // If the latest completion is not today, check if it's yesterday to maintain streak
    if (uniqueDays.isNotEmpty && uniqueDays.first.isBefore(checkDate)) {
      // If no completion today, allow streak to continue if last completion was yesterday
      if (uniqueDays.first.difference(checkDate).inDays.abs() > 1) {
        // Gap is more than 1 day (i.e. didn't complete yesterday)
        // Actually, difference logic is tricky. Let's stick to simple iteration.
      }
    }

    // Simplified robust logic:
    // Check if we have a completion for 'checkDate'. If yes, increment, move checkDate back.
    // If no, but checkDate is TODAY, just move checkDate back (streak persists if done yesterday).
    // BUT 'currentStreak' usually implies contiguous days ending now.

    // Standard approach:
    // 1. Check if today is completed. If yes, streak starts at 1, checkDate = yesterday.
    // 2. If today is NOT completed, check if yesterday is completed. If yes, streak starts at 1 (from yesterday), checkDate = day before yesterday.
    // 3. If neither, streak is 0.

    // However, since we want to simply count contiguous block backwards:

    // Let's refine based on the existing logic which was purely date matching.

    // Check if today is present

    // If today is in list, we start counting.
    // If today is NOT in list, but yesterday IS, we start counting from yesterday.

    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (uniqueDays.contains(today)) {
      checkDate = today;
    } else if (uniqueDays.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return 0; // Streak broken
    }

    for (final date in uniqueDays) {
      // Since uniqueDays is sorted descending, we can just look for the sequence
      if (date.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isAfter(checkDate)) {
        // Should not happen if we started correctly, but harmless skip
        continue;
      } else {
        // Date is older than expected checkDate -> Gap found
        break;
      }
    }

    return streak;
  }

  double get completionRate {
    final now = DateTime.now();
    int totalScheduled = 0;
    int completedCount = 0;

    // Iterate from created date to today
    DateTime date = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);

    // Optimization: if created long ago, this loop could be slow.
    // But for a personal app it's likely fine (thousands of iterations max).
    // Limit to last 365 days if needed? User wants "completion rate".
    // Let's do full history for accuracy.

    while (!date.isAfter(today)) {
      if (repeatDays.contains(date.weekday)) {
        totalScheduled++;
        if (isCompletedOn(date)) {
          completedCount++;
        }
      }
      date = date.add(const Duration(days: 1));
    }

    if (totalScheduled == 0) return 0.0;
    return completedCount / totalScheduled;
  }
}

@HiveType(typeId: 2)
enum IconType {
  @HiveField(0)
  star,
  @HiveField(1)
  run,
  @HiveField(2)
  book,
  @HiveField(3)
  water,
  @HiveField(4)
  meditation,
  @HiveField(5)
  workout,
  @HiveField(6)
  code,
  @HiveField(7)
  call,
  @HiveField(8)
  mail,
  @HiveField(9)
  shopping,
  @HiveField(10)
  heart,
  @HiveField(11)
  music,
  @HiveField(12)
  sleep,
  @HiveField(13)
  food,
}

@HiveType(typeId: 3)
enum AlarmMode {
  @HiveField(0)
  silent,
  @HiveField(1)
  vibrate,
  @HiveField(2)
  ring,
}

@HiveType(typeId: 1)
class Task {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final IconType icon;
  @HiveField(4)
  final String? customEmoji;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final bool isCompleted;
  @HiveField(7)
  final DateTime? completedAt;
  @HiveField(8)
  final DateTime? deadline;
  @HiveField(9)
  final DateTime? reminderTime;
  @HiveField(10, defaultValue: false)
  final bool isReminderOn;
  @HiveField(11, defaultValue: false)
  final bool isAlarmEnabled;
  @HiveField(12)
  final DateTime? alarmTime;
  @HiveField(13, defaultValue: 'assets/alarms/default.mp3')
  final String alarmRingtone;
  @HiveField(14, defaultValue: AlarmMode.ring)
  final AlarmMode alarmMode;

  Task({
    required this.id,
    required this.name,
    this.description,
    this.icon = IconType.star,
    this.customEmoji,
    DateTime? createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.deadline,
    this.reminderTime,
    this.isReminderOn = false,
    this.isAlarmEnabled = false,
    this.alarmTime,
    this.alarmRingtone = 'assets/alarms/default.mp3',
    this.alarmMode = AlarmMode.ring,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? name,
    String? description,
    IconType? icon,
    String? customEmoji,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? deadline,
    DateTime? reminderTime,
    bool? isReminderOn,
    bool? isAlarmEnabled,
    DateTime? alarmTime,
    String? alarmRingtone,
    AlarmMode? alarmMode,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      customEmoji: customEmoji ?? this.customEmoji,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      reminderTime: reminderTime ?? this.reminderTime,
      isReminderOn: isReminderOn ?? this.isReminderOn,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      alarmTime: alarmTime ?? this.alarmTime,
      alarmRingtone: alarmRingtone ?? this.alarmRingtone,
      alarmMode: alarmMode ?? this.alarmMode,
    );
  }
}
