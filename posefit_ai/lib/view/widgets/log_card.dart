import 'package:flutter/material.dart';

import '../../controller/workout_log_service.dart';
import '../../model/workout_log.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_sizes.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/exercise_image_helper.dart';

class LogCard extends StatelessWidget {
  final WorkoutLog log;
  final bool isHighlighted;
  final String Function(WorkoutLog log) formatWeight;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;

  const LogCard({
    super.key,
    required this.log,
    required this.isHighlighted,
    required this.formatWeight,
    required this.onEdit,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryGreen.withValues(alpha: 0.12)
            : AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withValues(alpha: 0.18),
          width: isHighlighted ? 1.8 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              ExerciseImageHelper.getImagePath(log.exerciseName),
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${log.exerciseName} - ${formatWeight(log)}',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),

                    if (log.isPr)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PR',
                          style: TextStyle(
                            color: AppColors.background,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  '${log.setsCount} x ${log.repsCount} reps • ${log.logDate}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: AppColors.aiMint,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text(
                          'Delete Log',
                          style: AppTextStyles.sectionTitle,
                        ),
                        content: const Text(
                          'Delete this workout log?',
                          style: AppTextStyles.body,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.secondary),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await WorkoutLogService.deleteLog(log.id);
                      onDeleted();
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
