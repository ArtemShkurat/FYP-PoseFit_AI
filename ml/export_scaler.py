import json
import joblib

scaler = joblib.load("feature_scaler.pkl")

scaler_data = {
    "mean": scaler.mean_.tolist(),
    "scale": scaler.scale_.tolist()
}

with open("feature_scaler.json", "w") as f:
    json.dump(scaler_data, f)

print("Saved feature_scaler.json")