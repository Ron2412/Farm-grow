# services/soil_service.py
import logging
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Dict, List, Any
from models.farmer_models import SoilData, CropRecommendation, CropRecommendationResponse, FertilizerRequest
router = APIRouter(prefix="/soil", tags=["Soil & Crop"])
logger = logging.getLogger(__name__)

class SoilService:
    def __init__(self):
        self.crop_database = self._initialize_crop_database()

    def _initialize_crop_database(self) -> Dict[str, Any]:
        return {
            "wheat": {
                "ph_range": (6.0, 7.5),
                "soil_types": ["loamy", "clay loam", "sandy loam"],
                "season": "rabi",
                "yield_potential": 4500,
                "fertilizers": {
                    "sowing": "DAP (18-46-0) 100kg/acre at sowing.",
                    "growth": "Urea 50kg/acre after 30 days.",
                    "harvest": "Avoid excess nitrogen near harvest."
                },
                "deficiencies": {
                    "yellow leaves": "Possible nitrogen deficiency.",
                    "purple leaves": "Possible phosphorus deficiency."
                }
            },
            "rice": {
                "ph_range": (5.5, 6.5),
                "soil_types": ["clay", "clay loam"],
                "season": "kharif",
                "yield_potential": 6000,
                "fertilizers": {
                    "sowing": "NPK (12:32:16) 80kg/acre before transplanting.",
                    "growth": "Urea 60kg/acre at tillering stage.",
                    "harvest": "Reduce nitrogen before harvest to avoid lodging."
                },
                "deficiencies": {
                    "brown leaf tips": "Possible potassium deficiency.",
                    "stunted growth": "Possible nitrogen deficiency."
                }
            }
        }

    # -----------------------------
    # ✅ ML/Rule-based Crop Recommendations
    # -----------------------------
    async def get_crop_recommendations(self, soil_data: SoilData) -> CropRecommendationResponse:
        recommendations = []
        normalized = self._normalize_input(soil_data)

        for crop, details in self.crop_database.items():
            ph_ok = details["ph_range"][0] <= normalized["ph"] <= details["ph_range"][1]
            soil_ok = normalized["soil_type"] in details["soil_types"]

            if ph_ok and soil_ok:
                recommendations.append(
                    CropRecommendation(
                        crop_name=crop,
                        suitability_score=80.0,
                        expected_yield=details["yield_potential"],
                        season=details["season"],
                        reasons=["pH suitable", f"Soil type: {normalized['soil_type']}"],
                        precautions=["Maintain irrigation", "Avoid excess fertilizer"]
                    )
                )

        return CropRecommendationResponse(
            recommendations=recommendations,
            soil_health_status="Good" if recommendations else "Needs Improvement",
            general_advice=["Use compost", "Rotate crops for better soil health"]
        )

    def _normalize_input(self, soil_data: SoilData) -> Dict[str, Any]:
        return {
            "ph": soil_data.ph or soil_data.ph_level or 6.5,
            "soil_type": soil_data.soil_type.lower() if soil_data.soil_type else "loamy"
        }

    # -----------------------------
    # 🌾 Fertilizer Guidance
    # -----------------------------
    async def get_fertilizer_guidance(self, request: FertilizerRequest) -> Dict[str, str]:
        crop = request.crop_name.lower()
        if crop not in self.crop_database:
            return {"error": f"No fertilizer data for {crop}"}

        fertilizers = self.crop_database[crop]["fertilizers"]
        return {"crop": crop, "guidance": fertilizers.get(request.growth_stage, "No data")}

    # -----------------------------
    # 🧪 Soil Deficiency Analysis
    # -----------------------------
    async def analyze_soil_deficiencies(self, soil_data: SoilData) -> Dict[str, str]:
        findings = {}
        normalized = self._normalize_input(soil_data)

        for crop, details in self.crop_database.items():
            for symptom, advice in details["deficiencies"].items():
                if "low" in symptom and normalized["ph"] < 6:
                    findings[crop] = advice
                elif "yellow" in symptom and soil_data.nitrogen < 40:
                    findings[crop] = advice

        return findings or {"message": "Soil looks balanced"}

    # -----------------------------
    # 📅 Seasonal Recommendations
    # -----------------------------
    async def get_seasonal_recommendations(self, season: str, region: str) -> Dict[str, Any]:
        season = season.lower()
        recs = [c for c, details in self.crop_database.items() if details["season"] == season]

        if not recs:
            return {"message": f"No crops found for {season} in {region}"}

        return {
            "season": season,
            "region": region,
            "recommended_crops": recs
        }