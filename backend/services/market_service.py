import logging
from typing import Dict

logger = logging.getLogger(__name__)

class MarketService:
    def __init__(self):
        # 📊 Mock market data (Ludhiana only for now)
        self.mock_data = {
            "wheat": {"mandi": "Ludhiana", "min_price": 1800, "max_price": 2200},
            "rice": {"mandi": "Ludhiana", "min_price": 2500, "max_price": 3100},
            "maize": {"mandi": "Ludhiana", "min_price": 1600, "max_price": 2000},
            "cotton": {"mandi": "Ludhiana", "min_price": 5200, "max_price": 6200},
        }

    async def get_crop_prices(self, crop_name: str) -> Dict:
        crop = crop_name.lower()

        if crop in self.mock_data:
            pd = self.mock_data[crop]
            avg_price = (pd["min_price"] + pd["max_price"]) // 2

            return {
                "crop": crop,
                "mandi": pd["mandi"],
                "min_price": pd["min_price"],
                "max_price": pd["max_price"],
                "current_price": avg_price,
                "source": "mock (Ludhiana)"
            }

        return {"error": f"No market data for crop: {crop}"}

    async def get_all_prices(self) -> Dict[str, Dict]:
        result = {}
        for crop in self.mock_data.keys():
            result[crop] = await self.get_crop_prices(crop)
        return result