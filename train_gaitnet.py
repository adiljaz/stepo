import os
import urllib.request
import zipfile
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import math
import random

print(f"TensorFlow Version: {tf.__version__}")

# ==========================================
# 1. DOWNLOAD & EXTRACT REAL HUMAN DATA
# ==========================================
url = "https://archive.ics.uci.edu/ml/machine-learning-databases/00240/UCI%20HAR%20Dataset.zip"
zip_path = "uci_har.zip"
extract_path = "uci_har_data"

if not os.path.exists(zip_path):
    print("Downloading UCI HAR real human dataset (~60MB)...")
    urllib.request.urlretrieve(url, zip_path)
    print("Downloaded!")

if not os.path.exists(extract_path):
    print("Extracting...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_path)
    print("Extracted!")

# ==========================================
# 2. LOAD & PROCESS REAL DATA
# ==========================================
print("Loading real human data from UCI HAR...")
base_dir = os.path.join(extract_path, "UCI HAR Dataset", "train", "Inertial Signals")

def load_file(filename):
    with open(os.path.join(base_dir, filename), 'r') as f:
        return np.array([ [float(v) for v in line.split()] for line in f.readlines() ])

total_acc_x = load_file("total_acc_x_train.txt")
total_acc_y = load_file("total_acc_y_train.txt")
total_acc_z = load_file("total_acc_z_train.txt")

body_acc_x = load_file("body_acc_x_train.txt")
body_acc_y = load_file("body_acc_y_train.txt")
body_acc_z = load_file("body_acc_z_train.txt")

body_gyro_x = load_file("body_gyro_x_train.txt")
body_gyro_y = load_file("body_gyro_y_train.txt")
body_gyro_z = load_file("body_gyro_z_train.txt")

with open(os.path.join(extract_path, "UCI HAR Dataset", "train", "y_train.txt"), 'r') as f:
    y_train = np.array([int(line.strip()) for line in f.readlines()])

X = []
Y = []

real_walk_count = 0

for i in range(len(y_train)):
    label = y_train[i]
    if label not in [1, 2, 3]: # 1: WALK, 2: UPSTAIRS, 3: DOWNSTAIRS
        continue
        
    window = np.zeros((75, 9), dtype=np.float32)
    dt = 0.02 # 50Hz
    
    for t in range(75):
        # Convert 'g's to m/s^2
        ax = total_acc_x[i][t] * 9.81
        ay = total_acc_y[i][t] * 9.81
        az = total_acc_z[i][t] * 9.81
        
        bax = body_acc_x[i][t] * 9.81
        bay = body_acc_y[i][t] * 9.81
        baz = body_acc_z[i][t] * 9.81
        
        gx = body_gyro_x[i][t]
        gy = body_gyro_y[i][t]
        gz = body_gyro_z[i][t]
        
        total_mag = math.sqrt(ax**2 + ay**2 + az**2)
        
        # Calculate Vertical Gravity projection
        grav_x = ax - bax
        grav_y = ay - bay
        grav_z = az - baz
        grav_mag = math.sqrt(grav_x**2 + grav_y**2 + grav_z**2) + 1e-6
        vert_gravity = (ax * grav_x + ay * grav_y + az * grav_z) / grav_mag
        
        # Jerk (Derivative of total mag)
        if t == 0:
            jerk = 0.0
        else:
            prev_ax = total_acc_x[i][t-1] * 9.81
            prev_ay = total_acc_y[i][t-1] * 9.81
            prev_az = total_acc_z[i][t-1] * 9.81
            prev_mag = math.sqrt(prev_ax**2 + prev_ay**2 + prev_az**2)
            jerk = abs((total_mag - prev_mag) / dt)
            
        window[t][0] = ax
        window[t][1] = ay
        window[t][2] = az
        window[t][3] = gx
        window[t][4] = gy
        window[t][5] = gz
        window[t][6] = vert_gravity
        window[t][7] = total_mag
        window[t][8] = jerk
        
    X.append(window)
    Y.append(0) # Class 0: Walk
    real_walk_count += 1

print(f"Processed {real_walk_count} real human walking samples.")

# ==========================================
# 3. GENERATE SYNTHETIC DATA (Shake/Run)
# ==========================================
def generate_sample(class_label):
    window = np.zeros((75, 9), dtype=np.float32)
    
    if class_label == 1: # FAKE SHAKE
        freq = random.uniform(3.0, 5.5)
        amp = random.uniform(1.5, 4.0)
    else: # RUN (Class 2)
        freq = random.uniform(2.5, 3.5)
        amp = random.uniform(2.0, 4.0)
        
    dt = 0.02
    for i in range(75):
        t = i * dt
        base_wave = math.sin(2 * math.pi * freq * t)
        if class_label == 1:
            base_wave += random.uniform(-1, 1)
            
        vert = 9.81 + (base_wave * amp * 9.81)
        mag = abs(vert) + random.uniform(0, 0.5)
        
        jerk = (math.cos(2 * math.pi * freq * t) * amp * 9.81) / dt
        if class_label == 1:
            jerk = random.uniform(15.0, 40.0)
            
        window[i][0] = random.uniform(-2, 2)
        window[i][1] = random.uniform(-2, 2)
        window[i][2] = vert
        window[i][3] = random.uniform(-1, 1)
        window[i][4] = random.uniform(-1, 1)
        window[i][5] = random.uniform(-1, 1)
        window[i][6] = vert
        window[i][7] = mag
        window[i][8] = abs(jerk)
    return window

print("Generating synthetic Shake and Run samples to balance dataset...")
for c in [1, 2]:
    for _ in range(real_walk_count): # Balance classes
        X.append(generate_sample(c))
        Y.append(c)

X = np.array(X)
Y = np.array(Y)
print(f"Final Dataset Shape: {X.shape}")

# ==========================================
# 4. TRAIN 1D-CNN MODEL
# ==========================================
model = keras.Sequential([
    keras.Input(shape=(75, 9)),
    layers.Conv1D(filters=32, kernel_size=3, activation='relu'),
    layers.MaxPooling1D(pool_size=2),
    layers.Conv1D(filters=64, kernel_size=3, activation='relu'),
    layers.GlobalAveragePooling1D(),
    layers.Dense(64, activation='relu'),
    layers.Dense(3, activation='softmax')
])

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

print("Training Model...")
model.fit(X, Y, epochs=15, batch_size=32, validation_split=0.2)

# ==========================================
# 5. EXPORT TO TFLITE
# ==========================================
print("Exporting to TFLite format...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('gaitnet_v3.tflite', 'wb') as f:
    f.write(tflite_model)

print("SUCCESS! 'gaitnet_v3.tflite' has been generated with real human data.")
