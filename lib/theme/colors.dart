import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color spWhite = Color(0xFFFFFFFF);
  static const Color spLight = Color(0xFFD4D4D4);
  static const Color spGray = Color(0xFFB3B3B3);
  static const Color spMedium = Color(0xFFB3B3B3);
  static const Color spDark = Color(0xFF2B2B2B);

  // Semantic mappings (for dark mode)
  static const Color primary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFD4D4D4);
  static const Color tertiary = Color(0xFFB3B3B3);
  static const Color surface =
      Color(0xFF1E1E1E); // Darker surface for contrast with cards
  static const Color background =
      Color(0xFF121212); // Slightly lighter dark background

  static const Color saltWhite = Color(0xFFFFFFFF);
  static const Color pepper =
      Color(0xFF1A1A1A); // Darker for better text contrast in light mode
  static const Color stone = Color(0xFFD4D4D4);
  static const Color ash =
      Color(0xFF6B6B6B); // Darker gray for better readability
  static const Color saltMedium = Color(0xFFE5E5E5);
  static const Color saltLight = Color(0xFFF5F5F5);

  // Light Mode specific
  static const Color pageBgLight =
      Color(0xFFF5F5F5); // Slight gray instead of pure white
  static const Color cardBgLight =
      Color(0xFFFFFFFF); // Pure white cards for contrast

  // Accent Colors (for Vibrancy)
  static const Color accentBlue = Color(0xFF64B5F6); // Soft Blue
  static const Color accentPurple = Color(0xFF9575CD); // Soft Purple
  static const Color accentOrange = Color(0xFFFFB74D); // Soft Orange
  static const Color accentGreen = Color(0xFF81C784); // Soft Green
  static const Color accentCyan = Color(0xFF00F2FF); // Neon Cyan (Deep Sea)

  // Gradients
  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFF0A192F), Color(0xFF0A192F)], // Solid Navy for Cards
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)], // Orange/Gold Gradient
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Vibrant Gradients for Light Mode Cards
  static const LinearGradient lightBlueGradient = LinearGradient(
    colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)], // Bright Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightPurpleGradient = LinearGradient(
    colors: [Color(0xFF9575CD), Color(0xFF7E57C2)], // Bright Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mode specific
  static const Color pageBgDark = Color(0xFF004D7A); // Deep Sea Start
  static const Color cardBgDark = Color(0xFF0A192F); // Dark Navy

  // Page Background Gradients
  static const LinearGradient pageGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFBBDEFB), // Blue 100 - More visible
      Color(0xFFF5F5F5), // Grey 100 - Soft bottom
    ],
    stops: [0.0, 0.4], // Gradient fades out by 40% down
  );

  static const LinearGradient pageGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF021B2B), // Deepest Navy
      Color(0xFF004D7A), // Deep Teal
      Color(0xFF006064), // Dark Cyan
    ],
  );
}
