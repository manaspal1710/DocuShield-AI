import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:docushield_ai/core/theme/app_theme.dart';
import 'package:docushield_ai/features/verification/providers/verification_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SelfieScreen extends ConsumerStatefulWidget {
  const SelfieScreen({super.key});

  @override
  ConsumerState<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends ConsumerState<SelfieScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  XFile? _capturedSelfie;
  
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  String _instructionText = "Step 2: Face Match (Take Selfie)";
  Color _instructionColor = Colors.white;
  bool _blinkDetected = false;
  bool _livenessVerified = false;
  
  // Track blink state
  bool _eyesWereOpen = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _faceDetector = FaceDetector(options: FaceDetectorOptions(enableClassification: true, enableTracking: true));
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          
          // ML Kit face detection is not supported on Web.
          if (!kIsWeb) {
            _startImageStream();
          } else {
            setState(() {
              _instructionText = "Step 2: Face Match (Take Selfie)";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  void _startImageStream() {
    if (kIsWeb) return;
    _controller?.startImageStream((CameraImage image) {
      if (_isDetecting || _livenessVerified) return;
      _isDetecting = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final BytesBuilder allBytes = BytesBuilder();
      for (final Plane plane in image.planes) {
        allBytes.add(plane.bytes);
      }
      final bytes = allBytes.toBytes();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameras!.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      if (_faceDetector == null) return;
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final leftEyeOpenProb = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpenProb = face.rightEyeOpenProbability ?? 1.0;

        if (leftEyeOpenProb > 0.8 && rightEyeOpenProb > 0.8) {
          _eyesWereOpen = true;
          if (!_blinkDetected) {
            setState(() {
              _instructionText = "Please blink to verify you are real";
            });
          }
        } else if (leftEyeOpenProb < 0.2 && rightEyeOpenProb < 0.2 && _eyesWereOpen) {
          _blinkDetected = true;
        } else if (leftEyeOpenProb > 0.8 && rightEyeOpenProb > 0.8 && _blinkDetected) {
          _verifyLiveness();
        }
      } else {
        if (!_livenessVerified) {
          setState(() {
            _instructionText = "Position your face in the circle";
            _eyesWereOpen = false;
            _blinkDetected = false;
          });
        }
      }
    } catch (e) {
      // Ignore errors in stream
    } finally {
      _isDetecting = false;
    }
  }

  void _verifyLiveness() async {
    _livenessVerified = true;
    setState(() {
      _instructionText = "✓ Liveness verified!";
      _instructionColor = Colors.greenAccent;
    });
    
    if (!kIsWeb) {
      await _controller?.stopImageStream();
    }
    
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_controller != null && _controller!.value.isInitialized) {
        try {
          final XFile image = await _controller!.takePicture();
          if (mounted) {
            setState(() {
              _capturedSelfie = image;
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking selfie: $e')));
          }
        }
      }
    });
  }

  Future<void> _manualCapture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      if (!kIsWeb) {
        try {
          await _controller?.stopImageStream();
        } catch (_) {}
      }
      try {
        final XFile image = await _controller!.takePicture();
        if (mounted) {
          setState(() {
            _capturedSelfie = image;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking selfie: $e')));
        }
      }
    }
  }

  Future<void> _pickSelfieFromGallery() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() {
          _capturedSelfie = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      try {
        _controller?.stopImageStream();
      } catch (_) {}
      _faceDetector?.close();
    }
    _controller?.dispose();
    super.dispose();
  }

  void _verify() {
    if (_capturedSelfie != null) {
      ref.read(verificationProvider.notifier).setSelfieImage(_capturedSelfie);
      Navigator.pushNamed(context, '/processing');
    }
  }

  void _retake() {
    setState(() {
      _capturedSelfie = null;
      _livenessVerified = false;
      _blinkDetected = false;
      _eyesWereOpen = false;
      _instructionText = "Step 2: Face Match (Take Selfie)";
      _instructionColor = Colors.white;
    });
    if (!kIsWeb) {
      _startImageStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized && _capturedSelfie == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_capturedSelfie == null && _controller != null)
            CameraPreview(_controller!)
          else if (_capturedSelfie != null)
            kIsWeb 
                ? Image.network(_capturedSelfie!.path, fit: BoxFit.cover)
                : Image.file(File(_capturedSelfie!.path), fit: BoxFit.cover),
          
          if (_capturedSelfie == null)
            CustomPaint(painter: CircleOverlayPainter()),
            
          if (_capturedSelfie == null)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _livenessVerified ? Colors.greenAccent : AppTheme.primaryCyan, width: 4),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
            ),
          
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Text(
              _instructionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _instructionColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
            
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              color: Colors.black.withOpacity(0.7),
              child: _capturedSelfie == null ? _buildCaptureControls() : _buildReviewControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _manualCapture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Selfie (Step 2)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _pickSelfieFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            ref.read(verificationProvider.notifier).setSelfieImage(null);
            Navigator.pushNamed(context, '/processing');
          },
          child: const Text(
            'Skip Face Match →',
            style: TextStyle(color: Colors.white70, fontSize: 15, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _retake,
            child: const Text('Retake'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _verify,
            child: const Text('Verify →'),
          ),
        ),
      ],
    );
  }
}

class CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final width = size.width * 0.6;
    final circleRect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: width / 2);

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addOval(circleRect),
    );

    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
