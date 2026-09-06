import cv2
import numpy as np
import io
from PIL import Image

def decode_image(image_bytes: bytes) -> np.ndarray:
    """Decode bytes to OpenCV BGR image."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    return img

def encode_image_to_bytes(image_np: np.ndarray, format: str = 'jpg') -> bytes:
    """Encode numpy array to bytes."""
    success, encoded_image = cv2.imencode(f'.{format}', image_np)
    if success:
        return encoded_image.tobytes()
    return b""

def resize_for_processing(image_np: np.ndarray, max_dim: int = 1600) -> np.ndarray:
    """Resize keeping aspect ratio."""
    h, w = image_np.shape[:2]
    if max(h, w) > max_dim:
        scale = max_dim / float(max(h, w))
        image_np = cv2.resize(image_np, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    return image_np

def convert_to_grayscale(image_np: np.ndarray) -> np.ndarray:
    """BGR to grayscale."""
    if len(image_np.shape) == 3:
        return cv2.cvtColor(image_np, cv2.COLOR_BGR2GRAY)
    return image_np

def deskew_image(image_np: np.ndarray) -> np.ndarray:
    """Auto-deskew using Hough lines."""
    gray = convert_to_grayscale(image_np)
    edges = cv2.Canny(gray, 50, 150, apertureSize=3)
    lines = cv2.HoughLines(edges, 1, np.pi/180, 200)
    
    if lines is not None:
        angles = []
        for line in lines:
            r, theta = line[0]
            angle = np.degrees(theta)
            if angle < 45:
                angles.append(angle)
            elif angle > 135:
                angles.append(angle - 180)
                
        if angles:
            median_angle = np.median(angles)
            (h, w) = image_np.shape[:2]
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
            rotated = cv2.warpAffine(image_np, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
            return rotated
            
    return image_np
