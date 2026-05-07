import 'package:flutter/material.dart';
import '../../controller/workout_log_service.dart';
import '../../model/workout_log.dart';
import '../../controller/exercise_service.dart';
import '../../model/exercise.dart';
import '../../utils/exercise_image_helper.dart';

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
    final exerciseController = TextEditingController(
      text: log?.exerciseName ?? '',
    );
    final setsController = TextEditingController(
      text: log?.setsCount.toString() ?? '',
    );
    final repsController = TextEditingController(
      text: log?.repsCount.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: log?.weight.toString() ?? '',
    );

    bool isPr = log?.isPr ?? false;
    bool isSaving = false;
    String selectedUnit = log?.weightUnit ?? 'kg';

    DateTime selectedDate = DateTime.now();

    if (log != null) {
      selectedDate = DateTime.tryParse(log.logDate) ?? DateTime.now();
    }

    String formattedDate() {
      return selectedDate.toIso8601String().split('T').first;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void showDialogMessage(String message) {
              showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (_) {
                  Future.delayed(const Duration(seconds: 2), () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  });

                  return Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            Future<void> saveLog() async {
              if (exerciseController.text.trim().isEmpty ||
                  setsController.text.trim().isEmpty ||
                  repsController.text.trim().isEmpty ||
                  (selectedUnit != 'bw' &&
                      weightController.text.trim().isEmpty)) {
                showDialogMessage('Please fill in all fields');
                return;
              }

              final selectedExerciseName = exerciseController.text.trim();

              final exerciseExists = availableExercises.any(
                (exercise) =>
                    exercise.name.toLowerCase() ==
                    selectedExerciseName.toLowerCase(),
              );

              if (!exerciseExists) {
                showDialogMessage(
                  'Please select an exercise from the available list.',
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                final weightValue = selectedUnit == 'bw'
                    ? 0.0
                    : double.parse(weightController.text.trim());
                if (log == null) {
                  await WorkoutLogService.addLog(
                    exerciseName: exerciseController.text.trim(),
                    setsCount: int.parse(setsController.text.trim()),
                    repsCount: int.parse(repsController.text.trim()),
                    weight: weightValue,
                    weightUnit: selectedUnit,
                    isPr: isPr,
                    logDate: formattedDate(),
                  );
                } else {
                  await WorkoutLogService.updateLog(
                    logId: log.id,
                    exerciseName: exerciseController.text.trim(),
                    setsCount: int.parse(setsController.text.trim()),
                    repsCount: int.parse(repsController.text.trim()),
                    weight: weightValue,
                    weightUnit: selectedUnit,
                    isPr: isPr,
                    logDate: formattedDate(),
                  );
                }

                if (!context.mounted) return;
                FocusScope.of(context).unfocus();
                Navigator.pop(context, true);
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                });

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }

            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (picked == null) return;

              setDialogState(() {
                selectedDate = picked;
              });
            }

            return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.92,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log == null
                                  ? 'Add Workout Record'
                                  : 'Edit Workout Record',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// EXERCISE
                            Autocomplete<String>(
                              initialValue: TextEditingValue(
                                text: exerciseController.text,
                              ),
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<String>.empty();
                                }

                                return availableExercises
                                    .map((e) => e.name)
                                    .where(
                                      (name) => name.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      ),
                                    );
                              },
                              onSelected: (value) {
                                exerciseController.text = value;
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              fieldViewBuilder:
                                  (context, controller, focusNode, _) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Search exercises...',
                                        prefixIcon: const Icon(Icons.search),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        exerciseController.text = value;
                                      },
                                    );
                                  },
                            ),

                            const SizedBox(height: 20),

                            /// SETS / REPS / WEIGHT + UNIT
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: setsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Sets',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: TextField(
                                    controller: repsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Reps',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  flex: 2, // 👈 makes weight wider
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: weightController,
                                          keyboardType: TextInputType.number,
                                          enabled: selectedUnit != 'bw',
                                          decoration: InputDecoration(
                                            labelText: 'Weight',
                                            hintText: selectedUnit == 'bw'
                                                ? 'Bodyweight'
                                                : null,
                                          ),
                                        ),
                                      ),

                                      /// UNIT DROPDOWN (RIGHT SIDE)
                                      PopupMenuButton<String>(
                                        initialValue: selectedUnit,
                                        onSelected: (value) {
                                          setDialogState(() {
                                            selectedUnit = value;

                                            if (value == 'bw') {
                                              weightController.clear();
                                            }
                                          });
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'kg',
                                            child: Text('kilograms'),
                                          ),
                                          PopupMenuItem(
                                            value: 'lb',
                                            child: Text('pounds'),
                                          ),
                                          PopupMenuItem(
                                            value: 'bw',
                                            child: Text('bodyweight'),
                                          ),
                                        ],
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6,
                                            top: 18,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                selectedUnit,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.keyboard_arrow_down,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            /// PR SWITCH
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Personal Record'),
                              value: isPr,
                              onChanged: (value) {
                                setDialogState(() {
                                  isPr = value;
                                });
                              },
                            ),

                            /// DATE
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today),
                              title: Text('Date: ${formattedDate()}'),
                              onTap: pickDate,
                            ),

                            const SizedBox(height: 16),

                            /// BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          Navigator.pop(context, false);
                                        },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          saveLog();
                                        },
                                  child: Text(isSaving ? 'Saving...' : 'Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // exerciseController.dispose();
    // setsController.dispose();
    // repsController.dispose();
    // weightController.dispose();

    if (result == true) {
      loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddEditRecordDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showPrsOnly = false;
                      });
                    },
                    child: Container(
                      height: 44,
                      color: !showPrsOnly
                          ? Colors.blue.withOpacity(0.12)
                          : Colors.transparent,
                      alignment: Alignment.center,
                      child: const Text(
                        'Workouts',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showPrsOnly = true;
                      });
                    },
                    child: Container(
                      height: 44,
                      color: showPrsOnly
                          ? Colors.blue.withOpacity(0.12)
                          : Colors.transparent,
                      alignment: Alignment.center,
                      child: const Text(
                        'Personal Records',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    final filteredLogs = showPrsOnly
        ? logs.where((log) => log.isPr).toList()
        : logs.where((log) => !log.isPr).toList();

    final visibleLogs = sortLogs(filteredLogs);

    if (visibleLogs.isEmpty) {
      return Center(
        child: Text(showPrsOnly ? 'No PRs yet.' : 'No workout logs yet.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showPrsOnly)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade600),
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.question_mark, size: 16),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Personal Records'),
                            content: const Text(
                              'A Personal Record (PR) is your best performance for an exercise.\n\n'
                              'This tab keeps your PR workouts separate, so you can quickly track your strongest lifts and progress over time.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),

              PopupMenuButton<LogSortType>(
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
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 20),
                      const SizedBox(width: 6),
                      Text(getSortLabel()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadLogs,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: visibleLogs.length,
              itemBuilder: (context, index) {
                final log = visibleLogs[index];
                logKeys.putIfAbsent(log.id, () => GlobalKey());
                return Container(
                  key: logKeys[log.id],
                  child: _buildLogCard(log),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(WorkoutLog log) {
    final isHighlighted = log.id == activeHighlightLogId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHighlighted ? Colors.green : Colors.grey.shade400,
          width: isHighlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isHighlighted ? Colors.green.withOpacity(0.1) : Colors.white,
      ),
      child: Row(
        children: [
          Image.asset(
            ExerciseImageHelper.getImagePath(log.exerciseName),
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 👈 IMPORTANT
              mainAxisSize: MainAxisSize.min, // 👈 IMPORTANT
              children: [
                Text(
                  '${log.exerciseName} - ${_formatWeight(log)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2), // 👈 smaller spacing
                Text(
                  '${log.setsCount} x ${log.repsCount} reps • ${log.logDate}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  openAddEditRecordDialog(log: log);
                },
                icon: const Icon(Icons.edit, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete'),
                      content: const Text('Delete this log?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
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
                    loadLogs();
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
