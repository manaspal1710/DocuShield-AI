from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    APP_NAME: str = "DocuShield AI"
    API_VERSION: str = "v1"
    ELA_QUALITY: int = 90
    ELA_ANOMALY_THRESHOLD: float = 0.35
    NOISE_RATIO_THRESHOLD: float = 2.5
    FACE_MATCH_THRESHOLD: float = 0.45
    ALLOWED_ORIGINS: List[str] = ["*"]
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB

    class Config:
        env_file = ".env"

settings = Settings()
