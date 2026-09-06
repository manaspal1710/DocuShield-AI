import numpy as np
from insightface.app import FaceAnalysis
from typing import Dict, Any, Tuple
from app.utils.image_utils import decode_image
from app.core.config import settings

class FaceService:
    def __init__(self):
        """Initialize InsightFace."""
        self.app = FaceAnalysis(name='buffalo_s', providers=['CPUExecutionProvider'])
        self.app.prepare(ctx_id=0, det_size=(320, 320))

    def detect_face_box(self, image_bytes: bytes) -> Tuple[int, int, int, int] | None:
        """Return (x, y, w, h) of the largest detected face."""
        image_np = decode_image(image_bytes)
        faces = self.app.get(image_np)
        
        if not faces:
            return None
            
        # Find largest face by area
        largest_face = max(faces, key=lambda f: (f.bbox[2]-f.bbox[0]) * (f.bbox[3]-f.bbox[1]))
        box = largest_face.bbox.astype(int)
        x, y, w, h = box[0], box[1], box[2] - box[0], box[3] - box[1]
        return (x, y, w, h)

    def verify(self, doc_image_bytes: bytes, selfie_image_bytes: bytes, threshold: float = None) -> Dict[str, Any]:
        """Verify if face in document matches face in selfie."""
        threshold = threshold or settings.FACE_MATCH_THRESHOLD
        
        doc_np = decode_image(doc_image_bytes)
        selfie_np = decode_image(selfie_image_bytes)
        
        doc_faces = self.app.get(doc_np)
        selfie_faces = self.app.get(selfie_np)
        
        doc_face_found = len(doc_faces) > 0
        selfie_face_found = len(selfie_faces) > 0
        
        result = {
            "matched": False,
            "similarity_score": 0.0,
            "threshold": threshold,
            "face_found_in_document": doc_face_found,
            "face_found_in_selfie": selfie_face_found,
            "doc_face_bbox": None,
            "error": None
        }
        
        if not doc_face_found:
            result["error"] = "No face found in document."
            return result
            
        if not selfie_face_found:
            result["error"] = "No face found in selfie."
            return result
            
        doc_face = max(doc_faces, key=lambda f: (f.bbox[2]-f.bbox[0]) * (f.bbox[3]-f.bbox[1]))
        selfie_face = max(selfie_faces, key=lambda f: (f.bbox[2]-f.bbox[0]) * (f.bbox[3]-f.bbox[1]))
        
        doc_emb = doc_face.normed_embedding
        selfie_emb = selfie_face.normed_embedding
        
        # Cosine similarity
        similarity = np.dot(doc_emb, selfie_emb)
        
        box = doc_face.bbox.astype(int)
        result["doc_face_bbox"] = (int(box[0]), int(box[1]), int(box[2] - box[0]), int(box[3] - box[1]))
        result["similarity_score"] = float(similarity)
        result["matched"] = bool(similarity >= threshold)
        
        return result
