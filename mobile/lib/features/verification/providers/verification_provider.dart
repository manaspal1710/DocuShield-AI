import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushield_ai/core/network/dio_client.dart';
import 'package:docushield_ai/features/verification/models/verification_result.dart';
import 'package:image_picker/image_picker.dart';

enum VerificationState { idle, capturingDocument, capturingSelfie, uploading, processing, completed, error }

class VerificationNotifier extends StateNotifier<VerificationState> {
  VerificationNotifier() : super(VerificationState.idle);

  XFile? documentImage;
  XFile? selfieImage;
  VerificationResult? result;
  String? errorMessage;
  double uploadProgress = 0.0;

  void setDocumentImage(XFile image) {
    documentImage = image;
  }

  void setSelfieImage(XFile? image) {
    selfieImage = image;
  }

  Future<void> submitVerification() async {
    if (documentImage == null) {
      errorMessage = "Document image is missing.";
      state = VerificationState.error;
      return;
    }

    state = VerificationState.uploading;
    uploadProgress = 0.0;

    try {
      final response = await DioClient().uploadVerification(
        documentImage!,
        selfieImage,
        onProgress: (sent, total) {
          if (total > 0) {
            uploadProgress = sent / total;
            if (uploadProgress >= 1.0) {
              state = VerificationState.processing;
            }
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        result = VerificationResult.fromJson(response.data);
        state = VerificationState.completed;
      } else {
        errorMessage = "Invalid response from server.";
        state = VerificationState.error;
      }
    } on DioException catch (e) {
      errorMessage = e.message ?? "A network error occurred.";
      state = VerificationState.error;
    } catch (e) {
      errorMessage = e.toString();
      state = VerificationState.error;
    }
  }

  void reset() {
    documentImage = null;
    selfieImage = null;
    result = null;
    errorMessage = null;
    uploadProgress = 0.0;
    state = VerificationState.idle;
  }
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier();
});
