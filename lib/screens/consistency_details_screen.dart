import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class ConsistencyDetailsScreen extends StatelessWidget {
  const ConsistencyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF18181b) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Consistency History',
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

          // 1. Determine Start Date dynamically
          DateTime startDate = now;

          // Check Habits
          if (provider.habits.isNotEmpty) {
            try {
              final sorted = List<Habit>.from(provider.habits)
                ..sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
              final first = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(sorted.first.id));
              startDate = first;
            } catch (e) {
              debugPrint("Error parsing habit ID: $e");
            }
          }

          // Tasks check removed as per user request (Show only Habits)

          if (startDate.isAfter(now)) startDate = now;

          final months = _getMonthsInRange(startDate, now);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final monthDate = months[index];
              return _buildMonthCard(context, monthDate, provider, isDark,
                  cardColor, textColor, subTextColor);
            },
          );
        },
      ),
    );
  }

  List<DateTime> _getMonthsInRange(DateTime start, DateTime end) {
    List<DateTime> months = [];
    DateTime current = DateTime(end.year, end.month);
    // Limit to start of the start month
    final limit = DateTime(start.year, start.month);

    // Safety break
    int safety = 0;
    while (!current.isBefore(limit) && safety < 100) {
      months.add(current);
      if (current.month == 1) {
        current = DateTime(current.year - 1, 12);
      } else {
        current = DateTime(current.year, current.month - 1);
      }
      safety++;
    }
    return months;
  }

  Widget _buildMonthCard(
      BuildContext context,
      DateTime monthDate,
      HabitProvider provider,
      bool isDark,
      Color cardColor,
      Color text,
      Color subText) {
    final title = DateFormat('MMMM yyyy').format(monthDate);
    final daysInMonth =
        DateUtils.getDaysInMonth(monthDate.year, monthDate.month);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth +
                (DateTime(monthDate.year, monthDate.month, 1).weekday - 1),
            itemBuilder: (context, index) {
              final firstWeekday =
                  DateTime(monthDate.year, monthDate.month, 1).weekday;
              final offset = firstWeekday - 1;

              if (index < offset) return const SizedBox();

              final dayNum = index - offset + 1;
              final date = DateTime(monthDate.year, monthDate.month, dayNum);

              final isFuture = date.isAfter(DateTime.now());

              if (isFuture) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$dayNum',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: subText.withValues(alpha: 0.5))),
                );
              }

              final scheduled =
                  provider.habits.where((h) => h.isScheduledOn(date)).length;
              final completed =
                  provider.habits.where((h) => h.isCompletedOn(date)).length;

              double ratio = 0;
              if (scheduled > 0) ratio = completed / scheduled;

              Color cellColor;
              if (scheduled == 0) {
                cellColor = isDark ? Colors.white10 : Colors.grey[300]!;
              } else {
                if (ratio == 0) {
                  cellColor = isDark
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.red[100]!;
                } else if (ratio < 0.5) {
                  cellColor = Colors.orangeAccent.withValues(alpha: 0.6);
                } else if (ratio < 1.0) {
                  cellColor = Colors.lightGreen.withValues(alpha: 0.6);
                } else {
                  cellColor = isDark ? Colors.greenAccent[700]! : Colors.green;
                }
              }

              return Tooltip(
                message: '$dayNum: $completed/$scheduled',
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$dayNum',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: (ratio >= 1.0) ? Colors.white : text)),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
