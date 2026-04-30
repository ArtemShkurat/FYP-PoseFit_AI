import json
import numpy as np
import pandas as pd
import tensorflow as tf

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, accuracy_score
import joblib

# Load dataset
df = pd.read_csv("dataset_clean.csv")

X = df.drop("label", axis=1)
Y = df["label"]

# Handle missing values
X = X.fillna(X.median(numeric_only=True))

# Save feature names in correct order
feature_names = list(X.columns)
with open("feature_names.json", "w") as f:
    json.dump(feature_names, f)

# Encode labels
label_encoder = LabelEncoder()
Y_encoded = label_encoder.fit_transform(Y)

with open("labels.json", "w") as f:
    json.dump(label_encoder.classes_.tolist(), f)

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

scaler_data = {
    "mean": scaler.mean_.tolist(),
    "scale": scaler.scale_.tolist()
}

with open("feature_scaler.json", "w") as f:
    json.dump(scaler_data, f)

joblib.dump(scaler, "feature_scaler.pkl")

X_train, X_test, Y_train, Y_test = train_test_split(
    X_scaled,
    Y_encoded,
    test_size=0.2,
    random_state=42,
    stratify=Y_encoded
)

# Small neural network
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(X_train.shape[1],)),
    tf.keras.layers.Dense(32, activation="relu"),
    tf.keras.layers.Dense(16, activation="relu"),
    tf.keras.layers.Dense(len(label_encoder.classes_), activation="softmax"),
])

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

model.fit(
    X_train,
    Y_train,
    epochs=50,
    batch_size=32,
    validation_split=0.2,
    verbose=1
)

Y_pred_probs = model.predict(X_test)
Y_pred = np.argmax(Y_pred_probs, axis=1)

print("Accuracy:", accuracy_score(Y_test, Y_pred))
print(classification_report(Y_test, Y_pred, target_names=label_encoder.classes_))

# Save Keras model
model.save("exercise_classifier_keras.keras")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open("exercise_classifier.tflite", "wb") as f:
    f.write(tflite_model)

print("Saved exercise_classifier.tflite")
print("Saved labels.json")
print("Saved feature_names.json")
print("Saved feature_scaler.json")