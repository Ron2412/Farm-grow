# routes/pest_routes.py
from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Query
from typing import Optional, List
import logging
from models.farmer_models import PestDetectionResult
import random
import time

router = APIRouter(prefix="/pest", tags=["Pest Detection"])
logger = logging.getLogger(__name__)

# Mock pest detection data
MOCK_PESTS = {
    "aphids": {
        "severity_level": "moderate",
        "affected_area_percentage": 35.0,
        "treatment_recommendations": [
            "Apply neem oil spray (15ml per liter of water)",
            "Introduce ladybugs as natural predators",
            "Remove heavily infested plant parts",
            "Apply insecticidal soap for severe infestations"
        ],
        "preventive_measures": [
            "Regularly inspect plants for early signs",
            "Maintain proper plant spacing for air circulation",
            "Use yellow sticky traps to monitor population",
            "Plant companion plants like marigold or nasturtium"
        ],
        "organic_alternatives": [
            "Garlic spray (crush 10 cloves in 1L water)",
            "Diatomaceous earth application",
            "Soap and water spray (2 tbsp soap in 1L water)"
        ]
    },
    "powdery_mildew": {
        "severity_level": "high",
        "affected_area_percentage": 60.0,
        "treatment_recommendations": [
            "Apply fungicide with sulfur as active ingredient",
            "Remove and destroy infected plant parts",
            "Increase air circulation around plants",
            "Apply potassium bicarbonate solution"
        ],
        "preventive_measures": [
            "Avoid overhead watering",
            "Space plants properly",
            "Use resistant varieties when available",
            "Rotate crops annually"
        ],
        "organic_alternatives": [
            "Milk spray (1 part milk to 9 parts water)",
            "Baking soda solution (1 tbsp in 1 gallon water with few drops of soap)",
            "Neem oil application"
        ]
    },
    "leaf_spot": {
        "severity_level": "low",
        "affected_area_percentage": 15.0,
        "treatment_recommendations": [
            "Apply copper-based fungicide",
            "Remove infected leaves",
            "Improve drainage around plants",
            "Avoid wetting foliage when watering"
        ],
        "preventive_measures": [
            "Rotate crops",
            "Use disease-free seeds",
            "Maintain proper plant spacing",
            "Clean garden tools between uses"
        ],
        "organic_alternatives": [
            "Compost tea spray",
            "Garlic and pepper spray",
            "Apple cider vinegar solution (2 tbsp in 1 gallon water)"
        ]
    }
}

@router.post("/detect", response_model=PestDetectionResult)
async def detect_pest(
    image: UploadFile = File(...),
    crop_type: str = Form(...),
    location: Optional[str] = Form(None)
):
    """
    Upload an image for pest or disease detection.
    This endpoint accepts plant images and returns detection results.
    """
    try:
        # Simulate processing time
        time.sleep(1)
        
        # Mock detection - randomly select a pest or return no detection
        detection_options = list(MOCK_PESTS.keys()) + [None]
        weights = [0.25, 0.25, 0.25, 0.25]  # 75% chance of detection
        
        detected = random.choices(detection_options, weights=weights, k=1)[0]
        
        if detected is None:
            return PestDetectionResult(
                detected_pest=None,
                detected_disease=None,
                confidence_score=0.95,
                severity_level="none",
                affected_area_percentage=0,
                treatment_recommendations=["No treatment needed"],
                preventive_measures=["Continue regular monitoring"]
            )
        
        pest_info = MOCK_PESTS[detected]
        confidence = round(random.uniform(0.70, 0.98), 2)
        
        # Determine if it's a pest or disease (for demo purposes)
        is_disease = detected in ["powdery_mildew", "leaf_spot"]
        
        return PestDetectionResult(
            detected_pest=None if is_disease else detected,
            detected_disease=detected if is_disease else None,
            confidence_score=confidence,
            severity_level=pest_info["severity_level"],
            affected_area_percentage=pest_info["affected_area_percentage"],
            treatment_recommendations=pest_info["treatment_recommendations"],
            preventive_measures=pest_info["preventive_measures"],
            organic_alternatives=pest_info["organic_alternatives"]
        )
        
    except Exception as e:
        logger.error(f"Error in pest detection: {e}")
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


@router.get("/common-pests")
async def get_common_pests(crop: Optional[str] = Query(None)):
    """Get list of common pests for a specific crop or general pests"""
    
    crop_pests = {
        "rice": ["Rice weevil", "Brown planthopper", "Stem borer"],
        "wheat": ["Aphids", "Hessian fly", "Wheat stem sawfly"],
        "cotton": ["Bollworm", "Whitefly", "Thrips"],
        "maize": ["Fall armyworm", "Corn earworm", "Corn rootworm"]
    }
    
    if crop and crop.lower() in crop_pests:
        return {"crop": crop, "common_pests": crop_pests[crop.lower()]}
    
    # Return general pest information if no specific crop or unknown crop
    return {
        "general_pests": [
            {
                "name": "Aphids",
                "description": "Small sap-sucking insects that can cause significant damage",
                "affected_crops": ["wheat", "vegetables", "fruits"]
            },
            {
                "name": "Whitefly",
                "description": "Small winged insects that feed on plant sap and spread diseases",
                "affected_crops": ["cotton", "vegetables", "ornamentals"]
            },
            {
                "name": "Thrips",
                "description": "Tiny, slender insects that feed on plant tissues",
                "affected_crops": ["onions", "cotton", "flowers"]
            }
        ]
    }