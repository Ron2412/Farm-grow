# routes/ml_routes.py
from fastapi import APIRouter, HTTPException, Depends
from models.farmer_models import SoilData
from services.ml_service import MLService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ml", tags=["Machine Learning"])
ml_service = MLService()

# Temporary user verification (avoid circular import for now)
async def verify_user():
    return "user_123"

@router.post("/recommend-crop")
async def recommend_crop_ml(soil_data: SoilData, user_id: str = Depends(verify_user)):
    try:
        recommendation = ml_service.predict_crop(soil_data)
        # recommendation is already a dict {"recommended_crop": "rice"}
        return recommendation  
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))