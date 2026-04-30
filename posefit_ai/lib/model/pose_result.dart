import 'pose_landmark.dart';

class PoseResult {
  final bool poseDetected;
  final List<PoseLandmark> landmarks;

  const PoseResult({required this.poseDetected, required this.landmarks});

  factory PoseResult.empty() {
    return const PoseResult(poseDetected: false, landmarks: []);
  }

  factory PoseResult.fromMap(Map<dynamic, dynamic> map) {
    final rawLandmarks = (map['landmarks'] as List<dynamic>? ?? []);

    return PoseResult(
      poseDetected: map['poseDetected'] as bool? ?? false,
      landmarks: rawLandmarks
          .map((item) => PoseLandmark.fromMap(item as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}
