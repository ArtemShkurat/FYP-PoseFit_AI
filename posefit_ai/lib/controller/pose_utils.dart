import 'dart:math';
import '../model/pose_landmark.dart';
import '../model/pose_result.dart';

class PoseUtils {
  // MediaPipe Pose landmark indexes
  static const int nose = 0;

  static const int leftShoulder = 11;
  static const int rightShoulder = 12;

  static const int leftElbow = 13;
  static const int rightElbow = 14;

  static const int leftWrist = 15;
  static const int rightWrist = 16;

  static const int leftHip = 23;
  static const int rightHip = 24;

  static const int leftKnee = 25;
  static const int rightKnee = 26;

  static const int leftAnkle = 27;
  static const int rightAnkle = 28;

  static PoseLandmark? getLandmark(List<PoseLandmark> landmarks, int index) {
    try {
      return landmarks.firstWhere((landmark) => landmark.index == index);
    } catch (_) {
      return null;
    }
  }

  static bool hasRequiredLandmarks(PoseResult poseResult, List<int> indexes) {
    if (!poseResult.poseDetected) return false;

    for (final index in indexes) {
      if (getLandmark(poseResult.landmarks, index) == null) {
        return false;
      }
    }

    return true;
  }

  static double calculateDistance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);

    double angle = radians * 180 / pi;
    angle = angle.abs();

    if (angle > 180) {
      angle = 360 - angle;
    }

    return angle;
  }

  static double? getLeftElbowAngle(PoseResult poseResult) {
    final shoulder = getLandmark(poseResult.landmarks, leftShoulder);
    final elbow = getLandmark(poseResult.landmarks, leftElbow);
    final wrist = getLandmark(poseResult.landmarks, leftWrist);

    if (shoulder == null || elbow == null || wrist == null) {
      return null;
    }

    return calculateAngle(shoulder, elbow, wrist);
  }

  static double? getRightElbowAngle(PoseResult poseResult) {
    final shoulder = getLandmark(poseResult.landmarks, rightShoulder);
    final elbow = getLandmark(poseResult.landmarks, rightElbow);
    final wrist = getLandmark(poseResult.landmarks, rightWrist);

    if (shoulder == null || elbow == null || wrist == null) {
      return null;
    }

    return calculateAngle(shoulder, elbow, wrist);
  }

  static double? getLeftKneeAngle(PoseResult poseResult) {
    final hip = getLandmark(poseResult.landmarks, leftHip);
    final knee = getLandmark(poseResult.landmarks, leftKnee);
    final ankle = getLandmark(poseResult.landmarks, leftAnkle);

    if (hip == null || knee == null || ankle == null) {
      return null;
    }

    return calculateAngle(hip, knee, ankle);
  }

  static double? getRightKneeAngle(PoseResult poseResult) {
    final hip = getLandmark(poseResult.landmarks, rightHip);
    final knee = getLandmark(poseResult.landmarks, rightKnee);
    final ankle = getLandmark(poseResult.landmarks, rightAnkle);

    if (hip == null || knee == null || ankle == null) {
      return null;
    }

    return calculateAngle(hip, knee, ankle);
  }

  static double? getLeftHipAngle(PoseResult poseResult) {
    final shoulder = getLandmark(poseResult.landmarks, leftShoulder);
    final hip = getLandmark(poseResult.landmarks, leftHip);
    final knee = getLandmark(poseResult.landmarks, leftKnee);

    if (shoulder == null || hip == null || knee == null) {
      return null;
    }

    return calculateAngle(shoulder, hip, knee);
  }

  static double? getRightHipAngle(PoseResult poseResult) {
    final shoulder = getLandmark(poseResult.landmarks, rightShoulder);
    final hip = getLandmark(poseResult.landmarks, rightHip);
    final knee = getLandmark(poseResult.landmarks, rightKnee);

    if (shoulder == null || hip == null || knee == null) {
      return null;
    }

    return calculateAngle(shoulder, hip, knee);
  }

  static double? getRightShoulderAngle(PoseResult poseResult) {
    final shoulder = getLandmark(poseResult.landmarks, rightShoulder);
    final elbow = getLandmark(poseResult.landmarks, rightElbow);
    final hip = getLandmark(poseResult.landmarks, rightHip);

    if (shoulder == null || elbow == null || hip == null) return null;

    return calculateAngle(hip, shoulder, elbow);
  }

  static double? getLeftShoulderAngle(PoseResult poseResult) {
    final shoulder = getLandmark(poseResult.landmarks, leftShoulder);
    final elbow = getLandmark(poseResult.landmarks, leftElbow);
    final hip = getLandmark(poseResult.landmarks, leftHip);

    if (shoulder == null || elbow == null || hip == null) return null;

    return calculateAngle(hip, shoulder, elbow);
  }

  static Map<String, double?> extractBasicFeatures(PoseResult poseResult) {
    return {
      'leftElbowAngle': getLeftElbowAngle(poseResult),
      'rightElbowAngle': getRightElbowAngle(poseResult),
      'leftKneeAngle': getLeftKneeAngle(poseResult),
      'rightKneeAngle': getRightKneeAngle(poseResult),
      'leftHipAngle': getLeftHipAngle(poseResult),
      'rightHipAngle': getRightHipAngle(poseResult),
      'leftShoulderAngle': getLeftShoulderAngle(poseResult),
      'rightShoulderAngle': getRightShoulderAngle(poseResult),
    };
  }
}

