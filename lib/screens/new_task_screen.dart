import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/habit_provider.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';

class NewTaskScreen extends StatefulWidget {
  final Task? task;
  const NewTaskScreen({super.key, this.task});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedIconIndex = 0;

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _dateEnabled = false;
  DateTime _selectedDate = DateTime.now();

  // Alarm State
  bool _alarmEnabled = false;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 7, minute: 0);
  AlarmMode _alarmMode = AlarmMode.ring;
  String _alarmRingtone = 'assets/alarms/default.mp3';

  final List<IconType> _iconTypes = [
    IconType.star,
    IconType.book,
    IconType.call,
    IconType.mail,
    IconType.shopping,
    IconType.heart,
    IconType.food,
  ];

  final List<IconData> _icons = [
    Icons.check_circle_outline,
    Icons.edit_note,
    Icons.event,
    Icons.work_outline,
    Icons.shopping_cart_outlined,
    Icons.phone_outlined,
    Icons.email_outlined,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      final task = widget.task!;
      _nameController.text = task.name;
      _selectedIconIndex = _iconTypes.indexOf(task.icon);
      if (_selectedIconIndex == -1) _selectedIconIndex = 0;
      _selectedEmoji = task.customEmoji;

      if (task.deadline != null) {
        _dateEnabled = true;
        _selectedDate = task.deadline!;
      }

      _reminderEnabled = task.isReminderOn;
      if (task.reminderTime != null) {
        _reminderTime = TimeOfDay.fromDateTime(task.reminderTime!);
      }

      _alarmEnabled = task.isAlarmEnabled;
      if (task.alarmTime != null) {
        _alarmTime = TimeOfDay.fromDateTime(task.alarmTime!);
      }
      _alarmMode = task.alarmMode;
      _alarmRingtone = task.alarmRingtone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }

    // Reminder Time
    DateTime? reminderDateTime;
    if (_reminderEnabled) {
      final now = _dateEnabled ? _selectedDate : DateTime.now();
      reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );
    }

    // Deadline
    DateTime? deadline;
    if (_dateEnabled) {
      deadline = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59);
    }

    // Alarm Time
    DateTime? alarmDateTime;
    if (_alarmEnabled) {
      final now = _dateEnabled ? _selectedDate : DateTime.now();
      alarmDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _alarmTime.hour,
        _alarmTime.minute,
      );
    }

    if (widget.task != null) {
      // Update existing task
      final updatedTask = widget.task!.copyWith(
        name: name,
        icon: _iconTypes[_selectedIconIndex],
        customEmoji: _selectedEmoji,
        deadline: deadline,
        isReminderOn: _reminderEnabled,
        reminderTime: reminderDateTime,
        isAlarmEnabled: _alarmEnabled,
        alarmTime: alarmDateTime,
        alarmMode: _alarmMode,
        alarmRingtone: _alarmRingtone,
      );
      context.read<HabitProvider>().updateTask(updatedTask);
    } else {
      // Create new task
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        icon: _iconTypes[_selectedIconIndex],
        customEmoji: _selectedEmoji,
        deadline: deadline,
        isReminderOn: _reminderEnabled,
        reminderTime: reminderDateTime,
        isAlarmEnabled: _alarmEnabled,
        alarmTime: alarmDateTime,
        alarmMode: _alarmMode,
        alarmRingtone: _alarmRingtone,
      );
      context.read<HabitProvider>().addTask(task);
    }

    context.pop();
  }

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
      });
    }
  }

  Future<void> _pickDate() async {
    // Ensure firstDate is before or equal to initialDate
    final firstDate = DateTime(2020);
    final initial =
        _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate:
          firstDate, // Allow picking past dates for correction, or just prevent crash
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
        if (_alarmEnabled) {
          _alarmTime = picked;
        }
      });
    }
  }

  Future<void> _pickAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );
    if (picked != null) {
      setState(() {
        _alarmTime = picked;
        if (_reminderEnabled) {
          _reminderTime = picked;
        }
      });
    }
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
            'Are you sure you want to delete this task? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider =
                  Provider.of<HabitProvider>(context, listen: false);
              provider.removeTask(widget.task!.id);
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

    final activeColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Glass Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.8)
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
                    Text(widget.task != null ? 'Edit Task' : 'New Task',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    TextButton(
                      onPressed: _saveTask,
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
                      // Task Name Section
                      _sectionLabel('Task Name', subTextColor),
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
                                  hintText: 'e.g. Buy groceries',
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
                      // Icon Selector
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _icons.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // Plus / Emoji
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

                            final iconIndex = index - 1;
                            final isSelected = _selectedEmoji == null &&
                                _selectedIconIndex == iconIndex;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedIconIndex = iconIndex;
                                _selectedEmoji = null;
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

                      // Deadline Section
                      _sectionLabel('Due Date', subTextColor),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Row(
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
                                      child: Icon(Icons.calendar_today,
                                          color: textColor),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('Set Date',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ],
                                ),
                                Switch(
                                  value: _dateEnabled,
                                  onChanged: (val) =>
                                      setState(() => _dateEnabled = val),
                                  activeThumbColor:
                                      isDark ? Colors.black : Colors.white,
                                  activeTrackColor: activeColor,
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: AppColors.spLight,
                                ),
                              ],
                            ),
                            if (_dateEnabled) ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('EEE, MMM d, y')
                                            .format(_selectedDate),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.edit,
                                          size: 16, color: subTextColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                                Text('Reminder',
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: InkWell(
                            onTap: _pickTime,
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
                                  child: Text(_reminderTime.format(context),
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
                                children: AlarmMode.values.map((mode) {
                                  final isSelected = _alarmMode == mode;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _alarmMode = mode),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? activeColor
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: isSelected
                                              ? null
                                              : Border.all(color: borderColor),
                                        ),
                                        child: Text(
                                          mode.name.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
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
              padding: EdgeInsets.fromLTRB(20, 20, 20,
                  math.max(32, MediaQuery.of(context).padding.bottom + 16)),
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
              child: widget.task != null
                  ? Row(
                      children: [
                        // Delete Button
                        GestureDetector(
                          onTap: _deleteTask,
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
                            onPressed: _saveTask,
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
                            child: const Text('Update Task',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: activeColor.withValues(alpha: 0.3),
                      ),
                      child: const Text('Create Task',
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
}
