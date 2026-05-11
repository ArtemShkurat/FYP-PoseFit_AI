import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../controller/workout_log_service.dart';
import '../../model/workout_log.dart';
import '../../controller/exercise_service.dart';
import '../../model/exercise.dart';
import '../widgets/add_workout_log_dialog.dart';
import '../widgets/log_tab_button.dart';
import '../widgets/log_card.dart';

enum LogSortType { nameAsc, nameDesc, setsDesc, newest, oldest }

class LogsScreen extends StatefulWidget {
  final int? highlightLogId;
  final bool initialShowPrsOnly;
  final bool openAddDialog;

  const LogsScreen({
    super.key,
    this.highlightLogId,
    this.initialShowPrsOnly = false,
    this.openAddDialog = false,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  LogSortType currentSort = LogSortType.newest;
  List<WorkoutLog> logs = [];
  List<Exercise> availableExercises = [];
  bool isLoading = true;
  bool showPrsOnly = false;
  String? errorMessage;
  int? activeHighlightLogId;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> logKeys = {};

  @override
  void initState() {
    super.initState();
    showPrsOnly = widget.initialShowPrsOnly;
    loadLogs();
    loadExercises();

    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openAddEditRecordDialog(); // 👈 your existing function
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        activeHighlightLogId = null;
      });
    });
  }

  String _formatWeight(WorkoutLog log) {
    if (log.weightUnit == 'bw') {
      return 'bodyweight';
    }

    return '${log.weight.toStringAsFixed(0)}${log.weightUnit}';
  }

  Future<void> loadExercises() async {
    try {
      final exercises = await ExerciseService.getExercises();

      if (!mounted) return;

      setState(() {
        availableExercises = exercises;
      });
    } catch (_) {
      debugPrint('Failed to load exercises.');
    }
  }

  Future<void> loadLogs() async {
    try {
      final loadedLogs = await WorkoutLogService.getLogs();

      if (!mounted) return;

      setState(() {
        logs = loadedLogs;
        isLoading = false;
        errorMessage = null;

        // 👇 set highlight when logs are loaded
        activeHighlightLogId = widget.highlightLogId;
      });

      if (widget.highlightLogId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = logKeys[widget.highlightLogId!];

          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.3,
            );
          }
        });
      }

      // 👇 remove highlight after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          activeHighlightLogId = null;
        });
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load workout logs.';
      });
    }
  }

  List<WorkoutLog> sortLogs(List<WorkoutLog> input) {
    final sorted = [...input];

    switch (currentSort) {
      case LogSortType.nameAsc:
        sorted.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
        break;

      case LogSortType.nameDesc:
        sorted.sort((a, b) => b.exerciseName.compareTo(a.exerciseName));
        break;

      case LogSortType.setsDesc:
        sorted.sort((a, b) => b.setsCount.compareTo(a.setsCount));
        break;

      case LogSortType.newest:
        sorted.sort((a, b) => b.logDate.compareTo(a.logDate));
        break;

      case LogSortType.oldest:
        sorted.sort((a, b) => a.logDate.compareTo(b.logDate));
        break;
    }

    return sorted;
  }

  String getSortLabel() {
    switch (currentSort) {
      case LogSortType.nameAsc:
        return 'A–Z';
      case LogSortType.nameDesc:
        return 'Z–A';
      case LogSortType.setsDesc:
        return 'Sets';
      case LogSortType.newest:
        return 'Latest';
      case LogSortType.oldest:
        return 'Oldest';
    }
  }

  Future<void> openAddEditRecordDialog({WorkoutLog? log}) async {
    final result = await showAddWorkoutLogDialog(
      context: context,
      availableExercises: availableExercises,
      log: log,
    );

    if (result == true) {
      loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: AppColors.background,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddEditRecordDialog,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.background,
        elevation: 0,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Workout Logs', style: AppTextStyles.heading),

                const SizedBox(height: 8),

                const Text(
                  'View your workout history and personal records.',
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: LogTabButton(
                          label: 'Workouts',
                          isSelected: !showPrsOnly,
                          onTap: () {
                            setState(() {
                              showPrsOnly = false;
                            });
                          },
                        ),
                      ),

                      Expanded(
                        child: LogTabButton(
                          label: 'Personal Records',
                          isSelected: showPrsOnly,
                          onTap: () {
                            setState(() {
                              showPrsOnly = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!, style: AppTextStyles.body));
    }

    final filteredLogs = showPrsOnly
        ? logs.where((log) => log.isPr).toList()
        : logs.where((log) => !log.isPr).toList();

    final visibleLogs = sortLogs(filteredLogs);

    if (visibleLogs.isEmpty) {
      return Center(
        child: Text(
          showPrsOnly ? 'No PRs yet.' : 'No workout logs yet.',
          style: AppTextStyles.body,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            0,
            AppSizes.screenPadding,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showPrsOnly)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.question_mark,
                      size: 17,
                      color: AppColors.aiMint,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.card,
                          title: const Text(
                            'Personal Records',
                            style: AppTextStyles.sectionTitle,
                          ),
                          content: const Text(
                            'A Personal Record (PR) is your best performance for an exercise.\n\n'
                            'This tab keeps your PR workouts separate, so you can quickly track your strongest lifts and progress over time.',
                            style: AppTextStyles.body,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Got it',
                                style: TextStyle(color: AppColors.primaryGreen),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                const SizedBox(width: 38),

              PopupMenuButton<LogSortType>(
                color: AppColors.card,
                onSelected: (value) {
                  setState(() {
                    currentSort = value;
                  });
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: LogSortType.nameAsc,
                    child: Text('Exercise name (A-Z)'),
                  ),
                  PopupMenuItem(
                    value: LogSortType.nameDesc,
                    child: Text('Exercise name (Z-A)'),
                  ),
                  PopupMenuItem(
                    value: LogSortType.setsDesc,
                    child: Text('Sets amount'),
                  ),
                  PopupMenuItem(
                    value: LogSortType.newest,
                    child: Text('Newest added'),
                  ),
                  PopupMenuItem(
                    value: LogSortType.oldest,
                    child: Text('Last added'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 20, color: AppColors.aiMint),
                      const SizedBox(width: 6),
                      Text(
                        getSortLabel(),
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.softText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            backgroundColor: AppColors.card,
            onRefresh: loadLogs,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              itemCount: visibleLogs.length,
              itemBuilder: (context, index) {
                final log = visibleLogs[index];
                logKeys.putIfAbsent(log.id, () => GlobalKey());

                return Container(
                  key: logKeys[log.id],
                  child: LogCard(
                    log: log,
                    isHighlighted: log.id == activeHighlightLogId,
                    formatWeight: _formatWeight,

                    onEdit: () {
                      openAddEditRecordDialog(log: log);
                    },

                    onDeleted: () {
                      loadLogs();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
