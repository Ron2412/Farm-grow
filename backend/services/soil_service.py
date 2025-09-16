# services/soil_service.py
import logging
from typing import Dict, List, Any, Tuple
from models.farmer_models import SoilData, CropRecommendation, CropRecommendationResponse

logger = logging.getLogger(__name__)

class SoilService:
    def __init__(self):
        self.crop_database = self._initialize_crop_database()

    def _initialize_crop_database(self) -> Dict[str, Any]:
        """Initialize a simple crop suitability database"""
        return {
            "wheat": {
                "ph_range": (6.0, 7.5),
                "nitrogen_req": (40, 80),
                "phosphorus_req": (20, 40),
                "potassium_req": (30, 60),
                "soil_types": ["loamy", "clay loam", "sandy loam"],
                "temperature_range": (15, 25),
                "water_requirement": "medium",
                "yield_potential": 4500,
            },
            "rice": {
                "ph_range": (5.5, 6.5),
                "nitrogen_req": (80, 120),
                "phosphorus_req": (30, 50),
                "potassium_req": (40, 80),
                "soil_types": ["clay", "clay loam"],
                "temperature_range": (20, 30),
                "water_requirement": "high",
                "yield_potential": 6000,
            }
            # ➕ You can add more crops here...
        }

    def _normalize_input(self, soil_data: SoilData) -> Dict[str, Any]:
        """
        Normalize soil data into a standard dict for both ML and rule-based checks.
        """
        return {
            "ph": soil_data.ph or soil_data.ph_level or 6.5,
            "nitrogen": soil_data.nitrogen,
            "phosphorus": soil_data.phosphorus,
            "potassium": soil_data.potassium,
            "temperature": soil_data.temperature or 25,
            "humidity": soil_data.humidity or 60,
            "rainfall": soil_data.rainfall or 100,
            "soil_type": soil_data.soil_type.lower() if soil_data.soil_type else "unknown",
            "organic_carbon": soil_data.organic_carbon or 0.7,
        }

    async def get_crop_recommendations(self, soil_data: SoilData) -> CropRecommendationResponse:
        """
        Recommend crops based on normalized soil parameters.
        """
        try:
            normalized = self._normalize_input(soil_data)
            recommendations = []

            for crop_name, crop_info in self.crop_database.items():
                score = self._calculate_suitability_score(normalized, crop_info)

                if score > 60:  # Only recommend if reasonably suitable
                    recommendation = CropRecommendation(
                        crop_name=crop_name,
                        suitability_score=round(score, 1),
                        expected_yield=self._estimate_yield(crop_info, score),
                        season="N/A",
                        reasons=[f"pH {normalized['ph']} in range {crop_info['ph_range']}"],
                        precautions=["Ensure irrigation as per crop needs"],
                    )
                    recommendations.append(recommendation)

            return CropRecommendationResponse(
                recommendations=recommendations,
                soil_health_status=self._assess_soil_health(normalized),
                general_advice=["Use organic compost", "Perform soil test every season"]
            )
        except Exception as e:
            logger.error(f"Error generating crop recommendations: {e}")
            raise Exception(f"Failed to generate crop recommendations: {e}")

    def _calculate_suitability_score(self, soil: Dict[str, Any], crop_info: Dict) -> float:
        """Calculate simple suitability score."""
        score = 0

        # pH
        ph_min, ph_max = crop_info["ph_range"]
        if ph_min <= soil["ph"] <= ph_max:
            score += 30

        # Nutrients
        if soil["nitrogen"] >= crop_info["nitrogen_req"][0]:
            score += 20
        if soil["phosphorus"] >= crop_info["phosphorus_req"][0]:
            score += 20
        if soil["potassium"] >= crop_info["potassium_req"][0]:
            score += 20

        # Soil type
        if any(st in soil["soil_type"] for st in crop_info["soil_types"]):
            score += 10

        return min(score, 100)

    def _estimate_yield(self, crop_info: Dict, score: float) -> float:
        """Estimate yield proportional to suitability score."""
        return round(crop_info["yield_potential"] * (score / 100), 2)

    def _assess_soil_health(self, soil: Dict[str, Any]) -> str:
        """Rough soil health status."""
        if 6 <= soil["ph"] <= 7.5 and soil["nitrogen"] > 50:
            return "Good"
        return "Needs Improvement"