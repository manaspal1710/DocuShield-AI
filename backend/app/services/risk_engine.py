from typing import Dict, Any
from app.core.config import settings

class RiskEngine:
    def calculate_risk(self, mrz_result: Dict[str, Any], tampering_result: Dict[str, Any], face_result: Dict[str, Any], is_expired: bool) -> Dict[str, Any]:
        """Aggregate signals and compute a weighted risk score (0-100)."""
        risk_score = 0.0
        risk_factors = []

        # 1. MRZ Checksum Failure (weight 0.30)
        # Only penalize if an MRZ was actually detected on a travel document and failed
        if mrz_result.get("format") is not None and not mrz_result.get("checksums_passed", True):
            risk_score += 30.0
            risk_factors.append("MRZ checksum validation failed")

        # 2. Tampering - ELA Anomaly (weight 0.20)
        ela_score = tampering_result.get("ela_anomaly_score", 0)
        if ela_score > settings.ELA_ANOMALY_THRESHOLD:
            # Scale anomaly relative to threshold, up to 20 pts
            pts = min(20.0, 20.0 * (ela_score / settings.ELA_ANOMALY_THRESHOLD))
            risk_score += pts
            risk_factors.append(f"High image anomaly detected (ELA: {ela_score:.2f})")

        # 3. Tampering - Noise Inconsistency (weight 0.10)
        noise_ratio = tampering_result.get("noise_inconsistency_ratio", 1.0)
        if noise_ratio > settings.NOISE_RATIO_THRESHOLD:
            risk_score += 10.0
            risk_factors.append("Inconsistent image noise around portrait (Possible face paste)")

        # 4. Tampering - EXIF Editing Tools (weight 0.05)
        if tampering_result.get("exif_flagged"):
            risk_score += 5.0
            risk_factors.append(f"Suspicious editing software detected ({tampering_result.get('flagged_tool')})")

        # 5. Face Mismatch (weight 0.15)
        # Only penalize if a selfie was provided and face did not match
        if not face_result.get("matched", True):
            is_skipped = face_result.get("error") and "Skipped" in str(face_result.get("error"))
            if not is_skipped:
                similarity = face_result.get("similarity_score", 1.0)
                risk_score += 15.0 * (1.0 - max(similarity, 0))
                risk_factors.append(f"Low face similarity score ({similarity:.2f})")
            
        # 6. Document Expired (weight 0.05)
        if is_expired:
            risk_score += 5.0
            risk_factors.append("Document has expired")

        # Ensure bounds
        risk_score = min(max(risk_score, 0.0), 100.0)

        # Decision
        if risk_score < 30.0:
            decision = "CLEAR"
        elif risk_score <= 60.0:
            decision = "REVIEW"
        else:
            decision = "REJECT"

        return {
            "risk_score": risk_score,
            "decision": decision,
            "risk_factors": risk_factors
        }
