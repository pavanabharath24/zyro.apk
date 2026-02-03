import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class DailyFlowDetailsScreen extends StatelessWidget {
  final String? filter; // 'habit' or 'task'

  const DailyFlowDetailsScreen({super.key, this.filter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF18181b) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    String title = 'Activity Log';
    if (filter == 'habit') title = 'Habit Activity Log';
    if (filter == 'task') title = 'Task Activity Log';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          title,
          style:
              GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();

          // 1. Calculate Start Date from First Habit or Task
          DateTime startDate = now;
          bool hasHistory = false;

          // Check Habits
          if (filter == null || filter == 'habit') {
            if (provider.habits.isNotEmpty) {
              try {
                final sorted = List<Habit>.from(provider.habits)
                  ..sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
                final firstHabitDate = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(sorted.first.id));
                startDate = firstHabitDate;
                hasHistory = true;
              } catch (e) {
                debugPrint("Error parsing habit date: $e");
              }
            }
          }

          // Check Tasks
          if (filter == null || filter == 'task') {
            if (provider.tasks.isNotEmpty) {
              try {
                final sortedTasks = List<Task>.from(provider.tasks)
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                final firstTaskDate = sortedTasks.first.createdAt;

                if (!hasHistory || firstTaskDate.isBefore(startDate)) {
                  startDate = firstTaskDate;
                  hasHistory = true;
                }
              } catch (e) {
                debugPrint("Error parsing task date: $e");
              }
            }
          }

          // If no history found, just show this week
          if (!hasHistory) {
            startDate = now.subtract(const Duration(days: 6));
          }

          // Safety: If startDate is in future (e.g. clock skew), cap at now
          if (startDate.isAfter(now)) startDate = now;

          // Calculate days count
          final start =
              DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(now.year, now.month, now.day);
          final daysCount = end.difference(start).inDays + 1;

          final dates =
              List.generate(daysCount, (i) => end.subtract(Duration(days: i)));

          if (dates.isEmpty) {
            return Center(
                child: Text("No activity yet",
                    style: GoogleFonts.inter(color: subTextColor)));
          }

          // Optimized: Fetch all progress in one go using the cached provider logic
          final progressMap = provider.getProgressForRange(start, end);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isYesterday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day - 1;

              String dateLabel;
              if (isToday) {
                dateLabel = "Today";
              } else if (isYesterday) {
                dateLabel = "Yesterday";
              } else {
                dateLabel = DateFormat('EEEE, MMM d').format(date);
              }

              // Optimized: Access pre-calculated data
              // The key in progressMap is the offset from startDate
              final dayOffset = date.difference(start).inDays;
              final dayData = progressMap[dayOffset];

              // Default to 0 if something goes wrong (shouldn't happen)
              int scheduledHabits = dayData?.scheduled ?? 0;
              int completedHabits = dayData?.completed ?? 0;
              int totalTasks = dayData?.totalTasks ?? 0;
              int completedTasks = dayData?.completedTasks ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () =>
                      _showDayDetailsSheet(context, provider, date, isDark),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Line
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? (isDark ? Colors.white : Colors.black)
                                    : subTextColor.withValues(alpha: 0.5),
                                border: Border.all(color: bgColor, width: 2)),
                          ),
                          Container(
                            width: 2,
                            height: 80, // Dynamic?
                            color: subTextColor.withValues(alpha: 0.2),
                          )
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Habits Card
                                if (filter == null || filter == 'habit')
                                  Expanded(
                                      child: _buildStatCard(
                                          context,
                                          'Habits',
                                          completedHabits,
                                          scheduledHabits,
                                          Icons.repeat,
                                          isDark,
                                          isHabit: true)),
                                if (filter == null) const SizedBox(width: 12),
                                // Tasks Card
                                if (filter == null || filter == 'task')
                                  Expanded(
                                      child: _buildStatCard(
                                          context,
                                          'Tasks',
                                          completedTasks,
                                          totalTasks,
                                          Icons.check_circle_outline,
                                          isDark,
                                          isHabit: false)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDayDetailsSheet(BuildContext context, HabitProvider provider,
      DateTime date, bool isDark) {
    final bgColor = isDark ? const Color(0xFF18181b) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final dateLabel = DateFormat('EEEE, MMM d').format(date);

    final habits = provider.habits.where((h) => h.isScheduledOn(date)).toList();
    final tasks = provider.tasks.where((t) {
      if (t.deadline != null) {
        return _isSameDay(t.deadline!, date);
      }
      return _isSameDay(t.createdAt, date);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subTextColor!.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLabel,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          )),
                      Text('Day History',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: subTextColor,
                          )),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if ((filter == null || filter == 'habit') &&
                      habits.isNotEmpty) ...[
                    Text('HABITS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subTextColor,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 12),
                    ...habits.map((habit) {
                      final isCompleted = habit.isCompletedOn(date);
                      return _buildHistoryItem(
                        context,
                        habit.name,
                        isCompleted,
                        () => provider.toggleHabitCompletion(habit.id, date),
                        isDark,
                        Icons.repeat,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  if ((filter == null || filter == 'task') &&
                      tasks.isNotEmpty) ...[
                    Text('TASKS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subTextColor,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 12),
                    ...tasks.map((task) {
                      // Note: for tasks, we check if it was completed AT ANY TIME
                      // but if the user wants to mark it "for this day",
                      // it's tricky because tasks are usually one-off.
                      // However, to support common user intuition ("I did this on Wed"):
                      return _buildHistoryItem(
                        context,
                        task.name,
                        task.isCompleted,
                        () =>
                            provider.toggleTaskCompletion(task.id, date: date),
                        isDark,
                        Icons.check_circle_outline,
                      );
                    }),
                  ],
                  if (habits.isEmpty && tasks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text('No activity scheduled for this day',
                            style: GoogleFonts.inter(color: subTextColor)),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String name, bool isCompleted,
      VoidCallback onToggle, bool isDark, IconData icon) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: subColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isCompleted,
              onChanged: (_) => onToggle(),
              activeTrackColor: Colors.purpleAccent,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildStatCard(BuildContext context, String title, int completed,
      int total, IconData icon, bool isDark,
      {required bool isHabit}) {
    final bgColor = isDark ? const Color(0xFF27272A) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

    double progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subColor)),
              Icon(icon, size: 14, color: subColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isHabit)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: subColor!.withValues(alpha: 0.2),
                    color: textColor,
                    strokeCap: StrokeCap.round,
                  ),
                )
              else
                Icon(Icons.check,
                    size: 24,
                    color: total > 0 && completed == total
                        ? Colors.green
                        : textColor),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$completed/$total',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text(isHabit ? 'Done' : 'Completed',
                      style: GoogleFonts.inter(fontSize: 10, color: subColor)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
