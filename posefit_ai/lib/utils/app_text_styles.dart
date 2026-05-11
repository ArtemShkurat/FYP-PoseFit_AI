import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    color: AppColors.softText,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.softText,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.secondary,
    fontSize: 16,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.softText,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.secondary,
    fontSize: 14,
  );

  static const TextStyle buttonText = TextStyle(
    color: AppColors.background,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle small = TextStyle(
    color: AppColors.secondary,
    fontSize: 13,
  );
}
