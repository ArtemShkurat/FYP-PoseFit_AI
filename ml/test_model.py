import pandas as pd
import joblib

df = pd.read_csv("dataset_clean.csv")
model = joblib.load("exercise_classifier.pkl")

sample = df.drop("label", axis=1).iloc[:10]
preds = model.predict(sample)

print("Predictions:")
print(preds)

print("\nActual labels:")
print(df["label"].iloc[:10].values)