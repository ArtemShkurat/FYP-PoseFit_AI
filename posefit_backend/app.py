from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import bcrypt
import json
import joblib
import numpy as np

app = Flask(__name__)
CORS(app)

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Mysql_For_Artem1",
    database="posefit_ai_db"
)

@app.route('/')
def home():
    return "Backend is working!"

@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()

    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if not username or not email or not password:
        return jsonify({"success": False, "message": "All fields are required."}), 400

    cursor = db.cursor(dictionary=True)

    cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
    existing_user = cursor.fetchone()

    if existing_user:
        return jsonify({"success": False, "message": "Email already exists."}), 409

    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    cursor.execute(
        "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
        (username, email, password_hash)
    )
    db.commit()

    return jsonify({"success": True, "message": "Account created successfully."}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"success": False, "message": "Email and password are required."}), 400

    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cursor.fetchone()

    if not user:
        return jsonify({"success": False, "message": "Invalid email or password."}), 401

    stored_hash = user["password_hash"].encode('utf-8')

    if not bcrypt.checkpw(password.encode('utf-8'), stored_hash):
        return jsonify({"success": False, "message": "Invalid email or password."}), 401

    return jsonify({
        "success": True,
        "message": "Login successful.",
        "user": {
            "id": user["id"],
            "username": user["username"],
            "email": user["email"]
        }
    }), 200

@app.route('/delete-account', methods=['POST'])
def delete_account():
    data = request.get_json()

    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"success": False, "message": "User ID is required."}), 400

    cursor = db.cursor(dictionary=True)

    cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()

    if not user:
        return jsonify({"success": False, "message": "User not found."}), 404

    cursor.execute("DELETE FROM workout_logs WHERE user_id = %s", (user_id,))
    cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
    db.commit()

    return jsonify({
        "success": True,
        "message": "Account deleted successfully."
    }), 200

@app.route('/exercises', methods=['GET'])
def get_exercises():
    try:
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                id,
                name,
                category,
                description,
                instructions,
                tips,
                muscle_group,
                is_camera_supported
            FROM exercises
            ORDER BY name ASC
        """)

        exercises = cursor.fetchall()
        cursor.close()

        return jsonify({
            "success": True,
            "exercises": exercises
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

@app.route('/exercise-samples', methods=['POST'])
def save_exercise_sample():
    try:
        data = request.json

        cursor = db.cursor()

        sql = """
            INSERT INTO exercise_feature_samples (
                exercise_label,
                features
            )
            VALUES (%s, %s)
        """

        values = (
            data.get('exercise_label'),
            json.dumps(data.get('features'))
        )

        cursor.execute(sql, values)
        db.commit()
        cursor.close()

        return jsonify({"success": True}), 201

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500
    
model = joblib.load("exercise_classifier.pkl")

with open("feature_names.txt") as f:
    feature_names = [line.strip() for line in f.readlines()]

@app.route('/predict-exercise', methods=['POST'])
def predict_exercise():
    try:
        data = request.json
        features = data.get("features", {})

        vector = [features.get(name, 0.0) for name in feature_names]

        prediction = model.predict([vector])[0]

        probabilities = model.predict_proba([vector])[0]
        confidence = float(max(probabilities))

        return jsonify({
            "success": True,
            "prediction": prediction,
            "confidence": confidence
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)