import re
import cv2
import numpy as np
import easyocr
from typing import List, Dict, Any
from app.utils.image_utils import decode_image, resize_for_processing


class OCRService:
    def __init__(self):
        """Initialize EasyOCR Reader with English language support.
        
        EasyOCR uses CRAFT text detection + CRNN recognition.
        It handles rotated, skewed, and noisy mobile camera captures well.
        """
        self.reader = easyocr.Reader(['en'], gpu=False)

    def extract_text(self, image_bytes: bytes) -> List[Dict[str, Any]]:
        """Run OCR on image bytes, return list of {text, confidence, bounding_box}."""
        image_np = decode_image(image_bytes)
        image_np = resize_for_processing(image_np)

        results = self.reader.readtext(image_np)
        ocr_items = []
        for (box, text, confidence) in results:
            ocr_items.append({
                "text": text.strip(),
                "confidence": round(float(confidence), 3),
                "bounding_box": box
            })
        return ocr_items

    def extract_mrz_lines(self, ocr_items: List[Dict[str, Any]]) -> List[str]:
        """Filter OCR results to find genuine MRZ lines (ICAO 9303 format).
        
        MRZ lines contain uppercase letters, digits, and '<' filler characters.
        A real MRZ line ALWAYS contains multiple '<' characters (at least 2).
        TD3 (Passport): 2 lines × 44 chars
        TD2 (Visa/ID):  2 lines × 36 chars  
        TD1 (Nat. ID):  3 lines × 30 chars
        """
        mrz_items = []
        for item in ocr_items:
            # Normalize common OCR misreads in MRZ zones
            text = item["text"].replace(' ', '').replace('«', '<').replace('{', '<').replace('(', '<').upper()
            
            # An MRZ line MUST have at least 2 '<' characters and be between 28 and 46 chars
            if text.count('<') >= 2 and 28 <= len(text) <= 46:
                y_coord = item["bounding_box"][0][1] if item["bounding_box"] else 0
                mrz_items.append((y_coord, text))

        # Sort by Y-coordinate to maintain line order (top to bottom)
        mrz_items.sort(key=lambda x: x[0])
        return [item[1] for item in mrz_items]

    def extract_document_fields(self, ocr_items: List[Dict[str, Any]], mrz_result: Dict[str, Any] = None) -> Dict[str, Any]:
        """Extract structured identity fields from OCR items and/or MRZ data.
        
        Intelligently identifies document type (Passport, Aadhaar Card, PAN Card, Driving License, National ID)
        and extracts:
        - full_name
        - document_number
        - nationality
        - date_of_birth
        - expiry_date
        - gender
        - document_type
        """
        raw_lines = [item["text"].strip() for item in ocr_items if item["text"].strip()]
        full_text = " ".join(raw_lines)
        full_text_lower = full_text.lower()
        
        extracted = {
            "document_type": "Identity Document",
            "full_name": None,
            "document_number": None,
            "nationality": None,
            "date_of_birth": None,
            "expiry_date": None,
            "gender": None
        }

        # 1. If MRZ is valid, prioritize MRZ for official passport fields
        if mrz_result and mrz_result.get("is_valid") and mrz_result.get("format"):
            extracted["document_type"] = f"Passport ({mrz_result.get('format', 'ICAO')})"
            surname = mrz_result.get("surname", "") or ""
            names = mrz_result.get("names", "") or ""
            extracted["full_name"] = f"{names} {surname}".strip()
            extracted["document_number"] = mrz_result.get("document_number")
            extracted["nationality"] = mrz_result.get("nationality")
            extracted["date_of_birth"] = mrz_result.get("birth_date")
            extracted["expiry_date"] = mrz_result.get("expiry_date")
            extracted["gender"] = mrz_result.get("sex")
            return extracted

        # 2. Document Type Detection
        is_aadhaar = any(k in full_text_lower for k in ["aadhaar", "govemment of india", "government of india", "unique identification", "uidai", "enrollment"]) or bool(re.search(r'\b\d{4}\s\d{4}\s\d{4}\b', full_text))
        is_pan = any(k in full_text_lower for k in ["income tax department", "permanent account number", "govt. of india"]) or bool(re.search(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b', full_text))
        is_driving = any(k in full_text_lower for k in ["driving licence", "driving license", "union of india driving", "transport department"])
        is_passport = any(k in full_text_lower for k in ["passport", "republic of india passport"])

        if is_aadhaar:
            extracted["document_type"] = "Aadhaar Card (India)"
            extracted["nationality"] = "Indian"
            extracted["expiry_date"] = "Lifetime (No Expiry)"
        elif is_pan:
            extracted["document_type"] = "PAN Card (India)"
            extracted["nationality"] = "Indian"
            extracted["expiry_date"] = "Lifetime (No Expiry)"
        elif is_driving:
            extracted["document_type"] = "Driving License"
        elif is_passport:
            extracted["document_type"] = "Passport"

        # 3. Document Number Extraction
        if is_aadhaar:
            # 12-digit Aadhaar pattern: 0000 0000 0000
            aadhaar_match = re.search(r'\b(\d{4}\s\d{4}\s\d{4})\b', full_text)
            if aadhaar_match:
                extracted["document_number"] = aadhaar_match.group(1)
            else:
                m12 = re.search(r'\b(\d{12})\b', full_text)
                if m12:
                    extracted["document_number"] = f"{m12.group(1)[:4]} {m12.group(1)[4:8]} {m12.group(1)[8:]}"

        if not extracted["document_number"] and is_pan:
            pan_match = re.search(r'\b([A-Z]{5}[0-9]{4}[A-Z])\b', full_text)
            if pan_match:
                extracted["document_number"] = pan_match.group(1)

        if not extracted["document_number"]:
            dl_match = re.search(r'\b([A-Z]{2}[0-9]{2}\s?[0-9]{11})\b', full_text)
            if dl_match:
                extracted["document_number"] = dl_match.group(1)
            else:
                for line in raw_lines:
                    m = re.search(r'(?:no|number|num|id)[:.\s]*([A-Z0-9-]{6,16})', line, re.IGNORECASE)
                    if m:
                        extracted["document_number"] = m.group(1)
                        break

        # 4. Date of Birth Extraction
        dob_match = re.search(r'(?:DOB|Date of Birth|Birth Date|Birth|जन्म)[:\s]*(\d{2}[/-]\d{2}[/-]\d{4})', full_text, re.IGNORECASE)
        if dob_match:
            extracted["date_of_birth"] = dob_match.group(1)
        else:
            dates = re.findall(r'\b(\d{2}[/-]\d{2}[/-]\d{4})\b', full_text)
            if dates:
                extracted["date_of_birth"] = dates[0]

        # 5. Expiry Date Extraction
        if not extracted["expiry_date"]:
            exp_match = re.search(r'(?:Expiry|Expires|Valid Till|Valid Until|Validity)[:\s]*(\d{2}[/-]\d{2}[/-]\d{4})', full_text, re.IGNORECASE)
            if exp_match:
                extracted["expiry_date"] = exp_match.group(1)
            else:
                dates = re.findall(r'\b(\d{2}[/-]\d{2}[/-]\d{4})\b', full_text)
                if len(dates) > 1 and dates[0] == extracted["date_of_birth"]:
                    extracted["expiry_date"] = dates[1]

        # 6. Gender Extraction
        gender_match = re.search(r'\b(Male|Female|Transgender)\b', full_text, re.IGNORECASE)
        if gender_match:
            extracted["gender"] = gender_match.group(1).capitalize()
        elif re.search(r'\b(पुरुष|महिला)\b', full_text):
            extracted["gender"] = "Male" if "पुरुष" in full_text else "Female"

        # 7. Name Extraction
        stop_words = {
            "government", "govemment", "india", "state", "republic", "department", 
            "income", "tax", "identity", "card", "authority", "unique", "enrollment", 
            "help", "date", "birth", "male", "female", "transgender", "father", "address",
            "proof", "citizenship", "year", "valid", "driver", "licence", "license",
            "permanent", "account", "number", "national", "signature"
        }

        for i, line in enumerate(raw_lines):
            name_label_match = re.search(r'(?:Name|Given Name|Full Name|नाम)[:\s]+([A-Za-z\s]{3,30})', line, re.IGNORECASE)
            if name_label_match:
                candidate = name_label_match.group(1).strip()
                if len(candidate.split()) >= 1 and not any(w.lower() in stop_words for w in candidate.split()):
                    extracted["full_name"] = candidate
                    break
            elif re.match(r'^(?:Name|Given Names?|Full Name|नाम)$', line.strip(), re.IGNORECASE) and i + 1 < len(raw_lines):
                candidate = raw_lines[i+1].strip()
                if not any(w.lower() in stop_words for w in candidate.split()):
                    extracted["full_name"] = candidate
                    break

        if not extracted["full_name"]:
            candidate_names = []
            for line in raw_lines:
                clean = line.strip()
                words = clean.split()
                if 2 <= len(words) <= 4:
                    if all(w.isalpha() and (w.isupper() or (w[0].isupper() and w[1:].islower())) for w in words):
                        if not any(w.lower() in stop_words for w in words):
                            candidate_names.append(clean)
            
            if candidate_names:
                extracted["full_name"] = candidate_names[0]

        # 8. Nationality Fallback
        if not extracted["nationality"]:
            if "india" in full_text_lower or "bharat" in full_text_lower or "bhārat" in full_text_lower:
                extracted["nationality"] = "Indian"
            elif "united states" in full_text_lower or "usa" in full_text_lower:
                extracted["nationality"] = "American"
            elif "united kingdom" in full_text_lower or "british" in full_text_lower:
                extracted["nationality"] = "British"

        return extracted
