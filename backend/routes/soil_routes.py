# routes/soil_routes.py
import logging
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Dict, List, Any
from models.farmer_models import SoilData, CropRecommendation, CropRecommendationResponse, FertilizerRequest
from services.soil_service import SoilService

router = APIRouter(prefix="/soil", tags=["Soil & Crop"])
logger = logging.getLogger(__name__)

# Initialize service
soil_service = SoilService()

# API Routes

@router.post("/recommend-crop")
async def recommend_crop(soil_data: SoilData):
    try:
        recommendations = await soil_service.get_crop_recommendations(soil_data)
        return recommendations
    except Exception as e:
        logger.error(f"Error in crop recommendation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/fertilizer")
async def get_fertilizer_guidance(request: FertilizerRequest):
    try:
        guidance = await soil_service.get_fertilizer_guidance(request)
        return guidance
    except Exception as e:
        logger.error(f"Error in fertilizer guidance: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/deficiencies")
async def analyze_soil_deficiencies(soil_data: SoilData):
    try:
        deficiencies = await soil_service.analyze_soil_deficiencies(soil_data)
        return deficiencies
    except Exception as e:
        logger.error(f"Error in soil deficiency analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/seasonal-recommendations")
async def get_seasonal_recommendations(
    season: str = Query(..., description="Season (e.g., rabi, kharif)"),
    region: str = Query("ludhiana", description="Region name")
):
    try:
        recommendations = await soil_service.get_seasonal_recommendations(season, region)
        return recommendations
    except Exception as e:
        logger.error(f"Error in seasonal recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))