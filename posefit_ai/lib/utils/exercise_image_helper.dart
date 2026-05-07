class ExerciseImageHelper {
  static String getImagePath(String exerciseName) {
    final key = exerciseName.toLowerCase().trim();

    // ===== EXERCISE IMAGES =====
    switch (key) {
      case 'bench press':
        return 'assets/exercises/bench_press-removebg-preview.png';
      case 'biceps curl':
        return 'assets/exercises/biceps_curl-removebg-preview.png';
      case 'lateral raise':
        return 'assets/exercises/lateral_raise-removebg-preview.png';
      case 'pull up':
        return 'assets/exercises/pull_up-removebg-preview.png';
      case 'squat':
      case 'squads':
        return 'assets/exercises/squat-removebg-preview.png';
      case 'triceps extension':
        return 'assets/exercises/triceps_extension-removebg-preview.png';
      default:
        return 'assets/exercises/default.png';
    }
  }

  // ===== BODY PART IMAGES =====
  static String getBodyPartImage(String category) {
    final key = category.toLowerCase();

    switch (key) {
      case 'chest':
        return 'assets/body_parts/chest-removebg-preview.png';
      case 'back':
        return 'assets/body_parts/back-removebg-preview.png';
      case 'legs':
        return 'assets/body_parts/legs-removebg-preview.png';
      case 'shoulders':
        return 'assets/body_parts/shoulders-removebg-preview.png';
      case 'arms':
      case 'biceps':
        return 'assets/body_parts/biceps-removebg-preview.png';
      case 'triceps':
        return 'assets/body_parts/triceps-removebg-preview.png';
      case 'core':
      case 'abs':
        return 'assets/body_parts/core-removebg-preview.png';
      case 'all':
        return 'assets/body_parts/all-removebg-preview.png';
      default:
        return 'assets/body_parts/all-removebg-preview.png';
    }
  }
}
