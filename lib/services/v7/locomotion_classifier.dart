import '../../models/locomotion_state.dart';
import '../../utils/logger.dart';

/// STAGE 8 — ADVANCED MULTI-SIGNAL LOCOMOTION CLASSIFIER.
/// 
/// Fuses GPS, Kinematics, and Spectral signals to detect vehicle transit.
class LocomotionClassifier {
  // Buffers for transition debounce
  final List<LocomotionState> _buffer = [];
  static const int kBufferSize = 6; // 3 seconds at 0.5s evaluation

  LocomotionState _currentState = const StationaryState();
  DateTime _lastTransitionTime = DateTime.now();

  /// Core classification engine.
  LocomotionState classify({
    required double gpsSpeedKmh,
    required double gpsAccuracy,
    required double maxJerk,
    required double avgMag,
    required double spectralPowerGaitBand, // 1.5-2.5Hz power
    required double gyroVariance,
    required double altitudeDelta,
  }) {
    // ── SIGNAL A: GPS VELOCITY (Weight: 0.4) ─────────────────────────────────
    double gpsScore = 0.0;
    if (gpsSpeedKmh > 7.0 && gpsAccuracy < 20.0) {
      gpsScore = (gpsSpeedKmh / 30.0).clamp(0.0, 1.0); 
    }

    // ── SIGNAL B: SPECTRAL PURITY (Weight: 0.3) ──────────────────────────────
    // High power in gait band suggests biological walking/running.
    double gaitPowerScore = spectralPowerGaitBand.clamp(0.0, 1.0);

    // ── SIGNAL C: KINEMATIC IMPACT (Weight: 0.2) ─────────────────────────────
    // Vehicle floor is smooth (< 3 m/s³). Footstrikes are sharp (> 5 m/s³).
    bool isImpactLow = maxJerk < 3.0;
    bool isImpactHigh = maxJerk > 5.0;

    // ── SIGNAL D: HEADING STABILITY (Weight: 0.1) ───────────────────────────
    // Rail and Highway driving have ultra-low angular variance.
    bool isHeadingStable = gyroVariance < 5.0;

    // ── FUSION LOGIC ─────────────────────────────────────────────────────────
    double vehicleConfidence = 0.0;
    if (gpsScore > 0.2) vehicleConfidence += 0.4;
    if (gaitPowerScore < 0.2) vehicleConfidence += 0.3;
    if (isImpactLow) vehicleConfidence += 0.2;
    if (isHeadingStable) vehicleConfidence += 0.1;

    LocomotionState candidate;

    if (vehicleConfidence > 0.75) {
      final vType = _subClassifyVehicle(gpsSpeedKmh, gyroVariance);
      candidate = InVehicleState(vType, confidence: vehicleConfidence);
    } else if (vehicleConfidence < 0.3 && isImpactHigh) {
      candidate = avgMag > 1.6 ? const RunningState() : const WalkingState();
    } else if (gpsSpeedKmh < 1.0 && maxJerk < 1.0) {
      candidate = const StationaryState();
    } else {
      candidate = const AmbiguousState('MID_TRANSIT');
    }

    return _debounce(candidate);
  }

  /// Vehicle type profiling based on motion dynamics.
  VehicleType _subClassifyVehicle(double speed, double gyroVar) {
    if (speed > 10.0 && speed < 30.0 && gyroVar > 10.0) return VehicleType.cycling;
    if (speed > 60.0 && gyroVar < 1.0) return VehicleType.rail;
    if (speed > 10.0 && speed < 50.0 && gyroVar > 5.0) return VehicleType.bus;
    return VehicleType.car;
  }

  /// 3-second transition debounce implementation.
  LocomotionState _debounce(LocomotionState candidate) {
    _buffer.add(candidate);
    if (_buffer.length > kBufferSize) _buffer.removeAt(0);

    // Check for consensus in buffer
    if (_buffer.every((s) => s.runtimeType == candidate.runtimeType)) {
      if (candidate.runtimeType != _currentState.runtimeType) {
        _currentState = candidate;
        _lastTransitionTime = DateTime.now();
        AppLogger.i('Locomotion', 'STATE_TRANSITION: ${_currentState.runtimeType}');
      }
    }

    // Dismount Logic: Require GPS < 3km/h and 5s grace period
    if (_currentState is InVehicleState && candidate is WalkingState) {
      final elapsed = DateTime.now().difference(_lastTransitionTime).inSeconds;
      if (elapsed < 5) return _currentState;
    }

    return _currentState;
  }
}
