import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class HabitDetailsScreen extends StatelessWidget {
  final String? habitId;

  const HabitDetailsScreen({super.key, this.habitId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final habit = provider.habits.firstWhere(
          (h) => h.id == habitId,
          orElse: () => Habit(
              id: 'notFound',
              name: 'Habit Not Found',
              icon: IconType.star,
              repeatDays: []),
        );

        if (habit.id == 'notFound') {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
            body: const Center(child: Text("Habit not found")),
          );
        }

        final isCompletedToday = habit.isCompletedOn(DateTime.now());

        // Gradient colors based on theme
        final gradientColors = isDark
            ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
            : [const Color(0xFF667eea), const Color(0xFF764ba2)];

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),

              // Glass Overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Custom App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                          // Title
                          Text('Details',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          // Edit Button - NOW WORKING!
                          GestureDetector(
                            onTap: () =>
                                context.push('/new-habit', extra: habit),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            // Icon Container - Glass Effect
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8))
                                ],
                              ),
                              child: habit.customEmoji != null
                                  ? Center(
                                      child: Text(habit.customEmoji!,
                                          style: const TextStyle(fontSize: 56)))
                                  : Icon(_getIconData(habit.icon),
                                      size: 56, color: Colors.white),
                            ),

                            const SizedBox(height: 28),

                            // Habit Name
                            Text(habit.name,
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),

                            const SizedBox(height: 12),

                            // Tags Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Text('HABIT',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                          color: Colors.white)),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 12),
                                Text(habit.scheduledTime ?? 'Any Time',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white
                                            .withValues(alpha: 0.8))),
                              ],
                            ),

                            const SizedBox(height: 48),

                            // Mark as Done Button - Glass Effect
                            GestureDetector(
                              onTap: () {
                                provider.toggleHabitCompletion(
                                    habit.id, DateTime.now());
                              },
                              child: Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: isCompletedToday
                                      ? LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.9),
                                            Colors.white.withValues(alpha: 0.7)
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: (isCompletedToday
                                                ? Colors.green
                                                : Colors.white)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6))
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        isCompletedToday
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        size: 28,
                                        color: isCompletedToday
                                            ? Colors.white
                                            : AppColors.pepper),
                                    const SizedBox(width: 12),
                                    Text(
                                        isCompletedToday
                                            ? 'Completed!'
                                            : 'Mark as Done',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isCompletedToday
                                                ? Colors.white
                                                : AppColors.pepper)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Glass Stat Cards
                            Row(
                              children: [
                                _glassStatCard(
                                    '${(habit.completedDaysCount > 0 ? (habit.completedDaysCount / (habit.completedDaysCount + 7) * 100).round() : 0)}%',
                                    'Success',
                                    Icons.percent,
                                    isDark),
                                const SizedBox(width: 14),
                                _glassStatCard('${habit.completedDaysCount}',
                                    'Days', Icons.calendar_month, isDark),
                                const SizedBox(width: 14),
                                _glassStatCard(
                                    '${habit.currentStreak}',
                                    'Streak',
                                    Icons.local_fire_department,
                                    isDark),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Delete Button
                            GestureDetector(
                              onTap: () =>
                                  _showDeleteDialog(context, provider, habit),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        color: Colors.red.shade300),
                                    const SizedBox(width: 8),
                                    Text('Delete Habit',
                                        style: TextStyle(
                                            color: Colors.red.shade300,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(
      BuildContext context, HabitProvider provider, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text(
            'Are you sure you want to delete this habit? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeHabit(habit.id);
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(IconType iconType) {
    switch (iconType) {
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
      default:
        return Icons.star;
    }
  }

  Widget _glassStatCard(
      String value, String label, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 14),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
