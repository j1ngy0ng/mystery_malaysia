import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 38,
      height: 1.05,
      fontWeight: FontWeight.w900,
      color: AppColors.ink,
      letterSpacing: -1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      height: 1.08,
      fontWeight: FontWeight.w900,
      color: AppColors.ink,
      letterSpacing: -0.7,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 1.1,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.ink),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.4,
      color: AppColors.secondaryText,
    ),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
  );
}
