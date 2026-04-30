import 'dart:convert';
import 'package:http/http.dart' as http;

class ExercisePrediction {
  final String prediction;
  final double confidence;

  ExercisePrediction({required this.prediction, required this.confidence});
}

class ExerciseSampleService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  static Future<void> saveSample({
    required String exerciseLabel,
    required Map<String, double?> features,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/exercise-samples'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'exercise_label': exerciseLabel, 'features': features}),
    );
  }

  static Future<ExercisePrediction?> predictExercise(
    Map<String, double?> features,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict-exercise'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return ExercisePrediction(
        prediction: data['prediction'] ?? 'Unknown',
        confidence: (data['confidence'] ?? 0.0).toDouble(),
      );
    }

    return null;
  }
}
