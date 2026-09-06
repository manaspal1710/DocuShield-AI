from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.config import settings
from app.api.v1.router import api_router
from app.services.ocr_service import OCRService
from app.services.face_service import FaceService

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Preload AI models into app.state on startup
    print("Loading AI Models...")
    app.state.ocr_service = OCRService()
    app.state.face_service = FaceService()
    print("Models loaded successfully.")
    yield
    print("Shutting down and cleaning up resources.")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.API_VERSION,
    lifespan=lifespan
)

# Add CORS middleware with all origins allowed for hackathon
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.APP_NAME} API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
