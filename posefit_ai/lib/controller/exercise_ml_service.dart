import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ExerciseMlPrediction {
  final String prediction;
  final double confidence;

  ExerciseMlPrediction({required this.prediction, required this.confidence});
}

class ExerciseMlService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static List<String> _featureNames = [];
  static List<double> _mean = [];
  static List<double> _scale = [];

  static Future<void> initialize() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/ml/exercise_classifier.tflite',
    );

    final labelsJson = await rootBundle.loadString('assets/ml/labels.json');
    _labels = List<String>.from(jsonDecode(labelsJson));

    final featuresJson = await rootBundle.loadString(
      'assets/ml/feature_names.json',
    );
    _featureNames = List<String>.from(jsonDecode(featuresJson));

    final scalerJson = await rootBundle.loadString(
      'assets/ml/feature_scaler.json',
    );
    final scalerData = jsonDecode(scalerJson);

    _mean = List<double>.from(
      scalerData['mean'].map((value) => value.toDouble()),
    );

    _scale = List<double>.from(
      scalerData['scale'].map((value) => value.toDouble()),
    );
  }

  static Future<ExerciseMlPrediction?> predict(
    Map<String, double?> features,
  ) async {
    if (_interpreter == null) {
      await initialize();
    }

    final inputValues = <double>[];

    for (int i = 0; i < _featureNames.length; i++) {
      final featureName = _featureNames[i];
      final rawValue = features[featureName] ?? 0.0;

      final scaledValue = (rawValue - _mean[i]) / _scale[i];
      inputValues.add(scaledValue);
    }

    final input = [inputValues];

    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    _interpreter!.run(input, output);

    final probabilities = output[0];

    int bestIndex = 0;
    double bestConfidence = probabilities[0];

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > bestConfidence) {
        bestIndex = i;
        bestConfidence = probabilities[i];
      }
    }

    return ExerciseMlPrediction(
      prediction: _labels[bestIndex],
      confidence: bestConfidence,
    );
  }
}
