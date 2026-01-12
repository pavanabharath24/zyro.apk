import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../providers/settings_provider.dart';
import '../providers/habit_provider.dart';
import '../services/notification_service.dart' as import_notification_service;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _nameController.text = settings.userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.pageBgLight;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final cardColor = isDark ? AppColors.surface : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.go('/home'),
                                  icon: Icon(Icons.arrow_back,
                                      color: textColor, size: 28),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Settings',
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Name Input Section
                            Text(
                              'Your Name',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We\'ll use this for personalized motivational notifications',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: TextField(
                                controller: _nameController,
                                style: GoogleFonts.inter(color: textColor),
                                decoration: InputDecoration(
                                  hintText: 'Enter your name',
                                  hintStyle:
                                      GoogleFonts.inter(color: subTextColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  suffixIcon: IconButton(
                                    icon:
                                        Icon(Icons.check, color: Colors.green),
                                    onPressed: () {
                                      settings.setUserName(
                                          _nameController.text.trim());
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Name saved!'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                onSubmitted: (value) {
                                  settings.setUserName(value.trim());
                                },
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Gender Selection
                            Text(
                              'Gender',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Help us personalize your experience',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'Male',
                                'Female',
                                'Other',
                                'Prefer not to say'
                              ].map((gender) {
                                final isSelected = settings.gender == gender;
                                return ChoiceChip(
                                  label: Text(gender),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      settings.setGender(gender);
                                    }
                                  },
                                  selectedColor: AppColors.accentPurple
                                      .withValues(alpha: 0.2),
                                  backgroundColor: cardColor,
                                  labelStyle: GoogleFonts.inter(
                                    color: isSelected
                                        ? AppColors.accentPurple
                                        : textColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.accentPurple
                                          : (isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : Colors.grey
                                                  .withValues(alpha: 0.3)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 32),

                            // Theme Mode Section
                            Text(
                              'Appearance',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose your preferred theme mode',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Theme Toggle Buttons
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildThemeOption(
                                    'System',
                                    Icons.settings_suggest,
                                    ThemeMode.system,
                                    settings,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                  ),
                                  _buildThemeOption(
                                    'Light',
                                    Icons.light_mode,
                                    ThemeMode.light,
                                    settings,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                  ),
                                  _buildThemeOption(
                                    'Dark',
                                    Icons.dark_mode,
                                    ThemeMode.dark,
                                    settings,
                                    textColor,
                                    subTextColor,
                                    isDark,
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Danger Zone
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Danger Zone',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reset all data like habits, tasks, and settings.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: subTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await import_notification_service
                                                .NotificationService()
                                            .showInstantNotification();
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Test notification sent!')),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: Text(
                                        'Test Notification',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _showResetConfirmation(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: Text(
                                        'Reset App',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Version Info
                            Center(
                              child: Text(
                                'ZYRO v1.0.0',
                                style: GoogleFonts.inter(
                                  color: subTextColor,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            // Safe area padding for bottom
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    ThemeMode mode,
    SettingsProvider settings,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    final isSelected = settings.themeMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => settings.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? textColor : subTextColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? textColor : subTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset App?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete all your habits, tasks, and settings. This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Reset data
              await Provider.of<HabitProvider>(context, listen: false)
                  .resetData();
              await Provider.of<SettingsProvider>(context, listen: false)
                  .resetSettings();

              if (mounted) {
                // Show brief success message then navigate
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App reset successfully'),
                    backgroundColor: Colors.red,
                  ),
                );

                // Small delay to let snackbar show
                await Future.delayed(const Duration(milliseconds: 500));

                if (mounted) context.go('/');
              }
            },
            child: Text(
              'Reset',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
