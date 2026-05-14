"""
train_gait_model.py — Stepooo Gait Classifier Training Script
═══════════════════════════════════════════════════════════════

Trains a 1D-CNN on PAMAP2-format accelerometer data and exports a
fully-integer-quantised TFLite model compatible with tflite_flutter ^0.10.4.

Architecture:
  Input  : [batch, 50, 3]  (50 samples × x,y,z accelerometer in g-force)
  Layer 1: Conv1D(64, 3, relu) + BatchNorm + MaxPool
  Layer 2: Conv1D(128, 3, relu) + BatchNorm + MaxPool
  Layer 3: Conv1D(64, 3, relu) + GlobalAvgPool
  Layer 4: Dense(64, relu) + Dropout(0.3)
  Output : Dense(4, softmax)  [walking, running, cycling, stationary]

Classes:
  0 = walking    (PAMAP2 activities: 3=walking, 4=nordic walking)
  1 = running    (PAMAP2 activity:   12=rope jumping, 13=running)
  2 = cycling    (PAMAP2 activity:   14=cycling)
  3 = stationary (PAMAP2 activity:   1=lying, 2=sitting, 7=standing)

Requirements:
  pip install tensorflow numpy pandas scikit-learn

Usage:
  python scripts/train_gait_model.py \
    --data_dir /path/to/PAMAP2_Dataset/Protocol \
    --output   assets/models/gait_classifier.tflite

PAMAP2 dataset:
  https://archive.ics.uci.edu/dataset/231/pamap2+physical+activity+monitoring
"""

import argparse
import os
import numpy as np
import pandas as pd
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# ─── Configuration ─────────────────────────────────────────────────────────────

WINDOW_SIZE  = 50    # samples per window (1 second @ 50 Hz)
STRIDE       = 25    # 50% overlap
N_AXES       = 3     # x, y, z (wrist accelerometer columns in PAMAP2)
N_CLASSES    = 4     # walking, running, cycling, stationary
EPOCHS       = 40
BATCH_SIZE   = 64
LEARNING_RATE = 1e-3

# PAMAP2 activity IDs → our class labels
ACTIVITY_MAP = {
    1:  'stationary',  # lying
    2:  'stationary',  # sitting
    3:  'walking',     # walking
    4:  'walking',     # nordic walking
    7:  'stationary',  # standing
    12: 'running',     # rope jumping
    13: 'running',     # running
    14: 'cycling',     # cycling
}

# PAMAP2 column layout (100 Hz raw file):
# col 0: timestamp
# col 1: activity ID
# col 2: heart rate
# cols 3-5:   IMU hand      (temp, ax, ay, az, gx, gy, gz, mx, my, mz, orientation x4)
# cols 4-6:   wrist accel   — actual offsets vary by subject file
# We use the wrist accelerometer at cols 4,5,6 (after temp col at 3)
WRIST_ACCEL_COLS = [4, 5, 6]  # x, y, z in m/s²

# ─── Data Loading ───────────────────────────────────────────────────────────────

