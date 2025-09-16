import firebase_admin
from firebase_admin import credentials, firestore, auth, storage
import os
import json
from typing import Optional

def init_firebase():
    """Initialize Firebase Admin SDK"""
    if not firebase_admin._apps:
        try:
            # Try to load credentials from environment variable
            cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
            
            if cred_path and os.path.exists(cred_path):
                # Load from file path
                cred = credentials.Certificate(cred_path)
            else:
                # Try to load from environment variable as JSON string
                cred_json = os.getenv('FIREBASE_CREDENTIALS_JSON')
                if cred_json:
                    cred_dict = json.loads(cred_json)
                    cred = credentials.Certificate(cred_dict)
                else:
                    # For development, try to load from default location
                    cred = credentials.Certificate('./firebase-credentials.json')
            
            firebase_admin.initialize_app(cred, {
                'storageBucket': os.getenv('FIREBASE_STORAGE_BUCKET', 'your-project.appspot.com')
            })
            print("Firebase initialized successfully")
            
        except Exception as e:
            print(f"Error initializing Firebase: {e}")
            raise e

def get_firestore_client():
    """Get Firestore client"""
    return firestore.client()

def get_storage_bucket():
    """Get Firebase Storage bucket"""
    return storage.bucket()

def verify_firebase_token(token: str) -> Optional[dict]:
    """Verify Firebase ID token and return decoded token"""
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        print(f"Token verification failed: {e}")
        return None

# Database collection names
COLLECTIONS = {
    'farmers': 'farmers',
    'chat_interactions': 'chat_interactions',
    'soil_recommendations': 'soil_recommendations',
    'fertilizer_guidance': 'fertilizer_guidance',
    'pest_detections': 'pest_detections',
    'weather_alerts': 'weather_alerts',
    'market_prices': 'market_prices',
    'feedback': 'feedback',
    'notifications': 'notifications',
    'analytics': 'analytics',
    'usage_logs': 'usage_logs'
}

# Firebase Storage folders
STORAGE_FOLDERS = {
    'pest_images': 'pest_detection_images/',
    'audio_files': 'voice_interactions/',
    'profile_images': 'profile_pictures/',
    'crop_images': 'crop_photos/'
}