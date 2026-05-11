import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../model/exercise.dart';
import '../../model/workout_log.dart';
import '../../controller/workout_log_service.dart';
import '../../utils/exercise_image_helper.dart';
import '../widgets/add_workout_log_dialog.dart';
import '../widgets/tab_button.dart';

class ExerciseDetailsScreen extends StatefulWidget {
  const ExerciseDetailsScreen({super.key});

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  late Exercise exercise;
  bool askToLog = false;
  bool _askedToLogAlready = false;
  bool showRecords = false;
  bool isLoadingLogs = true;
  List<WorkoutLog> exerciseLogs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments;

    if (args is Exercise) {
      exercise = args;
      askToLog = false;
    } else if (args is Map<String, dynamic>) {
      exercise = args['exercise'] as Exercise;
      askToLog = args['askToLog'] ?? false;
    }

    loadExerciseLogs();

    if (askToLog && !_askedToLogAlready) {
      _askedToLogAlready = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddLogQuestion();
      });
    }
  }

  void _showAddLogQuestion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Add workout log?',
          style: AppTextStyles.sectionTitle,
        ),
        content: Text(
          'Exercise detected: ${exercise.name}\n\n'
          'Do you want to add a workout log for this exercise?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'No',
              style: TextStyle(color: AppColors.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final result = await showAddWorkoutLogDialog(
                context: context,
                availableExercises: [exercise],
                prefillExerciseName: exercise.name,
              );

              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Workout log added successfully'),
                    backgroundColor: AppColors.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                    ),
                  ),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> loadExerciseLogs() async {
    try {
      final logs = await WorkoutLogService.getLogs();

      if (!mounted) return;

      setState(() {
        exerciseLogs = logs
            .where(
              (log) =>
                  log.exerciseName.toLowerCase() == exercise.name.toLowerCase(),
            )
            .toList();

        isLoadingLogs = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        exerciseLogs = [];
        isLoadingLogs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.softText),
        title: Text(exercise.name, style: AppTextStyles.sectionTitle),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabButton(
                    label: 'Info',
                    isSelected: !showRecords,
                    onTap: () {
                      setState(() {
                        showRecords = false;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TabButton(
                    label: 'Records',
                    isSelected: showRecords,
                    onTap: () {
                      setState(() {
                        showRecords = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: showRecords ? _recordsTab() : _infoTab(exercise)),
        ],
      ),
    );
  }

  Widget _infoTab(Exercise exercise) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              ),
              child: Image.asset(
                ExerciseImageHelper.getImagePath(exercise.name),
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(exercise.name, style: AppTextStyles.heading),

          const SizedBox(height: 14),

          _sectionCard(title: 'Target muscles', content: exercise.muscleGroup),
          _sectionCard(title: 'Overview', content: exercise.description),
          _sectionCard(title: 'Instructions', content: exercise.instructions),
          _sectionCard(title: 'Tips', content: exercise.tips),
        ],
      ),
    );
  }

  Widget _recordsTab() {
    if (isLoadingLogs) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (exerciseLogs.isEmpty) {
      return const Center(
        child: Text(
          'No logs for this exercise yet.',
          style: AppTextStyles.body,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      itemCount: exerciseLogs.length,
      itemBuilder: (context, index) {
        final log = exerciseLogs[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  ExerciseImageHelper.getImagePath(log.exerciseName),
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${log.exerciseName} - ${_formatWeight(log)}',
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        if (log.isPr)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
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
                      '${log.setsCount} x ${log.repsCount} reps - ${log.logDate}',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.softText,
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/main-navigation',
                    arguments: {
                      'tabIndex': 3,
                      'highlightLogId': log.id,
                      'showPrsOnly': log.isPr,
                      'openAddDialog': true,
                      'prefillExerciseName': log.exerciseName,
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatWeight(WorkoutLog log) {
    if (log.weightUnit == 'bw') {
      return 'bodyweight';
    }

    return '${log.weight.toStringAsFixed(0)}${log.weightUnit}';
  }

  Widget _sectionCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(
            content.isNotEmpty ? content : 'Information not available yet.',
            style: AppTextStyles.body.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
