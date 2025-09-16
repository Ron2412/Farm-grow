# services/ml_service.py
import os
import joblib
from models.farmer_models import SoilData

class MLService:
    def __init__(self):
        # Path to trained model
        model_path = os.path.join("models", "crop_model.pkl")
        if not os.path.exists(model_path):
            raise FileNotFoundError("❌ Crop model not found. Run train_crop_model.py first.")
        self.crop_model = joblib.load(model_path)

    def _normalize_input(self, soil_data: SoilData):
        """
        Normalize soil data into the 7 features required by the ML model:
        [Nitrogen, Phosphorus, Potassium, Temperature, Humidity, pH, Rainfall]
        If fields are missing, safe defaults are used.
        """
        return [[
            soil_data.nitrogen,
            soil_data.phosphorus,
            soil_data.potassium,
            soil_data.temperature or 25,       # default 25°C
            soil_data.humidity or 60,          # default 60%
            soil_data.ph or soil_data.ph_level or 6.5,  # default pH
            soil_data.rainfall or 100          # default 100 mm
        ]]

    def predict_crop(self, soil_data: SoilData):
        """
        Predict the best crop for given soil conditions.
        """
        try:
            features = self._normalize_input(soil_data)
            prediction = self.crop_model.predict(features)
            return {"recommended_crop": str(prediction[0])}
        except Exception as e:
            raise RuntimeError(f"❌ Crop prediction failed: {str(e)}")