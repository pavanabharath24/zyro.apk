import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_flow/providers/settings_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Prefer not to say';

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to continue')),
      );
      return;
    }

    final settings = context.read<SettingsProvider>();
    await settings.setUserName(_nameController.text.trim());
    await settings.setGender(_selectedGender);
    await settings.completeOnboarding();

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme colors directly for consistency
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Welcome to Zyro',
                    description:
                        'Your journey to better habits starts here. Build the life you want, one habit at a time.',
                    graphic: Image.asset(
                      'assets/icon.png',
                      width: 100,
                      height: 100,
                    ),
                    color: colorScheme.primary,
                    isLogo: true,
                  ),
                  _buildPage(
                    title: 'Track Your Habits',
                    description:
                        'Stay consistent with daily tracking. Simple, intuitive, and designed for your success.',
                    graphic: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 80,
                      color: Colors.orange,
                    ),
                    color: Colors.orange,
                  ),
                  _buildPage(
                    title: 'Manage Daily Tasks',
                    description:
                        'Keep track of your to-dos alongside your habits. Never miss a deadline again.',
                    graphic: Icon(
                      Icons.checklist_rounded,
                      size: 80,
                      color: Colors.blue,
                    ),
                    color: Colors.blue,
                  ),
                  _buildPage(
                    title: 'Visualize Progress',
                    description:
                        'See your consistency with beautiful streaks and stats. Motivation at a glance.',
                    graphic: Icon(
                      Icons.insights_rounded,
                      size: 80,
                      color: Colors.purple,
                    ),
                    color: Colors.purple,
                  ),
                  _buildPersonalizationPage(colorScheme),
                ],
              ),
            ),
            _buildBottomControls(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required Widget graphic,
    required Color color,
    bool isLogo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLogo)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                child: graphic,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: graphic,
            ),
          const SizedBox(height: 48),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationPage(ColorScheme colorScheme) {
    final settings = context.watch<SettingsProvider>();

    return Stack(
      children: [
        // Glass background effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Glass icon container
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Let's get to know you",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "We'll customize your experience based on your details.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'What should we call you?',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Gender',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _genders.map((gender) {
                  final isSelected = _selectedGender == gender;

                  // Determine color based on gender
                  Color chipColor;
                  switch (gender) {
                    case 'Male':
                      chipColor = Colors.blueAccent;
                      break;
                    case 'Female':
                      chipColor = Colors.pinkAccent;
                      break;
                    case 'Other':
                      chipColor = Colors.orangeAccent;
                      break;
                    default:
                      chipColor = Colors.tealAccent;
                  }

                  return GestureDetector(
                    onTap: () => setState(() => _selectedGender = gender),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? chipColor : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: chipColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(Icons.check,
                                  size: 18, color: Colors.white),
                            ),
                          Text(
                            gender,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'App Theme',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildThemeChip('System', ThemeMode.system, settings),
                  _buildThemeChip('Light', ThemeMode.light, settings),
                  _buildThemeChip('Dark', ThemeMode.dark, settings),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeChip(
      String label, ThemeMode mode, SettingsProvider settings) {
    final isSelected = settings.themeMode == mode;

    // Determine color based on theme mode
    Color chipColor;
    if (mode == ThemeMode.dark) {
      chipColor = Colors.purpleAccent;
    } else if (mode == ThemeMode.light) {
      chipColor = Colors.blue;
    } else {
      // System mode - adaptive
      final brightness = MediaQuery.platformBrightnessOf(context);
      chipColor =
          brightness == Brightness.dark ? Colors.purpleAccent : Colors.blue;
    }

    return GestureDetector(
      onTap: () => settings.setThemeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.check, size: 18, color: Colors.white),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Indicators
          Row(
            children: List.generate(5, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFFFFD700) // Gold for active
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          // Next/Finish Button - Gold Glass styled
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700), // Gold
                    Color(0xFFFFA000), // Amber
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == 4 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_currentPage != 4) ...[
                    const Icon(Icons.arrow_forward_rounded,
                        size: 22, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
