import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../theme/colors.dart';

class BottomNavBar extends StatefulWidget {
  final String activePath;

  const BottomNavBar({super.key, required this.activePath});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  double _sliderPosition = 0;
  final double _sliderWidth = 280;
  final double _thumbSize = 48;
  bool _isSliding = false;

  void _resetSlider() {
    setState(() {
      _sliderPosition = 0;
      _isSliding = false;
    });
  }

  void _onSlideComplete() {
    context.push('/add');
    Future.delayed(const Duration(milliseconds: 300), _resetSlider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Swipe to Add Slider
        Container(
          width: _sliderWidth,
          height: 56,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A).withValues(alpha: 0.95)
                : Colors.grey[200]!.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _sliderPosition + _thumbSize,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.1),
                          ]
                        : [
                            Colors.grey.withValues(alpha: 0.3),
                            Colors.grey.withValues(alpha: 0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              // Center text
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isSliding ? 0.3 : 0.7,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_forward,
                          size: 16,
                          color:
                              isDark ? AppColors.secondary : Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Swipe to add',
                        style: TextStyle(
                          color:
                              isDark ? AppColors.secondary : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Draggable thumb
              Positioned(
                left: _sliderPosition + 4,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    setState(() => _isSliding = true);
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sliderPosition += details.delta.dx;
                      _sliderPosition = _sliderPosition.clamp(
                          0, _sliderWidth - _thumbSize - 8);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_sliderPosition >
                        (_sliderWidth - _thumbSize - 8) * 0.8) {
                      _onSlideComplete();
                    } else {
                      _resetSlider();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: _isSliding
                          ? (isDark ? AppColors.primary : Colors.grey[800])
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: _isSliding
                          ? (isDark ? Colors.black : Colors.white)
                          : AppColors.pepper,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Navigation Bar without expensive Blur
        Container(
          padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              top: 12,
              left: 24,
              right: 24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface.withValues(alpha: 0.95) // Higher opacity
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(color: borderColor),
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), // Lighter shadow
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GNav(
            mainAxisAlignment: MainAxisAlignment.center,
            gap: 8,
            activeColor: isDark ? AppColors.primary : AppColors.pepper,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.pepper.withValues(alpha: 0.1),
            color: isDark ? AppColors.tertiary : AppColors.ash,
            tabs: [
              GButton(
                icon: Icons.home_rounded,
                text: 'Home',
                onPressed: () => context.go('/home'),
              ),
              GButton(
                icon: Icons.bar_chart_rounded,
                text: 'Progress',
                onPressed: () => context.go('/stats'),
              ),
            ],
            selectedIndex: widget.activePath == '/home' ? 0 : 1,
            onTabChange: (index) {
              if (index == 0) context.go('/home');
              if (index == 1) context.go('/stats');
            },
          ),
        ),
      ],
    );
  }
}
