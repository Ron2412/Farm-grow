from typing import List, Dict
import logging
from models.farmer_models import SoilData

logger = logging.getLogger(__name__)

class AlertService:
    def __init__(self):
        self.crop_rules = {
            "wheat": {
                "temp_range": (10, 25),  
                "humidity_max": 85,      
                "rainfall_max": 20,      
                "alerts": {
                    "heat": "High temp may reduce yield and cause heat stress in wheat.",
                    "frost": "Low temp may damage wheat seedlings. Consider irrigation to reduce frost.",
                    "humidity": "High humidity increases rust & fungal disease risk. Apply fungicide if needed.",
                    "rain": "Heavy rain may cause lodging & waterlogging. Ensure drainage."
                }
            },
            "rice": {
                "temp_range": (20, 35),  
                "humidity_min": 60,      
                "rainfall_min": 5,       
                "alerts": {
                    "cold": "Low temp may slow rice growth. Consider transplanting delay.",
                    "heat": "Excess heat may cause spikelet sterility in rice.",
                    "humidity": "Low humidity may reduce tillering. Keep fields irrigated.",
                    "drought": "Insufficient rainfall detected. Ensure irrigation for paddy."
                }
            }
        }

    def generate_weather_alerts(self, forecast: List[Dict], crop: str) -> List[Dict]:
        crop = crop.lower()
        if crop not in self.crop_rules:
            logger.warning(f"No crop rules defined for {crop}")
            return []

        rules = self.crop_rules[crop]
        alerts = []

        for day in forecast:
            temp_min = day["temperature"]["min"]
            temp_max = day["temperature"]["max"]
            rainfall = day["rainfall"]
            humidity = day["humidity"]

            if crop == "wheat":
                if temp_max > rules["temp_range"][1]:
                    alerts.append(self._make_alert(day, "Heat Stress", "high", rules["alerts"]["heat"]))
                if temp_min < rules["temp_range"][0]:
                    alerts.append(self._make_alert(day, "Frost Risk", "medium", rules["alerts"]["frost"]))
                if humidity > rules["humidity_max"]:
                    alerts.append(self._make_alert(day, "High Humidity", "medium", rules["alerts"]["humidity"]))
                if rainfall > rules["rainfall_max"]:
                    alerts.append(self._make_alert(day, "Heavy Rain Risk", "high", rules["alerts"]["rain"]))

            elif crop == "rice":
                if temp_min < rules["temp_range"][0]:
                    alerts.append(self._make_alert(day, "Cold Stress", "medium", rules["alerts"]["cold"]))
                if temp_max > rules["temp_range"][1]:
                    alerts.append(self._make_alert(day, "Heat Stress", "high", rules["alerts"]["heat"]))
                if humidity < rules["humidity_min"]:
                    alerts.append(self._make_alert(day, "Low Humidity", "medium", rules["alerts"]["humidity"]))
                if rainfall < rules["rainfall_min"]:
                    alerts.append(self._make_alert(day, "Drought Risk", "high", rules["alerts"]["drought"]))

        return alerts

    def generate_soil_weather_alerts(self, soil_data: SoilData, forecast: List[Dict], crop: str) -> List[Dict]:
        alerts = self.generate_weather_alerts(forecast, crop)

        for day in forecast:
            rainfall = day["rainfall"]
            humidity = day["humidity"]

            if soil_data.moisture_level and soil_data.moisture_level > 70 and rainfall > 20:
                alerts.append(self._make_alert(day, "Waterlogging Risk", "high",
                                               "Soil already moist + heavy rain expected → flooding risk. Ensure proper drainage."))

            if soil_data.nitrogen < 50 and rainfall > 30:
                alerts.append(self._make_alert(day, "Nutrient Leaching", "medium",
                                               "Low nitrogen + heavy rain → possible nutrient loss. Apply nitrogen fertilizer after rain."))

            if soil_data.moisture_level and soil_data.moisture_level < 30 and rainfall < 5:
                alerts.append(self._make_alert(day, "Drought Stress", "high",
                                               "Soil moisture low + no rain expected → drought risk. Irrigation recommended."))

            if soil_data.organic_carbon and soil_data.organic_carbon < 0.5 and humidity > 80:
                alerts.append(self._make_alert(day, "Disease Susceptibility", "medium",
                                               "Low organic carbon + high humidity may increase fungal disease risk. Use organic matter."))

        return alerts

    def _make_alert(self, day: Dict, alert_type: str, severity: str, message: str) -> Dict:
        return {
            "date": day["date"],
            "type": alert_type,
            "severity": severity,
            "message": message
        }