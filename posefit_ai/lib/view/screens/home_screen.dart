import 'package:flutter/material.dart';
import '../../controller/auth_service.dart';
import '../../controller/workout_log_service.dart';
import '../../model/workout_log.dart';
import '../../utils/exercise_image_helper.dart';

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
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      'Hi, $username!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ready for your workout?',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onNavigateToTab?.call(2);
                        },
                        icon: const Icon(Icons.photo_camera),
                        label: const Text(
                          'Start Exercise Detection',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: _HomeOptionCard(
                            icon: Icons.fitness_center,
                            label: 'Browse\nExercises',
                            onTap: () {
                              widget.onNavigateToTab?.call(1);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HomeOptionCard(
                            icon: Icons.history,
                            label: 'Workout\nHistory',
                            onTap: () {
                              widget.onNavigateToTab?.call(3);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HomeOptionCard(
                            icon: Icons.edit_note,
                            label: 'Manual\nLog',
                            onTap: () {
                              widget.onNavigateToTab?.call(3, openAdd: true);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Recent Workouts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (isLoadingLatestLogs)
                      const Center(child: CircularProgressIndicator())
                    else if (latestLogs.isEmpty)
                      const Text('No exercises logged yet.')
                    else
                      Column(
                        children: latestLogs.map((log) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  ExerciseImageHelper.getImagePath(
                                    log.exerciseName,
                                  ),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
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
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          if (log.isPr == true)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 6,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(6),
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
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
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

class _HomeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
