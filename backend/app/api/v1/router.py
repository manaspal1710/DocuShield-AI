from fastapi import APIRouter
from app.api.v1.endpoints import verify, ocr, tampering, face

api_router = APIRouter()
api_router.include_router(verify.router, prefix="/verify", tags=["Unified Verification"])
api_router.include_router(ocr.router, prefix="/ocr", tags=["OCR Extraction"])
api_router.include_router(tampering.router, prefix="/tampering", tags=["Tampering Detection"])
api_router.include_router(face.router, prefix="/face", tags=["Face Verification"])
