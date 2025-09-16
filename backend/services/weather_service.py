# backend/services/weather_service.py
import os
import requests
import logging
from dotenv import load_dotenv
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# Load environment variables from .env
load_dotenv()

class WeatherService:
    def __init__(self):
        self.api_key = os.getenv("OPENWEATHER_API_KEY")
        if not self.api_key:
            raise ValueError("❌ OPENWEATHER_API_KEY not found in environment.")
        self.base_url = "https://api.openweathermap.org/data/2.5"

    def get_current_weather(self, latitude: float, longitude: float):
        """Fetch current weather data (formatted)."""
        url = f"{self.base_url}/weather"
        params = {
            "lat": latitude,
            "lon": longitude,
            "appid": self.api_key,
            "units": "metric"
        }
        response = requests.get(url, params=params)
        data = response.json()

        if response.status_code != 200:
            logger.error(f"Weather API error: {data}")
            raise Exception(data.get("message", "Failed to fetch weather"))

        return {
            "temperature": data["main"]["temp"],
            "humidity": data["main"]["humidity"],
            "pressure": data["main"]["pressure"],
            "weather_condition": data["weather"][0]["description"],
            "wind_speed": data["wind"]["speed"],
            "city": data.get("name", "Unknown")
        }

    def get_weather_forecast(self, latitude: float, longitude: float, days: int = 5):
        """
        Fetch and format weather forecast (3-hourly → daily summary).
        Uses OpenWeather 5-day forecast API.
        """
        url = f"{self.base_url}/forecast"
        params = {
            "lat": latitude,
            "lon": longitude,
            "appid": self.api_key,
            "units": "metric"
        }
        response = requests.get(url, params=params)
        data = response.json()

        if response.status_code != 200:
            logger.error(f"Forecast API error: {data}")
            raise Exception(data.get("message", "Failed to fetch forecast"))

        # Aggregate into daily forecasts
        forecast_list = data.get("list", [])
        daily_data = {}

        for entry in forecast_list:
            date_str = entry["dt_txt"].split(" ")[0]  # YYYY-MM-DD
            temp = entry["main"]["temp"]
            humidity = entry["main"]["humidity"]
            rainfall = entry.get("rain", {}).get("3h", 0)

            if date_str not in daily_data:
                daily_data[date_str] = {
                    "date": date_str,
                    "temperature": {"min": temp, "max": temp},
                    "humidity": [humidity],
                    "rainfall": rainfall
                }
            else:
                daily_data[date_str]["temperature"]["min"] = min(daily_data[date_str]["temperature"]["min"], temp)
                daily_data[date_str]["temperature"]["max"] = max(daily_data[date_str]["temperature"]["max"], temp)
                daily_data[date_str]["humidity"].append(humidity)
                daily_data[date_str]["rainfall"] += rainfall

        # Convert to list and average humidity
        formatted_forecast = []
        for date, values in list(daily_data.items())[:days]:
            formatted_forecast.append({
                "date": date,
                "temperature": values["temperature"],
                "rainfall": round(values["rainfall"], 1),
                "humidity": sum(values["humidity"]) // len(values["humidity"])
            })

        return {
            "city": data.get("city", {}).get("name"),
            "forecast": formatted_forecast
        }