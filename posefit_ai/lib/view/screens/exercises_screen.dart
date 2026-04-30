import 'package:flutter/material.dart';
import '../../controller/exercise_service.dart';
import '../../model/exercise.dart';

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Exercises'),
        ),
        body: Center(child: Text(errorMessage!)),
      );
    }

    if (selectedExercise != null) {
      return _exerciseDetailsScreen();
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Exercises'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isSearching
                  ? filteredExercises.isEmpty
                        ? const Center(child: Text('No exercises found'))
                        : ListView.builder(
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];

                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.fitness_center),
                                ),
                                title: Text(exercise.name),
                                subtitle: Text(exercise.category),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => openExercise(exercise),
                              );
                            },
                          )
                  : GridView.builder(
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        return GestureDetector(
                          onTap: () => openCategory(category),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.accessibility_new, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  category.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBack,
        ),
        title: Text(
          selectedCategory == 'All'
              ? 'All Exercises'
              : '$selectedCategory Exercises',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('No exercises found'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final exercise = list[index];

                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.fitness_center),
                          ),
                          title: Text(exercise.name),
                          subtitle: Text(exercise.muscleGroup),
                          trailing: const Icon(Icons.chevron_right),
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

  // ================= EXERCISE DETAILS SCREEN =================

  Widget _exerciseDetailsScreen() {
    final exercise = selectedExercise!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBack,
        ),
        title: Text(exercise.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.isCameraSupported)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Camera detection supported',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  exercise.muscleGroup.isNotEmpty
                      ? exercise.muscleGroup
                      : 'Muscle group',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Overview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(exercise.description),

            const SizedBox(height: 20),

            const Text(
              'Instructions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(exercise.instructions),

            const SizedBox(height: 20),

            const Text(
              'Tips',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(exercise.tips),
          ],
        ),
      ),
    );
  }
}
