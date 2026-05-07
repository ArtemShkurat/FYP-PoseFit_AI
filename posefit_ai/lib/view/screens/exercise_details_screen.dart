import 'package:flutter/material.dart';
import '../../model/exercise.dart';
import '../../model/workout_log.dart';
import '../../controller/workout_log_service.dart';
import '../../utils/exercise_image_helper.dart';
import '../widgets/add_workout_log_dialog.dart';

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
        title: const Text('Add workout log?'),
        content: Text(
          'Exercise detected: ${exercise.name}\n\n'
          'Do you want to add a workout log for this exercise?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No'),
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
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      appBar: AppBar(title: Text(exercise.name)),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showRecords = false;
                    });
                  },
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    color: !showRecords
                        ? Colors.blue.withOpacity(0.12)
                        : Colors.transparent,
                    child: const Text(
                      'Info',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showRecords = true;
                    });
                  },
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    color: showRecords
                        ? Colors.blue.withOpacity(0.12)
                        : Colors.transparent,
                    child: const Text(
                      'Records',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(child: showRecords ? _recordsTab() : _infoTab(exercise)),
        ],
      ),
    );
  }

  Widget _infoTab(Exercise exercise) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              ExerciseImageHelper.getImagePath(exercise.name),
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            exercise.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (exerciseLogs.isEmpty) {
      return const Center(child: Text('No logs for this exercise yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exerciseLogs.length,
      itemBuilder: (context, index) {
        final log = exerciseLogs[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Image.asset(
                ExerciseImageHelper.getImagePath(log.exerciseName),
                width: 44,
                height: 44,
                fit: BoxFit.contain,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (log.isPr)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${log.setsCount} x ${log.repsCount} reps - ${log.logDate}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.chevron_right),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content.isNotEmpty ? content : 'Information not available yet.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
