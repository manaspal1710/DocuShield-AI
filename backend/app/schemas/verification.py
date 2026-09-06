from pydantic import BaseModel
from typing import List, Optional, Any

class OCRItem(BaseModel):
    text: str
    confidence: float
    bounding_box: List[List[float]]

class OCRResult(BaseModel):
    items: List[OCRItem]
    raw_text: str
    mrz_lines_detected: List[str]
    full_name: Optional[str] = None
    document_number: Optional[str] = None
    nationality: Optional[str] = None
    date_of_birth: Optional[str] = None
    expiry_date: Optional[str] = None
    gender: Optional[str] = None
    document_type: Optional[str] = None

class MRZValidation(BaseModel):
    is_valid: bool
    format: Optional[str] = None
    document_number: Optional[str] = None
    nationality: Optional[str] = None
    birth_date: Optional[str] = None
    expiry_date: Optional[str] = None
    sex: Optional[str] = None
    surname: Optional[str] = None
    names: Optional[str] = None
    checksums_passed: bool = False
    mrz_viz_match: Optional[bool] = None
    warnings: List[str] = []

class TamperingAnalysis(BaseModel):
    is_tampered: bool
    overall_tamper_score: float
    ela_anomaly_score: float
    noise_inconsistency_ratio: float
    exif_flagged: bool
    flagged_tool: Optional[str] = None
    suspicious_indicators: List[str] = []

class FaceVerification(BaseModel):
    matched: bool
    similarity_score: float
    threshold: float
    face_found_in_document: bool
    face_found_in_selfie: bool
    error: Optional[str] = None

class RiskAssessment(BaseModel):
    risk_score: float
    decision: str
    risk_factors: List[str]

class VerificationResponse(BaseModel):
    status: str
    document_type: Optional[str] = None
    ocr_data: OCRResult
    mrz_validation: MRZValidation
    tampering_analysis: TamperingAnalysis
    face_verification: FaceVerification
    risk_assessment: RiskAssessment
    processing_time_ms: int
