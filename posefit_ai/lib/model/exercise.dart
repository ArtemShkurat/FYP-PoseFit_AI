class Exercise {
  final int id;
  final String name;
  final String category;
  final String description;
  final String instructions;
  final String tips;
  final String muscleGroup;
  final bool isCameraSupported;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.instructions,
    required this.tips,
    required this.muscleGroup,
    required this.isCameraSupported,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      instructions: json['instructions'] ?? '',
      tips: json['tips'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      isCameraSupported:
          json['is_camera_supported'] == 1 ||
          json['is_camera_supported'] == true,
    );
  }
}
