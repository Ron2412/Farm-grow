# routes/soil_routes.py
from fastapi import APIRouter, HTTPException, Depends, Query
from models.farmer_models import SoilData, FertilizerRequest
from services.soil_service import SoilService

router = APIRouter(prefix="/soil", tags=["Soil & Crop"])

# ✅ Create service instance
soil_service = SoilService()

# Temporary dependency (mock user auth)
async def verify_user():
    return "user_123"


# ----------------------------
# 🌱 Crop Recommendations (ML-based)
# ----------------------------
@router.post("/recommend-crop")
async def recommend_crop(soil_data: SoilData, user_id: str = Depends(verify_user)):
    """
    Recommend crops using ML model based on detailed soil data (NPK, pH, etc.).
    """
    try:
        recommendations = await soil_service.get_crop_recommendations(soil_data)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------
# 🌾 Fertilizer Guidance
# ----------------------------
@router.post("/fertilizer-guidance")
async def fertilizer_guidance(request: FertilizerRequest, user_id: str = Depends(verify_user)):
    """
    Recommend fertilizer guidance based on crop, soil, and growth stage.
    """
    try:
        guidance = await soil_service.get_fertilizer_guidance(request)
        return guidance
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------
# 🧪 Soil Deficiency Analysis
# ----------------------------
@router.post("/analyze-deficiencies")
async def analyze_deficiencies(soil_data: SoilData, user_id: str = Depends(verify_user)):
    """
    Analyze soil data to detect possible nutrient deficiencies.
    """
    try:
        deficiencies = await soil_service.analyze_soil_deficiencies(soil_data)
        return deficiencies
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------
# 📅 Seasonal Recommendations (Simplified for Farmers)
# ----------------------------
@router.get("/seasonal-recommendations")
async def seasonal_recommendations(
    season: str = Query(..., description="Choose season: rabi or kharif"),
    region: str = Query("ludhiana", description="Region (default: Ludhiana)"),
    user_id: str = Depends(verify_user)
):
    """
    Recommend crops based on season & region.
    Farmers don’t need to input soil data, defaults are used for Ludhiana.
    """
    try:
        recommendations = await soil_service.get_seasonal_recommendations(season, region)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))