from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import logging

# Import services and models
from services.ml_service import MLService
from models.farmer_models import SoilData

# Import routes
from routes import weather_routes, soil_routes, ml_routes, alert_routes, market_routes
# Later: market_routes, voice_routes, pest_routes, farmer_routes

# Initialize ML service
ml_service = MLService()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="Smart Crop Advisory System API",
    description="Backend API for Smart Crop Advisory System for Small and Marginal Farmers",
    version="1.0.0"
)

# CORS Middleware (allow frontend access)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ⚠️ In production, restrict to frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------
# Utility placeholder
# -----------------------------
async def verify_user():
    # Later replace with Firebase JWT verification
    return "user_123"

# -----------------------------
# Health check
# -----------------------------
@app.get("/")
async def root():
    return {
        "message": "Smart Crop Advisory System API is running 🚀",
        "status": "healthy"
    }

# -----------------------------
# Register routers
# -----------------------------
app.include_router(weather_routes.router)
app.include_router(soil_routes.router)
app.include_router(ml_routes.router)
app.include_router(alert_routes.router)
app.include_router(market_routes.router)

# -----------------------------
# ML direct test route (optional)
# -----------------------------
@app.post("/ml/recommend-crop")
async def recommend_crop_ml(soil_data: SoilData, user_id: str = Depends(verify_user)):
    try:
        features = [
            soil_data.ph_level or soil_data.ph,
            soil_data.nitrogen,
            soil_data.phosphorus,
            soil_data.potassium,
            soil_data.temperature or 25,
            soil_data.humidity or 60,
            soil_data.rainfall or 200
        ]
        recommendation = ml_service.recommend_crop(features)
        return {"recommended_crop": recommendation}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# -----------------------------
# Run app
# -----------------------------
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)