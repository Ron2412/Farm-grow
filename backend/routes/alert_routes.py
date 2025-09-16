from fastapi import APIRouter, Query, HTTPException
from models.farmer_models import SoilData
from services.alert_service import AlertService
from services.weather_service import WeatherService

router = APIRouter(prefix="/alerts", tags=["Alerts"])

alert_service = AlertService()
weather_service = WeatherService()

@router.post("/soil-weather")
async def get_soil_weather_alerts(
    soil_data: SoilData,
    crop: str = Query(..., description="Crop name e.g. wheat, rice"),
    lat: float = Query(..., description="Latitude of farm"),
    lon: float = Query(..., description="Longitude of farm"),
    days: int = Query(3, description="Forecast days (default=3)")
):
    try:
        # ✅ Fetch live forecast
        forecast_data = weather_service.get_weather_forecast(lat, lon, days)

        # ✅ Normalize forecast into alert-friendly format
        forecast = []
        for day in forecast_data.get("daily", []):
            forecast.append({
                "date": day["dt"],  # unix timestamp
                "temperature": {
                    "min": day["temp"]["min"],
                    "max": day["temp"]["max"]
                },
                "rainfall": day.get("rain", 0),
                "humidity": day["humidity"]
            })

        # ✅ Generate combined soil+weather alerts
        alerts = alert_service.generate_soil_weather_alerts(soil_data, forecast, crop)
        return {"alerts": alerts}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))