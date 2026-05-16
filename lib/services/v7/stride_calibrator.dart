import '../../utils/logger.dart';

class StrideCalibrator {
  double _baseStride = 0.762; // Default (Average human stride)
  
  /// Calculates dynamic stride length based on current cadence (Steps Per Minute).
  /// Human biology: faster cadence = longer stride.
  double calculateDynamicStride(int spm) {
    if (spm < 40) return _baseStride * 0.75; // Shuffling / Stationary
    if (spm > 180) return _baseStride * 1.45; // Sprinting
    
    // Logarithmic-linear scaling:
    // At 100 SPM (Normal Walk) -> 1.0x Base
    // At 150 SPM (Jogging)     -> 1.25x Base
    // At 180 SPM (Running)     -> 1.45x Base
    final scale = 1.0 + (spm - 100) * 0.0055;
    return (_baseStride * scale).clamp(_baseStride * 0.7, _baseStride * 1.6);
  }

  /// Real-time GPS-assisted calibration.
  /// Call this when GPS accuracy is high to refine the user's base stride.
  void calibrateFromGps(int stepsDelta, double distanceDeltaMeters) {
    if (stepsDelta > 50 && distanceDeltaMeters > 30) {
      final calculatedBase = distanceDeltaMeters / stepsDelta;
      // Use alpha-filter to prevent sudden jumps
      _baseStride = (_baseStride * 0.9) + (calculatedBase * 0.1);
      AppLogger.i('StrideCalibrator', 'GPS_CALIBRATION: Base Stride refined to ${_baseStride.toStringAsFixed(3)}m');
    }
  }

  double get baseStride => _baseStride;
}
