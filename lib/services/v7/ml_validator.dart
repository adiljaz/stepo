import 'dart:async';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../utils/logger.dart';

/// STAGE 4 — SOURCE C (GaitNet ML Validator).
/// 
/// Runs TFLite inference on [1, 75, 9] biomechanical tensors.
/// Designed for high-frequency asynchronous execution in an Isolate.
class GaitNetMLValidator {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  static const String _modelPath = 'assets/models/gaitnet_v3.tflite';

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isLoaded = true;
      AppLogger.i('GaitNet', 'Model v3 [1, 75, 9] loaded successfully.');
    } catch (e) {
      AppLogger.e('GaitNet', 'Failed to load model: $e');
    }
  }

  /// Predicts the class of a 75-sample biomechanical window.
  /// 
  /// Input tensor shape: [1, 75, 9]
  /// 0: AccX, 1: AccY, 2: AccZ
  /// 3: GyroX, 4: GyroY, 5: GyroZ
  /// 6: VerticalAcc, 7: Magnitude, 8: Jerk
  Future<GaitNetResult> predict(List<List<double>> window) async {
    if (!_isLoaded || _interpreter == null) {
      // --- DETERMINISTIC HAND-SHAKE ANTI-CHEAT ENGINE ---
      // When the TFLite model is missing, we use advanced kinematics to catch cheating.
      // Index 8 is Jerk (change in acceleration over time). 
      // Hand shaking causes violent, high-frequency jerk compared to smooth leg swinging.
      
      double sumJerk = 0.0;
      double maxJerk = 0.0;
      
      for (int i = 0; i < 75; i++) {
        final j = window[i][8].abs();
        sumJerk += j;
        if (j > maxJerk) maxJerk = j;
      }
      
      final avgJerk = sumJerk / 75.0;

      // Thresholds: A normal walking stride rarely exceeds an average jerk of 5.0 or a max of 15.0.
      // Violent wrist shaking easily hits max jerk > 25.0.
      if (maxJerk > 18.0 || avgJerk > 8.0) {
        AppLogger.w('GaitNet', 'ANTI-CHEAT ENGAGED: Violent Hand-Shake Detected! (MaxJerk: ${maxJerk.toStringAsFixed(2)})');
        return GaitNetResult(prediction: 1, confidence: 0.99, isFallback: true); // 1 = FAKE
      }

      // If kinematics look biological and smooth, approve as WALK (0)
      return GaitNetResult(prediction: 0, confidence: 0.85, isFallback: true);
    }

    final input = Float32List(1 * 75 * 9);
    for (int i = 0; i < 75; i++) {
      for (int j = 0; j < 9; j++) {
        input[i * 9 + j] = window[i][j].toDouble();
      }
    }

    final output = Float32List(1 * 3).reshape([1, 3]);
    _interpreter!.run(input.buffer.asFloat32List(), output);

    final scores = output[0] as List<double>;
    int bestClass = 0;
    double maxConf = 0.0;
    
    for (int i = 0; i < 3; i++) {
      if (scores[i] > maxConf) {
        maxConf = scores[i];
        bestClass = i;
      }
    }

    return GaitNetResult(
      prediction: bestClass,
      confidence: maxConf,
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}

class GaitNetResult {
  final int prediction; // 0=WALK, 1=FAKE, 2=RUN
  final double confidence;
  final bool isFallback;

  GaitNetResult({
    required this.prediction,
    required this.confidence,
    this.isFallback = false,
  });

  bool get isFake => prediction == 1;
  bool get isRunning => prediction == 2;
  bool get isWalking => prediction == 0;
}
