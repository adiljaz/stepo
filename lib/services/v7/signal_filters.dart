import 'dart:math' as math;
import '../../constants/step_constants.dart';

/// STAGE 2 — FILTER (Signal Cleaning).
/// 
/// Implements a 2nd order Butterworth Band-pass filter (0.5Hz - 5.0Hz)
/// and an orientation-invariant gravity removal system.
class ButterworthFilter {
  // Filter state for 3 channels (Vertical, Magnitude, Jerk)
  final List<double> _v = List.filled(3 * 3, 0.0); 

  /// Applies 2nd Order Butterworth Band-pass.
  /// b = [0.0976, 0, -0.0976], a = [1.0, -1.7869, 0.8048]
  double process(double input, int channel) {
    int offset = channel * 3;
    
    // Direct Form II Transposed implementation
    double x = input;
    double y = AppConfig.kButterB[0] * x + _v[offset + 0];
    _v[offset + 0] = AppConfig.kButterB[1] * x - AppConfig.kButterA[1] * y + _v[offset + 1];
    _v[offset + 1] = AppConfig.kButterB[2] * x - AppConfig.kButterA[2] * y;
    
    return y;
  }
}

class OrientationNormalizer {
  double _gx = 0, _gy = 0, _gz = 0;
  
  /// Removes gravity using EMA and computes vertical component.
  Map<String, double> normalize(double ax, double ay, double az) {
    // 1. G_filtered = 0.8 * G_prev + 0.2 * G_raw
    _gx = (1.0 - AppConfig.kGemaAlpha) * _gx + AppConfig.kGemaAlpha * ax;
    _gy = (1.0 - AppConfig.kGemaAlpha) * _gy + AppConfig.kGemaAlpha * ay;
    _gz = (1.0 - AppConfig.kGemaAlpha) * _gz + AppConfig.kGemaAlpha * az;
    
    // 2. Linear = Raw - G_filtered
    final lx = ax - _gx;
    final ly = ay - _gy;
    final lz = az - _gz;
    
    // 3. Vertical component: dot(linear, normalize(G))
    final gMag = math.sqrt(_gx * _gx + _gy * _gy + _gz * _gz);
    double vertical = 0.0;
    if (gMag > 0.1) {
      vertical = (lx * _gx + ly * _gy + lz * _gz) / gMag;
    }
    
    // 4. Magnitude
    final mag = math.sqrt(ax * ax + ay * ay + az * az) / 9.81;
    
    return {
      'vertical': vertical,
      'magnitude': mag,
      'lx': lx,
      'ly': ly,
      'lz': lz,
    };
  }
}
