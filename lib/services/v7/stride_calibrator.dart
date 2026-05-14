import '../../utils/logger.dart';

class StrideCalibrator {
  int _stepStart = 0;
  double _distanceStartMeters = 0.0;
  bool _isCalibrating = false;

  /// Starts a calibration phase, recording the baseline steps and GPS distance
  void startCalibration(int currentSteps, double currentDistanceMeters) {
    _stepStart = currentSteps;
    _distanceStartMeters = currentDistanceMeters;
    _isCalibrating = true;
    AppLogger.i('StrideCalibrator', 'Calibration phase started.');
  }

  /// Ends the calibration phase and returns the highly accurate, personalized stride length in meters.
  /// Returns null if not enough distance was covered to be statistically significant.
  double? endCalibration(int currentSteps, double currentDistanceMeters) {
    if (!_isCalibrating) return null;
    _isCalibrating = false;

    final stepsTaken = currentSteps - _stepStart;
    final distanceTraveled = currentDistanceMeters - _distanceStartMeters;

    // Require at least 100 steps or 50 meters of continuous outdoor walking to prevent noisy GPS data
    if (stepsTaken > 100 && distanceTraveled > 50.0) {
      final customStride = distanceTraveled / stepsTaken;
      AppLogger.i('StrideCalibrator', 'Calibration complete! New biological stride length: ${customStride.toStringAsFixed(3)} meters');
      return customStride;
    }
    
    AppLogger.w('StrideCalibrator', 'Calibration aborted: Not enough distance traveled for statistical significance.');
    return null;
  }
}