enum CurlStage { up, down, unknown }

class CurlDetectionResult {
  final CurlStage stage;
  final double? angle;

  const CurlDetectionResult({required this.stage, required this.angle});
}

class CurlLogic {
  static CurlDetectionResult detectStageFromAngle(double? angle) {
    if (angle == null) {
      return const CurlDetectionResult(stage: CurlStage.unknown, angle: null);
    }

    if (angle < 60) {
      return CurlDetectionResult(stage: CurlStage.up, angle: angle);
    }

    if (angle > 150) {
      return CurlDetectionResult(stage: CurlStage.down, angle: angle);
    }

    return CurlDetectionResult(stage: CurlStage.unknown, angle: angle);
  }

  static CurlDetectionResult detectUsingRightArm(PoseResult poseResult) {
    final angle = PoseUtils.getRightElbowAngle(poseResult);
    return detectStageFromAngle(angle);
  }

  static CurlDetectionResult detectUsingLeftArm(PoseResult poseResult) {
    final angle = PoseUtils.getLeftElbowAngle(poseResult);
    return detectStageFromAngle(angle);
  }

  static CurlDetectionResult detectUsingBestArm(PoseResult poseResult) {
    final leftAngle = PoseUtils.getLeftElbowAngle(poseResult);
    final rightAngle = PoseUtils.getRightElbowAngle(poseResult);

    if (leftAngle == null && rightAngle == null) {
      return const CurlDetectionResult(stage: CurlStage.unknown, angle: null);
    }

    if (leftAngle != null && rightAngle == null) {
      return detectStageFromAngle(leftAngle);
    }

    if (rightAngle != null && leftAngle == null) {
      return detectStageFromAngle(rightAngle);
    }

    final bestAngle = leftAngle! < rightAngle! ? leftAngle : rightAngle;

    return detectStageFromAngle(bestAngle);
  }
}

class RepCounter {
  int reps = 0;
  CurlStage _lastConfirmedStage = CurlStage.unknown;
  bool _reachedUp = false;

  int update(CurlStage currentStage) {
    // Ignore unknown stages completely
    if (currentStage == CurlStage.unknown) {
      return reps;
    }

    // Only react when the stage really changes
    if (currentStage != _lastConfirmedStage) {
      if (currentStage == CurlStage.up) {
        _reachedUp = true;
      }

      if (currentStage == CurlStage.down && _reachedUp) {
        reps++;
        _reachedUp = false;
      }

      _lastConfirmedStage = currentStage;
    }

    return reps;
  }

  void reset() {
    reps = 0;
    _lastConfirmedStage = CurlStage.unknown;
    _reachedUp = false;
  }
}

enum SquatStage { standing, down, unknown }

class SquatDetectionResult {
  final SquatStage stage;
  final double? kneeAngle;
  final double? hipAngle;

