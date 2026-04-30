import pandas as pd

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import joblib

# Load prepared dataset
df = pd.read_csv("dataset_clean.csv")

print("Dataset shape:", df.shape)
print("\nSamples per class:")
print(df["label"].value_counts())

# Split features and target
X = df.drop("label", axis=1)
Y = df["label"]

# Replace missing values if any
X = X.fillna(X.median(numeric_only=True))

# Train/test split
X_train, X_test, Y_train, Y_test = train_test_split(
    X,
    Y,
    test_size=0.2,
    random_state=42,
    stratify=Y
)

# Create model
model = RandomForestClassifier(
    n_estimators=200,
    random_state=42
)

# Train model
model.fit(X_train, Y_train)

feature_names = list(X.columns)
with open("feature_names.txt", "w") as f:
    for name in feature_names:
        f.write(name + "\n")

# Test model
Y_pred = model.predict(X_test)

print("\nAccuracy:", accuracy_score(Y_test, Y_pred))

print("\nClassification Report:")
print(classification_report(Y_test, Y_pred))

print("\nConfusion Matrix:")
print(confusion_matrix(Y_test, Y_pred))

# Save model
joblib.dump(model, "exercise_classifier.pkl")

print("\nModel saved as exercise_classifier.pkl")