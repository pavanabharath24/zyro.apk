import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class NewHabitScreen extends StatefulWidget {
  final Habit? habit;
  const NewHabitScreen({super.key, this.habit});

  @override
  State<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends State<NewHabitScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedIconIndex = 0;
  int _selectedFrequency = 0; // 0: Daily, 1: Weekly, 2: Specific Days
  final List<bool> _selectedDays = [
    true,
    false,
    true,
    false,
    true,
    false,
    false
  ]; // M, T, W, T, F, S, S
  int _goalCount = 1;
  bool _reminderEnabled = true;
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
  // TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0); // Removed

  // Alarm State
  bool _alarmEnabled = false;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 7, minute: 0);
  AlarmMode _alarmMode = AlarmMode.ring;
  String _alarmRingtone = 'assets/alarms/default.mp3';

  final List<IconType> _iconTypes = [
    IconType.book,
    IconType.water,
    IconType.workout,
    IconType.meditation,
    IconType.code,
    IconType.sleep,
    IconType.heart,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      final habit = widget.habit!;
      _nameController.text = habit.name;
      _selectedIconIndex = _iconTypes.indexOf(habit.icon);
      if (_selectedIconIndex == -1) _selectedIconIndex = 0;
      _selectedEmoji = habit.customEmoji;

      // Initialize days
      if (habit.repeatDays.length == 7) {
        _selectedFrequency = 0; // Daily
        _selectedDays.fillRange(0, 7, true);
      } else if (habit.repeatDays.length == 1 &&
          habit.repeatDays.contains(DateTime.now().weekday)) {
        _selectedFrequency = 1; // Weekly (assuming today)
      } else {
        _selectedFrequency = 2; // Specific
        _selectedDays.fillRange(0, 7, false);
        for (final day in habit.repeatDays) {
          if (day >= 1 && day <= 7) _selectedDays[day - 1] = true;
        }
      }

      _goalCount = habit.dailyTarget;

      _reminderEnabled = habit.isReminderOn;
      if (habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty) {
        _reminderTimes = habit.reminderTimes!
            .map((dt) => TimeOfDay.fromDateTime(dt))
            .toList();
      } else if (habit.reminderTime != null) {
        // Fallback for migration
        _reminderTimes = [TimeOfDay.fromDateTime(habit.reminderTime!)];
      }

      // Ensure list size matches goal count (fill with last or default)
      if (_reminderTimes.length < _goalCount) {
        final last = _reminderTimes.isNotEmpty
            ? _reminderTimes.last
            : const TimeOfDay(hour: 9, minute: 0);
        while (_reminderTimes.length < _goalCount) {
          _reminderTimes.add(last);
        }
      } else if (_reminderTimes.length > _goalCount) {
        _reminderTimes = _reminderTimes.sublist(0, _goalCount);
      }

      _alarmEnabled = habit.isAlarmEnabled;
      if (habit.alarmTime != null) {
        _alarmTime = TimeOfDay.fromDateTime(habit.alarmTime!);
      }
      _alarmMode = habit.alarmMode;
      _alarmRingtone = habit.alarmRingtone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    // Get selected days as weekday numbers (1=Mon, 7=Sun)
    List<int> repeatDays = [];
    if (_selectedFrequency == 0) {
      // Daily
      repeatDays = [1, 2, 3, 4, 5, 6, 7];
    } else if (_selectedFrequency == 1) {
      // Weekly - just today's weekday
      repeatDays = [DateTime.now().weekday];
    } else {
      // Specific days
      for (int i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) {
          repeatDays.add(i + 1); // 1=Mon, 2=Tue, etc.
        }
      }
    }

    // Reminder Time
    List<DateTime>? reminderDateTimes;
    DateTime? legacyReminderTime;

    if (_reminderEnabled) {
      final now = DateTime.now();
      reminderDateTimes = [];
      for (final t in _reminderTimes) {
        reminderDateTimes.add(DateTime(
          now.year,
          now.month,
          now.day,
          t.hour,
          t.minute,
        ));
      }
      // Set legacy field to first one for backward compatibility
      if (reminderDateTimes.isNotEmpty) {
        legacyReminderTime = reminderDateTimes.first;
      }
    }

    // Alarm Time
    DateTime? alarmDateTime;
    if (_alarmEnabled) {
      final now = DateTime.now();
      alarmDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _alarmTime.hour,
        _alarmTime.minute,
      );
    }

    if (widget.habit != null) {
      // Update existing
      final updatedHabit = widget.habit!.copyWith(
        name: name,
        icon: _iconTypes[_selectedIconIndex],
        customEmoji: _selectedEmoji,
        repeatDays: repeatDays,
        isReminderOn: _reminderEnabled,
        reminderTime: legacyReminderTime,
        isAlarmEnabled: _alarmEnabled,
        alarmTime: alarmDateTime,
        alarmMode: _alarmMode,
        alarmRingtone: _alarmRingtone,
        dailyTarget: _goalCount,
        reminderTimes: reminderDateTimes,
      );
      context.read<HabitProvider>().updateHabit(updatedHabit);
    } else {
      // Create new
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        icon: _iconTypes[_selectedIconIndex],
        customEmoji: _selectedEmoji,
        repeatDays: repeatDays,
        isReminderOn: _reminderEnabled,
        reminderTime: legacyReminderTime,
        isAlarmEnabled: _alarmEnabled,
        alarmTime: alarmDateTime,
        alarmMode: _alarmMode,
        alarmRingtone: _alarmRingtone,
        dailyTarget: _goalCount,
        reminderTimes: reminderDateTimes,
      );
      context.read<HabitProvider>().addHabit(habit);
    }

    if (mounted) {
      if (_reminderEnabled &&
          reminderDateTimes != null &&
          reminderDateTimes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved! Reminders set for Today')),
        );
      } else if (_alarmEnabled && alarmDateTime != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Saved! Alarm set for Today ${_formatTime(alarmDateTime)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit saved successfully!')),
        );
      }
    }

    context.pop();
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (picked != null) {
      setState(() {
        _reminderTimes[index] = picked;
        // Sync alarm time if single reminder setup (optional UX choice)
        if (_goalCount == 1 && _alarmEnabled) {
          _alarmTime = picked;
        }
      });
    }
  }

  void _updateGoalCount(int newCount) {
    if (newCount < 1) return;
    setState(() {
      _goalCount = newCount;
      if (_reminderTimes.length < newCount) {
        // Add new times initialized to the last one or default
        final last = _reminderTimes.isNotEmpty
            ? _reminderTimes.last
            : const TimeOfDay(hour: 9, minute: 0);
        while (_reminderTimes.length < newCount) {
          _reminderTimes.add(last);
        }
      } else if (_reminderTimes.length > newCount) {
        // Remove excess
        _reminderTimes = _reminderTimes.sublist(0, newCount);
      }
    });
  }

  Future<void> _pickAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );
    if (picked != null) {
      setState(() {
        _alarmTime = picked;
        // If single reminder, sync it back (optional)
        if (_reminderEnabled && _goalCount == 1) {
          _reminderTimes[0] = picked;
        }
      });
    }
  }

  final List<IconData> _icons = [
    Icons.menu_book,
    Icons.water_drop,
    Icons.fitness_center,
    Icons.self_improvement,
    Icons.code,
    Icons.bedtime,
    Icons.local_florist,
  ];

  String? _selectedEmoji;

  Future<void> _pickEmoji() async {
    final controller = TextEditingController();
    final emoji = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter an Emoji'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32),
          decoration: const InputDecoration(
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (emoji != null && emoji.isNotEmpty) {
      setState(() {
        _selectedEmoji = emoji;
        // Keep _selectedIconIndex as is or reset, but visual priority is emoji
      });
    }
  }

  void _deleteHabit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text(
            'Are you sure you want to delete this habit? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider =
                  Provider.of<HabitProvider>(context, listen: false);
              provider.removeHabit(widget.habit!.id);
              Navigator.pop(context); // Close dialog
              context.pop(); // Close screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.pepper : AppColors.saltWhite;
    final textColor = isDark ? AppColors.saltWhite : AppColors.pepper;
    final subTextColor = isDark ? AppColors.spLight : AppColors.spMedium;
    final borderColor = isDark ? Colors.white24 : AppColors.spLight;
    final cardBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.saltWhite;

    // Default color for UI elements since we removed picker
    final activeColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Colors.transparent, // Important for glassmorphism
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Glass Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: isDark
                  ? Colors.black
                      .withValues(alpha: 0.8) // Darker for readability
                  : Colors.white.withValues(alpha: 0.8),
            ),
          ),

          Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 12),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.95),
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close, color: subTextColor),
                    ),
                    Text(widget.habit != null ? 'Edit Habit' : 'New Habit',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    TextButton(
                      onPressed: _saveHabit,
                      child: Text('Save',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Habit Name Section
                      _sectionLabel('Habit Name', subTextColor),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: activeColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: _selectedEmoji != null
                                ? Center(
                                    child: Text(_selectedEmoji!,
                                        style: const TextStyle(fontSize: 32)))
                                : Icon(_icons[_selectedIconIndex],
                                    color: isDark ? Colors.black : Colors.white,
                                    size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                style:
                                    TextStyle(fontSize: 18, color: textColor),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Read a book',
                                  hintStyle: TextStyle(color: subTextColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Icon Selector with Plus Button
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _icons.length + 1, // +1 for the Plus icon
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // Plus / Emoji Button
                              final isSelected = _selectedEmoji != null;
                              return GestureDetector(
                                onTap: _pickEmoji,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected ? activeColor : cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isSelected
                                            ? activeColor
                                            : borderColor,
                                        width: isSelected ? 2 : 1),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: activeColor.withValues(
                                                    alpha: 0.3),
                                                blurRadius: 8)
                                          ]
                                        : [],
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Text(_selectedEmoji!,
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  color: isDark
                                                      ? Colors.black
                                                      : Colors.white)))
                                      : Icon(Icons.add, color: subTextColor),
                                ),
                              );
                            }

                            // Standard Icons
                            final iconIndex = index - 1;
                            final isSelected = _selectedEmoji == null &&
                                _selectedIconIndex == iconIndex;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedIconIndex = iconIndex;
                                _selectedEmoji = null; // Clear emoji selection
                              }),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected ? activeColor : cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected
                                          ? activeColor
                                          : borderColor,
                                      width: isSelected ? 2 : 1),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                              color: activeColor.withValues(
                                                  alpha: 0.3),
                                              blurRadius: 8)
                                        ]
                                      : [],
                                ),
                                child: Icon(_icons[iconIndex],
                                    color: isSelected
                                        ? (isDark ? Colors.black : Colors.white)
                                        : subTextColor),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                      Divider(color: borderColor),
                      const SizedBox(height: 24),

                      // Color Theme Section

                      const SizedBox(height: 32),

                      // Frequency Section
                      _sectionLabel('Frequency', subTextColor),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : AppColors.spLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: ['Daily', 'Weekly', 'Specific Days']
                              .asMap()
                              .entries
                              .map((entry) {
                            final isSelected = _selectedFrequency == entry.key;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedFrequency = entry.key),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cardBg
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: borderColor.withValues(
                                                alpha: 0.5))
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 4)
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    entry.value,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color:
                                          isSelected ? textColor : subTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_selectedFrequency == 2) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .asMap()
                              .entries
                              .map((entry) {
                            final isSelected = _selectedDays[entry.key];
                            return GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedDays[entry.key] =
                                      !_selectedDays[entry.key]),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? activeColor : cardBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isSelected
                                          ? activeColor
                                          : borderColor),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                              color: activeColor.withValues(
                                                  alpha: 0.3),
                                              blurRadius: 4)
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark
                                              ? Colors.black
                                              : Colors.white)
                                          : subTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Goal Section
                      _sectionLabel('Goal', subTextColor),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : AppColors.spLight
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.flag, color: textColor),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DAILY TARGET',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: subTextColor,
                                            letterSpacing: 1)),
                                    Text(
                                        '$_goalCount time${_goalCount > 1 ? 's' : ''}',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : AppColors.spLight.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: borderColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  _counterButton(Icons.remove, () {
                                    _updateGoalCount(_goalCount - 1);
                                  }, false, textColor, cardBg, borderColor),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('$_goalCount',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ),
                                  _counterButton(
                                      Icons.add,
                                      () => _updateGoalCount(_goalCount + 1),
                                      true,
                                      textColor,
                                      cardBg,
                                      borderColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Reminders Section
                      _sectionLabel('Reminders', subTextColor),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : AppColors.spLight
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.notifications,
                                      color: textColor),
                                ),
                                const SizedBox(width: 16),
                                Text('Daily Reminder',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor)),
                              ],
                            ),
                            Switch(
                              value: _reminderEnabled,
                              onChanged: (val) =>
                                  setState(() => _reminderEnabled = val),
                              activeThumbColor:
                                  isDark ? Colors.black : Colors.white,
                              activeTrackColor: activeColor,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: AppColors.spLight,
                            ),
                          ],
                        ),
                      ),
                      if (_reminderEnabled) ...[
                        const SizedBox(height: 12),
                        // List of Time Pickers
                        Column(
                          children:
                              List.generate(_reminderTimes.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: InkWell(
                                  onTap: () => _pickTime(index),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          _goalCount > 1
                                              ? 'Reminder ${index + 1}'
                                              : 'Time',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: textColor)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white10
                                              : AppColors.spLight
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: borderColor.withValues(
                                                  alpha: 0.3)),
                                        ),
                                        child: Text(
                                            _reminderTimes[index]
                                                .format(context),
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                                letterSpacing: 2)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Alarm Section
                      _sectionLabel('Alarm', subTextColor),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : AppColors.spLight
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.alarm, color: textColor),
                                ),
                                const SizedBox(width: 16),
                                Text('Alarm Clock',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor)),
                              ],
                            ),
                            Switch(
                              value: _alarmEnabled,
                              onChanged: (val) =>
                                  setState(() => _alarmEnabled = val),
                              activeThumbColor:
                                  isDark ? Colors.black : Colors.white,
                              activeTrackColor: activeColor,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: AppColors.spLight,
                            ),
                          ],
                        ),
                      ),
                      if (_alarmEnabled) ...[
                        const SizedBox(height: 12),
                        // Time Picker
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: InkWell(
                            onTap: _pickAlarmTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Time',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textColor)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : AppColors.spLight
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            borderColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(_alarmTime.format(context),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          letterSpacing: 2)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mode Selector
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mode',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: subTextColor)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _modeButton(
                                      'SILENT',
                                      AlarmMode.silent,
                                      _alarmMode,
                                      (m) => setState(() => _alarmMode = m),
                                      textColor,
                                      cardBg,
                                      borderColor,
                                      activeColor),
                                  const SizedBox(width: 8),
                                  _modeButton(
                                      'VIBRATE',
                                      AlarmMode.vibrate,
                                      _alarmMode,
                                      (m) => setState(() => _alarmMode = m),
                                      textColor,
                                      cardBg,
                                      borderColor,
                                      activeColor),
                                  const SizedBox(width: 8),
                                  _modeButton(
                                      'RING',
                                      AlarmMode.ring,
                                      _alarmMode,
                                      (m) => setState(() => _alarmMode = m),
                                      textColor,
                                      cardBg,
                                      borderColor,
                                      activeColor),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    bgColor,
                    bgColor.withValues(alpha: 0.95),
                    bgColor.withValues(alpha: 0)
                  ],
                ),
              ),
              child: widget.habit != null
                  ? Row(
                      children: [
                        // Delete Button
                        GestureDetector(
                          onTap: _deleteHabit,
                          child: Container(
                            width: 56,
                            height: 56,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red),
                          ),
                        ),
                        // Update Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveHabit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeColor,
                              foregroundColor:
                                  isDark ? Colors.black : Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: activeColor.withValues(alpha: 0.3),
                            ),
                            child: const Text('Update Habit',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _saveHabit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: activeColor.withValues(alpha: 0.3),
                      ),
                      child: const Text('Create Habit',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1)),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onPressed, bool isPrimary,
      Color textColor, Color cardBg, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary ? activeColor : cardBg,
          borderRadius: BorderRadius.circular(8),
          border: isPrimary
              ? null
              : Border.all(color: borderColor.withValues(alpha: 0.5)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                      color: activeColor.withValues(alpha: 0.3), blurRadius: 4)
                ]
              : [],
        ),
        child: Icon(icon,
            size: 18,
            color:
                isPrimary ? (isDark ? Colors.black : Colors.white) : textColor),
      ),
    );
  }

  Widget _modeButton(
      String text,
      AlarmMode mode,
      AlarmMode currentMode,
      Function(AlarmMode) onTap,
      Color textColor,
      Color cardBg,
      Color borderColor,
      Color activeColor) {
    final isSelected = mode == currentMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : cardBg,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? null : Border.all(color: borderColor),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
