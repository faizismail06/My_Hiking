import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'controllers/face_liveness_controller.dart';
import 'widgets/face_oval_painter.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  late final FaceLivenessController _livenessController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _livenessController = FaceLivenessController();
    _livenessController.addListener(_onLivenessStateChanged);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _cameraController!.startImageStream((image) {
        _livenessController.processImage(image, frontCamera);
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _onLivenessStateChanged() {
    if (_livenessController.currentStep == LivenessStep.completed && !_isCapturing) {
      _capturePhoto();
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _cameraController!.stopImageStream();
      final XFile capturedImage = await _cameraController!.takePicture();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liveness berhasil! Mengunggah foto ke server...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      final File imageFile = File(capturedImage.path);
      final response = await ApiService().uploadFaceVerification(imageFile);

      if (!mounted) return;

      if (response['success'] == true) {
        ApiService().clearUserCache();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi Wajah Berhasil Disimpan ke MySQL! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal unggah foto: ${response['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isCapturing = false;
        });
      }
    } catch (e) {
      debugPrint('Error capturing picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kesalahan sistem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  void dispose() {
    _livenessController.removeListener(_onLivenessStateChanged);
    _livenessController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Feed (Proportional Aspect Ratio Fix)
          _buildCameraPreview(),

          // 2. Face Oval Mask & Border
          AnimatedBuilder(
            animation: _livenessController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: FaceOvalPainter(
                  borderColor: _livenessController.borderColor,
                  currentStep: _livenessController.currentStep,
                  progress: _livenessController.progress,
                ),
              );
            },
          ),

          // 3. Top Bar (Back Button & Title)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Verifikasi Wajah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Instruction Banner & Progress Indicators
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _livenessController,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepChip('1. Posisi', _livenessController.currentStep.index >= 0),
                        const SizedBox(width: 8),
                        _buildStepChip('2. Kedip', _livenessController.currentStep.index >= 1),
                        const SizedBox(width: 8),
                        _buildStepChip('3. Senyum', _livenessController.currentStep.index >= 2),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Instruction Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _livenessController.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _livenessController.currentStep == LivenessStep.completed
                                ? Icons.check_circle
                                : Icons.face,
                            color: _livenessController.borderColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _livenessController.instructionText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    
    // In portrait mode, camera aspect ratio is height / width
    var cameraRatio = _cameraController!.value.aspectRatio;
    if (cameraRatio > 1) {
      cameraRatio = 1 / cameraRatio;
    }

    var scale = cameraRatio / deviceRatio;
    if (scale < 1.0) {
      scale = 1.0 / scale;
    }

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildStepChip(String label, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.shade400,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
