from flask import Flask, request, jsonify
from flask_cors import CORS
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

import mysql.connector
import bcrypt
import json
import joblib
import numpy as np
import smtplib
import re
import random
import string
import smtplib

app = Flask(__name__)
CORS(app)

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Mysql_For_Artem1",
    database="posefit_ai_db"
)

def get_db_cursor(dictionary=False):
    global db

    if not db.is_connected():
        db.reconnect(attempts=3, delay=2)

    db.ping(reconnect=True, attempts=3, delay=2)

    return db.cursor(dictionary=dictionary)


@app.route('/')
def home():
    return "Backend is working!"


@app.route('/signup', methods=['POST'])
def signup():
    cursor = None

    try:
        data = request.get_json()

        username = data.get('username')
        email = data.get('email')
        password = data.get('password')

        if not username or not email or not password:
            return jsonify({
                "success": False,
                "message": "All fields are required."
            }), 400

        if len(password) < 8:
            return jsonify({
                "success": False,
                "message": "Password must be at least 8 characters long."
            }), 400

        if not re.search(r'[A-Z]', password):
            return jsonify({
                "success": False,
                "message": "Password must contain at least 1 capital letter."
            }), 400

        if not re.search(r'[0-9]', password):
            return jsonify({
                "success": False,
                "message": "Password must contain at least 1 number."
            }), 400

        if not re.search(r'[^A-Za-z0-9]', password):
            return jsonify({
                "success": False,
                "message": "Password must contain at least 1 symbol."
            }), 400

        cursor = get_db_cursor(dictionary=True)

        cursor.execute(
            "SELECT id FROM users WHERE email = %s",
            (email,)
        )
        existing_user = cursor.fetchone()

        if existing_user:
            return jsonify({
                "success": False,
                "message": "Email already exists."
            }), 409

        password_hash = bcrypt.hashpw(
            password.encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')

        cursor.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
            (username, email, password_hash)
        )

        db.commit()

        return jsonify({
            "success": True,
            "message": "Account created successfully."
        }), 201

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        if cursor:
            cursor.close()


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"success": False, "message": "Email and password are required."}), 400

    cursor = get_db_cursor(dictionary=True)
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
            "email": user["email"],
            "must_change_password": user["must_change_password"]
        }
    }), 200


@app.route('/delete-account', methods=['POST'])
def delete_account():
    data = request.get_json()

    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"success": False, "message": "User ID is required."}), 400

    cursor = get_db_cursor(dictionary=True)

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
        cursor = get_db_cursor(dictionary=True)

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

        cursor = get_db_cursor()

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
    

@app.route('/workout-logs', methods=['GET'])
def get_workout_logs():
    try:
        user_id = request.args.get('user_id')

        if not user_id:
            return jsonify({
                "success": False,
                "message": "Missing user_id"
            }), 400

        cursor = get_db_cursor(dictionary=True)

        cursor.execute("""
            SELECT
                id,
                user_id,
                exercise_name,
                sets_count,
                reps_count,
                weight,
                weight_unit,
                is_pr,
                log_date
            FROM workout_logs
            WHERE user_id = %s
            ORDER BY log_date DESC, id DESC
        """, (user_id,))

        logs = cursor.fetchall()
        cursor.close()

        formatted_logs = []

        for row in logs:
            if row["log_date"] is not None:
                row["log_date"] = row["log_date"].strftime("%Y-%m-%d")

            row["weight"] = float(row["weight"])
            formatted_logs.append(row)

        return jsonify({
            "success": True,
            "logs": formatted_logs
        }), 200

    except Exception as e:
        print("GET /workout-logs error:", e)
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500


@app.route('/workout-logs', methods=['POST'])
def add_workout_log():
    try:
        data = request.json

        cursor = get_db_cursor()

        sql = """
            INSERT INTO workout_logs (
                user_id,
                exercise_name,
                sets_count,
                reps_count,
                weight,
                weight_unit,
                is_pr,
                log_date
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """

        values = (
            data.get('user_id', 1),
            data.get('exercise_name'),
            data.get('sets_count'),
            data.get('reps_count'),
            data.get('weight'),
            data.get('weight_unit', 'kg'),
            data.get('is_pr', False),
            data.get('log_date'),
        )

        cursor.execute(sql, values)
        db.commit()
        cursor.close()

        return jsonify({
            "success": True,
            "message": "Workout log added"
        }), 201

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500
    

@app.route('/workout-logs/<int:log_id>', methods=['PUT'])
def update_workout_log(log_id):
    try:
        data = request.json
        cursor = get_db_cursor()

        sql = """
            UPDATE workout_logs
            SET exercise_name = %s,
                sets_count = %s,
                reps_count = %s,
                weight = %s,
                weight_unit = %s,
                is_pr = %s,
                log_date = %s
            WHERE id = %s AND user_id = %s
        """

        values = (
            data.get('exercise_name'),
            data.get('sets_count'),
            data.get('reps_count'),
            data.get('weight'),
            data.get('weight_unit', 'kg'),
            data.get('is_pr', False),
            data.get('log_date'),
            log_id,
            data.get('user_id'),
        )

        cursor.execute(sql, values)
        db.commit()
        cursor.close()

        return jsonify({"success": True, "message": "Workout log updated"}), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@app.route('/workout-logs/<int:log_id>', methods=['DELETE'])
