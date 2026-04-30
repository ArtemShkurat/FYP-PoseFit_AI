import 'package:flutter/services.dart';
import '../model/pose_result.dart';

class PoseService {
  static const MethodChannel _channel = MethodChannel(
    'posefit_ai/pose_landmarker',
  );

  static Future<void> initialize() async {
    await _channel.invokeMethod('initializePoseLandmarker');
  }

  static Future<PoseResult> detectPoseFromImage({
    required String imagePath,
  }) async {
    final result = await _channel.invokeMethod('detectPoseFromImage', {
      'imagePath': imagePath,
    });

    if (result == null) {
      return PoseResult.empty();
    }

    return PoseResult.fromMap(result as Map<dynamic, dynamic>);
  }

  static Future<PoseResult> detectPoseFromFrame({
    required List<Uint8List> planes,
    required List<int> bytesPerRow,
    required List<int?> bytesPerPixel,
    required int width,
    required int height,
    required int rotation,
  }) async {
    final result = await _channel.invokeMethod('detectPoseFromFrame', {
      'planes': planes,
      'bytesPerRow': bytesPerRow,
      'bytesPerPixel': bytesPerPixel,
      'width': width,
      'height': height,
      'rotation': rotation,
    });

    if (result == null) {
      return PoseResult.empty();
    }

    return PoseResult.fromMap(result as Map<dynamic, dynamic>);
  }

  static Future<void> dispose() async {
    await _channel.invokeMethod('disposePoseLandmarker');
  }
}
