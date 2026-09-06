from fastapi import APIRouter, UploadFile, File, HTTPException, Request
from app.schemas.verification import OCRResult

router = APIRouter()

@router.post("", response_model=OCRResult)
@router.post("/", response_model=OCRResult)
async def extract_ocr(request: Request, image: UploadFile = File(...)):
    """Extract text and MRZ lines from an image."""
    try:
        image_bytes = await image.read()
        ocr_service = request.app.state.ocr_service
        
        ocr_items = ocr_service.extract_text(image_bytes)
        mrz_lines = ocr_service.extract_mrz_lines(ocr_items)
        
        raw_text = "\n".join([item["text"] for item in ocr_items])
        
        return OCRResult(
            items=ocr_items,
            raw_text=raw_text,
            mrz_lines_detected=mrz_lines
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