def delete_workout_log(log_id):
    try:
        user_id = request.args.get('user_id')

        cursor = get_db_cursor()
        cursor.execute(
            "DELETE FROM workout_logs WHERE id = %s AND user_id = %s",
            (log_id, user_id)
        )
        db.commit()
        cursor.close()

        return jsonify({"success": True, "message": "Workout log deleted"}), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    

@app.route('/update-username', methods=['POST'])
def update_username():
    cursor = None

    try:
        data = request.get_json()

        user_id = data.get('user_id')
        username = data.get('username')

        if not user_id or not username:
            return jsonify({
                "success": False,
                "message": "User ID and username are required."
            }), 400

        cursor = get_db_cursor(dictionary=True)

        cursor.execute(
            "UPDATE users SET username = %s WHERE id = %s",
            (username, user_id)
        )

        db.commit()

        return jsonify({
            "success": True,
            "message": "Username updated successfully.",
            "username": username
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        if cursor:
            cursor.close()


@app.route('/change-password', methods=['POST'])
def change_password():
    cursor = None

    try:
        data = request.get_json()

        user_id = data.get('user_id')
        current_password = data.get('current_password')
        new_password = data.get('new_password')

        if not user_id or not current_password or not new_password:
            return jsonify({
                "success": False,
                "message": "All fields are required."
            }), 400

        cursor = get_db_cursor(dictionary=True)

        cursor.execute(
            "SELECT password_hash FROM users WHERE id = %s",
            (user_id,)
        )

        user = cursor.fetchone()

        if not user:
            return jsonify({
                "success": False,
                "message": "User not found."
            }), 404

        stored_hash = user["password_hash"].encode('utf-8')

        if not bcrypt.checkpw(
            current_password.encode('utf-8'),
            stored_hash
        ):
            return jsonify({
                "success": False,
                "message": "Current password is incorrect."
            }), 401

        new_hash = bcrypt.hashpw(
            new_password.encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')

        cursor.execute(
            "UPDATE users SET password_hash = %s, must_change_password = FALSE WHERE id = %s",
            (new_hash, user_id)
        )

        db.commit()

        return jsonify({
            "success": True,
            "message": "Password changed successfully."
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        if cursor:
            cursor.close()


@app.route('/support-message', methods=['POST'])
def send_support_message():
    try:
        data = request.get_json()

        user_email = data.get('user_email')
        username = data.get('username')
        support_subject = data.get('subject')
        message = data.get('message')

        if not support_subject or not message:
            return jsonify({
                "success": False,
                "message": "Subject and message are required."
            }), 400

        sender_email = "posefit.ai@gmail.com"
        app_password = "..."

        receiver_email = "posefit.ai@gmail.com"

        subject = f"[PoseFit AI Support] {support_subject}"

        body = f"""
PoseFit AI Support Request

Username: {username}
User Email: {user_email}

Subject:
{support_subject}

Message:
{message}
"""

        msg = MIMEMultipart()
        msg["From"] = sender_email
        msg["To"] = receiver_email
        msg["Subject"] = subject

        msg.attach(MIMEText(body, "plain"))

        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()

        server.login(sender_email, app_password)

        server.sendmail(
            sender_email,
            receiver_email,
            msg.as_string()
        )

        server.quit()

        return jsonify({
            "success": True,
            "message": "Message sent successfully."
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500


@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    cursor = None

    try:
        data = request.get_json()

        email = data.get('email')

        if not email:
            return jsonify({
                "success": False,
                "message": "Email is required."
            }), 400

        cursor = get_db_cursor(dictionary=True)

        cursor.execute(
            "SELECT * FROM users WHERE email = %s",
            (email,)
        )

        user = cursor.fetchone()

        if not user:
            return jsonify({
                "success": False,
                "message": "No account found with this email."
            }), 404

        characters = (
            string.ascii_letters +
            string.digits +
            "!@#$%^&*"
        )

        temporary_password = ''.join(
            random.choice(characters)
            for _ in range(10)
        )

        password_hash = bcrypt.hashpw(
            temporary_password.encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')

        cursor.execute(
            """
            UPDATE users
            SET password_hash = %s,
                must_change_password = TRUE
            WHERE email = %s
            """,
            (password_hash, email)
        )

        db.commit()

        sender_email = "posefit.ai@gmail.com"
        app_password = "..."

        receiver_email = email

        subject = "PoseFit AI Password Reset"

        body = f"""
Hello {user['username']},

Your temporary password is:

{temporary_password}

Please log in using this password and change it immediately.

PoseFit AI Support
"""

        msg = MIMEMultipart()

        msg['From'] = sender_email
        msg['To'] = receiver_email
        msg['Subject'] = subject

        msg.attach(
            MIMEText(body, 'plain')
        )

        server = smtplib.SMTP(
            'smtp.gmail.com',
            587
        )

        server.starttls()

        server.login(
            sender_email,
            app_password
        )

        server.sendmail(
            sender_email,
            receiver_email,
            msg.as_string()
        )

        server.quit()

        return jsonify({
            "success": True,
            "message":
                "Temporary password sent to your email."
        }), 200

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)