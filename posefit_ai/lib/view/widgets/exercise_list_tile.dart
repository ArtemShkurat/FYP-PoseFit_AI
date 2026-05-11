import 'package:flutter/material.dart';

import '../../model/exercise.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_sizes.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/exercise_image_helper.dart';

class ExerciseListTile extends StatelessWidget {
  final Exercise exercise;
  final String subtitle;
  final VoidCallback onTap;

  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

        leading: Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.asset(
            ExerciseImageHelper.getImagePath(exercise.name),
            fit: BoxFit.contain,
          ),
        ),

        title: Text(exercise.name, style: AppTextStyles.cardTitle),

        subtitle: Text(subtitle, style: AppTextStyles.small),

        trailing: const Icon(Icons.chevron_right, color: AppColors.softText),

        onTap: onTap,
      ),
    );
  }
}
