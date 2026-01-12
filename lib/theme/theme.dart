import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.pageBgLight,
      primaryColor: AppColors.pepper,
      cardColor: AppColors.cardBgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.pepper,
        secondary: AppColors.spGray,
        surface: AppColors.cardBgLight,
        onPrimary: AppColors.spWhite,
        onSurface: AppColors.pepper,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.pepper,
        displayColor: AppColors.pepper,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.pageBgDark,
      primaryColor: AppColors.spWhite,
      cardColor: AppColors.cardBgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.spWhite,
        secondary: AppColors.spLight,
        surface: AppColors.cardBgDark,
        onPrimary: AppColors.pepper,
        onSurface: AppColors.spWhite,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.spWhite,
        displayColor: AppColors.spWhite,
      ),
      useMaterial3: true,
    );
  }
}
