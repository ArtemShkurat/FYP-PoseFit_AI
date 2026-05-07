import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/workout_log.dart';
import 'auth_service.dart';

class WorkoutLogService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  static Future<List<WorkoutLog>> getLogs() async {
    final userId = await AuthService.getUserId();

    final response = await http.get(
      Uri.parse('$baseUrl/workout-logs?user_id=$userId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List logs = data['logs'];
      return logs.map((item) => WorkoutLog.fromJson(item)).toList();
    }

    throw Exception(data['message'] ?? 'Failed to load logs');
  }

  static Future<void> addLog({
    required String exerciseName,
    required int setsCount,
    required int repsCount,
    required double weight,
    required String weightUnit,
    required bool isPr,
    required String logDate,
  }) async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('No logged-in user found.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/workout-logs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': int.parse(userId),
        'exercise_name': exerciseName,
        'sets_count': setsCount,
        'reps_count': repsCount,
        'weight': weight,
        'weight_unit': weightUnit,
        'is_pr': isPr,
        'log_date': logDate,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to add workout log');
    }
  }

  static Future<void> updateLog({
    required int logId,
    required String exerciseName,
    required int setsCount,
    required int repsCount,
    required double weight,
    required String weightUnit,
    required bool isPr,
    required String logDate,
  }) async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('No logged-in user found.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/workout-logs/$logId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': int.parse(userId),
        'exercise_name': exerciseName,
        'sets_count': setsCount,
        'reps_count': repsCount,
        'weight': weight,
        'weight_unit': weightUnit,
        'is_pr': isPr,
        'log_date': logDate,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update workout log');
    }
  }

  static Future<void> deleteLog(int logId) async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('No logged-in user found.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/workout-logs/$logId?user_id=$userId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete workout log');
    }
  }
}
