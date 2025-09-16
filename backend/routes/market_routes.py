from fastapi import APIRouter, HTTPException, Depends, Query
from services.market_service import MarketService

router = APIRouter(prefix="/market", tags=["Market Prices"])
market_service = MarketService()

async def verify_user():
    return "user_123"

# 📌 Get price for a specific crop
@router.get("/price")
async def price_for_crop(
    crop: str = Query(..., description="Crop name (e.g., wheat, rice)"),
    user_id: str = Depends(verify_user),
):
    result = await market_service.get_crop_prices(crop)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result

# 📌 Get prices for all crops
@router.get("/all")
async def all_prices(user_id: str = Depends(verify_user)):
    return await market_service.get_all_prices()