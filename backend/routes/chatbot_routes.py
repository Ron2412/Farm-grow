# routes/chatbot_routes.py
from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, List, Any, Optional
import logging
import random
from models.farmer_models import ChatbotQuery, ChatbotResponse

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])
logger = logging.getLogger(__name__)

# Mock responses for different query categories
MOCK_RESPONSES = {
    "weather": [
        "Based on the current forecast, expect clear skies with temperatures around 25°C. This is good weather for field work.",
        "The weather forecast shows a chance of rain in the next 48 hours. Consider completing any harvesting activities today.",
        "Temperatures are expected to rise to 32°C this week. Ensure your crops have adequate irrigation."
    ],
    "crop": [
        "For your soil type and current season, I recommend planting wheat, rice, or maize. Would you like specific details about any of these crops?",
        "Based on your region, rice cultivation would be optimal now. The ideal sowing time is approaching.",
        "Your soil appears suitable for multiple crops. Consider crop rotation with legumes to improve soil nitrogen content."
    ],
    "pest": [
        "To identify pests or diseases, please use the image detector feature. You can upload a photo of the affected plant for analysis.",
        "Common pests this season include aphids and whiteflies. Monitor your crops regularly and consider preventive measures.",
        "For organic pest control, neem oil solution (15ml per liter of water) is effective against many common pests."
    ],
    "market": [
        "Current market prices: Wheat - ₹2100/quintal, Rice - ₹3200/quintal. Prices have increased by 2.5% this week.",
        "The market trend for your crops is positive. Consider holding your harvest for another 2 weeks if storage is available.",
        "Local mandis are offering better prices than wholesale markets this week. Compare rates before selling."
    ],
    "fertilizer": [
        "For wheat at the vegetative stage, apply urea at 50kg/acre. Water the field immediately after application.",
        "Organic alternatives to chemical fertilizers include compost, vermicompost, and green manure. These improve soil health over time.",
        "Your crop may benefit from micronutrient supplementation. Look for signs of yellowing or stunted growth."
    ],
    "general": [
        "I'm here to help with any farming questions. Feel free to ask about crops, weather, pests, or market prices.",
        "For more detailed assistance, try providing specific information about your farm location, crop type, and current growth stage.",
        "Consider joining the local farmer producer organization for collective bargaining and knowledge sharing."
    ]
}

# Follow-up questions based on category
FOLLOW_UP_QUESTIONS = {
    "weather": [
        "Would you like to see the 7-day forecast?",
        "Do you need crop-specific weather advice?",
        "Should I set up weather alerts for your region?"
    ],
    "crop": [
        "Would you like detailed cultivation practices for a specific crop?",
        "Do you need information about seed varieties?",
        "Are you interested in intercropping options?"
    ],
    "pest": [
        "Would you like to know about preventive measures?",
        "Do you need organic alternatives for pest control?",
        "Should I provide information about beneficial insects?"
    ],
    "market": [
        "Would you like price forecasts for the next month?",
        "Do you need information about storage facilities?",
        "Are you interested in direct marketing channels?"
    ],
    "fertilizer": [
        "Would you like a customized fertilizer schedule?",
        "Do you need information about soil testing services?",
        "Are you interested in organic farming practices?"
    ],
    "general": [
        "Would you like information about government schemes for farmers?",
        "Do you need assistance with any specific farming challenge?",
        "Are you interested in learning about sustainable farming practices?"
    ]
}

@router.post("/query", response_model=ChatbotResponse)
async def process_query(query: ChatbotQuery):
    """
    Process a user query and return an appropriate response.
    This endpoint handles natural language queries related to farming.
    """
    try:
        # Lowercase message for keyword matching
        message = query.message.lower()
        
        # Determine category based on keywords
        category = "general"  # default
        if any(word in message for word in ["weather", "rain", "temperature", "forecast", "climate"]):
            category = "weather"
        elif any(word in message for word in ["crop", "plant", "sow", "grow", "seed", "harvest"]):
            category = "crop"
        elif any(word in message for word in ["pest", "disease", "insect", "bug", "infection"]):
            category = "pest"
        elif any(word in message for word in ["market", "price", "sell", "buy", "mandi", "cost"]):
            category = "market"
        elif any(word in message for word in ["fertilizer", "nutrient", "manure", "compost", "urea"]):
            category = "fertilizer"
        
        # Get a random response from the appropriate category
        response = random.choice(MOCK_RESPONSES[category])
        
        # Get follow-up questions
        follow_ups = random.sample(FOLLOW_UP_QUESTIONS[category], 2)
        
        # Generate suggestions based on category
        suggestions = []
        if category == "weather":
            suggestions = ["Show me weather forecast", "Weather alerts for my crops"]
        elif category == "crop":
            suggestions = ["Best crops for this season", "How to increase yield"]
        elif category == "pest":
            suggestions = ["Identify pest in my crop", "Organic pest control methods"]
        elif category == "market":
            suggestions = ["Current market prices", "When to sell my harvest"]
        elif category == "fertilizer":
            suggestions = ["Fertilizer schedule for wheat", "Organic alternatives"]
        else:
            suggestions = ["Crop recommendations", "Weather forecast", "Pest control advice"]
        
        return ChatbotResponse(
            response=response,
            confidence=round(random.uniform(0.75, 0.98), 2),
            suggestions=suggestions,
            follow_up_questions=follow_ups
        )
        
    except Exception as e:
        logger.error(f"Error processing chatbot query: {e}")
        raise HTTPException(status_code=500, detail=f"Query processing failed: {str(e)}")


@router.get("/suggestions")
async def get_suggestions(context: Optional[str] = None):
    """Get contextual suggestions for the chatbot"""
    
    general_suggestions = [
        "What crops should I plant this season?",
        "How's the weather forecast for this week?",
        "What are the current market prices for wheat?",
        "How do I identify and treat common crop diseases?",
        "What fertilizers are best for my soil type?"
    ]
    
    context_suggestions = {
        "weather": [
            "Will it rain tomorrow?",
            "What's the temperature forecast for this week?",
            "Should I irrigate my fields today?",
            "Is there any weather alert for my region?"
        ],
        "crop": [
            "Which variety of wheat is best for my region?",
            "When should I harvest my rice crop?",
            "How much seed do I need per acre?",
            "What's the ideal spacing for maize plants?"
        ],
        "pest": [
            "How do I control aphids on my wheat?",
            "What are the signs of stem borer infestation?",
            "Are there organic solutions for whitefly?",
            "How to prevent common diseases in rice?"
        ]
    }
    
    if context and context in context_suggestions:
        return {"suggestions": context_suggestions[context]}
    
    return {"suggestions": general_suggestions}