  const SquatDetectionResult({
    required this.stage,
    required this.kneeAngle,
    required this.hipAngle,
  });
}

class SquatLogic {
  static SquatDetectionResult detectStageFromAngles({
    required double? kneeAngle,
    required double? hipAngle,
  }) {
    if (kneeAngle == null || hipAngle == null) {
      return SquatDetectionResult(
        stage: SquatStage.unknown,
        kneeAngle: kneeAngle,
        hipAngle: hipAngle,
      );
    }

    if (kneeAngle > 155 && hipAngle > 140) {
      return SquatDetectionResult(
        stage: SquatStage.standing,
        kneeAngle: kneeAngle,
        hipAngle: hipAngle,
      );
    }

    if (kneeAngle < 110 && hipAngle < 130) {
      return SquatDetectionResult(
        stage: SquatStage.down,
        kneeAngle: kneeAngle,
        hipAngle: hipAngle,
      );
    }

    return SquatDetectionResult(
      stage: SquatStage.unknown,
      kneeAngle: kneeAngle,
      hipAngle: hipAngle,
    );
  }

  static SquatDetectionResult detectUsingRightSide(PoseResult poseResult) {
    final kneeAngle = PoseUtils.getRightKneeAngle(poseResult);
    final hipAngle = PoseUtils.getRightHipAngle(poseResult);

    return detectStageFromAngles(kneeAngle: kneeAngle, hipAngle: hipAngle);
  }

  static SquatDetectionResult detectUsingLeftSide(PoseResult poseResult) {
    final kneeAngle = PoseUtils.getLeftKneeAngle(poseResult);
    final hipAngle = PoseUtils.getLeftHipAngle(poseResult);

    return detectStageFromAngles(kneeAngle: kneeAngle, hipAngle: hipAngle);
  }
}

class SquatRepCounter {
  int reps = 0;
  SquatStage _lastConfirmedStage = SquatStage.unknown;
  bool _reachedDown = false;

  int update(SquatStage currentStage) {
    if (currentStage == SquatStage.unknown) {
      return reps;
    }

    if (currentStage != _lastConfirmedStage) {
      if (currentStage == SquatStage.down) {
        _reachedDown = true;
      }

      if (currentStage == SquatStage.standing && _reachedDown) {
        reps++;
        _reachedDown = false;
      }

      _lastConfirmedStage = currentStage;
    }

    return reps;
  }

  void reset() {
    reps = 0;
    _lastConfirmedStage = SquatStage.unknown;
    _reachedDown = false;
  }
}

enum LateralRaiseStage { down, up, unknown }

class LateralRaiseResult {
  final LateralRaiseStage stage;
  final double? shoulderAngle;

  const LateralRaiseResult({required this.stage, required this.shoulderAngle});
}

class LateralRaiseLogic {
  static LateralRaiseResult detect(PoseResult pose) {
    final angle = PoseUtils.getRightShoulderAngle(pose);

    if (angle == null) {
      return const LateralRaiseResult(
        stage: LateralRaiseStage.unknown,
        shoulderAngle: null,
      );
    }

    if (angle < 30) {
      return LateralRaiseResult(
        stage: LateralRaiseStage.down,
        shoulderAngle: angle,
      );
    }

    if (angle > 70) {
      return LateralRaiseResult(
        stage: LateralRaiseStage.up,
        shoulderAngle: angle,
      );
    }

    return LateralRaiseResult(
      stage: LateralRaiseStage.unknown,
      shoulderAngle: angle,
    );
  }
}

class LateralRaiseRepCounter {
  int reps = 0;
  LateralRaiseStage _lastStage = LateralRaiseStage.unknown;
  bool _reachedUp = false;

  int update(LateralRaiseStage current) {
    if (current == LateralRaiseStage.unknown) return reps;

    if (current != _lastStage) {
      if (current == LateralRaiseStage.up) {
        _reachedUp = true;
      }

      if (current == LateralRaiseStage.down && _reachedUp) {
        reps++;
        _reachedUp = false;
      }

      _lastStage = current;
    }

    return reps;
  }

  void reset() {
    reps = 0;
    _lastStage = LateralRaiseStage.unknown;
    _reachedUp = false;
  }
}
