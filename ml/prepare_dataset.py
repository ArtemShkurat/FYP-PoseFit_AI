import pandas as pd
import json

df = pd.read_csv("dataset_raw.csv")

rows = []

for _, row in df.iterrows():
    features = json.loads(row["features"])
    features["label"] = row["exercise_label"]
    rows.append(features)

clean_df = pd.DataFrame(rows)

clean_df.to_csv("dataset_clean.csv", index=False)

print("Dataset prepared:", clean_df.shape)