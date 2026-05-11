import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../controller/auth_service.dart';
import '../../controller/workout_log_service.dart';
import '../../model/workout_log.dart';
import '../../utils/exercise_image_helper.dart';
import '../widgets/home_option_card.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int, {bool openAdd})? onNavigateToTab;
  final Function(WorkoutLog log) onOpenLog;

  const HomeScreen({super.key, this.onNavigateToTab, required this.onOpenLog});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = 'User';
  bool isLoading = true;
  bool isLoadingLatestLogs = true;

  List<WorkoutLog> latestLogs = [];

  @override
  void initState() {
    super.initState();
    loadUsername();
    loadLatestLogs();
  }

  Future<void> loadUsername() async {
    final storedUsername = await AuthService.getUsername();

    if (!mounted) return;

    setState(() {
      username = (storedUsername != null && storedUsername.isNotEmpty)
          ? storedUsername
          : 'User';
      isLoading = false;
    });
  }

  Future<void> loadLatestLogs() async {
    try {
      final logs = await WorkoutLogService.getLogs();

      if (!mounted) return;

      setState(() {
        latestLogs = logs.take(3).toList();
        isLoadingLatestLogs = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        latestLogs = [];
        isLoadingLatestLogs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $username!', style: AppTextStyles.heading),

                    const SizedBox(height: 8),

                    const Text(
                      'Ready to improve your form today?',
                      style: AppTextStyles.body,
                    ),

                    const SizedBox(height: AppSizes.sectionSpacing),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardRadius,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start AI Exercise Detection',
                            style: AppTextStyles.sectionTitle,
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Use your camera to recognise exercises and track your workout.',
                            style: AppTextStyles.cardSubtitle,
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                widget.onNavigateToTab?.call(2);
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text(
                                'Open Camera',
                                style: AppTextStyles.buttonText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.sectionSpacing),

                    const Text(
                      'Quick Access',
                      style: AppTextStyles.sectionTitle,
                    ),

                    const SizedBox(height: AppSizes.itemSpacing),

                    Row(
                      children: [
                        Expanded(
                          child: HomeOptionCard(
                            icon: Icons.fitness_center,
                            label: 'Exercises',
                            color: AppColors.aiMint,
                            onTap: () {
                              widget.onNavigateToTab?.call(1);
                            },
                          ),
                        ),

                        const SizedBox(width: AppSizes.itemSpacing),

                        Expanded(
                          child: HomeOptionCard(
                            icon: Icons.history,
                            label: 'Logs',
                            color: AppColors.aiMint,
                            onTap: () {
                              widget.onNavigateToTab?.call(3);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.itemSpacing),

                    Row(
                      children: [
                        Expanded(
                          child: HomeOptionCard(
                            icon: Icons.edit_note,
                            label: 'Manual Log',
                            color: AppColors.aiMint,
                            onTap: () {
                              widget.onNavigateToTab?.call(3, openAdd: true);
                            },
                          ),
                        ),

                        const SizedBox(width: AppSizes.itemSpacing),

                        Expanded(
                          child: HomeOptionCard(
                            icon: Icons.person,
                            label: 'Account',
                            color: AppColors.aiMint,
                            onTap: () {
                              widget.onNavigateToTab?.call(4);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.sectionSpacing),

                    const Text(
                      'Recent Workouts',
                      style: AppTextStyles.sectionTitle,
                    ),

                    const SizedBox(height: 12),

                    if (isLoadingLatestLogs)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      )
                    else if (latestLogs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(
                            AppSizes.cardRadius,
                          ),
                        ),
                        child: const Text(
                          'No exercises logged yet.',
                          style: AppTextStyles.body,
                        ),
                      )
                    else
                      Column(
                        children: latestLogs.map((log) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(
                                AppSizes.cardRadius,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(
                                      alpha: 0.45,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Image.asset(
                                    ExerciseImageHelper.getImagePath(
                                      log.exerciseName,
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${log.exerciseName} - ${log.weightUnit == 'bw' ? 'bodyweight' : '${log.weight.toStringAsFixed(0)}${log.weightUnit}'}',
                                              style: AppTextStyles.cardTitle,
                                            ),
                                          ),

                                          if (log.isPr == true)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 6,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen,
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                    widget.onOpenLog(log);
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
