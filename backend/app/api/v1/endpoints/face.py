from fastapi import APIRouter, UploadFile, File, HTTPException, Request
from app.schemas.verification import FaceVerification

router = APIRouter()

@router.post("", response_model=FaceVerification)
@router.post("/", response_model=FaceVerification)
async def verify_face(request: Request, document_image: UploadFile = File(...), selfie_image: UploadFile = File(...)):
    """Verify if the face in the document matches the selfie."""
    try:
        doc_bytes = await document_image.read()
        selfie_bytes = await selfie_image.read()
        
        face_service = request.app.state.face_service
        result = face_service.verify(doc_bytes, selfie_bytes)
        
        return FaceVerification(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
