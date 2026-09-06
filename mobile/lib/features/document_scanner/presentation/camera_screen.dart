import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushield_ai/core/theme/app_theme.dart';
import 'package:docushield_ai/features/document_scanner/presentation/widgets/card_overlay_painter.dart';
import 'package:docushield_ai/features/verification/providers/verification_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    if (_controller != null) {
      setState(() {
        _isFlashOn = !_isFlashOn;
        _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final XFile image = await _controller!.takePicture();
        setState(() {
          _capturedImage = image;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _continue() {
    if (_capturedImage != null) {
      ref.read(verificationProvider.notifier).setDocumentImage(_capturedImage!);
      Navigator.pushNamed(context, '/selfie');
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized && _capturedImage == null) {
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
          if (_capturedImage == null && _controller != null)
            CameraPreview(_controller!)
          else if (_capturedImage != null)
            kIsWeb 
                ? Image.network(_capturedImage!.path, fit: BoxFit.cover)
                : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
          
          if (_capturedImage == null)
            CustomPaint(
              painter: CardOverlayPainter(),
            ),
          
          if (_capturedImage == null)
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Text(
                'Align your document within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
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
              child: _capturedImage == null ? _buildCaptureControls() : _buildReviewControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: _pickFromGallery,
          icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
        ),
        GestureDetector(
          onTap: _takePicture,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryCyan,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _toggleFlash,
          icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 32),
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
            onPressed: _continue,
            child: const Text('Continue →'),
          ),
        ),
      ],
    );
  }
}
