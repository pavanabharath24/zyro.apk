import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/bottom_nav.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? AppColors.spWhite : AppColors.spDark;
    final subTextColor = isDark
        ? AppColors.spLight
        : AppColors.spDark; // Using dark text for labels in light mode
    final cardColor = isDark ? const Color(0xFF18181b) : AppColors.spWhite;
    final borderColor = isDark ? Colors.white10 : AppColors.spLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Text('Your Progress',
            style: GoogleFonts.inter(
                color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: const [],
      ),
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

          SafeArea(
            bottom: false,
            child: Consumer<HabitProvider>(
              builder: (context, provider, child) {
                // Calculate Date Range
                final now = DateTime.now();
                DateTime startDate, endDate;

                if (_selectedPeriod == 'Weekly') {
                  startDate = now.subtract(Duration(days: now.weekday - 1));
                  endDate = startDate.add(const Duration(days: 6));
                } else if (_selectedPeriod == 'Monthly') {
                  endDate = now;
                  startDate = now.subtract(const Duration(days: 29));
                } else {
                  // All Time
                  endDate = now;
                  if (provider.habits.isNotEmpty) {
                    // Find earliest habit creation if possible, else 90 days apprx
                    // Since we are using ID as timestamp
                    try {
                      final sorted = List<Habit>.from(provider.habits)
                        ..sort((a, b) =>
                            int.parse(a.id).compareTo(int.parse(b.id)));
                      final first = DateTime.fromMillisecondsSinceEpoch(
                          int.parse(sorted.first.id));
                      startDate = first;
                      // Ensure start date is not after end date (sanity check)
                      if (startDate.isAfter(endDate))
                        startDate = endDate.subtract(const Duration(days: 1));
                    } catch (e) {
                      startDate = now.subtract(const Duration(days: 90));
                    }
                  } else {
                    startDate = now.subtract(const Duration(days: 90));
                  }
                }

                // normalize start date to beginning of day
                startDate =
                    DateTime(startDate.year, startDate.month, startDate.day);
                // normalize end date to end of day? No, just compare dates.
                endDate = DateTime(endDate.year, endDate.month, endDate.day);

                final progressMap =
                    provider.getProgressForRange(startDate, endDate);

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Selector
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? AppColors.streakGradient
                                : AppColors.lightBlueGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : const Color(0xFF64B5F6)
                                        .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children:
                                ['Weekly', 'Monthly', 'All Time'].map((p) {
                              final isSelected = _selectedPeriod == p;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedPeriod = p),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      p,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Daily Activity Section (Habits + Tasks with dots)
                      _buildDailyActivitySection(
                          context,
                          provider,
                          progressMap,
                          isDark,
                          cardColor,
                          borderColor,
                          textColor,
                          subTextColor),

                      // Overview Section REMOVED as per user request
                      // Padding(
                      //   padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      //   child: Text('Overview',
                      //       style: GoogleFonts.inter(
                      //           fontSize: 18,
                      //           fontWeight: FontWeight.bold,
                      //           color: textColor)),
                      // ),
                      // _buildOverviewCards(provider, progressMap, isDark,
                      //     cardColor, borderColor, textColor, subTextColor),

                      // Habit Progress Section (Replaces Consistency)
                      _buildHabitProgressSection(context, progressMap, isDark,
                          cardColor, borderColor, textColor, subTextColor),

                      // Task Progress Section (assignment-style for Tasks)
                      _buildTaskProgressSection(context, provider, isDark,
                          cardColor, borderColor, textColor, subTextColor),

                      // Next Milestone
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text('Next Milestone',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                      ),
                      _buildMilestoneCard(provider, isDark, cardColor,
                          borderColor, textColor, subTextColor),
                    ],
                  ),
                );
              },
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(activePath: '/stats'),
          ),
        ],
      ),
    );
  }

  // DAILY ACTIVITY SECTION - Combined Habits and Tasks with dot visualization
  Widget _buildDailyActivitySection(
      BuildContext context,
      HabitProvider provider,
      Map<int, DayProgress> progressMap,
      bool isDark,
      Color cardBg,
      Color border,
      Color text,
      Color subText) {
    final sortedKeys = progressMap.keys.toList()..sort();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Helper to build a single day column for habits
    Widget buildHabitDayColumn(int key) {
      final data = progressMap[key]!;
      final date = data.date;
      final dayName = dayNames[date.weekday - 1];
      final displayLabel =
          _selectedPeriod == 'Weekly' ? dayName : '${date.day}/${date.month}';

      final total = data.scheduled;
      final completed = data.completed;
      final showTotal = total == 0 ? 3 : total.clamp(1, 9);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Column(
          children: [
            SizedBox(
              width: 28,
              child: Center(
                  child: Text(displayLabel,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color:
                              data.isToday ? Colors.white : Colors.white70))),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 28,
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                alignment: WrapAlignment.center,
                children: List.generate(showTotal, (i) {
                  bool isFilled = i < completed;
                  return Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? (isDark ? AppColors.spWhite : AppColors.spDark)
                          : (isDark ? Colors.white10 : AppColors.spLight),
                      shape: BoxShape.circle,
                      border: isFilled
                          ? null
                          : Border.all(color: border, width: 0.5),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Text('$completed/$total',
                style: GoogleFonts.inter(fontSize: 8, color: Colors.white70)),
          ],
        ),
      );
    }

    // Helper to build a single day column for tasks
    Widget buildTaskDayColumn(int key, DateTime date) {
      final data = progressMap[key]!;
      final dayName = dayNames[date.weekday - 1];
      final displayLabel =
          _selectedPeriod == 'Weekly' ? dayName : '${date.day}/${date.month}';

      final total = data.totalTasks; // Optimized access
      final completed = data.completedTasks; // Optimized access
      final showTotal = total == 0 ? 3 : total.clamp(1, 9);
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Column(
          children: [
            SizedBox(
              width: 28,
              child: Center(
                  child: Text(displayLabel,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isToday ? Colors.white : Colors.white70))),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 28,
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                alignment: WrapAlignment.center,
                children: List.generate(showTotal, (i) {
                  bool isFilled = i < completed;
                  return Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? (isDark ? Colors.greenAccent : Colors.green)
                          : (isDark ? Colors.white10 : AppColors.spLight),
                      shape: BoxShape.circle,
                      border: isFilled
                          ? null
                          : Border.all(color: border, width: 0.5),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Text('$completed/$total',
                style: GoogleFonts.inter(fontSize: 8, color: Colors.white70)),
          ],
        ),
      );
    }

    // Calculate aggregate percentages
    int totalHabitScheduled = 0;
    int totalHabitCompleted = 0;
    progressMap.forEach((_, v) {
      totalHabitScheduled += v.scheduled;
      totalHabitCompleted += v.completed;
    });
    final habitPercentage = totalHabitScheduled == 0
        ? 0
        : ((totalHabitCompleted / totalHabitScheduled) * 100).toInt();

    int totalTasks = 0;
    int totalTasksCompleted = 0;
    progressMap.forEach((_, v) {
      totalTasks += v.totalTasks;
      totalTasksCompleted += v.completedTasks;
    });

    final taskPercentage = totalTasks == 0
        ? 0
        : ((totalTasksCompleted / totalTasks) * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Daily Activity',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold, color: text)),
            GestureDetector(
              onTap: () => context.push('/daily-flow-details'),
              child: Icon(Icons.arrow_forward, size: 20, color: subText),
            )
          ]),
          const SizedBox(height: 12),

          // Habits Card
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.streakGradient
                  : AppColors.lightBlueGradient,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.repeat,
                              size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text('Habits',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                    Text('$habitPercentage%',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                _selectedPeriod == 'Weekly'
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: sortedKeys
                            .map((key) => buildHabitDayColumn(key))
                            .toList(),
                      )
                    : _buildHabitsGraph(
                        sortedKeys, progressMap, isDark, subText, text),
              ],
            ),
          ),

          // Tasks Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.streakGradient
                  : AppColors.lightBlueGradient,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline,
                              size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text('Tasks',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                    Text('$taskPercentage%',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                _selectedPeriod == 'Weekly'
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: sortedKeys.map((key) {
                          final data = progressMap[key]!;
                          return buildTaskDayColumn(key, data.date);
                        }).toList(),
                      )
                    : _buildTasksGraph(sortedKeys, progressMap, isDark, subText,
                        text, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Habits Line Graph for Monthly/All Time
  Widget _buildHabitsGraph(
      List<int> sortedKeys,
      Map<int, DayProgress> progressMap,
      bool isDark,
      Color subText,
      Color text) {
    final lineColor =
        isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00ACC1);

    // Calculate completion rate for each day (as percentage)
    final List<_GraphDataPoint> dataPoints = sortedKeys.map((k) {
      final data = progressMap[k]!;
      final rate = data.scheduled > 0
          ? (data.completed / data.scheduled * 100).clamp(0.0, 100.0).toDouble()
          : 0.0;
      return _GraphDataPoint(date: data.date, value: rate);
    }).toList();

    return _buildAxisGraph(
        dataPoints, lineColor, isDark, subText, 'Completion Rate');
  }

  // Build Tasks Line Graph for Monthly/All Time
  Widget _buildTasksGraph(
      List<int> sortedKeys,
      Map<int, DayProgress> progressMap,
      bool isDark,
      Color subText,
      Color text,
      HabitProvider provider) {
    final lineColor =
        isDark ? const Color(0xFFFF7043) : const Color(0xFFFF5722);

    // Calculate completion rate for each day based on TASKS, not habits
    final List<_GraphDataPoint> dataPoints = sortedKeys.map((k) {
      final dayData = progressMap[k]!; // Access pre-calculated data
      final total = dayData.totalTasks;
      final completed = dayData.completedTasks;

      final rate = total > 0
          ? (completed / total * 100).clamp(0.0, 100.0).toDouble()
          : 0.0;
      return _GraphDataPoint(date: dayData.date, value: rate);
    }).toList();

    return _buildAxisGraph(
        dataPoints, lineColor, isDark, subText, 'Completion Rate');
  }

  // New axis-based graph widget (now interactive)
  Widget _buildAxisGraph(List<_GraphDataPoint> dataPoints, Color lineColor,
      bool isDark, Color subText, String label) {
    if (dataPoints.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Text(
          'No data available',
          style: GoogleFonts.inter(
              fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
        ),
      );
    }

    // Y-axis labels
    final yLabels = ['100%', '75%', '50%', '25%', '0%'];

    // Select X-axis date labels (pick 5 evenly spaced points)
    List<String> xLabels = [];
    if (dataPoints.length >= 5) {
      final step = (dataPoints.length - 1) / 4;
      for (int i = 0; i < 5; i++) {
        final idx = (i * step).round().clamp(0, dataPoints.length - 1);
        final date = dataPoints[idx].date;
        xLabels.add('${_getMonthAbbr(date.month)} ${date.day}');
      }
    } else {
      for (int i = 0; i < dataPoints.length; i++) {
        final date = dataPoints[i].date;
        xLabels.add('${_getMonthAbbr(date.month)} ${date.day}');
      }
    }

    return Container(
      height: 180, // Slightly taller to accommodate tooltip
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white
                .withValues(alpha: 0.9), // White bg for graph in light mode
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y-axis labels
          SizedBox(
            width: 36,
            child: Padding(
              padding: const EdgeInsets.only(top: 24), // Space for tooltip
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: yLabels
                    .map((l) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(l,
                              style: GoogleFonts.inter(
                                  fontSize: 9, color: subText)),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Graph area with interactivity
          Expanded(
            child: Column(
              children: [
                // Interactive Graph
                Expanded(
                  child: _InteractiveGraph(
                    dataPoints: dataPoints,
                    lineColor: lineColor,
                    isDark: isDark,
                    subText: subText,
                  ),
                ),
                const SizedBox(height: 4),
                // X-axis labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: xLabels
                      .map((l) => Text(
                            l,
                            style:
                                GoogleFonts.inter(fontSize: 9, color: subText),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // HABIT PROGRESS SECTION - assignment-style for Habits
  Widget _buildHabitProgressSection(
      BuildContext context,
      Map<int, DayProgress> progressMap,
      bool isDark,
      Color cardBg,
      Color border,
      Color text,
      Color subText) {
    int totalScheduled = 0;
    int totalCompleted = 0;
    progressMap.forEach((_, v) {
      totalScheduled += v.scheduled;
      totalCompleted += v.completed;
    });

    final completionRate =
        totalScheduled > 0 ? (totalCompleted / totalScheduled) : 0.0;
    final pending = totalScheduled - totalCompleted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Habit Progress',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.bold, color: text)),
              IconButton(
                onPressed: () =>
                    context.push('/daily-flow-details', extra: 'habit'),
                icon: Icon(Icons.arrow_forward_rounded, color: text),
                tooltip: 'View History',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.streakGradient
                  : AppColors.lightBlueGradient,
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
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.repeat,
                              size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text('Overview',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$totalScheduled Scheduled',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 12,
                    backgroundColor:
                        isDark ? Colors.white10 : AppColors.spLight,
                    color: isDark
                        ? const Color(0xFF4DD0E1)
                        : const Color(0xFF00ACC1),
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Completed
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle,
                              size: 18,
                              color: isDark ? Colors.tealAccent : Colors.teal),
                        ),
                        const SizedBox(height: 4),
                        Text('$totalCompleted',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Done',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 50,
                      color: border,
                    ),
                    // Pending
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.hourglass_bottom,
                              size: 18,
                              color:
                                  isDark ? Colors.orangeAccent : Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text('$pending',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Pending',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 50,
                      color: border,
                    ),
                    // Rate
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.pie_chart,
                              size: 18,
                              color:
                                  isDark ? Colors.purpleAccent : Colors.purple),
                        ),
                        const SizedBox(height: 4),
                        Text('${(completionRate * 100).toInt()}%',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Rate',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TASK PROGRESS SECTION - new assignment-style visualization
  Widget _buildTaskProgressSection(BuildContext context, HabitProvider provider,
      bool isDark, Color cardBg, Color border, Color text, Color subText) {
    // Get tasks based on period
    final now = DateTime.now();
    List<Task> periodTasks;
    String periodLabel;

    if (_selectedPeriod == 'Weekly') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      periodTasks = provider.tasks.where((t) {
        final diff = t.createdAt.difference(weekStart).inDays;
        return diff >= 0 && diff < 7;
      }).toList();
      periodLabel = 'This Week';
    } else if (_selectedPeriod == 'Monthly') {
      periodTasks = provider.tasks.where((t) {
        return t.createdAt.month == now.month && t.createdAt.year == now.year;
      }).toList();
      periodLabel = 'This Month';
    } else {
      periodTasks = provider.tasks;
      periodLabel = 'All Time';
    }

    final totalTasks = periodTasks.length;
    final completedTasks = periodTasks.where((t) => t.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Task Progress',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold, color: text)),
            GestureDetector(
              onTap: () => context.push('/daily-flow-details', extra: 'task'),
              child: Icon(Icons.arrow_forward, size: 20, color: subText),
            )
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.streakGradient
                  : AppColors.lightBlueGradient,
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
              children: [
                // Header with period label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment,
                              size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(periodLabel,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$totalTasks Tasks',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 12,
                    backgroundColor:
                        isDark ? Colors.white10 : AppColors.spLight,
                    color: isDark ? Colors.greenAccent : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Completed
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle,
                              size: 18,
                              color: isDark ? Colors.tealAccent : Colors.teal),
                        ),
                        const SizedBox(height: 4),
                        Text('$completedTasks',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Done',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white70)),
                      ],
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 50,
                      color: border,
                    ),

                    // Pending
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.pending_actions,
                              size: 18,
                              color:
                                  isDark ? Colors.orangeAccent : Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text('$pendingTasks',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Pending',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white70)),
                      ],
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 50,
                      color: border,
                    ),

                    // Rate
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.pie_chart,
                              size: 18,
                              color:
                                  isDark ? Colors.purpleAccent : Colors.purple),
                        ),
                        const SizedBox(height: 4),
                        Text('${(completionRate * 100).toInt()}%',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Rate',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(HabitProvider provider, bool isDark, Color cardBg,
      Color border, Color text, Color subText) {
    int currentStreak = provider.totalActiveDays;

    // PUBG-style ranks with custom icons and requirements
    final milestones = [
      {
        'name': 'Bronze',
        'icon': Icons.shield_outlined,
        'days': 3,
        'color': const Color(0xFFCD7F32)
      },
      {
        'name': 'Silver',
        'icon': Icons.shield,
        'days': 7,
        'color': isDark ? const Color(0xFFC0C0C0) : const Color(0xFF757575)
      },
      {
        'name': 'Gold',
        'icon': Icons.workspace_premium_outlined,
        'days': 14,
        'color': isDark ? const Color(0xFFFFD700) : const Color(0xFFFBC02D)
      },
      {
        'name': 'Platinum',
        'icon': Icons.diamond_outlined,
        'days': 21,
        'color': const Color(0xFF00CED1)
      },
      {
        'name': 'Diamond',
        'icon': Icons.diamond,
        'days': 30,
        'color': const Color(0xFF00BFFF)
      },
      {
        'name': 'Crown',
        'icon': Icons.emoji_events_outlined,
        'days': 50,
        'color': const Color(0xFFFFAA00)
      },
      {
        'name': 'Ace',
        'icon': Icons.military_tech,
        'days': 75,
        'color': const Color(0xFFFF6B6B)
      },
      {
        'name': 'Master',
        'icon': Icons.stars,
        'days': 100,
        'color': const Color(0xFFE040FB)
      },
      {
        'name': 'Grandmaster',
        'icon': Icons.auto_awesome,
        'days': 150,
        'color': const Color(0xFF7C4DFF)
      },
      {
        'name': 'Legend',
        'icon': Icons.emoji_events,
        'days': 200,
        'color': const Color(0xFFFF5722)
      },
      {
        'name': 'Mythic',
        'icon': Icons.flare,
        'days': 300,
        'color': const Color(0xFFE91E63)
      },
      {
        'name': 'Immortal',
        'icon': Icons.whatshot,
        'days': 365,
        'color': const Color(0xFF9C27B0)
      },
      {
        'name': 'Conqueror',
        'icon': Icons.bolt,
        'days': 500,
        'color': const Color(0xFFFF1744)
      },
    ];

    // Find current and next rank
    int currentRankIndex = -1;
    for (int i = milestones.length - 1; i >= 0; i--) {
      if (currentStreak >= (milestones[i]['days'] as int)) {
        currentRankIndex = i;
        break;
      }
    }

    final nextRankIndex = currentRankIndex + 1;
    final nextRank =
        nextRankIndex < milestones.length ? milestones[nextRankIndex] : null;
    final daysToNext =
        nextRank != null ? (nextRank['days'] as int) - currentStreak : 0;
    final progressToNext =
        nextRank != null ? currentStreak / (nextRank['days'] as int) : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Progress Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentRankIndex >= 0
                    ? [
                        (milestones[currentRankIndex]['color'] as Color)
                            .withValues(alpha: 0.3),
                        (milestones[currentRankIndex]['color'] as Color)
                            .withValues(alpha: 0.1),
                      ]
                    : [
                        Colors.grey.withValues(alpha: 0.2),
                        Colors.grey.withValues(alpha: 0.1)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: currentRankIndex >= 0
                    ? (milestones[currentRankIndex]['color'] as Color)
                        .withValues(alpha: 0.5)
                    : border,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Current rank badge
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentRankIndex >= 0
                              ? [
                                  (milestones[currentRankIndex]['color']
                                      as Color),
                                  (milestones[currentRankIndex]['color']
                                          as Color)
                                      .withValues(alpha: 0.7),
                                ]
                              : [Colors.grey, Colors.grey.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (currentRankIndex >= 0
                                    ? milestones[currentRankIndex]['color']
                                        as Color
                                    : Colors.grey)
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          currentRankIndex >= 0
                              ? milestones[currentRankIndex]['icon'] as IconData
                              : Icons.eco_outlined,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentRankIndex >= 0
                                    ? milestones[currentRankIndex]['name']
                                        as String
                                    : 'Beginner',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: text,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.lock_open,
                                  size: 16,
                                  color: currentRankIndex >= 0
                                      ? milestones[currentRankIndex]['color']
                                          as Color
                                      : Colors.grey),
                            ],
                          ),
                          Text(
                            '$currentStreak days active',
                            style:
                                GoogleFonts.inter(fontSize: 12, color: subText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (nextRank != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Next: ${nextRank['name']}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: nextRank['color'] as Color,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      nextRank['icon'] as IconData,
                                      size: 14,
                                      color: nextRank['color'] as Color,
                                    ),
                                  ],
                                ),
                                Text(
                                  '$daysToNext days left',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: subText),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressToNext,
                                minHeight: 6,
                                color: nextRank['color'] as Color,
                                backgroundColor: (nextRank['color'] as Color)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (provider.hasUnclaimedRank) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.claimRank();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Rank Claimed: ${milestones[currentRankIndex]['name']}!'),
                            backgroundColor:
                                milestones[currentRankIndex]['color'] as Color,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            milestones[currentRankIndex]['color'] as Color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor:
                            (milestones[currentRankIndex]['color'] as Color)
                                .withValues(alpha: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Claim New Rank!',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // All Ranks Horizontal Scroll
          Text('All Ranks',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: milestones.length,
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                final isUnlocked = currentStreak >= (milestone['days'] as int);
                final isCurrent = index == currentRankIndex;
                final rankColor = milestone['color'] as Color;

                return Container(
                  width: 75,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUnlocked
                                ? [rankColor, rankColor.withValues(alpha: 0.7)]
                                : [
                                    rankColor.withValues(
                                        alpha:
                                            0.3), // Restored Crystal Gradient
                                    rankColor.withValues(alpha: 0.15),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrent
                              ? Border.all(color: Colors.white, width: 2)
                              : Border.all(
                                  color: isUnlocked
                                      ? rankColor.withValues(alpha: 0.8)
                                      : rankColor.withValues(
                                          alpha: 0.5), // Colored border
                                  width: 1),
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: rankColor.withValues(
                                        alpha: isDark ? 0.6 : 0.4),
                                    blurRadius: isDark ? 8 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: rankColor.withValues(
                                        alpha: 0.2), // Colored shadow
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                milestone['icon'] as IconData,
                                size: 26,
                                color: isUnlocked
                                    ? Colors.white
                                    : rankColor.withValues(
                                        alpha:
                                            0.9), // Colored icon for Crystal look
                              ),
                            ),
                            if (!isUnlocked)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: rankColor.withValues(
                                        alpha: 0.8), // Colored lock bg
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                            if (isUnlocked)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        milestone['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight:
                              isUnlocked ? FontWeight.bold : FontWeight.w600,
                          color: isUnlocked
                              ? rankColor
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : text), // Use dark text in light mode
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${milestone['days']}d',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: isUnlocked
                              ? subText
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : subText), // Use dark subtext in light mode
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Data point for the axis graph
class _GraphDataPoint {
  final DateTime date;
  final double value; // 0-100 percentage

  _GraphDataPoint({required this.date, required this.value});
}

// Interactive graph widget with tooltip on touch
class _InteractiveGraph extends StatefulWidget {
  final List<_GraphDataPoint> dataPoints;
  final Color lineColor;
  final bool isDark;
  final Color subText;

  const _InteractiveGraph({
    required this.dataPoints,
    required this.lineColor,
    required this.isDark,
    required this.subText,
  });

  @override
  State<_InteractiveGraph> createState() => _InteractiveGraphState();
}

class _InteractiveGraphState extends State<_InteractiveGraph> {
  int? _selectedIndex;

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final graphWidth = constraints.maxWidth;
    final x = details.localPosition.dx.clamp(0.0, graphWidth);

    // Calculate which data point is nearest
    final pointWidth = graphWidth / (widget.dataPoints.length - 1);
    final index =
        (x / pointWidth).round().clamp(0, widget.dataPoints.length - 1);

    setState(() {
      _selectedIndex = index;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Keep showing tooltip for 1 second after release
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _selectedIndex = null;
        });
      }
    });
  }

  void _onTapUp(TapUpDetails details, BoxConstraints constraints) {
    final graphWidth = constraints.maxWidth;
    final x = details.localPosition.dx.clamp(0.0, graphWidth);

    final pointWidth = graphWidth / (widget.dataPoints.length - 1);
    final index =
        (x / pointWidth).round().clamp(0, widget.dataPoints.length - 1);

    setState(() {
      _selectedIndex = index;
    });

    // Hide after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _selectedIndex = null;
        });
      }
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details, constraints),
          onPanEnd: _onPanEnd,
          onTapUp: (details) => _onTapUp(details, constraints),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The actual graph
              Positioned.fill(
                top: 24, // Leave space for tooltip at top
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _AxisGraphPainter(
                    dataPoints: widget.dataPoints,
                    lineColor: widget.lineColor,
                    gridColor:
                        widget.isDark ? Colors.white12 : Colors.grey[400]!,
                    isDark: widget.isDark,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),

              // Tooltip
              if (_selectedIndex != null &&
                  _selectedIndex! < widget.dataPoints.length)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            widget.isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.dataPoints[_selectedIndex!].value.toStringAsFixed(0)}% | ${_formatDate(widget.dataPoints[_selectedIndex!].date)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Axis Graph Painter with grid lines and percentage scale
class _AxisGraphPainter extends CustomPainter {
  final List<_GraphDataPoint> dataPoints;
  final Color lineColor;
  final Color gridColor;
  final bool isDark;
  final int? selectedIndex;

  _AxisGraphPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.gridColor,
    required this.isDark,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal dashed grid lines at 0%, 25%, 50%, 75%, 100%
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (dataPoints.length < 2) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final pointWidth = size.width / (dataPoints.length - 1);
    final linePath = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * pointWidth;
      // Value is 0-100, map to height (100% at top, 0% at bottom)
      final normalizedValue = dataPoints[i].value / 100;
      final y = size.height - (normalizedValue * size.height);

      final point = Offset(x, y.clamp(0, size.height));
      points.add(point);

      if (i == 0) {
        linePath.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, size.height);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    // Complete the fill path
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Draw fill first, then line on top
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // Draw dots for key points (not all, just a few for clarity)
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = isDark ? Colors.black : Colors.white
      ..style = PaintingStyle.fill;

    // Draw dots at start, end, and highest point
    if (points.isNotEmpty) {
      // Find highest value point
      int maxIdx = 0;
      double maxVal = 0;
      for (int i = 0; i < dataPoints.length; i++) {
        if (dataPoints[i].value > maxVal) {
          maxVal = dataPoints[i].value;
          maxIdx = i;
        }
      }

      // Draw key dots
      final keyIndices = <int>{0, maxIdx, points.length - 1};
      for (final idx in keyIndices) {
        if (idx < points.length) {
          canvas.drawCircle(points[idx], 4, dotBorderPaint);
          canvas.drawCircle(points[idx], 3, dotPaint);
        }
      }
    }

    // Draw selection indicator (vertical line + larger dot)
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];

      // Vertical line from top to bottom
      final selectionLinePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(selectedPoint.dx, 0),
        Offset(selectedPoint.dx, size.height),
        selectionLinePaint,
      );

      // Large dot at the selected point
      canvas.drawCircle(selectedPoint, 6, dotBorderPaint);
      canvas.drawCircle(selectedPoint, 5, dotPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final distance = (end - start).distance;
    final dx = (end.dx - start.dx) / distance;
    final dy = (end.dy - start.dy) / distance;

    double currentX = start.dx;
    double currentY = start.dy;
    double drawn = 0;

    while (drawn < distance) {
      final drawEnd = (drawn + dashWidth).clamp(0, distance);
      canvas.drawLine(
        Offset(currentX, currentY),
        Offset(start.dx + dx * drawEnd, start.dy + dy * drawEnd),
        paint,
      );
      drawn += dashWidth + dashSpace;
      currentX = start.dx + dx * drawn;
      currentY = start.dy + dy * drawn;
    }
  }

  @override
  bool shouldRepaint(covariant _AxisGraphPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor;
  }
}
