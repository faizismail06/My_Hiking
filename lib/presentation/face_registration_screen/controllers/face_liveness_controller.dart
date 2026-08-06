import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../widgets/face_oval_painter.dart';

class FaceLivenessController extends ChangeNotifier {
  late final FaceDetector _faceDetector;

  bool _isProcessing = false;
  LivenessStep _currentStep = LivenessStep.positioning;
  String _instructionText = 'Posisikan wajah Anda di dalam oval';
  Color _borderColor = Colors.white;
  double _progress = 0.0; // 0.0 to 1.0

  bool _isEyeBlinked = false;
  bool _isSmileDetected = false;

  LivenessStep get currentStep => _currentStep;
  String get instructionText => _instructionText;
  Color get borderColor => _borderColor;
  double get progress => _progress;

  FaceLivenessController() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
  }

  void reset() {
    _currentStep = LivenessStep.positioning;
    _instructionText = 'Posisikan wajah Anda di dalam oval';
    _borderColor = Colors.white;
    _progress = 0.0;
    _isEyeBlinked = false;
    _isSmileDetected = false;
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> processImage(CameraImage image, CameraDescription camera) async {
    if (_isProcessing || _currentStep == LivenessStep.completed) return;
    _isProcessing = true;

    try {
      final inputImage = _formatCameraImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _instructionText = 'Wajah tidak terdeteksi. Harap mendekat ke kamera';
        _borderColor = Colors.orangeAccent;
        _progress = 0.0;
        notifyListeners();
        _isProcessing = false;
        return;
      }

      if (faces.length > 1) {
        _instructionText = 'Harap hanya satu wajah yang ada di kamera';
        _borderColor = Colors.redAccent;
        notifyListeners();
        _isProcessing = false;
        return;
      }

      final face = faces.first;

      // Check Liveness Steps
      switch (_currentStep) {
        case LivenessStep.positioning:
          _borderColor = Colors.greenAccent;
          _progress = 0.33;
          _instructionText = 'Bagus! Sekarang KEDIPKAN MATA Anda';
          _currentStep = LivenessStep.blink;
          notifyListeners();
          break;

        case LivenessStep.blink:
          final leftEye = face.leftEyeOpenProbability;
          final rightEye = face.rightEyeOpenProbability;

          if (leftEye != null && rightEye != null) {
            // Check for blink (probability drops below 0.25)
            if (leftEye < 0.25 && rightEye < 0.25) {
              _isEyeBlinked = true;
              _progress = 0.66;
              _instructionText = 'Kedipan terdeteksi! Sekarang TERSENYUMlah 😊';
              _currentStep = LivenessStep.smile;
              _borderColor = Colors.greenAccent;
              notifyListeners();
            }
          }
          break;

        case LivenessStep.smile:
          final smileProb = face.smilingProbability;

          if (smileProb != null && smileProb > 0.70) {
            _isSmileDetected = true;
            _progress = 1.0;
            _instructionText = 'Verifikasi Wajah Berhasil! Mengambil Foto...';
            _currentStep = LivenessStep.completed;
            _borderColor = Colors.greenAccent;
            notifyListeners();
          }
          break;

        case LivenessStep.completed:
          break;
      }
    } catch (e) {
      debugPrint('Error processing face frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _formatCameraImage(CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = _getRotationCompensation(sensorOrientation);
      if (rotationCompensation == null) return null;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  int? _getRotationCompensation(int sensorOrientation) {
    var rotationCompensation = sensorOrientation;
    return rotationCompensation;
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }
}
