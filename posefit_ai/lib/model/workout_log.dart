class WorkoutLog {
  final int id;
  final int userId;
  final String exerciseName;
  final int setsCount;
  final int repsCount;
  final double weight;
  final String weightUnit;
  final bool isPr;
  final String logDate;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.setsCount,
    required this.repsCount,
    required this.weight,
    required this.weightUnit,
    required this.isPr,
    required this.logDate,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'],
      userId: json['user_id'],
      exerciseName: json['exercise_name'] ?? '',
      setsCount: json['sets_count'] ?? 0,
      repsCount: json['reps_count'] ?? 0,
      weight: double.tryParse(json['weight'].toString()) ?? 0.0,
      weightUnit: json['weight_unit'] ?? 'kg',
      isPr: json['is_pr'] == 1 || json['is_pr'] == true,
      logDate: json['log_date'] ?? '',
    );
  }
}
