# DocuShield AI Backend

AI-Based Fake Identity & Document Screening System backend (SIH26188). 
Built with FastAPI, PaddleOCR, InsightFace, and OpenCV.

## Features
- **OCR Extraction**: Robust text extraction from identity documents using PaddleOCR.
- **MRZ Validation**: Standardized TD1/TD2/TD3 Machine Readable Zone validation and parsing.
- **Tampering Detection**: Forensic checks using Error Level Analysis (ELA), Noise Inconsistency mapping, and EXIF metadata analysis.
- **Face Verification**: Match portrait on the ID with a live selfie using InsightFace (ArcFace model).
- **Risk Assessment Engine**: Aggregate multiple forensic parameters into a final 0-100 risk score and CLEAR/REVIEW/REJECT recommendation.

## Setup

1. Create virtual environment and install dependencies:
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

2. Run the application:
```bash
uvicorn app.main:app --reload
```
The first startup may take a bit longer as AI models (PaddleOCR, InsightFace buffalo_s) are downloaded.

## API Endpoints
All endpoints are prefixed with `/api/v1`.

### 1. `POST /api/v1/verify/`
Unified verification endpoint.

**Request:** `multipart/form-data`
- `document_image`: The ID document image file.
- `selfie_image`: The live user selfie image file.

### 2. `POST /api/v1/ocr/`
Extract text and identify MRZ.

**Request:** `multipart/form-data`
- `image`: The ID document image file.

### 3. `POST /api/v1/tampering/`
Perform forensic tampering analysis.

**Request:** `multipart/form-data`
- `image`: The ID document image file.

### 4. `POST /api/v1/face/`
Face similarity matching.

**Request:** `multipart/form-data`
- `document_image`: The ID document image file.
- `selfie_image`: The live user selfie image file.

## Testing with cURL
```bash
curl -X POST "http://localhost:8000/api/v1/verify/" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "document_image=@sample_id.jpg" \
  -F "selfie_image=@sample_selfie.jpg"
```
