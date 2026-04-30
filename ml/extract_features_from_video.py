import cv2
import mediapipe as mp
import pandas as pd
import numpy as np

mp_pose = mp.solutions.pose
pose = mp_pose.Pose()

# ---------- ANGLE FUNCTION ----------
def calculate_angle(a, b, c):
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)

    radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - \
              np.arctan2(a[1]-b[1], a[0]-b[0])

    angle = np.abs(radians * 180.0 / np.pi)

    if angle > 180:
        angle = 360 - angle

    return angle


# ---------- FEATURE EXTRACTION ----------
def extract_features(landmarks):
    def get(idx):
        lm = landmarks[idx]
        return [lm.x, lm.y]

    try:
        left_elbow = calculate_angle(get(11), get(13), get(15))
        right_elbow = calculate_angle(get(12), get(14), get(16))

        left_knee = calculate_angle(get(23), get(25), get(27))
        right_knee = calculate_angle(get(24), get(26), get(28))

        left_hip = calculate_angle(get(11), get(23), get(25))
        right_hip = calculate_angle(get(12), get(24), get(26))

        left_shoulder = calculate_angle(get(23), get(11), get(13))
        right_shoulder = calculate_angle(get(24), get(12), get(14))

        return {
            "leftElbowAngle": left_elbow,
            "rightElbowAngle": right_elbow,
            "leftKneeAngle": left_knee,
            "rightKneeAngle": right_knee,
            "leftHipAngle": left_hip,
            "rightHipAngle": right_hip,
            "leftShoulderAngle": left_shoulder,
            "rightShoulderAngle": right_shoulder,
        }

    except:
        return None


# ---------- MAIN ----------
video_path = "biceps_video.mp4"
label = "Biceps Curl"

cap = cv2.VideoCapture(video_path)

data = []

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = pose.process(image)

    if result.pose_landmarks:
        features = extract_features(result.pose_landmarks.landmark)

        if features:
            features["label"] = label
            data.append(features)

cap.release()

df = pd.DataFrame(data)
df.to_csv("dataset_video.csv", index=False)

print("Done. Saved to dataset_video.csv")