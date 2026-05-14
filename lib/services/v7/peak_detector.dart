import 'dart:math' as math;
import '../../constants/step_constants.dart';
import '../../utils/logger.dart';

/// STAGE 3 — DETECT (Biomechanical Peak Detector).
/// 
/// Implements Pan-Tompkins adaptive peak detection with strict 
/// biomechanical gating (Jerk, Shape, ISI Symmetry).
class BiomechanicalPeakDetector {
  final List<double> _signalBuffer = [];
  final List<double> _isiBuffer = [];
  
  DateTime? _lastStepTime;
  double _lastMag = 1.0;
  
  // Peak shape tracking
  bool _isRising = false;
  DateTime? _peakStartTime;
  DateTime? _peakMaxTime;
  double _peakMaxVal = 0.0;

  /// Returns true if the sample identifies a validated peak candidate.
  bool process(double mag, double vertical, double dt) {
    final now = DateTime.now();
    
    // 1. Maintain 3s signal buffer (at 50Hz = 150 samples)
    _signalBuffer.add(mag);
    if (_signalBuffer.length > 150) _signalBuffer.removeAt(0);
    
    if (_signalBuffer.length < 50) return false;

    // 2. Pan-Tompkins Adaptive Threshold
    final stats = _calculateStats(_signalBuffer);
    final threshold = stats['mean']! + AppConfig.kPeakThresholdStdWeight * stats['std']!;

    // 3. Peak Shape Tracking
    if (mag > _lastMag) {
      if (!_isRising) {
        _isRising = true;
        _peakStartTime = now;
        _peakMaxVal = mag;
        _peakMaxTime = now;
      }
      if (mag > _peakMaxVal) {
        _peakMaxVal = mag;
        _peakMaxTime = now;
      }
    } else if (mag < _lastMag && _isRising) {
      // Potential peak at _peakMaxTime
      _isRising = false;
      final validated = _validatePeak(threshold, now);
      _lastMag = mag;
      return validated;
    }
    
    _lastMag = mag;
    return false;
  }

  bool _validatePeak(double threshold, DateTime fallTime) {
    if (_peakMaxVal < threshold) return false;
    if (_peakStartTime == null || _peakMaxTime == null) return false;

    final now = DateTime.now();

    // ── GATE 1: Refractory Period (250ms - 2500ms) ──────────────────────────
    if (_lastStepTime != null) {
      final isi = now.difference(_lastStepTime!).inMilliseconds;
      if (isi < AppConfig.kMinStepIntervalMs || isi > AppConfig.kMaxStepIntervalMs) {
        return false;
      }
    }

    // ── GATE 2: Peak Shape (Rise 80-200ms, Fall 80-250ms) ───────────────────
    final riseTime = _peakMaxTime!.difference(_peakStartTime!).inMilliseconds;
    final fallTimeMs = fallTime.difference(_peakMaxTime!).inMilliseconds;
    
    if (riseTime < AppConfig.kMinRiseTimeMs || riseTime > AppConfig.kMaxRiseTimeMs) return false;
    if (fallTimeMs < AppConfig.kMinFallTimeMs || fallTimeMs > AppConfig.kMaxFallTimeMs) return false;

    // ── GATE 3: Jerk Range (5-80 m/s³) ─────────────────────────────────────
    // Approximated from peak magnitude change over rise time
    final jerk = (_peakMaxVal - 1.0).abs() * 9.81 / (riseTime / 1000.0);
    if (jerk < AppConfig.kMinJerk || jerk > AppConfig.kMaxJerk) return false;

    // ── GATE 4: Symmetry (ISI CV < 0.35) ───────────────────────────────────
    if (_lastStepTime != null) {
      final currentIsi = now.difference(_lastStepTime!).inMilliseconds.toDouble();
      _isiBuffer.add(currentIsi);
      if (_isiBuffer.length > 4) _isiBuffer.removeAt(0);

      if (_isiBuffer.length == 4) {
        final isiStats = _calculateStats(_isiBuffer);
        final cv = isiStats['std']! / isiStats['mean']!;
        if (cv > AppConfig.kMaxIsiCv) {
          AppLogger.w('PeakDetector', 'Rejected: Symmetry CV=${cv.toStringAsFixed(2)}');
          return false;
        }
      }
    }

    _lastStepTime = now;
    return true;
  }

  Map<String, double> _calculateStats(List<double> data) {
    if (data.isEmpty) return {'mean': 0.0, 'std': 0.0};
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    return {'mean': mean, 'std': math.sqrt(variance)};
  }
}
