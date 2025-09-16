# backend/routes/weather_routes.py
from fastapi import APIRouter, HTTPException, Query
from services.weather_service import WeatherService
from services.alert_service import AlertService

router = APIRouter(prefix="/weather", tags=["Weather"])

# Initialize services
weather_service = WeatherService()
alert_service = AlertService()

@router.get("/current")
async def get_current_weather(lat: float = Query(...), lon: float = Query(...)):
    """Get current weather conditions"""
    try:
        weather = weather_service.get_current_weather(lat, lon)
        return weather
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/forecast")
async def get_weather_forecast(
    lat: float = Query(...),
    lon: float = Query(...),
    days: int = Query(5, ge=1, le=7),
    crop: str = Query("wheat")  # default wheat
):
    """
    Get weather forecast + predictive crop-specific alerts
    """
    try:
        forecast = weather_service.get_weather_forecast(lat, lon, days)

        # Generate predictive alerts for chosen crop
        alerts = alert_service.generate_weather_alerts(forecast["forecast"], crop)

        return {
            "city": forecast["city"],
            "forecast": forecast["forecast"],
            "crop": crop,
            "alerts": alerts
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))