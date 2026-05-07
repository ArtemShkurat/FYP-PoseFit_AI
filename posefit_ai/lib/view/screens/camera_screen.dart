import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../controller/pose_service.dart';
import '../../controller/pose_utils.dart';
import '../../model/pose_result.dart';
import '../../controller/exercise_sample_service.dart';
import '../../controller/exercise_ml_service.dart';
import '../../controller/exercise_service.dart';
import '../../model/exercise.dart';
import 'camera_settings_screen.dart';

enum ExerciseMode { bicepsCurl, squat, lateralRaise }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  final List<String> _recentPredictions = [];
  List<Exercise> _allExercises = [];

  final List<double> _recentElbowAngles = [];
  final List<double> _recentKneeAngles = [];
  final List<double> _recentHipAngles = [];
  final List<double> _recentShoulderAngles = [];

  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isDisposed = false;
  bool _isInitializing = false;
  bool _isTracking = false;
  bool _isProcessingFrame = false;
  bool _isRecognizingExercise = false;
  bool _isCollectingData = false;
  bool _hasNavigatedFromPrediction = false;
  bool _lastMovementValid = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0;

  int _samplesCollected = 0;
  int _selectedCameraIndex = 0;
  int _stablePredictionCount = 0;
  static const int _movementBufferSize = 12;

  ExerciseMode _selectedExercise = ExerciseMode.bicepsCurl;

  String? _pendingNavigationPrediction;
  String? _errorMessage;
  String _poseStatusText =
      'Exercise: Biceps Curl\nAngle: N/A\nStage: UNKNOWN\nReps: 0';

  final RepCounter _curlRepCounter = RepCounter();
  final SquatRepCounter _squatRepCounter = SquatRepCounter();
  final LateralRaiseRepCounter _lateralRepCounter = LateralRaiseRepCounter();

  String _currentStageText = 'unknown';
  DateTime _lastProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);

  String get _selectedExerciseName {
    switch (_selectedExercise) {
      case ExerciseMode.bicepsCurl:
        return 'Biceps Curl';
      case ExerciseMode.squat:
        return 'Squat';
      case ExerciseMode.lateralRaise:
        return 'Lateral Raise';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndSetupCamera();
    _loadExercises();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopTracking();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndSetupCamera();
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final safeZoom = zoom.clamp(_minZoom, _maxZoom).toDouble();

    await _controller!.setZoomLevel(safeZoom);

    if (!mounted) return;

    setState(() {
      _currentZoom = safeZoom;
    });
  }

  Widget _zoomButton(String label, double zoom) {
    final isSelected = (_currentZoom - zoom).abs() < 0.1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => _setZoom(zoom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.9)
                : Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _addAngleToBuffer(List<double> buffer, double? angle) {
    if (angle == null) return;

    buffer.add(angle);

    if (buffer.length > _movementBufferSize) {
      buffer.removeAt(0);
    }
  }

  double _angleRange(List<double> buffer) {
    if (buffer.length < 4) return 0;

    final minValue = buffer.reduce((a, b) => a < b ? a : b);
    final maxValue = buffer.reduce((a, b) => a > b ? a : b);

    return maxValue - minValue;
  }

  void _clearMovementBuffers() {
    _recentElbowAngles.clear();
    _recentKneeAngles.clear();
    _recentHipAngles.clear();
    _recentShoulderAngles.clear();
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    _initializeControllerFuture = null;

    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}

      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _checkPermissionAndSetupCamera() async {
    if (_isDisposed || _isInitializing) return;

    _isInitializing = true;

    try {
      final status = await Permission.camera.status;

      if (_isDisposed) return;

      if (!status.isGranted) {
        await _disposeCamera();

        if (!mounted) return;

        setState(() {
          _hasPermission = false;
          _isCheckingPermission = false;
          _errorMessage = null;
        });

        return;
      }

      _hasPermission = true;
      await _setupCamera();
    } catch (_) {
      if (!mounted || _isDisposed) return;

      setState(() {
        _errorMessage = 'Failed to initialize camera.';
        _isCheckingPermission = false;
      });
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();

      if (_isDisposed) return;

      if (_cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'No camera found on this device.';
          _isCheckingPermission = false;
        });

        return;
      }

      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = 0;
      }

      await _initializeSelectedCamera();
    } catch (_) {
      if (!mounted || _isDisposed) return;

      await _disposeCamera();

      setState(() {
        _errorMessage = 'Failed to initialize camera.';
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _initializeSelectedCamera() async {
    await _disposeCamera();

    if (_isDisposed) return;

    final selectedCamera = _cameras[_selectedCameraIndex];

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _controller = controller;
    _initializeControllerFuture = controller.initialize();
    await _initializeControllerFuture;

    _minZoom = await _controller!.getMinZoomLevel();
    _maxZoom = await _controller!.getMaxZoomLevel();

    _currentZoom = 1.0.clamp(_minZoom, _maxZoom);

    await _controller!.setZoomLevel(_currentZoom);

    if (!mounted || _isDisposed) return;

    setState(() {
      _errorMessage = null;
      _isCheckingPermission = false;
    });
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  void _resetCurrentExerciseCounter() {
    if (_selectedExercise == ExerciseMode.bicepsCurl) {
      _curlRepCounter.reset();
      _poseStatusText =
          'Exercise: Biceps Curl\nAngle: N/A\nStage: UNKNOWN\nReps: 0\nSamples: 0';
    } else if (_selectedExercise == ExerciseMode.squat) {
      _squatRepCounter.reset();
      _poseStatusText =
          'Exercise: Squat\nKnee: N/A\nHip: N/A\nStage: UNKNOWN\nReps: 0\nSamples: 0';
    } else if (_selectedExercise == ExerciseMode.lateralRaise) {
      _lateralRepCounter.reset();
      _poseStatusText =
          'Exercise: Lateral Raise\nShoulder angle: N/A\nStage: UNKNOWN\nReps: 0\nSamples: 0';
    }

    _currentStageText = 'unknown';
  }

  Future<void> _startTracking() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isStreamingImages) return;

    _resetCurrentExerciseCounter();
    _lastProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);
    _clearMovementBuffers();

    setState(() {
      _isTracking = true;
    });

    _pendingNavigationPrediction = null;
    _stablePredictionCount = 0;

    _hasNavigatedFromPrediction = false;

    await _controller!.startImageStream((CameraImage image) async {
      if (!_isTracking || _isProcessingFrame) return;

      final now = DateTime.now();
      if (now.difference(_lastProcessedTime).inMilliseconds < 300) {
        return;
      }

      _lastProcessedTime = now;
      _isProcessingFrame = true;

      try {
        final PoseResult result = await PoseService.detectPoseFromFrame(
          planes: image.planes.map((p) => Uint8List.fromList(p.bytes)).toList(),
          bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
          bytesPerPixel: image.planes.map((p) => p.bytesPerPixel).toList(),
          width: image.width,
          height: image.height,
          rotation: _controller!.description.sensorOrientation,
        );

        if (!mounted) return;

        if (!result.poseDetected) {
          setState(() {
            _poseStatusText =
                'No pose detected\nStage: ${_currentStageText.toUpperCase()}';
          });
          return;
        }
        _updateMovementBuffers(result);

        final features = PoseUtils.extractBasicFeatures(result);

        if (_isRecognizingExercise) {
          final predictionResult = await ExerciseMlService.predict(features);
          final smoothedPrediction = _getSmoothedPrediction(
            predictionResult?.prediction,
          );
          final confidence = predictionResult?.confidence ?? 0.0;
          final movementValid = _isMovementValidForPrediction(
            smoothedPrediction,
          );

          _lastMovementValid = movementValid;

          await _maybeOpenPredictedExercisePage(
            smoothedPrediction,
            confidence,
            movementValid,
          );

          if (_selectedExercise == ExerciseMode.bicepsCurl) {
            _handleCurlResult(
              result,
              smoothedPrediction,
              confidence,
              movementValid,
            );
          } else if (_selectedExercise == ExerciseMode.squat) {
            _handleSquatResult(
              result,
              smoothedPrediction,
              confidence,
              movementValid,
            );
          } else if (_selectedExercise == ExerciseMode.lateralRaise) {
            _handleLateralRaiseResult(
              result,
              smoothedPrediction,
              confidence,
              movementValid,
            );
          }
        }

        if (_isCollectingData) {
          await ExerciseSampleService.saveSample(
            exerciseLabel: _selectedExerciseName,
            features: features,
          );

          _samplesCollected++;

          _updateRecordingStatus(result);
        }
      } catch (_) {
        // Ignore noisy frame errors for now.
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  void _handleCurlResult(
    PoseResult result,
    String prediction,
    double confidence,
    bool movementValid,
  ) {
    final curlResult = CurlLogic.detectUsingBestArm(result);

    String stageText;
    switch (curlResult.stage) {
      case CurlStage.up:
        stageText = 'UP';
        break;
      case CurlStage.down:
        stageText = 'DOWN';
        break;
      case CurlStage.unknown:
        stageText = 'UNKNOWN';
        break;
    }

    _currentStageText = stageText;

    setState(() {
      _poseStatusText =
          'ML Prediction: $prediction\n'
          'Confidence: ${(confidence * 100).toStringAsFixed(1)}%\n'
          'Movement: ${movementValid ? "VALID" : "NOT VALID"}\n';
    });
  }

  void _handleSquatResult(
    PoseResult result,
    String prediction,
    double confidence,
    bool movementValid,
  ) {
    final squatResult = SquatLogic.detectUsingRightSide(result);

    String stageText;
    switch (squatResult.stage) {
      case SquatStage.standing:
        stageText = 'STANDING';
        break;
      case SquatStage.down:
        stageText = 'DOWN';
        break;
      case SquatStage.unknown:
        stageText = 'UNKNOWN';
        break;
    }

    _currentStageText = stageText;

    setState(() {
      _poseStatusText =
          'ML Prediction: $prediction\n'
          'Confidence: ${(confidence * 100).toStringAsFixed(1)}%\n'
          'Movement: ${movementValid ? "VALID" : "NOT VALID"}\n';
    });
  }

  void _handleLateralRaiseResult(
    PoseResult result,
    String prediction,
    double confidence,
    bool movementValid,
  ) {
    final resultLR = LateralRaiseLogic.detect(result);

    String stageText;
    switch (resultLR.stage) {
      case LateralRaiseStage.up:
        stageText = 'UP';
        break;
      case LateralRaiseStage.down:
        stageText = 'DOWN';
        break;
      case LateralRaiseStage.unknown:
        stageText = 'UNKNOWN';
        break;
    }

    _currentStageText = stageText;

    setState(() {
      _poseStatusText =
          'ML Prediction: $prediction\n'
          'Confidence: ${(confidence * 100).toStringAsFixed(1)}%\n'
          'Movement: ${movementValid ? "VALID" : "NOT VALID"}\n';
    });
  }

  Future<void> _stopTracking() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isTracking = false;
      });
    }
  }

  void _updateRecordingStatus(PoseResult result) {
    if (_selectedExercise == ExerciseMode.bicepsCurl) {
      final rightElbow = PoseUtils.getRightElbowAngle(result);
      final curlResult = CurlLogic.detectUsingBestArm(result);
      final reps = _curlRepCounter.update(curlResult.stage);

      final angleText = rightElbow != null
          ? '${rightElbow.toStringAsFixed(1)}°'
          : 'N/A';

      String stageText;
      switch (curlResult.stage) {
        case CurlStage.up:
          stageText = 'UP';
          break;
        case CurlStage.down:
          stageText = 'DOWN';
          break;
        case CurlStage.unknown:
          stageText = 'UNKNOWN';
          break;
      }

      _currentStageText = stageText;

      setState(() {
        _poseStatusText =
            'Exercise: $_selectedExerciseName\n'
            'Angle: $angleText\n'
            'Stage: $stageText\n'
            'Reps: $reps\n'
            'Samples: $_samplesCollected';
      });
    } else if (_selectedExercise == ExerciseMode.squat) {
      final squatResult = SquatLogic.detectUsingRightSide(result);
      final reps = _squatRepCounter.update(squatResult.stage);

      final kneeText = squatResult.kneeAngle != null
          ? '${squatResult.kneeAngle!.toStringAsFixed(1)}°'
          : 'N/A';

      final hipText = squatResult.hipAngle != null
          ? '${squatResult.hipAngle!.toStringAsFixed(1)}°'
          : 'N/A';

      String stageText;
      switch (squatResult.stage) {
        case SquatStage.standing:
          stageText = 'STANDING';
          break;
        case SquatStage.down:
          stageText = 'DOWN';
          break;
        case SquatStage.unknown:
          stageText = 'UNKNOWN';
          break;
      }

      _currentStageText = stageText;

      setState(() {
        _poseStatusText =
            'Exercise: $_selectedExerciseName\n'
            'Knee: $kneeText\n'
            'Hip: $hipText\n'
            'Stage: $stageText\n'
            'Reps: $reps\n'
            'Samples: $_samplesCollected';
      });
    } else if (_selectedExercise == ExerciseMode.lateralRaise) {
      final lateralResult = LateralRaiseLogic.detect(result);
      final reps = _lateralRepCounter.update(lateralResult.stage);

      final angleText = lateralResult.shoulderAngle != null
          ? '${lateralResult.shoulderAngle!.toStringAsFixed(1)}°'
          : 'N/A';

      String stageText;
      switch (lateralResult.stage) {
        case LateralRaiseStage.up:
          stageText = 'UP';
          break;
        case LateralRaiseStage.down:
          stageText = 'DOWN';
          break;
        case LateralRaiseStage.unknown:
          stageText = 'UNKNOWN';
          break;
      }

      _currentStageText = stageText;

      setState(() {
        _poseStatusText =
            'Exercise: $_selectedExerciseName\n'
            'Shoulder angle: $angleText\n'
            'Stage: $stageText\n'
            'Reps: $reps\n'
            'Samples: $_samplesCollected';
      });
    }
  }

  Future<void> _toggleRecognition() async {
    if (_isRecognizingExercise) {
      _isRecognizingExercise = false;
      await _stopTracking();
    } else {
      _isRecognizingExercise = true;
      _isCollectingData = false;
      _samplesCollected = 0;
      await _startTracking();
    }
  }

  Future<void> _toggleDataRecording() async {
    if (_isCollectingData) {
      _isCollectingData = false;
      await _stopTracking();
    } else {
      _isCollectingData = true;
      _isRecognizingExercise = false;
      _samplesCollected = 0;
      await _startTracking();
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _controller == null) return;

    if (_isTracking) {
      await _stopTracking();
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

    await _initializeSelectedCamera();

    if (!mounted) return;

    setState(() {
      _resetCurrentExerciseCounter();
    });
  }

  Future<void> _openPredictedExercisePage(
    String prediction,
    double confidence,
  ) async {
    if (_hasNavigatedFromPrediction) return;
    if (confidence < 0.85) return;

    Exercise? matchedExercise;

    for (final exercise in _allExercises) {
      if (exercise.name.toLowerCase() == prediction.toLowerCase()) {
        matchedExercise = exercise;
        break;
      }
    }

    if (matchedExercise == null) return;

    _hasNavigatedFromPrediction = true;

    if (_isTracking) {
      await _stopTracking();
    }

    await _stopRecognition();

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      '/exercise-details',
      arguments: {'exercise': matchedExercise, 'askToLog': true},
    ).then((_) {
      _hasNavigatedFromPrediction = false;
    });
  }

  Future<void> _stopRecognition() async {
    if (!_isRecognizingExercise) return;

    setState(() {
      _isRecognizingExercise = false;
    });
  }

  Future<void> _maybeOpenPredictedExercisePage(
    String prediction,
    double confidence,
    bool movementValid,
  ) async {
    if (_hasNavigatedFromPrediction) return;
    if (!movementValid) return;
    if (confidence < 0.90) return;
    if (prediction == 'Unknown') return;

    if (_pendingNavigationPrediction == prediction) {
      _stablePredictionCount++;
    } else {
      _pendingNavigationPrediction = prediction;
      _stablePredictionCount = 1;
    }

    if (_stablePredictionCount < 8) return;

    await _openPredictedExercisePage(prediction, confidence);
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await ExerciseService.getExercises();

      if (!mounted) return;

      setState(() {
        _allExercises = exercises;
      });
    } catch (_) {
      debugPrint('Failed to load exercises for camera navigation.');
    }
  }

  void _changeExercise(ExerciseMode? value) {
    if (value == null || _isTracking) return;

    setState(() {
      _selectedExercise = value;
      _resetCurrentExerciseCounter();
    });
  }

  String _getSmoothedPrediction(String? prediction) {
    if (prediction == null || prediction.trim().isEmpty) {
      return 'Unknown';
    }

    _recentPredictions.add(prediction);

    if (_recentPredictions.length > 7) {
      _recentPredictions.removeAt(0);
    }

    final counts = <String, int>{};

    for (final item in _recentPredictions) {
      counts[item] = (counts[item] ?? 0) + 1;
    }

    String bestPrediction = prediction;
    int bestCount = 0;

    counts.forEach((key, value) {
      if (value > bestCount) {
        bestPrediction = key;
        bestCount = value;
      }
    });

    return bestPrediction;
  }

  bool _isMovementValidForPrediction(String prediction) {
    final elbowRange = _angleRange(_recentElbowAngles);
    final kneeRange = _angleRange(_recentKneeAngles);
    final hipRange = _angleRange(_recentHipAngles);
    final shoulderRange = _angleRange(_recentShoulderAngles);

    switch (prediction) {
      case 'Biceps Curl':
        return elbowRange >= 40;

      case 'Squat':
        return kneeRange >= 35 && hipRange >= 25;

      case 'Lateral Raise':
        return shoulderRange >= 35;

      default:
        return false;
    }
  }

  void _showCameraHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Camera Guide'),
        content: const Text(
          'This screen allows you to detect exercises using your camera.\n\n'
          '• Press on a "Start Detection" button to begin recognising your movement.\n'
          '• The app will try to identify the exercise in real-time.\n'
          '• Make sure your full body is visible for best results.\n'
          '• Use pinch gestures to zoom if needed.\n'
          '• Use the switch icon to change cameras.\n\n'
          'Tip: Stand in good lighting and keep your phone stable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _updateMovementBuffers(PoseResult result) {
    final leftElbow = PoseUtils.getLeftElbowAngle(result);
    final rightElbow = PoseUtils.getRightElbowAngle(result);

    final leftKnee = PoseUtils.getLeftKneeAngle(result);
    final rightKnee = PoseUtils.getRightKneeAngle(result);

    final leftHip = PoseUtils.getLeftHipAngle(result);
    final rightHip = PoseUtils.getRightHipAngle(result);

    final leftShoulder = PoseUtils.getLeftShoulderAngle(result);
    final rightShoulder = PoseUtils.getRightShoulderAngle(result);

    final elbowAngle = _chooseBestAngle(leftElbow, rightElbow);
    final kneeAngle = _chooseBestAngle(leftKnee, rightKnee);
    final hipAngle = _chooseBestAngle(leftHip, rightHip);
    final shoulderAngle = _chooseBestAngle(leftShoulder, rightShoulder);

    _addAngleToBuffer(_recentElbowAngles, elbowAngle);
    _addAngleToBuffer(_recentKneeAngles, kneeAngle);
    _addAngleToBuffer(_recentHipAngles, hipAngle);
    _addAngleToBuffer(_recentShoulderAngles, shoulderAngle);
  }

  double? _chooseBestAngle(double? left, double? right) {
    if (left == null && right == null) return null;
    if (left != null && right == null) return left;
    if (right != null && left == null) return right;

    return ((left! + right!) / 2);
  }

  Widget _buildHintOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5), // translucent
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Start performing an exercise',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Camera access is not enabled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To change camera access, go to Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _openAppSettings,
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (_controller == null || _initializeControllerFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            return Stack(
              children: [
                GestureDetector(
                  onScaleStart: (_) {
                    _baseZoom = _currentZoom;
                  },
                  onScaleUpdate: (details) async {
                    if (_controller == null ||
                        !_controller!.value.isInitialized)
                      return;

                    final zoom = (_baseZoom * details.scale)
                        .clamp(_minZoom, _maxZoom)
                        .toDouble();

                    await _controller!.setZoomLevel(zoom);

                    if (!mounted) return;

                    setState(() {
                      _currentZoom = zoom;
                    });
                  },
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize!.height,
                        height: _controller!.value.previewSize!.width,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 40,
                  right: 20,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.flip_camera_ios),
                      color: Colors.black87,
                    ),
                  ),
                ),

                Positioned(
                  top: 50,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'camera_settings',
                        backgroundColor: Colors.black.withOpacity(0.5),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CameraSettingsScreen(),
                            ),
                          );
                        },
                        child: const Icon(Icons.settings),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: _showCameraHelp,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Positioned(
                //   top: 60,
                //   left: 20,
                //   right: 90,
                //   child: Container(
                //     padding: const EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.black.withOpacity(0.6),
                //       borderRadius: BorderRadius.circular(16),
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.center,
                //       children: [
                //         Text(
                //           _isCollectingData
                //               ? 'Data Samples Recording'
                //               : 'Exercise Detection',
                //           style: TextStyle(
                //             color: Colors.white,
                //             fontSize: 18,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const SizedBox(height: 10),
                //         Text(
                //           _poseStatusText,
                //           textAlign: TextAlign.center,
                //           style: const TextStyle(
                //             color: Colors.white,
                //             fontSize: 16,
                //             height: 1.4,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),

                // Positioned(
                //   bottom: 245,
                //   left: 20,
                //   right: 20,
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     decoration: BoxDecoration(
                //       color: Colors.black.withOpacity(0.6),
                //       borderRadius: BorderRadius.circular(16),
                //     ),
                //     child: DropdownButtonHideUnderline(
                //       child: DropdownButton<ExerciseMode>(
                //         value: _selectedExercise,
                //         isExpanded: true,
                //         dropdownColor: Colors.black87,
                //         iconEnabledColor: Colors.white,
                //         style: const TextStyle(
                //           color: Colors.white,
                //           fontSize: 16,
                //         ),
                //         items: const [
                //           DropdownMenuItem(
                //             value: ExerciseMode.bicepsCurl,
                //             child: Text('Biceps Curl'),
                //           ),
                //           DropdownMenuItem(
                //             value: ExerciseMode.squat,
                //             child: Text('Squat'),
                //           ),
                //           DropdownMenuItem(
                //             value: ExerciseMode.lateralRaise,
                //             child: Text('Lateral Raise'),
                //           ),
                //         ],
                //         onChanged: _isTracking ? null : _changeExercise,
                //       ),
                //     ),
                //   ),
                // ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggleRecognition,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        child: Center(
                          child: Container(
                            width: _isRecognizingExercise ? 26 : 30,
                            height: _isRecognizingExercise ? 26 : 30,
                            decoration: BoxDecoration(
                              color: _isRecognizingExercise
                                  ? Colors.red
                                  : Colors.red,
                              shape: _isRecognizingExercise
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: _isRecognizingExercise
                                  ? BorderRadius.circular(6)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // SizedBox(
                //   width: double.infinity,
                //   height: 56,
                //   child: ElevatedButton(
                //     onPressed: _toggleDataRecording,
                //     child: Text(
                //       _isCollectingData
                //           ? 'Stop Data Recording'
                //           : 'Start Data Recording',
                //     ),
                //   ),
                // ),

                // const SizedBox(height: 12),

                // SizedBox(
                //   width: double.infinity,
                //   height: 56,
                //   child: OutlinedButton(
                //     onPressed: () {
                //       setState(() {
                //         _resetCurrentExerciseCounter();
                //       });
                //     },
                //     child: const Text('Reset Reps'),
                //   ),
                // ),
                //     ],
                //   ),
                // ),
                if (_isRecognizingExercise && !_lastMovementValid)
                  _buildHintOverlay(),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
