import cv2
import numpy as np
import io
import piexif
from PIL import Image, ImageChops, ImageEnhance
from typing import Dict, Any, Tuple
from app.utils.image_utils import decode_image
from app.core.config import settings

class TamperingService:
    def analyze(self, image_bytes: bytes, face_box: Tuple[int, int, int, int] = None) -> Dict[str, Any]:
        """Run all 3 forensic checks and aggregate results."""
        suspicious_indicators = []
        
        # 1. EXIF Analysis
        exif_results = self.inspect_exif(image_bytes)
        if exif_results.get("suspicious_software_detected"):
            suspicious_indicators.append(f"Image edited with {exif_results['flagged_tool']}")
            
        # 2. ELA Analysis
        ela_img, ela_score = self.calculate_ela(image_bytes, quality=settings.ELA_QUALITY)
        if ela_score > settings.ELA_ANOMALY_THRESHOLD:
            suspicious_indicators.append(f"High ELA anomaly score ({ela_score:.2f})")
            
        # 3. Noise Analysis
        image_np = decode_image(image_bytes)
        noise_ratio = self.analyze_noise_variance(image_np, face_box)
        if noise_ratio > settings.NOISE_RATIO_THRESHOLD:
            suspicious_indicators.append(f"High noise discrepancy (ratio: {noise_ratio:.2f}) between face and document")

        # Aggregate tamper score (simple heuristic)
        tamper_score = 0.0
        if exif_results.get("suspicious_software_detected"): tamper_score += 0.2
        if ela_score > settings.ELA_ANOMALY_THRESHOLD: tamper_score += 0.4 * min(ela_score / settings.ELA_ANOMALY_THRESHOLD, 1.0)
        if noise_ratio > settings.NOISE_RATIO_THRESHOLD: tamper_score += 0.4 * min(noise_ratio / settings.NOISE_RATIO_THRESHOLD, 1.0)
        
        is_tampered = tamper_score >= 0.5 or len(suspicious_indicators) >= 2
        
        return {
            "is_tampered": is_tampered,
            "overall_tamper_score": min(tamper_score, 1.0),
            "ela_anomaly_score": ela_score,
            "noise_inconsistency_ratio": noise_ratio,
            "exif_flagged": exif_results.get("suspicious_software_detected", False),
            "flagged_tool": exif_results.get("flagged_tool"),
            "suspicious_indicators": suspicious_indicators
        }

    def calculate_ela(self, image_bytes: bytes, quality: int = 90) -> Tuple[np.ndarray, float]:
        """Calculate Error Level Analysis (ELA)."""
        original = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        
        # Re-save at specified quality
        buffer = io.BytesIO()
        original.save(buffer, 'JPEG', quality=quality)
        recompressed = Image.open(buffer)
        
        # Calculate diff
        diff = ImageChops.difference(original, recompressed)
        
        # Enhance difference
        extrema = diff.getextrema()
        max_diff = max([ex[1] for ex in extrema])
        if max_diff == 0: max_diff = 1
        scale = 255.0 / max_diff
        ela_image = ImageEnhance.Brightness(diff).enhance(scale)
        
        # Calculate anomaly score (std/mean of error intensities)
        ela_np = np.array(ela_image)
        mean_val = np.mean(ela_np)
        std_val = np.std(ela_np)
        
        anomaly_score = std_val / (mean_val + 1e-5)
        return (ela_np, anomaly_score)

    def analyze_noise_variance(self, image_np: np.ndarray, face_box: Tuple[int, int, int, int] = None) -> float:
        """Compute Laplacian variance ratio for face vs overall image."""
        gray = cv2.cvtColor(image_np, cv2.COLOR_BGR2GRAY)
        overall_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        if not face_box or overall_var == 0:
            return 1.0
            
        x, y, w, h = face_box
        face_crop = gray[y:y+h, x:x+w]
        
        if face_crop.size == 0:
            return 1.0
            
        face_var = cv2.Laplacian(face_crop, cv2.CV_64F).var()
        return face_var / overall_var

    def inspect_exif(self, image_bytes: bytes) -> Dict[str, Any]:
        """Check EXIF data for editing tools."""
        suspicious_tools = ["photoshop", "gimp", "canva", "lightroom", "paint.net", "snapseed"]
        result = {
            "has_exif": False,
            "software": None,
            "camera_make": None,
            "suspicious_software_detected": False,
            "flagged_tool": None
        }
        
        try:
            im = Image.open(io.BytesIO(image_bytes))
            if 'exif' in im.info:
                exif_dict = piexif.load(im.info['exif'])
                result["has_exif"] = True
                
                # Check 0th IFD for Software tag (305) and Make (271)
                if piexif.ImageIFD.Software in exif_dict["0th"]:
                    software = exif_dict["0th"][piexif.ImageIFD.Software].decode('utf-8', errors='ignore').lower()
                    result["software"] = software
                    for tool in suspicious_tools:
                        if tool in software:
                            result["suspicious_software_detected"] = True
                            result["flagged_tool"] = tool
                            break
                            
                if piexif.ImageIFD.Make in exif_dict["0th"]:
                    result["camera_make"] = exif_dict["0th"][piexif.ImageIFD.Make].decode('utf-8', errors='ignore')
        except Exception:
            pass # Ignore malformed EXIF
            
        return result
