import time
from fastapi import APIRouter, UploadFile, File, HTTPException, Request
from app.schemas.verification import VerificationResponse
from app.services.mrz_service import MRZService
from app.services.tampering_service import TamperingService
from app.services.risk_engine import RiskEngine
from typing import Optional

router = APIRouter()
mrz_service = MRZService()
tampering_service = TamperingService()
risk_engine = RiskEngine()

@router.post("", response_model=VerificationResponse)
@router.post("/", response_model=VerificationResponse)
async def verify_document(request: Request, document_image: UploadFile = File(...), selfie_image: Optional[UploadFile] = File(None)):
    """Unified endpoint to run OCR, MRZ parsing, Tampering analysis, Face verification, and Risk scoring."""
    start_time = time.time()
    try:
        doc_bytes = await document_image.read()
        selfie_bytes = await selfie_image.read() if selfie_image else None
        
        ocr_service = request.app.state.ocr_service
        face_service = request.app.state.face_service
        
        # 1. OCR & MRZ
        ocr_items = ocr_service.extract_text(doc_bytes)
        mrz_lines = ocr_service.extract_mrz_lines(ocr_items)
        mrz_result = mrz_service.parse_and_validate(mrz_lines)
        
        # Extract structured identity fields (VIZ + MRZ)
        doc_fields = ocr_service.extract_document_fields(ocr_items, mrz_result)
        
        is_expired = False
        if doc_fields.get("expiry_date") and "Lifetime" not in doc_fields["expiry_date"]:
            is_expired = mrz_service.check_expiry(doc_fields["expiry_date"])
            
        # 2. Face Verification
        if selfie_bytes:
            face_result = face_service.verify(doc_bytes, selfie_bytes)
        else:
            doc_face_bbox = face_service.detect_face_box(doc_bytes)
            face_result = {
                "matched": False,
                "similarity_score": 0.0,
                "threshold": 0.45,
                "face_found_in_document": doc_face_bbox is not None,
                "face_found_in_selfie": False,
                "error": "Skipped face verification (no selfie provided)",
                "doc_face_bbox": doc_face_bbox
            }
        # 3. Tampering Analysis
        # Use doc face bounding box for noise variance analysis
        doc_face_box = face_result.get("doc_face_bbox")
        tampering_result = tampering_service.analyze(doc_bytes, doc_face_box)
        
        # 4. Risk Scoring
        risk_result = risk_engine.calculate_risk(mrz_result, tampering_result, face_result, is_expired)
        
        processing_time_ms = int((time.time() - start_time) * 1000)
        
        # Assemble Response
        return {
            "status": "success",
            "document_type": doc_fields.get("document_type", mrz_result.get("format", "Identity Document")),
            "ocr_data": {
                "items": ocr_items,
                "raw_text": "\n".join([item["text"] for item in ocr_items]),
                "mrz_lines_detected": mrz_lines,
                "full_name": doc_fields.get("full_name"),
                "document_number": doc_fields.get("document_number"),
                "nationality": doc_fields.get("nationality"),
                "date_of_birth": doc_fields.get("date_of_birth"),
                "expiry_date": doc_fields.get("expiry_date"),
                "gender": doc_fields.get("gender"),
                "document_type": doc_fields.get("document_type"),
            },
            "mrz_validation": mrz_result,
            "tampering_analysis": tampering_result,
            "face_verification": face_result,
            "risk_assessment": risk_result,
            "processing_time_ms": processing_time_ms
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
