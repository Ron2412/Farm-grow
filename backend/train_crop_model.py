# train_crop_model.py
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import joblib
import os

# 1. Load dataset
data_path = os.path.join("datasets", "crop_recommendation.csv")
data = pd.read_csv(data_path)

# 2. Features (inputs) and target (output)
X = data.drop("label", axis=1)   # All columns except crop name
y = data["label"]                # Crop name (target)

# 3. Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# 4. Train model (Random Forest works great here)
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# 5. Evaluate accuracy
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
print(f"✅ Model trained with accuracy: {accuracy:.2f}")

# 6. Save model into models/ folder
os.makedirs("models", exist_ok=True)
joblib.dump(model, os.path.join("models", "crop_model.pkl"))
print("📂 Model saved at models/crop_model.pkl")