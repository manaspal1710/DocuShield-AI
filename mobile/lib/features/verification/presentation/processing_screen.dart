import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushield_ai/core/theme/app_theme.dart';
import 'package:docushield_ai/features/verification/providers/verification_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verificationProvider.notifier).submitVerification();
      _simulateSteps();
    });
  }

  Future<void> _simulateSteps() async {
    final steps = [1, 2, 3, 4];
    for (int step in steps) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _currentStepIndex = step;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.watch(verificationProvider.notifier);

    ref.listen<VerificationState>(verificationProvider, (previous, next) {
      if (next == VerificationState.completed) {
        Navigator.pushReplacementNamed(context, '/results');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundNavy,
      body: Center(
        child: state == VerificationState.error
            ? _buildErrorState(notifier.errorMessage ?? "An error occurred")
            : _buildProcessingState(notifier.uploadProgress),
      ),
    );
  }

  Widget _buildProcessingState(double progress) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryCyan, width: 4),
            ),
            child: const Center(
              child: Icon(Icons.security, size: 60, color: AppTheme.primaryCyan),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 2.seconds, color: AppTheme.accentTeal),
           
          const SizedBox(height: 48),
          
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: AppTheme.surfaceNavy,
            color: AppTheme.primaryCyan,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          
          const SizedBox(height: 48),
          
          _buildStepRow(0, "📤", "Uploading images..."),
          _buildStepRow(1, "📝", "Extracting text (OCR)..."),
          _buildStepRow(2, "✅", "Validating document..."),
          _buildStepRow(3, "🔍", "Analyzing for tampering..."),
          _buildStepRow(4, "👤", "Verifying identity..."),
        ],
      ),
    );
  }

  Widget _buildStepRow(int stepIndex, String emoji, String text) {
    final isCompleted = _currentStepIndex > stepIndex;
    final isActive = _currentStepIndex == stepIndex;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isActive ? Colors.white : (isCompleted ? Colors.white70 : Colors.white30),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppTheme.primaryCyan, size: 24).animate().scale(),
          if (isActive)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCyan),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
          const SizedBox(height: 24),
          Text(
            'Verification Failed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(verificationProvider.notifier).reset();
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
