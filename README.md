# 🛡️ DocuShield AI — SIH26188

## AI-Based Fake Identity & Document Screening System

> Smart India Hackathon 2026 | Problem Statement ID: SIH26188

DocuShield AI is an AI-powered document screening platform that automatically analyzes identity and travel documents, detects tampering or forgery, validates information against standards, and generates a risk score to assist border security personnel.

---

## 🏗️ Architecture

```
┌─────────────────────────────────┐
│     Flutter Mobile App          │
│                                 │
│  📷 Camera → 🤳 Selfie → 📊   │
│  Document    Liveness   Results │
│  Capture     Check      Dashboard│
└─────────┬───────────────────────┘
          │ HTTP POST (Multipart)
          ▼
┌─────────────────────────────────┐
│     FastAPI Backend             │
│                                 │
│  Module 1: OCR (PaddleOCR)     │
│  Module 2: MRZ Validation      │
│  Module 3: Tampering Detection  │
│  Module 4: Face Verification   │
│  ────────────────────────────── │
│  Risk Score Engine (0-100)     │
│  Decision: CLEAR/REVIEW/REJECT │
└─────────────────────────────────┘
```

---

## 🚀 Quick Start

### Backend (Python)

```bash
cd backend
python -m venv venv
source venv/bin/activate    # macOS/Linux
# venv\Scripts\activate     # Windows

pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at: http://localhost:8000/docs (Swagger UI)

### Frontend (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

> **Note:** Update the `baseUrl` in `lib/core/network/api_endpoints.dart` to point to your backend.
> - Android emulator: `http://10.0.2.2:8000`
> - iOS simulator: `http://localhost:8000`
> - Physical device: `http://<your-ip>:8000`

---

## 📋 4 Core Modules

### Module 1: OCR Extraction
- **Engine:** PaddleOCR (PP-OCRv4) with angle classification
- **Supports:** Passport, Visa, National ID, Driving License, Permits
- **Extracts:** Name, Document Number, Nationality, DOB, Expiry Date, Gender
- **MRZ Detection:** Automatically identifies Machine Readable Zones

### Module 2: Document Validation
- **Standard:** ICAO Doc 9303 compliance (TD1, TD2, TD3 formats)
- **Checksums:** Validates document number, DOB, expiry, and composite check digits
- **Cross-validation:** Compares Visual Inspection Zone (VIZ) text vs. MRZ fields
- **Expiry Check:** Flags expired documents

### Module 3: Tampering Detection (Core AI Innovation)
Three forensic analysis techniques:
1. **Error Level Analysis (ELA):** Detects digital splicing via JPEG compression artifact differences
2. **Noise Variance Analysis:** Compares Laplacian noise between face crop and document body to detect pasted portraits
3. **EXIF Metadata Inspection:** Flags documents edited with Photoshop, GIMP, Canva, etc.

### Module 4: Face Verification
- **Engine:** InsightFace (ArcFace/Buffalo_s) via ONNX Runtime
- **Accuracy:** 99.83% on LFW benchmark
- **Liveness:** Client-side blink detection via Google ML Kit (anti-spoofing)
- **Matching:** Cosine similarity with configurable threshold (default: 0.45)

---

## 📊 Risk Score Engine

| Signal | Weight | Trigger |
|---|---|---|
| MRZ Checksum Failure | 30% | Invalid ICAO checksums |
| ELA Anomaly | 20% | Score > 0.35 threshold |
| Face Mismatch | 15% | Cosine similarity < 0.45 |
| Noise Inconsistency | 10% | Ratio > 2.5x |
| EXIF Editing Tools | 5% | Photoshop/GIMP detected |
| Document Expired | 5% | Past expiry date |

**Decisions:**
- 🟢 **CLEAR** (Score < 30): Document appears authentic
- 🟡 **REVIEW** (Score 30-60): Manual review recommended
- 🔴 **REJECT** (Score > 60): High probability of fraud

---

## 🧪 API Testing (curl)

```bash
# OCR only
curl -X POST http://localhost:8000/api/v1/ocr \
  -F "image=@passport.jpg"

# Full verification
curl -X POST http://localhost:8000/api/v1/verify \
  -F "document_image=@passport.jpg" \
  -F "selfie_image=@selfie.jpg"

# Tampering analysis
curl -X POST http://localhost:8000/api/v1/tampering \
  -F "image=@document.jpg"

# Face verification
curl -X POST http://localhost:8000/api/v1/face \
  -F "document_image=@passport.jpg" \
  -F "selfie_image=@selfie.jpg"
```

---

## 📁 Project Structure

```
sih26188-docushield/
├── backend/                          # Python FastAPI Backend
│   ├── app/
│   │   ├── api/v1/endpoints/         # REST API endpoints
│   │   ├── core/                     # Config & settings
│   │   ├── schemas/                  # Pydantic response models
│   │   ├── services/                 # AI service modules
│   │   │   ├── ocr_service.py        # PaddleOCR extraction
│   │   │   ├── mrz_service.py        # ICAO MRZ validation
│   │   │   ├── tampering_service.py  # ELA + Noise + EXIF
│   │   │   ├── face_service.py       # InsightFace verification
│   │   │   └── risk_engine.py        # Weighted risk scoring
│   │   └── main.py                   # FastAPI app entry
│   ├── Dockerfile
│   └── requirements.txt
├── mobile/                           # Flutter Mobile App
│   ├── lib/
│   │   ├── core/                     # Theme, network, utils
│   │   ├── features/
│   │   │   ├── home/                 # Landing screen
│   │   │   ├── document_scanner/     # Camera + overlay
│   │   │   ├── liveness/            # Selfie + blink detection
│   │   │   └── verification/        # Processing + results
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

---

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Backend Framework | FastAPI + Uvicorn |
| OCR Engine | PaddleOCR (PP-OCRv4) |
| MRZ Parsing | `mrz` (ICAO 9303) |
| Tampering Detection | OpenCV + Pillow + piexif |
| Face Verification | InsightFace (ArcFace) + ONNX Runtime |
| Mobile App | Flutter 3.24+ / Dart 3.5+ |
| State Management | Riverpod |
| Camera & Vision | camera + Google ML Kit |
| Networking | Dio |

---

## 👥 Team

**SIH26188** — Smart India Hackathon 2026

---

## 📄 License

This project is built for educational and hackathon purposes.
