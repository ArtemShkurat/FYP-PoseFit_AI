import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/exercise.dart';

class ExerciseService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  static Future<List<Exercise>> getExercises() async {
    final response = await http.get(Uri.parse('$baseUrl/exercises'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List list = data['exercises'];
      return list.map((item) => Exercise.fromJson(item)).toList();
    }

    throw Exception(data['message'] ?? 'Failed to load exercises');
  }
}
