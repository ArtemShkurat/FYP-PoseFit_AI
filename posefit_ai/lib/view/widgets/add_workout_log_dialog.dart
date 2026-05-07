import 'package:flutter/material.dart';
import '../../controller/workout_log_service.dart';
import '../../model/exercise.dart';
import '../../model/workout_log.dart';

Future<bool?> showAddWorkoutLogDialog({
  required BuildContext context,
  required List<Exercise> availableExercises,
  WorkoutLog? log,
  String? prefillExerciseName,
}) async {
  final exerciseController = TextEditingController(
    text: log?.exerciseName ?? prefillExerciseName ?? '',
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

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> saveLog() async {
            final selectedExerciseName = exerciseController.text.trim();

            if (selectedExerciseName.isEmpty ||
                setsController.text.trim().isEmpty ||
                repsController.text.trim().isEmpty ||
                (selectedUnit != 'bw' &&
                    weightController.text.trim().isEmpty)) {
              return;
            }

            final exerciseExists = availableExercises.any(
              (exercise) =>
                  exercise.name.toLowerCase() ==
                  selectedExerciseName.toLowerCase(),
            );

            if (!exerciseExists) {
              return;
            }

            setDialogState(() {
              isSaving = true;
            });

            final weightValue = selectedUnit == 'bw'
                ? 0.0
                : double.parse(weightController.text.trim());

            if (log == null) {
              await WorkoutLogService.addLog(
                exerciseName: selectedExerciseName,
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
                exerciseName: selectedExerciseName,
                setsCount: int.parse(setsController.text.trim()),
                repsCount: int.parse(repsController.text.trim()),
                weight: weightValue,
                weightUnit: selectedUnit,
                isPr: isPr,
                logDate: formattedDate(),
              );
            }

            if (!context.mounted) return;
            Navigator.pop(context, true);
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

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: exerciseController,
                      readOnly: prefillExerciseName != null,
                      decoration: InputDecoration(
                        hintText: 'Search exercises...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                          flex: 2,
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
                                      Text(selectedUnit),
                                      const Icon(Icons.keyboard_arrow_down),
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

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Date: ${formattedDate()}'),
                      onTap: pickDate,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSaving ? null : saveLog,
                          child: Text(isSaving ? 'Saving...' : 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
