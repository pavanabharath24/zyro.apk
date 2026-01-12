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
  final AlarmMode alarmMode;

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
    );
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool isScheduledOn(DateTime date) {
    // Cannot be scheduled before it was created
    final checkDate = DateTime(date.year, date.month, date.day);
    final createdDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (checkDate.isBefore(createdDate)) return false;

    return repeatDays.contains(date.weekday);
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final date in sortedDates) {
      if (date.year == checkDate.year &&
          date.month == checkDate.month &&
          date.day == checkDate.day) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
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