def load_pamap2(data_dir: str):
    """Load all subject files from PAMAP2 Protocol directory."""
    files = sorted(Path(data_dir).glob("subject*.dat"))
    if not files:
        raise FileNotFoundError(f"No subject*.dat files found in {data_dir}")

    all_windows, all_labels = [], []
    for fpath in files:
        print(f"  Loading {fpath.name}...")
        df = pd.read_csv(fpath, sep=r'\s+', header=None)
        df = df.dropna()

        activity_col = df.iloc[:, 1].astype(int)
        accel        = df.iloc[:, WRIST_ACCEL_COLS].values.astype(np.float32)

        # Convert m/s² → g-force (PAMAP2 stores raw m/s²)
        accel = accel / 9.81

        # Segment into windows
        for start in range(0, len(accel) - WINDOW_SIZE, STRIDE):
            activity_id = int(activity_col.iloc[start + WINDOW_SIZE // 2])
            if activity_id not in ACTIVITY_MAP:
                continue
            window = accel[start:start + WINDOW_SIZE]  # [50, 3]
            if np.any(np.isnan(window)):
                continue
            all_windows.append(window)
            all_labels.append(ACTIVITY_MAP[activity_id])

    X = np.array(all_windows, dtype=np.float32)  # [N, 50, 3]
    y_raw = np.array(all_labels)

    # Encode labels
    le = LabelEncoder()
    le.classes_ = np.array(['walking', 'running', 'cycling', 'stationary'])
    y = le.transform(y_raw)
    y_onehot = keras.utils.to_categorical(y, num_classes=N_CLASSES)

    print(f"  Loaded {len(X)} windows. Class distribution:")
    for cls, lbl in enumerate(le.classes_):
        print(f"    {lbl}: {np.sum(y == cls)}")

    return X, y_onehot, le


# ─── Model Architecture ─────────────────────────────────────────────────────────

def build_model() -> keras.Model:
    """1D-CNN gait classifier optimised for mobile inference."""
    inp = keras.Input(shape=(WINDOW_SIZE, N_AXES), name='accel_window')

    # Block 1
    x = layers.Conv1D(64, 3, padding='same', activation='relu', name='conv1')(inp)
    x = layers.BatchNormalization(name='bn1')(x)
    x = layers.MaxPooling1D(2, name='pool1')(x)

    # Block 2
    x = layers.Conv1D(128, 3, padding='same', activation='relu', name='conv2')(x)
    x = layers.BatchNormalization(name='bn2')(x)
    x = layers.MaxPooling1D(2, name='pool2')(x)

    # Block 3
    x = layers.Conv1D(64, 3, padding='same', activation='relu', name='conv3')(x)
    x = layers.GlobalAveragePooling1D(name='gap')(x)

    # Classifier head
    x = layers.Dense(64, activation='relu', name='fc1')(x)
    x = layers.Dropout(0.3, name='dropout')(x)
    out = layers.Dense(N_CLASSES, activation='softmax', name='output')(x)

    model = keras.Model(inp, out, name='gait_1dcnn')
    model.compile(
        optimizer=keras.optimizers.Adam(LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy'],
    )
    model.summary()
    return model


# ─── TFLite Export ─────────────────────────────────────────────────────────────

def export_tflite(model: keras.Model, X_train: np.ndarray, output_path: str):
    """Convert to full-integer quantised TFLite flatbuffer."""
    print("\nConverting to TFLite (full int8 quantisation)...")

    # Representative dataset for quantisation calibration
    def representative_dataset():
        for i in range(min(500, len(X_train))):
            sample = X_train[i:i+1].astype(np.float32)
            yield [sample]

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type  = tf.float32   # Keep float I/O for tflite_flutter
    converter.inference_output_type = tf.float32

    tflite_model = converter.convert()

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f"  Saved {output_path} ({size_kb:.1f} KB)")
    return tflite_model


# ─── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='Train Stepooo Gait Classifier')
    parser.add_argument('--data_dir', required=True,
                        help='Path to PAMAP2_Dataset/Protocol directory')
    parser.add_argument('--output', default='assets/models/gait_classifier.tflite',
                        help='Output .tflite path')
    parser.add_argument('--epochs', type=int, default=EPOCHS)
    args = parser.parse_args()

    print("═══ Stepooo Gait Classifier Training ═══")
    print(f"Data dir : {args.data_dir}")
    print(f"Output   : {args.output}")
    print(f"Epochs   : {args.epochs}")
    print()

    # 1. Load data
    print("Step 1/4: Loading PAMAP2 dataset...")
    X, y, le = load_pamap2(args.data_dir)

    # 2. Train/validation split
    print("\nStep 2/4: Splitting dataset...")
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y.argmax(axis=1))
    print(f"  Train: {len(X_train)}  Val: {len(X_val)}")

    # 3. Train model
    print("\nStep 3/4: Training 1D-CNN...")
    model = build_model()
    callbacks = [
        keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
        keras.callbacks.ReduceLROnPlateau(factor=0.5, patience=3, min_lr=1e-5),
    ]
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=args.epochs,
        batch_size=BATCH_SIZE,
        callbacks=callbacks,
    )

    # Eval
    val_loss, val_acc = model.evaluate(X_val, y_val, verbose=0)
    print(f"\n  Validation accuracy: {val_acc*100:.2f}%")
    if val_acc < 0.85:
        print("  ⚠️  Accuracy below 85% — consider more training data or epochs")

    # 4. Export
    print("\nStep 4/4: Exporting TFLite model...")
    export_tflite(model, X_train, args.output)
    print("\n✅ Done! Place the .tflite file at: assets/models/gait_classifier.tflite")


if __name__ == '__main__':
    main()
