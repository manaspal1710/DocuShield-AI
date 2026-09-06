from fastapi import APIRouter, UploadFile, File, HTTPException, Request
from app.schemas.verification import TamperingAnalysis
from app.services.tampering_service import TamperingService
from app.services.face_service import FaceService

router = APIRouter()
tampering_service = TamperingService()

@router.post("", response_model=TamperingAnalysis)
@router.post("/", response_model=TamperingAnalysis)
async def analyze_tampering(request: Request, image: UploadFile = File(...)):
    """Analyze image for potential tampering (ELA, Noise, EXIF)."""
    try:
        image_bytes = await image.read()
        face_service = request.app.state.face_service
        
        # Try to find a face to compare noise levels
        face_box = face_service.detect_face_box(image_bytes)
        
        result = tampering_service.analyze(image_bytes, face_box)
        return TamperingAnalysis(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
