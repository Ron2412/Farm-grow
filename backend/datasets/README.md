# Dataset Documentation

This document provides information about the datasets used in the Sih Agro project for various machine learning models and features.

## Crop Recommendation Dataset

**Filename:** `crop_recommendation.csv`  
**Source:** Kaggle - Crop Recommendation Dataset  
**Description:** This dataset contains soil parameters and environmental conditions mapped to suitable crops.

### Features:
- **Nitrogen (N):** Amount of nitrogen in the soil (kg/ha)
- **Phosphorus (P):** Amount of phosphorus in the soil (kg/ha)
- **Potassium (K):** Amount of potassium in the soil (kg/ha)
- **Temperature:** Temperature in degrees Celsius
- **Humidity:** Relative humidity in percentage
- **pH:** pH value of the soil
- **Rainfall:** Rainfall in mm
- **Label:** Target crop that is suitable for the given conditions

### Usage:
This dataset is used to train the crop recommendation model in `train_crop_model.py` which predicts suitable crops based on soil and environmental parameters.

## Pest Detection Dataset

**Description:** The pest detection feature uses a collection of labeled images of common agricultural pests and plant diseases.

### Categories:
- Aphids
- Whiteflies
- Leaf Spots
- Powdery Mildew
- Rust
- Blight
- Caterpillars
- Beetles
- Mites
- Healthy Plants (control)

### Usage:
These images are used to train the pest detection model that identifies pests and diseases from uploaded plant images.

## Chatbot Training Data

**Description:** The chatbot feature uses structured question-answer pairs and contextual agricultural information.

### Categories:
- Crop Management
- Pest Control
- Fertilizer Application
- Weather Adaptation
- Market Information
- Government Schemes
- Organic Farming
- Irrigation Techniques
- Soil Health

### Usage:
This data is used to train the chatbot model to provide relevant responses to farmer queries.

## Seasonal Crop Recommendations

**Description:** This dataset contains information about crops suitable for different seasons and regions.

### Features:
- Season (Rabi, Kharif, Zaid)
- Region/State
- Suitable Crops
- Expected Rainfall
- Temperature Range

### Usage:
This data is used by the `get_seasonal_recommendations` method in the `SoilService` class to provide seasonal crop recommendations.

## Data Privacy and Usage

All datasets used in this project are either publicly available or synthetic. No personally identifiable information (PII) is included in any dataset. The data is used solely for the purpose of providing agricultural recommendations and assistance to farmers.

## Future Data Improvements

1. Integration with real-time soil testing data
2. Expansion of the pest detection dataset with more regional pests
3. Enhancement of chatbot training data with multilingual support
4. Addition of crop yield prediction datasets