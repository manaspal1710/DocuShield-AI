import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:docushield_ai/core/theme/app_theme.dart';
import 'package:docushield_ai/features/verification/providers/verification_provider.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(verificationProvider.notifier).result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('No results available')),
      );
    }

    final riskScore = result.riskAssessment?.riskScore ?? 0.0;
    Color scoreColor = Colors.green;
    if (riskScore > 60) scoreColor = Colors.red;
    else if (riskScore > 30) scoreColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Report'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Gauge
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 12.0,
              animation: true,
              percent: (riskScore / 100).clamp(0.0, 1.0),
              center: Text(
                "${riskScore.toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: scoreColor,
              backgroundColor: AppTheme.surfaceNavy,
            ).animate().scale(),
            
            const SizedBox(height: 16),
            
            Chip(
              label: Text(
                result.riskAssessment?.decision ?? 'UNKNOWN',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: scoreColor.withOpacity(0.2),
              side: BorderSide(color: scoreColor),
            ),
            
            if (result.processingTimeMs != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Processing time: ${result.processingTimeMs}ms",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),

            const SizedBox(height: 24),
            
            _buildOCRCard(result.ocrData).animate().fadeIn().slideY(),
            const SizedBox(height: 16),
            _buildMRZCard(result.mrzValidation).animate().fadeIn(delay: 100.ms).slideY(),
            const SizedBox(height: 16),
            _buildTamperingCard(result.tamperingAnalysis).animate().fadeIn(delay: 200.ms).slideY(),
            const SizedBox(height: 16),
            _buildFaceCard(result.faceVerification).animate().fadeIn(delay: 300.ms).slideY(),
            const SizedBox(height: 16),
            _buildRiskCard(result.riskAssessment).animate().fadeIn(delay: 400.ms).slideY(),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(verificationProvider.notifier).reset();
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                    child: const Text('New Scan'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {}, // Placeholder for export
                    child: const Text('Export Report'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOCRCard(dynamic ocrData) {
    if (ocrData == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Extracted Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
                if (ocrData.documentType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.4)),
                    ),
                    child: Text(ocrData.documentType!, style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const Divider(color: Colors.white10),
            _buildInfoRow('Full Name', ocrData.fullName ?? 'N/A'),
            _buildInfoRow('Document #', ocrData.documentNumber ?? 'N/A'),
            _buildInfoRow('Nationality', ocrData.nationality ?? 'N/A'),
            _buildInfoRow('DOB', ocrData.dateOfBirth ?? 'N/A'),
            _buildInfoRow('Expiry', ocrData.expiryDate ?? 'N/A'),
            if (ocrData.gender != null)
              _buildInfoRow('Gender', ocrData.gender!),
          ],
        ),
      ),
    );
  }

  Widget _buildMRZCard(dynamic mrz) {
    if (mrz == null) return const SizedBox.shrink();
    final bool hasMrz = mrz.format != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MRZ Validation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
                if (hasMrz)
                  Chip(label: Text(mrz.format!), backgroundColor: AppTheme.surfaceNavy),
              ],
            ),
            const Divider(color: Colors.white10),
            if (hasMrz) ...[
              _buildInfoRow('Status', mrz.isValid ? 'Valid ✅' : 'Invalid ❌'),
              _buildInfoRow('Checksums', (mrz.checksumsPassed ?? false) ? 'Passed ✅' : 'Failed ❌'),
              if (mrz.warnings != null && mrz.warnings!.isNotEmpty)
                ...mrz.warnings!.map((w) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('⚠️ $w', style: const TextStyle(color: Colors.orange)),
                )),
            ] else ...[
              _buildInfoRow('Status', 'Not Applicable (Non-Travel ID) ℹ️'),
              const Padding(
                padding: EdgeInsets.only(top: 6.0),
                child: Text('MRZ is specific to international travel documents (Passports/Visas). Identity fields were extracted and verified via VIZ inspection.',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTamperingCard(dynamic tampering) {
    if (tampering == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tampering Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
            const Divider(color: Colors.white10),
            _buildInfoRow('Tampered', tampering.isTampered ? 'Yes ❌' : 'No ✅'),
            const SizedBox(height: 8),
            const Text('Tamper Score:', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 4),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: (tampering.overallTamperScore ?? 0.0).clamp(0.0, 1.0),
              progressColor: Colors.redAccent,
              backgroundColor: AppTheme.surfaceNavy,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('EXIF Flagged', (tampering.exifFlagged ?? false) ? 'Yes ⚠️ (${tampering.flaggedTool ?? ''})' : 'No ✅'),
            if (tampering.suspiciousIndicators != null && tampering.suspiciousIndicators!.isNotEmpty)
              ...tampering.suspiciousIndicators!.map((w) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('• $w', style: const TextStyle(color: Colors.redAccent)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceCard(dynamic face) {
    if (face == null) return const SizedBox.shrink();
    final bool isSkipped = face.error != null && face.error.toString().contains('Skipped');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biometric Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
            const Divider(color: Colors.white10),
            Row(
              children: [
                Icon(
                  isSkipped ? Icons.person_off : (face.matched ? Icons.verified_user : Icons.gpp_bad), 
                  color: isSkipped ? Colors.amber : (face.matched ? Colors.green : Colors.red), 
                  size: 48
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSkipped ? 'SKIPPED' : (face.matched ? 'MATCHED' : 'NO MATCH'), 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18, 
                        color: isSkipped ? Colors.amber : (face.matched ? Colors.green : Colors.red)
                      )
                    ),
                    Text(isSkipped ? 'Face check skipped' : 'Similarity: ${((face.similarityScore ?? 0) * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard(dynamic risk) {
    if (risk == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Risk Factors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
            const Divider(color: Colors.white10),
            if (risk.riskFactors == null || risk.riskFactors!.isEmpty)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('No risk factors detected'),
                ],
              )
            else
              ...risk.riskFactors!.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f.toString())),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
