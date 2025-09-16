# backend/models/farmer_models.py
"""
Pydantic v2 models for Smart Crop Advisory backend.
- Compatible with Pydantic v2 (uses field_validator, pattern instead of regex).
- Includes robust validators for phone and crops_grown.
- Keeps both `ph` and `ph_level` (backwards-compatible) and normalizes access via a helper property.
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


# -----------------------
# Authentication
# -----------------------
class TokenVerification(BaseModel):
    token: str


# -----------------------
# Farmer Profile
# -----------------------
class FarmerProfile(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., pattern=r'^\+?[1-9]\d{1,14}$')
    state: str = Field(..., min_length=2, max_length=50)
    district: str = Field(..., min_length=2, max_length=50)
    village: str = Field(..., min_length=2, max_length=50)
    farm_size: float = Field(..., gt=0, description="Farm size in acres")
    farming_experience: int = Field(..., ge=0, le=100)
    primary_language: str = Field(..., min_length=2, max_length=10)
    crops_grown: List[str] = Field(..., min_items=1, description="List of crops (strings)")
    education_level: Optional[str] = None
    annual_income: Optional[float] = Field(None, ge=0)

    @field_validator("phone")
    def validate_phone_number(cls, v: str) -> str:
        """Ensure phone has 10-15 digits (strip formatting)."""
        cleaned = ''.join(filter(str.isdigit, v))
        if len(cleaned) < 10 or len(cleaned) > 15:
            raise ValueError("Phone number must be between 10–15 digits")
        return v

    @field_validator("crops_grown")
    def validate_crops(cls, v: List[str]) -> List[str]:
        """Normalize crop names: strip + lowercase; ensure at least one crop."""
        if not v or len(v) == 0:
            raise ValueError("At least one crop must be specified")
        normalized = []
        for crop in v:
            if not isinstance(crop, str) or not crop.strip():
                continue
            normalized.append(crop.strip().lower())
        if not normalized:
            raise ValueError("At least one valid crop must be provided")
        return normalized


# -----------------------
# Chatbot
# -----------------------
class ChatbotQuery(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    language: str = Field(default="hi", min_length=2, max_length=10)
    context: Optional[Dict[str, Any]] = None


class ChatbotResponse(BaseModel):
    response: str
    confidence: float = Field(..., ge=0, le=1)
    suggestions: Optional[List[str]] = None
    follow_up_questions: Optional[List[str]] = None


# -----------------------
# Soil & Crop
# -----------------------
class SoilData(BaseModel):
    # Allow either 'ph' or legacy 'ph_level' to be provided by the client.
    # Prefer using `ph` in new requests.
    ph: Optional[float] = Field(None, ge=0, le=14, description="Soil pH (preferred)")
    ph_level: Optional[float] = Field(None, ge=0, le=14, description="Legacy alias for pH")

    nitrogen: float = Field(..., ge=0, description="Available N (kg/ha or user unit)")
    phosphorus: float = Field(..., ge=0, description="Available P")
    potassium: float = Field(..., ge=0, description="Available K")
    temperature: Optional[float] = Field(None, description="Ambient temperature °C")
    humidity: Optional[float] = Field(None, ge=0, le=100, description="Ambient humidity %")
    rainfall: Optional[float] = Field(None, ge=0, description="Recent rainfall / mm")

    organic_carbon: Optional[float] = Field(None, ge=0, description="Organic carbon %")
    soil_type: Optional[str] = Field(None, min_length=2, max_length=50)
    moisture_level: Optional[float] = Field(None, ge=0, le=100, description="Soil moisture %")
    location: Optional[Dict[str, float]] = None  # {"lat": ..., "lng": ...}

    def normalized_ph(self) -> Optional[float]:
        """
        Return the canonical pH value:
         - prefer `ph` if provided; otherwise use legacy `ph_level`
        """
        return self.ph if self.ph is not None else self.ph_level


class CropRecommendation(BaseModel):
    crop_name: str
    suitability_score: float = Field(..., ge=0, le=100)
    expected_yield: Optional[float] = None
    season: str
    reasons: List[str]
    precautions: Optional[List[str]] = None


class CropRecommendationResponse(BaseModel):
    recommendations: List[CropRecommendation]
    soil_health_status: str
    general_advice: List[str]


# -----------------------
# Fertilizer
# -----------------------
class GrowthStage(str, Enum):
    SEEDLING = "seedling"
    VEGETATIVE = "vegetative"
    FLOWERING = "flowering"
    FRUITING = "fruiting"
    MATURITY = "maturity"


class FertilizerRequest(BaseModel):
    crop_name: str = Field(..., min_length=2, max_length=50)
    soil_data: SoilData
    growth_stage: GrowthStage
    area: float = Field(..., gt=0, description="Area in acres")
    current_season: str


class FertilizerRecommendation(BaseModel):
    fertilizer_name: str
    quantity: float
    unit: str
    application_method: str
    timing: str
    cost_estimate: Optional[float] = None
    precautions: List[str]


class FertilizerGuidanceResponse(BaseModel):
    recommendations: List[FertilizerRecommendation]
    total_cost_estimate: Optional[float] = None
    application_schedule: Dict[str, List[str]]


# -----------------------
# Weather
# -----------------------
class WeatherAlert(BaseModel):
    alert_type: str
    severity: str
    message: str
    start_date: datetime
    end_date: Optional[datetime] = None
    affected_crops: List[str]
    recommendations: List[str]


class WeatherData(BaseModel):
    temperature: float
    humidity: float
    rainfall: float
    wind_speed: float
    pressure: float
    weather_condition: str
    alerts: List[WeatherAlert]
    timestamp: datetime


class WeatherForecast(BaseModel):
    daily_forecast: List[WeatherData]
    weekly_summary: Dict[str, Any]
    crop_specific_advice: List[str]


# -----------------------
# Pest Detection
# -----------------------
class PestDetectionResult(BaseModel):
    detected_pest: Optional[str] = None
    detected_disease: Optional[str] = None
    confidence_score: float = Field(..., ge=0, le=1)
    severity_level: str
    affected_area_percentage: Optional[float] = Field(None, ge=0, le=100)
    treatment_recommendations: List[str]
    preventive_measures: List[str]
    organic_alternatives: Optional[List[str]] = None


# -----------------------
# Market Prices
# -----------------------
class MarketPrice(BaseModel):
    mandi_name: str
    price_per_quintal: float
    date: datetime
    variety: Optional[str] = None
    quality: Optional[str] = None


class MarketPriceResponse(BaseModel):
    crop_name: str
    current_prices: List[MarketPrice]
    price_trend: str
    average_price: float
    price_forecast: Optional[Dict[str, float]] = None
    best_selling_locations: List[str]


# -----------------------
# Voice Support
# -----------------------
class TTSRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=1000)
    language: str = Field(default="hi", min_length=2, max_length=10)
    voice_type: Optional[str] = Field(default="female")


class VoiceResponse(BaseModel):
    audio_url: str
    duration: Optional[float] = None


# -----------------------
# Feedback
# -----------------------
class FeedbackCategory(str, Enum):
    CROP_RECOMMENDATION = "crop_recommendation"
    FERTILIZER_GUIDANCE = "fertilizer_guidance"
    WEATHER_ALERTS = "weather_alerts"
    PEST_DETECTION = "pest_detection"
    MARKET_PRICES = "market_prices"
    APP_USABILITY = "app_usability"
    GENERAL = "general"


class FeedbackData(BaseModel):
    category: FeedbackCategory
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=500)
    feature_used: Optional[str] = None
    suggestions: Optional[str] = Field(None, max_length=500)
    would_recommend: Optional[bool] = None


# -----------------------
# Analytics
# -----------------------
class UsageAnalytics(BaseModel):
    feature_name: str
    usage_count: int
    last_used: datetime
    success_rate: Optional[float] = Field(None, ge=0, le=1)


class FarmerAnalytics(BaseModel):
    total_queries: int
    most_used_features: List[str]
    avg_session_duration: Optional[float] = None
    satisfaction_score: Optional[float] = Field(None, ge=0, le=5)
    usage_analytics: List[UsageAnalytics]


# -----------------------
# Notifications
# -----------------------
class NotificationType(str, Enum):
    WEATHER_ALERT = "weather_alert"
    PEST_WARNING = "pest_warning"
    MARKET_UPDATE = "market_update"
    FERTILIZER_REMINDER = "fertilizer_reminder"
    GENERAL_TIP = "general_tip"


class NotificationData(BaseModel):
    type: NotificationType
    title: str = Field(..., min_length=1, max_length=100)
    message: str = Field(..., min_length=1, max_length=500)
    priority: str = Field(default="medium")
    target_crops: Optional[List[str]] = None
    target_regions: Optional[List[str]] = None
    expires_at: Optional[datetime] = None


# -----------------------
# Error / Success
# -----------------------
class ErrorResponse(BaseModel):
    error: bool = True
    message: str
    error_code: Optional[str] = None
    details: Optional[Dict[str, Any]] = None


class SuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: Optional[Dict[str, Any]] = None