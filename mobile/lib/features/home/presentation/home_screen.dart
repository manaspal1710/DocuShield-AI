import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:docushield_ai/core/theme/app_theme.dart';
import 'package:docushield_ai/core/network/api_endpoints.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundNavy,
              Color(0xFF0F1532),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                    tooltip: 'Server Settings',
                    onPressed: () => _showServerSettingsDialog(context),
                  ),
                ),
                const SizedBox(height: 16),
                // App Logo/Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceNavy,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryCyan.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: AppTheme.primaryCyan,
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                // Title
                Text(
                  'DocuShield AI',
                  style: Theme.of(context).textTheme.displayLarge,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'AI-Powered Identity Verification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentTeal,
                        fontWeight: FontWeight.w400,
                      ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                const SizedBox(height: 48),
                
                // Features Grid
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: constraints.maxWidth > 800 ? 1.0 : 0.85,
                        children: [
                          _buildFeatureCard(
                            context,
                            icon: Icons.document_scanner,
                            title: 'OCR Extraction',
                            description: 'Extract text from any ID document',
                            delay: 400,
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.verified_user,
                            title: 'Document Validation',
                            description: 'Verify MRZ checksums & standards',
                            delay: 500,
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.policy,
                            title: 'Tampering Detection',
                            description: 'Detect forged & altered documents',
                            delay: 600,
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.face,
                            title: 'Face Verification',
                            description: 'Match document to live person',
                            delay: 700,
                          ),
                        ],
                      );
                    }
                  ),
                ),
                
                // Start Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/scan');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Start Verification',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
                const SizedBox(height: 24),
                // Footer
                Text(
                  'SIH26188 | AI-Based Fake Identity & Document Screening System',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String title, required String description, required int delay}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryCyan, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).scale(curve: Curves.easeOut);
  }

  void _showServerSettingsDialog(BuildContext context) {
    final textController = TextEditingController(text: ApiEndpoints.baseUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.dns_rounded, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text('Server Settings', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Server URL:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. http://192.168.29.173:8000',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: AppTheme.surfaceNavy,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primaryCyan.withOpacity(0.3)),
                ),
                prefixIcon: const Icon(Icons.link, color: AppTheme.primaryCyan, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Enter the computer\'s Wi-Fi IP (when on same Wi-Fi) or an ngrok tunnel URL (when testing remotely).',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ApiEndpoints.setBaseUrl('http://192.168.29.173:8000');
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Server URL reset to default (192.168.29.173:8000)'),
                  backgroundColor: AppTheme.surfaceNavy,
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = textController.text.trim();
              if (newUrl.isNotEmpty) {
                ApiEndpoints.setBaseUrl(newUrl);
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connected to: $newUrl'),
                    backgroundColor: AppTheme.primaryCyan,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
