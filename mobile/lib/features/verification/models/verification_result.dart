class VerificationResult {
  final String status;
  final String? documentType;
  final OCRData? ocrData;
  final MRZValidation? mrzValidation;
  final TamperingAnalysis? tamperingAnalysis;
  final FaceVerificationResult? faceVerification;
  final RiskAssessment? riskAssessment;
  final int? processingTimeMs;

  VerificationResult({
    required this.status,
    this.documentType,
    this.ocrData,
    this.mrzValidation,
    this.tamperingAnalysis,
    this.faceVerification,
    this.riskAssessment,
    this.processingTimeMs,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      status: json['status'] ?? 'unknown',
      documentType: json['document_type'],
      ocrData: json['ocr_data'] != null ? OCRData.fromJson(json['ocr_data']) : null,
      mrzValidation: json['mrz_validation'] != null ? MRZValidation.fromJson(json['mrz_validation']) : null,
      tamperingAnalysis: json['tampering_analysis'] != null ? TamperingAnalysis.fromJson(json['tampering_analysis']) : null,
      faceVerification: json['face_verification'] != null ? FaceVerificationResult.fromJson(json['face_verification']) : null,
      riskAssessment: json['risk_assessment'] != null ? RiskAssessment.fromJson(json['risk_assessment']) : null,
      processingTimeMs: json['processing_time_ms'],
    );
  }
}

class OCRData {
  final String? fullName;
  final String? documentNumber;
  final String? nationality;
  final String? dateOfBirth;
  final String? expiryDate;
  final String? gender;
  final String? documentType;
  final List<dynamic>? items;

  OCRData({
    this.fullName, 
    this.documentNumber, 
    this.nationality, 
    this.dateOfBirth, 
    this.expiryDate, 
    this.gender, 
    this.documentType, 
    this.items
  });

  factory OCRData.fromJson(Map<String, dynamic> json) {
    return OCRData(
      fullName: json['full_name'],
      documentNumber: json['document_number'],
      nationality: json['nationality'],
      dateOfBirth: json['date_of_birth'],
      expiryDate: json['expiry_date'],
      gender: json['gender'],
      documentType: json['document_type'],
      items: json['items'] as List<dynamic>?,
    );
  }
}

class MRZValidation {
  final bool isValid;
  final String? format;
  final String? documentNumber;
  final String? nationality;
  final String? birthDate;
  final String? expiryDate;
  final String? sex;
  final String? surname;
  final String? names;
  final bool? checksumsPassed;
  final List<dynamic>? warnings;

  MRZValidation({
    required this.isValid,
    this.format,
    this.documentNumber,
    this.nationality,
    this.birthDate,
    this.expiryDate,
    this.sex,
    this.surname,
    this.names,
    this.checksumsPassed,
    this.warnings,
  });

  factory MRZValidation.fromJson(Map<String, dynamic> json) {
    return MRZValidation(
      isValid: json['is_valid'] ?? false,
      format: json['format'],
      documentNumber: json['document_number'],
      nationality: json['nationality'],
      birthDate: json['birth_date'],
      expiryDate: json['expiry_date'],
      sex: json['sex'],
      surname: json['surname'],
      names: json['names'],
      checksumsPassed: json['checksums_passed'],
      warnings: json['warnings'] as List<dynamic>?,
    );
  }
}

class TamperingAnalysis {
  final bool isTampered;
  final double? overallTamperScore;
  final double? elaAnomalyScore;
  final double? noiseInconsistencyRatio;
  final bool? exifFlagged;
  final String? flaggedTool;
  final List<dynamic>? suspiciousIndicators;

  TamperingAnalysis({
    required this.isTampered,
    this.overallTamperScore,
    this.elaAnomalyScore,
    this.noiseInconsistencyRatio,
    this.exifFlagged,
    this.flaggedTool,
    this.suspiciousIndicators,
  });

  factory TamperingAnalysis.fromJson(Map<String, dynamic> json) {
    return TamperingAnalysis(
      isTampered: json['is_tampered'] ?? false,
      overallTamperScore: (json['overall_tamper_score'] as num?)?.toDouble(),
      elaAnomalyScore: (json['ela_anomaly_score'] as num?)?.toDouble(),
      noiseInconsistencyRatio: (json['noise_inconsistency_ratio'] as num?)?.toDouble(),
      exifFlagged: json['exif_flagged'],
      flaggedTool: json['flagged_tool'],
      suspiciousIndicators: json['suspicious_indicators'] as List<dynamic>?,
    );
  }
}

class FaceVerificationResult {
  final bool matched;
  final double? similarityScore;
  final double? threshold;
  final bool? faceFoundInDocument;
  final bool? faceFoundInSelfie;
  final String? error;

  FaceVerificationResult({
    required this.matched,
    this.similarityScore,
    this.threshold,
    this.faceFoundInDocument,
    this.faceFoundInSelfie,
    this.error,
  });

  factory FaceVerificationResult.fromJson(Map<String, dynamic> json) {
    return FaceVerificationResult(
      matched: json['matched'] ?? false,
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
      threshold: (json['threshold'] as num?)?.toDouble(),
      faceFoundInDocument: json['face_found_in_document'],
      faceFoundInSelfie: json['face_found_in_selfie'],
      error: json['error'],
    );
  }
}

class RiskAssessment {
  final double riskScore;
  final String decision;
  final List<dynamic>? riskFactors;

  RiskAssessment({
    required this.riskScore,
    required this.decision,
    this.riskFactors,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      decision: json['decision'] ?? 'UNKNOWN',
      riskFactors: json['risk_factors'] as List<dynamic>?,
    );
  }
}
