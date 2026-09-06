import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushield_ai/core/theme/app_theme.dart';
import 'package:docushield_ai/features/home/presentation/home_screen.dart';
import 'package:docushield_ai/features/document_scanner/presentation/camera_screen.dart';
import 'package:docushield_ai/features/liveness/presentation/selfie_screen.dart';
import 'package:docushield_ai/features/verification/presentation/processing_screen.dart';
import 'package:docushield_ai/features/verification/presentation/results_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DocuShieldApp(),
    ),
  );
}

class DocuShieldApp extends StatelessWidget {
  const DocuShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocuShield AI',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/scan': (context) => const CameraScreen(),
        '/selfie': (context) => const SelfieScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/results': (context) => const ResultsScreen(),
      },
    );
  }
}
