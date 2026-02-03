import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/bottom_nav.dart';
import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../models/habit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check for exact alarm permission on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().checkAndRequestAlarmPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.pageGradientDark
                  : AppColors.pageGradientLight,
            ),
          ),

          // Main Content
          Positioned.fill(
            child: Consumer<HabitProvider>(
              builder: (context, provider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SafeArea(
                        bottom: false,
                        child: _buildHeader(context),
                      ),

                      if (provider.hasUnclaimedRank)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: GestureDetector(
                            onTap: () => context.go('/stats'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyanAccent.withValues(alpha: 0.2),
                                    Colors.blueAccent.withValues(alpha: 0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.5),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_awesome,
                                        color: Colors.cyanAccent, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'New Rank Achieved!',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.pepper,
                                          ),
                                        ),
                                        Text(
                                          'Tap to claim your reward',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 14, color: subTextColor),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(settings.getGreeting(),
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w300,
                                    color: textColor,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text(_getFormattedDate(),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: subTextColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Dashboard (first)
                      _buildDashboard(context, provider),
                      const SizedBox(height: 32),

                      // Daily Flow (Habits)
                      _buildCompletionRateCard(context, provider),
                      const SizedBox(height: 24),
                      const SizedBox(height: 32),

                      // Active Streaks
                      _buildActiveStreaks(context, provider),
                      const SizedBox(height: 32),

                      // Completed Today
                      _buildCompletedToday(context, provider),

                      // Add bottom padding for FAB/BottomBar
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Nav
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(activePath: '/home'),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    // Uses device's locale for proper formatting
    return DateFormat('EEEE, MMM d').format(now);
  }

  Widget _buildHeader(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context, listen: false);
    // Simple notification check based on today's incomplete habits
    final todayHabits = provider.habits
        .where((h) => h.repeatDays.contains(DateTime.now().weekday))
        .toList();
    final incompleteCount = todayHabits
        .where((h) => !h.completedDates.any((d) =>
            d.year == DateTime.now().year &&
            d.month == DateTime.now().month &&
            d.day == DateTime.now().day))
        .length;
    final hasNotifications = incompleteCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Notification bell with dot
          GestureDetector(
            onTap: () => _showNotificationsPanel(context, provider),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.notifications_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  if (hasNotifications)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _iconButton(Icons.settings_outlined, () => context.go('/settings')),
        ],
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context, HabitProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final cardBg = isDark ? AppColors.surface : Colors.white;

    // Get today's habits and their status
    final today = DateTime.now();
    final todayHabits = provider.habits
        .where((h) => h.repeatDays.contains(today.weekday))
        .toList();

    final incompleteHabits = todayHabits
        .where((h) => !h.completedDates.any((d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day))
        .toList();

    final completedHabits = todayHabits
        .where((h) => h.completedDates.any((d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subTextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: textColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${incompleteHabits.length} pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: subTextColor.withValues(alpha: 0.1), height: 1),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pending habits
                  if (incompleteHabits.isNotEmpty) ...[
                    Text('⏰ Pending Today',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: subTextColor)),
                    const SizedBox(height: 8),
                    ...incompleteHabits.map((h) => _notificationItem(
                          context,
                          h.customEmoji ?? '📋',
                          h.name,
                          'Tap to complete',
                          Colors.orange,
                          isDark,
                        )),
                  ],
                  if (completedHabits.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('✅ Completed Today',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: subTextColor)),
                    const SizedBox(height: 8),
                    ...completedHabits.map((h) => _notificationItem(
                          context,
                          h.customEmoji ?? '🎉',
                          h.name,
                          'Great job!',
                          Colors.green,
                          isDark,
                        )),
                  ],
                  if (todayHabits.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 48,
                              color: subTextColor.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No habits scheduled today',
                              style: TextStyle(color: subTextColor)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationItem(BuildContext context, String emoji, String title,
      String subtitle, Color accentColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.primary : AppColors.pepper,
                    )),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.tertiary : AppColors.ash,
                    )),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.primary, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCompletionRateCard(
      BuildContext context, HabitProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;

    // Calculate Habit Progress
    final todayHabits = provider.todayHabits;
    final completedHabits = provider.completedToday;
    final habitProgress =
        todayHabits.isEmpty ? 0.0 : completedHabits.length / todayHabits.length;
    final habitPercentage = (habitProgress * 100).toInt();

    // Calculate Task Progress (Using Rollover Logic)
    final tasksForToday = provider.tasksForToday;
    final completedTasks =
        provider.completedTasksToday; // Already filtered for today
    final taskProgress = tasksForToday.isEmpty
        ? 0.0
        : completedTasks.length / tasksForToday.length;
    final taskPercentage = (taskProgress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Progress',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
              Text('Today',
                  style: TextStyle(fontSize: 12, color: subTextColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Habits Card
              Expanded(
                child: _buildProgressCard(
                  context,
                  'Habits',
                  habitPercentage,
                  '${completedHabits.length}/${todayHabits.length}',
                  Icons.repeat,
                  isDark
                      ? AppColors.streakGradient
                      : AppColors.lightBlueGradient,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              // Tasks Card
              Expanded(
                child: _buildProgressCard(
                  context,
                  'Tasks',
                  taskPercentage,
                  '${completedTasks.length}/${tasksForToday.length}',
                  Icons.task_alt,
                  isDark
                      ? AppColors.streakGradient
                      : AppColors.lightBlueGradient,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, String title, int percentage,
      String count, IconData icon, LinearGradient gradient, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF64B5F6).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              Text(count,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$percentage%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.black.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStreaks(BuildContext context, HabitProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final habits = provider.habits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text('Active Streaks',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(
            children: [
              _totalStreaksCard(context, provider.totalActiveDays, isDark),
              const SizedBox(width: 16),
              if (habits.isEmpty)
                _emptyStreakCard(context, isDark)
              else
                ...habits.map((habit) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _streakCard(context, habit, isDark),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyStreakCard(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.15);
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;

    return GestureDetector(
      onTap: () => context.push('/new-habit'),
      child: Container(
        width: 112,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, style: BorderStyle.solid),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: subTextColor.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.add, color: subTextColor, size: 24),
            ),
            Text(
              'Add Habit',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: subTextColor),
            ),
            const SizedBox(height: 4),
            Text('Tap to add',
                style: TextStyle(fontSize: 10, color: subTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _totalStreaksCard(BuildContext context, int total, bool isDark) {
    final textColor = isDark ? AppColors.primary : AppColors.pepper;

    return GestureDetector(
      onTap: () => context.push('/streak-calendar'),
      child: Container(
        width: 112,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient:
              isDark ? AppColors.streakGradient : AppColors.lightBlueGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0xFF64B5F6).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: textColor.withValues(alpha: 0.1),
                border: Border.all(color: textColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 15)
                ],
              ),
              child: Icon(Icons.emoji_events, color: textColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text('Total Days',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$total',
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                const SizedBox(width: 4),
                const Icon(Icons.local_fire_department,
                    size: 14, color: Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, HabitProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;

    // Use all pending tasks, sorted by date (urgent first)
    final activeTasks = List<Task>.from(provider.pendingTasks);
    activeTasks.sort((a, b) {
      DateTime getEffectiveTime(Task t) {
        if (t.isAlarmEnabled && t.alarmTime != null) return t.alarmTime!;
        if (t.isReminderOn && t.reminderTime != null) return t.reminderTime!;
        return t.deadline ?? t.createdAt;
      }

      final timeA = getEffectiveTime(a);
      final timeB = getEffectiveTime(b);
      return timeA.compareTo(timeB);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Dashboard',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 16),

          _dashboardCard(
            context: context,
            title: 'My Habits',
            icon: Icons.change_circle,
            badge: '${provider.pendingToday.length} Active',
            isEmpty: provider.pendingToday.isEmpty,
            showAddButton: provider.habits.isEmpty,
            emptyMessage: provider.habits.isEmpty
                ? 'No habits yet'
                : 'Hooray! You have completed your daily habits today',
            onAddTap: () => context.push('/new-habit'),
            isDark: isDark,
            isHabitCard: true,
            children: provider.pendingToday
                .map((habit) => _habitItem(
                      context,
                      habit,
                      () => provider.toggleHabitCompletion(
                          habit.id, DateTime.now()),
                      isDark,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // My Tasks Card
          _dashboardCard(
            context: context,
            title: 'My Tasks',
            icon: Icons.task_alt,
            badge: '${provider.pendingTasks.length} Pending',
            isEmpty: provider.pendingTasks.isEmpty,
            emptyMessage: provider.tasks.isEmpty
                ? 'No tasks yet'
                : 'All tasks completed!',
            showAddButton: true,
            onAddTap: () => context.push('/new-task'),
            isDark: isDark,
            children: (() {
              // 1. Get all pending tasks
              final allPending = List<Task>.from(provider.pendingTasks);

              // 2. Sort by Effective Time (Alarm/Reminder > Deadline > CreatedAt)
              allPending.sort((a, b) {
                DateTime getEffectiveTime(Task t) {
                  if (t.isAlarmEnabled && t.alarmTime != null)
                    return t.alarmTime!;
                  if (t.isReminderOn && t.reminderTime != null)
                    return t.reminderTime!;
                  return t.deadline ?? t.createdAt;
                }

                final timeA = getEffectiveTime(a);
                final timeB = getEffectiveTime(b);
                return timeA.compareTo(timeB);
              });

              return allPending.map((task) {
                return _taskItem(
                  context,
                  task,
                  () => provider.toggleTaskCompletion(task.id),
                  () => context.push('/new-task', extra: task),
                  isDark,
                );
              }).toList();
            })(),
          ),
        ],
      ),
    );
  }

  // Helper for determining date label
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    final diff = inputDate.difference(today).inHours;

    // We use hours to be safe, but actually calculating day difference directly via integer division or day comparison is better
    // Let's stick to the previous robust logic based on calendar days
    if (inputDate.isAtSameMomentAs(today)) return 'Today';

    final differenceDays = inputDate.difference(today).inDays;

    // Check strict calendar days
    if (inputDate.year == today.year &&
        inputDate.month == today.month &&
        inputDate.day == today.day) {
      return 'Today';
    }

    final tomorrow = today.add(const Duration(days: 1));
    if (inputDate.year == tomorrow.year &&
        inputDate.month == tomorrow.month &&
        inputDate.day == tomorrow.day) {
      return 'Tomorrow';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (inputDate.year == yesterday.year &&
        inputDate.month == yesterday.month &&
        inputDate.day == yesterday.day) {
      return 'Yesterday';
    }

    return DateFormat('MMM d').format(date);
  }

  Widget _dashboardCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String badge,
    required bool isEmpty,
    required String emptyMessage,
    bool showAddButton = true,
    required VoidCallback onAddTap,
    required List<Widget> children,
    required bool isDark,
    bool isHabitCard = false,
  }) {
    // Use blue gradient for both in light mode, purple in dark mode
    final gradient =
        isDark ? AppColors.streakGradient : AppColors.lightBlueGradient;

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : const Color(0xFF64B5F6).withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon,
                      size: 18, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEmpty)
            GestureDetector(
              onTap: showAddButton ? onAddTap : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    if (showAddButton) ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Icon(Icons.emoji_events,
                          size: 48, color: Colors.amber.withValues(alpha: 0.9)),
                      const SizedBox(height: 8),
                    ],
                    Text(emptyMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8))),
                    if (showAddButton)
                      Text('Tap to add',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _streakCard(BuildContext context, Habit habit, bool isDark,
      {double opacity = 1.0}) {
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final cardColor = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: () => context.push('/habit/${habit.id}'),
      child: Opacity(
        opacity: habit.currentStreak == 0 ? 0.6 : opacity,
        child: Container(
          width: 112,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: subTextColor.withValues(alpha: 0.3)),
                ),
                child: habit.customEmoji != null
                    ? Center(
                        child: Text(habit.customEmoji!,
                            style: const TextStyle(fontSize: 20)))
                    : Icon(_getIconData(habit.icon),
                        color: textColor, size: 20),
              ),
              Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subTextColor),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department,
                      size: 14, color: AppColors.accentOrange),
                  const SizedBox(width: 4),
                  Text('${habit.currentStreak}',
                      style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: subTextColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskItem(BuildContext context, Task task, VoidCallback onComplete,
      VoidCallback onEdit, bool isDark) {
    // Glass-like gradient colors
    final iconGradient = isDark
        ? [const Color(0xFF7C3AED), const Color(0xFF9333EA)]
        : [const Color(0xFF60A5FA), const Color(0xFF3B82F6)];
    final editGradient = isDark
        ? [const Color(0xFF475569), const Color(0xFF64748B)]
        : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)];
    final checkGradient = isDark
        ? [AppColors.accentCyan, AppColors.accentCyan.withValues(alpha: 0.8)]
        : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Glass-like icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: iconGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient[0].withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: task.customEmoji != null
                      ? Center(
                          child: Text(task.customEmoji!,
                              style: const TextStyle(fontSize: 18)))
                      : Icon(_getIconData(task.icon),
                          size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis),

                      // Metadata Row (Alarm/Reminder/Date)
                      Builder(builder: (context) {
                        final dateLabel =
                            _getDateLabel(task.deadline ?? task.createdAt);
                        final hasAlarm =
                            task.isAlarmEnabled && task.alarmTime != null;
                        final hasReminder =
                            task.isReminderOn && task.reminderTime != null;
                        final time =
                            (hasAlarm ? task.alarmTime : task.reminderTime);

                        return Row(
                          children: [
                            if (hasAlarm) ...[
                              Icon(Icons.alarm,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 4),
                            ],
                            if (hasReminder) ...[
                              Icon(Icons.notifications_active,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 4),
                            ],
                            // Show Description OR Date/Time
                            Expanded(
                              child: Text(
                                (hasAlarm || hasReminder)
                                    ? '$dateLabel • ${_formatTimeAmPm(time!)}'
                                    : (task.description != null &&
                                            task.description!.isNotEmpty)
                                        ? task.description!
                                        : dateLabel, // Fallback to date
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.white.withValues(alpha: 0.85)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glass-like edit button
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: editGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.edit,
                      size: 14,
                      color: isDark ? Colors.white : AppColors.pepper),
                ),
              ),
              // Glass-like complete button
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: checkGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: checkGradient[0].withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _habitItem(
      BuildContext context, Habit habit, VoidCallback onComplete, bool isDark) {
    // Glass-like gradient colors for habits (different from tasks)
    final iconGradient = isDark
        ? [const Color(0xFFEC4899), const Color(0xFFDB2777)]
        : [const Color(0xFFA78BFA), const Color(0xFF8B5CF6)];
    final editGradient = isDark
        ? [const Color(0xFF475569), const Color(0xFF64748B)]
        : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)];

    // Logic to determine which reminder time to show based on progress
    DateTime upcomingReminderTime = (habit.reminderTime ?? DateTime.now());
    if (habit.dailyTarget > 1 &&
        habit.reminderTimes != null &&
        habit.reminderTimes!.isNotEmpty) {
      // For multi-target, show the specific time for the NEXT step
      final count = habit.getCompletionCountOn(DateTime.now());
      int index = count;
      if (index >= habit.reminderTimes!.length) {
        index = habit.reminderTimes!.length - 1;
      }
      upcomingReminderTime = habit.reminderTimes![index];
    } else if (habit.isAlarmEnabled && habit.alarmTime != null) {
      upcomingReminderTime = habit.alarmTime!;
    }
    final checkGradient = isDark
        ? [AppColors.accentCyan, AppColors.accentCyan.withValues(alpha: 0.8)]
        : [const Color(0xFF34D399), const Color(0xFF10B981)];

    return GestureDetector(
      onTap: () => context.push('/habit/${habit.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  // Glass-like icon container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: iconGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: iconGradient[0].withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: habit.customEmoji != null
                        ? Center(
                            child: Text(habit.customEmoji!,
                                style: const TextStyle(fontSize: 18)))
                        : Icon(_getIconData(habit.icon),
                            size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(habit.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (habit.dailyTarget > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${habit.getCompletionCountOn(DateTime.now())}/${habit.dailyTarget}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (habit.isAlarmEnabled ||
                            (habit.isReminderOn && habit.reminderTime != null))
                          Row(
                            children: [
                              if (habit.isAlarmEnabled) ...[
                                const Icon(Icons.alarm,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              if (habit.isReminderOn) ...[
                                const Icon(Icons.notifications_active,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _formatTimeAmPm(upcomingReminderTime),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ],
                          )
                        else if (habit.description != null &&
                            habit.description!.isNotEmpty)
                          Text(habit.description!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8)),
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glass-like edit button
                GestureDetector(
                  onTap: () => context.push('/new-habit', extra: habit),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: editGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.edit,
                        size: 14,
                        color: isDark ? Colors.white : AppColors.pepper),
                  ),
                ),
                // Glass-like complete/add button
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: checkGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: checkGradient[0].withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(habit.dailyTarget > 1 ? Icons.add : Icons.check,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedToday(BuildContext context, HabitProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final cardColor = isDark
        ? AppColors.surface.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.08);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.15);

    final completedHabits = provider.completedToday;
    final completedTasks = provider.completedTasksToday;

    if (completedHabits.isEmpty && completedTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed Today',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text('No habits/tasks completed yet today',
                    style: TextStyle(color: subTextColor, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completed Today',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 16),
          ...completedHabits.map((habit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _completedItem(
                  _getIconData(habit.icon),
                  habit.name,
                  'Habit', // Changed from habit.scheduledTime ?? 'Today'
                  isDark: isDark,
                  onUndo: () =>
                      provider.toggleHabitCompletion(habit.id, DateTime.now()),
                ),
              )),
          ...completedTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _completedItem(
                  _getIconData(task.icon),
                  task.name,
                  'Task',
                  isDark: isDark,
                  onUndo: () => provider.toggleTaskCompletion(task.id),
                ),
              )),
        ],
      ),
    );
  }

  Widget _completedItem(IconData icon, String title, String time,
      {VoidCallback? onUndo, bool isDark = true}) {
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final cardColor = isDark
        ? AppColors.surface.withValues(alpha: 0.5)
        : Colors.grey.withValues(alpha: 0.08);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.15);
    final checkBgColor = isDark ? AppColors.accentCyan : AppColors.accentGreen;
    final checkIconColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Opacity(
              opacity: 0.6,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(icon, color: subTextColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subTextColor,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: subTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(time,
                            style:
                                TextStyle(fontSize: 12, color: subTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onUndo,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: checkBgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15)
                ],
              ),
              child: Icon(Icons.check,
                  size: 18, color: checkIconColor, weight: 700),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _showTaskEditDialog since we use full screen edit sheet now

  IconData _getIconData(IconType icon) {
    switch (icon) {
      case IconType.star:
        return Icons.star;
      case IconType.run:
        return Icons.directions_run;
      case IconType.book:
        return Icons.menu_book;
      case IconType.water:
        return Icons.water_drop;
      case IconType.meditation:
        return Icons.self_improvement;
      case IconType.workout:
        return Icons.fitness_center;
      case IconType.code:
        return Icons.code;
      case IconType.call:
        return Icons.call;
      case IconType.mail:
        return Icons.mail;
      case IconType.shopping:
        return Icons.shopping_cart;
      case IconType.heart:
        return Icons.favorite;
      case IconType.music:
        return Icons.music_note;
      case IconType.sleep:
        return Icons.bedtime;
      case IconType.food:
        return Icons.restaurant;
    }
  }

  String _formatTimeAmPm(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
}
