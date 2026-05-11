import 'package:flutter/material.dart';

import '../../controller/workout_log_service.dart';
import '../../model/exercise.dart';
import '../../model/workout_log.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_sizes.dart';
import '../../utils/app_text_styles.dart';
import 'dialog_text_field.dart';
import 'app_message_popup.dart';

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

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> saveLog() async {
            if (exerciseController.text.trim().isEmpty ||
                setsController.text.trim().isEmpty ||
                repsController.text.trim().isEmpty ||
                (selectedUnit != 'bw' &&
                    weightController.text.trim().isEmpty)) {
              showAppMessagePopup(
                context: context,
                message: 'Please fill in all fields',
                isError: true,
              );
              return;
            }

            final selectedExerciseName = exerciseController.text.trim();

            final exerciseExists = availableExercises.any(
              (exercise) =>
                  exercise.name.toLowerCase() ==
                  selectedExerciseName.toLowerCase(),
            );

            if (!exerciseExists) {
              showAppMessagePopup(
                context: context,
                message: 'Please select an exercise from the available list.',
                isError: true,
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
            } catch (e) {
              setDialogState(() {
                isSaving = false;
              });

              showAppMessagePopup(
                context: context,
                message: 'Error: $e',
                isError: true,
              );
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

          return Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.92,
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
                        style: AppTextStyles.sectionTitle,
                      ),

                      const SizedBox(height: 20),

                      if (prefillExerciseName != null)
                        DialogTextField(
                          controller: exerciseController,
                          hintText: 'Exercise',
                          prefixIcon: Icons.fitness_center,
                          enabled: false,
                        )
                      else
                        Autocomplete<String>(
                          initialValue: TextEditingValue(
                            text: exerciseController.text,
                          ),
                          optionsBuilder: (textEditingValue) {
                            final query = textEditingValue.text
                                .trim()
                                .toLowerCase();

                            if (query.isEmpty) {
                              return const Iterable<String>.empty();
                            }

                            return availableExercises
                                .map((exercise) => exercise.name)
                                .where(
                                  (name) => name.toLowerCase().contains(query),
                                );
                          },
                          onSelected: (value) {
                            exerciseController.text = value;
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, _) {
                                return DialogTextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  hintText: 'Search exercises...',
                                  prefixIcon: Icons.search,
                                  onChanged: (value) {
                                    exerciseController.text = value;
                                  },
                                );
                              },
                        ),

                      const SizedBox(height: 20),

                      /// SETS + REPS / WEIGHT + UNIT
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DialogTextField(
                                  controller: setsController,
                                  labelText: 'Sets',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DialogTextField(
                                  controller: repsController,
                                  labelText: 'Reps',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: DialogTextField(
                                  controller: weightController,
                                  labelText: 'Weight',
                                  hintText: selectedUnit == 'bw'
                                      ? 'Bodyweight'
                                      : null,
                                  keyboardType: TextInputType.number,
                                  enabled: selectedUnit != 'bw',
                                ),
                              ),

                              const SizedBox(width: 12),

                              PopupMenuButton<String>(
                                initialValue: selectedUnit,
                                color: AppColors.card,
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
                                child: Container(
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.buttonRadius,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        selectedUnit,
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.softText,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.aiMint,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primaryGreen,
                        activeTrackColor: AppColors.primaryGreen.withValues(
                          alpha: 0.35,
                        ),
                        title: const Text(
                          'Personal Record',
                          style: AppTextStyles.body,
                        ),
                        value: isPr,
                        onChanged: (value) {
                          setDialogState(() {
                            isPr = value;
                          });
                        },
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.calendar_today,
                          color: AppColors.aiMint,
                        ),
                        title: Text(
                          'Date: ${formattedDate()}',
                          style: AppTextStyles.body,
                        ),
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
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.secondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSaving ? null : saveLog,
                            child: Text(
                              isSaving ? 'Saving...' : 'Save',
                              style: AppTextStyles.buttonText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  exerciseController.dispose();
  setsController.dispose();
  repsController.dispose();
  weightController.dispose();

  return result;
}
