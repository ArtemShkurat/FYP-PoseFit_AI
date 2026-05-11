import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../controller/exercise_service.dart';
import '../../model/exercise.dart';
import '../../utils/exercise_image_helper.dart';
import '../widgets/search_field.dart';
import '../widgets/exercise_list_tile.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Exercise> allExercises = [];

  String selectedCategory = '';
  Exercise? selectedExercise;
  String searchQuery = '';

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  Future<void> loadExercises() async {
    try {
      final loadedExercises = await ExerciseService.getExercises();

      if (!mounted) return;

      setState(() {
        allExercises = loadedExercises;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load exercises.';
      });
    }
  }

  List<String> get categories {
    final categorySet = allExercises
        .map((exercise) => exercise.category)
        .toSet()
        .toList();

    categorySet.sort();

    return ['All', ...categorySet];
  }

  void openCategory(String category) {
    setState(() {
      selectedCategory = category;
      selectedExercise = null;
      searchQuery = '';
    });
  }

  void openExercise(Exercise exercise) {
    Navigator.pushNamed(context, '/exercise-details', arguments: exercise);
  }

  void goBack() {
    setState(() {
      if (selectedExercise != null) {
        selectedExercise = null;
      } else {
        selectedCategory = '';
        searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Exercises', style: AppTextStyles.sectionTitle),
        ),
        body: Center(child: Text(errorMessage!, style: AppTextStyles.body)),
      );
    }

    if (selectedCategory.isNotEmpty) {
      return _exerciseListScreen();
    }

    return _bodyPartsScreen();
  }

  // ================= BODY PARTS SCREEN =================

  Widget _bodyPartsScreen() {
    final filteredExercises =
        allExercises
            .where(
              (exercise) => exercise.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exercises', style: AppTextStyles.heading),

            const SizedBox(height: 8),

            const Text(
              'Browse exercises by muscle group or search directly.',
              style: AppTextStyles.body,
            ),

            const SizedBox(height: 20),

            SearchField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: AppSizes.itemSpacing),

            Expanded(
              child: isSearching
                  ? filteredExercises.isEmpty
                        ? const Center(
                            child: Text(
                              'No exercises found',
                              style: AppTextStyles.body,
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];

                              return ExerciseListTile(
                                exercise: exercise,
                                subtitle: exercise.category,
                                onTap: () => openExercise(exercise),
                              );
                            },
                          )
                  : GridView.builder(
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppSizes.itemSpacing,
                            crossAxisSpacing: AppSizes.itemSpacing,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        return GestureDetector(
                          onTap: () => openCategory(category),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(
                                AppSizes.cardRadius,
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    ExerciseImageHelper.getBodyPartImage(
                                      category,
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  category.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.softText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EXERCISE LIST SCREEN =================

  Widget _exerciseListScreen() {
    final list = allExercises.where((exercise) {
      final matchesCategory =
          selectedCategory == 'All' || exercise.category == selectedCategory;

      final matchesSearch = exercise.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      return matchesCategory && matchesSearch;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.softText),
          onPressed: goBack,
        ),
        title: Text(
          selectedCategory == 'All'
              ? 'All Exercises'
              : '$selectedCategory Exercises',
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          children: [
            SearchField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises found',
                        style: AppTextStyles.body,
                      ),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final exercise = list[index];

                        return ExerciseListTile(
                          exercise: exercise,
                          subtitle: exercise.muscleGroup,
                          onTap: () => openExercise(exercise),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
