# routes/soil_routes.py
from fastapi import APIRouter, HTTPException, Depends
from models.farmer_models import SoilData, FertilizerRequest
from services.soil_service import SoilService

router = APIRouter(prefix="/soil", tags=["Soil & Crop"])

# ✅ Create service instance
soil_service = SoilService()

# Temporary dependency (mock user auth)
async def verify_user():
    return "user_123"


# ----------------------------
# 🌱 Crop Recommendations
# ----------------------------
@router.post("/recommend-crop")
async def recommend_crop(soil_data: SoilData, user_id: str = Depends(verify_user)):
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
    try:
        deficiencies = await soil_service.analyze_soil_deficiencies(soil_data)
        return deficiencies
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------
# 📅 Seasonal Recommendations
# ----------------------------
@router.post("/seasonal-recommendations")
async def seasonal_recommendations(
    soil_data: SoilData,
    season: str,
    region: str,
    user_id: str = Depends(verify_user)
):
    try:
        recommendations = await soil_service.get_seasonal_recommendations(soil_data, season, region)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))