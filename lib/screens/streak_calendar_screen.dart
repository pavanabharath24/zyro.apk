import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../providers/habit_provider.dart';

import '../theme/colors.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final cardColor = isDark ? AppColors.surface : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient:
            isDark ? AppColors.pageGradientDark : AppColors.pageGradientLight,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Streak Calendar',
            style: GoogleFonts.inter(
                color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Consumer<HabitProvider>(
            builder: (context, provider, child) {
              final totalDays = provider.totalActiveDays;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Streak Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF16213E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$totalDays',
                                    style: GoogleFonts.inter(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.local_fire_department,
                                    size: 36,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Days',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Decorative dots around the streak
                          _buildStreakDots(provider),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Calendar Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        border: isDark
                            ? null
                            : Border.all(
                                color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          // Month Navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMMM').format(_currentMonth),
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chevron_left,
                                        color: subTextColor),
                                    onPressed: _previousMonth,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right,
                                        color: subTextColor),
                                    onPressed: _nextMonth,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Weekday Headers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                .map((day) => SizedBox(
                                      width: 40,
                                      child: Center(
                                        child: Text(day,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: subTextColor)),
                                      ),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 12),

                          // Calendar Grid
                          _buildCalendarGrid(
                              provider, textColor, subTextColor, isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Legend
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        border: isDark
                            ? null
                            : Border.all(
                                color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Legend',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 20,
                            runSpacing: 16,
                            children: [
                              // Full completion - circular fire indicator with rotating flames
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Full circular fire indicator like day 31
                                  CircularFireIndicator(
                                    totalHabits: 1,
                                    completedHabits: 1,
                                    isFullStreak: true,
                                    hasPartial: false,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('All completed',
                                      style: GoogleFonts.inter(
                                          fontSize: 12, color: subTextColor)),
                                ],
                              ),
                              // Partial completion
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Some completed',
                                      style: GoogleFonts.inter(
                                          fontSize: 12, color: subTextColor)),
                                ],
                              ),
                              // No completion - gray fire
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Missed',
                                      style: GoogleFonts.inter(
                                          fontSize: 12, color: subTextColor)),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStreakDots(HabitProvider provider) {
    final habits = provider.habits;
    final today = DateTime.now();

    return SizedBox(
      width: 80,
      height: 80,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: habits.take(9).map((habit) {
          final isCompleted = habit.isCompletedOn(today);
          return isCompleted
              ? const Icon(
                  Icons.local_fire_department,
                  size: 18,
                  color: Colors.orange,
                )
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(HabitProvider provider, Color textColor,
      Color subTextColor, bool isDark) {
    final now = DateTime.now();
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Calculate padding for first week (Monday = 1, Sunday = 7)
    int startingWeekday = firstDayOfMonth.weekday;
    int leadingEmptyDays = startingWeekday - 1;

    final totalCells = leadingEmptyDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - leadingEmptyDays + 1;

              if (cellIndex < leadingEmptyDays || dayNumber > daysInMonth) {
                return const SizedBox(width: 40, height: 50);
              }

              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isFuture = date.isAfter(now);
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return _buildDayCell(
                provider,
                date,
                dayNumber,
                isFuture,
                isToday,
                textColor,
                subTextColor,
                isDark,
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(
    HabitProvider provider,
    DateTime date,
    int dayNumber,
    bool isFuture,
    bool isToday,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    // Get habits scheduled for this day
    final scheduledHabits =
        provider.habits.where((h) => h.isScheduledOn(date)).toList();
    final completedHabits =
        scheduledHabits.where((h) => h.isCompletedOn(date)).toList();

    final totalScheduled = scheduledHabits.length;
    final totalCompleted = completedHabits.length;

    // Check if this is a "streak day" (all habits completed)
    final isFullStreak = totalScheduled > 0 && totalCompleted == totalScheduled;
    final hasPartial = totalCompleted > 0 && totalCompleted < totalScheduled;

    return SizedBox(
      width: 44,
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number at top
          Text(
            '$dayNumber',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: isFuture
                  ? subTextColor.withValues(alpha: 0.4)
                  : isToday
                      ? (isDark ? Colors.white : Colors.black)
                      : textColor,
            ),
          ),
          const SizedBox(height: 2),
          // Circular Fire Indicator
          if (!isFuture && totalScheduled > 0)
            CircularFireIndicator(
              totalHabits: totalScheduled,
              completedHabits: totalCompleted,
              isFullStreak: isFullStreak,
              hasPartial: hasPartial,
              size: 36,
            )
          else if (!isFuture)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Custom circular fire indicator widget with rotation animation
class CircularFireIndicator extends StatefulWidget {
  final int totalHabits;
  final int completedHabits;
  final bool isFullStreak;
  final bool hasPartial;
  final double size;

  const CircularFireIndicator({
    super.key,
    required this.totalHabits,
    required this.completedHabits,
    required this.isFullStreak,
    required this.hasPartial,
    this.size = 40,
  });

  @override
  State<CircularFireIndicator> createState() => _CircularFireIndicatorState();
}

class _CircularFireIndicatorState extends State<CircularFireIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    // Only start animation if full streak
    if (widget.isFullStreak) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularFireIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFullStreak && !oldWidget.isFullStreak) {
      _controller.repeat();
    } else if (!widget.isFullStreak && oldWidget.isFullStreak) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate rotation for the small orbiting fires (only when full streak)
        final rotationAngle =
            widget.isFullStreak ? _controller.value * 2 * math.pi : 0.0;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isFullStreak
                        ? Colors.orange.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.3),
                    width: widget.isFullStreak ? 2 : 1.5,
                  ),
                  boxShadow: widget.isFullStreak
                      ? [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),

              // Rotating small fire icons around the center (only for full streak)
              if (widget.isFullStreak)
                Transform.rotate(
                  angle: rotationAngle,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Small fires positioned around the circle
                      for (int i = 0; i < 3; i++)
                        Transform.rotate(
                          angle: (i * 2 * math.pi / 3),
                          child: Transform.translate(
                            // Push them out to the edge.
                            // widget.size/2 is radius. Subtracting small amount to keep inside border.
                            offset: Offset(0, -widget.size / 2 + 1),
                            child: Icon(
                              Icons.local_fire_department,
                              size: widget.size * 0.25, // Scale small fires
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Center content
              if (widget.isFullStreak)
                // Full streak: Static fire icon in center
                Icon(
                  Icons.local_fire_department,
                  size: widget.size * 0.45, // Scale center fire
                  color: Colors.orange,
                )
              else if (widget.hasPartial)
                // Partial: Small fire icon (no rotation)
                const Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: Colors.orange,
                )
              else
                // No completion: Simple dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Rotating fire icon for legend "All completed"
class RotatingFireIcon extends StatefulWidget {
  final double size;
  const RotatingFireIcon({super.key, this.size = 18});

  @override
  State<RotatingFireIcon> createState() => _RotatingFireIconState();
}

class _RotatingFireIconState extends State<RotatingFireIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Icon(
            Icons.local_fire_department,
            size: widget.size,
            color: Colors.orange,
          ),
        );
      },
    );
  }
}
