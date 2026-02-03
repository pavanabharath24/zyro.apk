// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      icon: fields[3] as IconType,
      customEmoji: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      completedDates: (fields[6] as List?)?.cast<DateTime>(),
      scheduledTime: fields[7] as String?,
      repeatDays: (fields[8] as List?)?.cast<int>(),
      reminderTime: fields[9] as DateTime?,
      isReminderOn: fields[10] == null ? false : fields[10] as bool,
      isAlarmEnabled: fields[11] == null ? false : fields[11] as bool,
      alarmTime: fields[12] as DateTime?,
      alarmRingtone: fields[13] == null
          ? 'assets/alarms/default.mp3'
          : fields[13] as String,
      alarmMode: fields[14] == null ? AlarmMode.ring : fields[14] as AlarmMode,
      dailyTarget: fields[15] == null ? 1 : fields[15] as int,
      reminderTimes: (fields[16] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.customEmoji)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.completedDates)
      ..writeByte(7)
      ..write(obj.scheduledTime)
      ..writeByte(8)
      ..write(obj.repeatDays)
      ..writeByte(9)
      ..write(obj.reminderTime)
      ..writeByte(10)
      ..write(obj.isReminderOn)
      ..writeByte(11)
      ..write(obj.isAlarmEnabled)
      ..writeByte(12)
      ..write(obj.alarmTime)
      ..writeByte(13)
      ..write(obj.alarmRingtone)
      ..writeByte(14)
      ..write(obj.alarmMode)
      ..writeByte(15)
      ..write(obj.dailyTarget)
      ..writeByte(16)
      ..write(obj.reminderTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      icon: fields[3] as IconType,
      customEmoji: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      isCompleted: fields[6] as bool,
      completedAt: fields[7] as DateTime?,
      deadline: fields[8] as DateTime?,
      reminderTime: fields[9] as DateTime?,
      isReminderOn: fields[10] == null ? false : fields[10] as bool,
      isAlarmEnabled: fields[11] == null ? false : fields[11] as bool,
      alarmTime: fields[12] as DateTime?,
      alarmRingtone: fields[13] == null
          ? 'assets/alarms/default.mp3'
          : fields[13] as String,
      alarmMode: fields[14] == null ? AlarmMode.ring : fields[14] as AlarmMode,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.customEmoji)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.completedAt)
      ..writeByte(8)
      ..write(obj.deadline)
      ..writeByte(9)
      ..write(obj.reminderTime)
      ..writeByte(10)
      ..write(obj.isReminderOn)
      ..writeByte(11)
      ..write(obj.isAlarmEnabled)
      ..writeByte(12)
      ..write(obj.alarmTime)
      ..writeByte(13)
      ..write(obj.alarmRingtone)
      ..writeByte(14)
      ..write(obj.alarmMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IconTypeAdapter extends TypeAdapter<IconType> {
  @override
  final int typeId = 2;

  @override
  IconType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IconType.star;
      case 1:
        return IconType.run;
      case 2:
        return IconType.book;
      case 3:
        return IconType.water;
      case 4:
        return IconType.meditation;
      case 5:
        return IconType.workout;
      case 6:
        return IconType.code;
      case 7:
        return IconType.call;
      case 8:
        return IconType.mail;
      case 9:
        return IconType.shopping;
      case 10:
        return IconType.heart;
      case 11:
        return IconType.music;
      case 12:
        return IconType.sleep;
      case 13:
        return IconType.food;
      default:
        return IconType.star;
    }
  }

  @override
  void write(BinaryWriter writer, IconType obj) {
    switch (obj) {
      case IconType.star:
        writer.writeByte(0);
        break;
      case IconType.run:
        writer.writeByte(1);
        break;
      case IconType.book:
        writer.writeByte(2);
        break;
      case IconType.water:
        writer.writeByte(3);
        break;
      case IconType.meditation:
        writer.writeByte(4);
        break;
      case IconType.workout:
        writer.writeByte(5);
        break;
      case IconType.code:
        writer.writeByte(6);
        break;
      case IconType.call:
        writer.writeByte(7);
        break;
      case IconType.mail:
        writer.writeByte(8);
        break;
      case IconType.shopping:
        writer.writeByte(9);
        break;
      case IconType.heart:
        writer.writeByte(10);
        break;
      case IconType.music:
        writer.writeByte(11);
        break;
      case IconType.sleep:
        writer.writeByte(12);
        break;
      case IconType.food:
        writer.writeByte(13);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmModeAdapter extends TypeAdapter<AlarmMode> {
  @override
  final int typeId = 3;

  @override
  AlarmMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmMode.silent;
      case 1:
        return AlarmMode.vibrate;
      case 2:
        return AlarmMode.ring;
      default:
        return AlarmMode.silent;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmMode obj) {
    switch (obj) {
      case AlarmMode.silent:
        writer.writeByte(0);
        break;
      case AlarmMode.vibrate:
        writer.writeByte(1);
        break;
      case AlarmMode.ring:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
