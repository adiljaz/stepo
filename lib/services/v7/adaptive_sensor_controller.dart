import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../../utils/logger.dart';

/// STAGE 1 — SENSE (Adaptive Sensor Controller).
/// 
/// Manages high-frequency sensor ingestion and calculates the actual 
/// hardware sampling rate to adapt downstream processing buffers.
class AdaptiveSensorController {
  StreamSubscription? _accSub;
  StreamSubscription? _gyroSub;

  final List<double> _tickIntervals = [];
  DateTime? _lastTick;
  
  double _actualHz = 50.0;
  bool _isCalibrated = false;
  int _tickCount = 0;

  final Function(double ax, double ay, double az, double gx, double gy, double gz, double dt) onSample;
  final Function() onHardwareFallback;

  AdaptiveSensorController({required this.onSample, required this.onHardwareFallback});

  void start() {
    AppLogger.i('AdaptiveSensor', 'Starting SENSOR_DELAY_GAME stream...');
    
    // Request highest rate available via top-level functions
    _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((acc) {
      _processTick(acc.x, acc.y, acc.z, true);
    });

    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval).listen((gyro) {
      _processTick(gyro.x, gyro.y, gyro.z, false);
    });
  }

  // We sync on accelerometer ticks as primary time-base
  double _lx = 0, _ly = 0, _lz = 0;
  double _lgx = 0, _lgy = 0, _lgz = 0;

  void _processTick(double x, double y, double z, bool isAcc) {
    final now = DateTime.now();
    
    if (isAcc) {
      _lx = x; _ly = y; _lz = z;
      
      if (_lastTick != null) {
        final dt = now.difference(_lastTick!).inMicroseconds / 1000000.0;
        
        if (!_isCalibrated) {
          _calibrate(dt);
        }

        onSample(_lx, _ly, _lz, _lgx, _lgy, _lgz, dt);
      }
      _lastTick = now;
    } else {
      _lgx = x; _lgy = y; _lgz = z;
    }
  }

  void _calibrate(double dt) {
    if (dt <= 0) return;
    _tickCount++;
    _tickIntervals.add(dt);
    
    if (_tickCount >= 150) { // 3 seconds at ~50Hz
      final avgDt = _tickIntervals.reduce((a, b) => a + b) / _tickIntervals.length;
      if (avgDt > 0) {
        _actualHz = 1.0 / avgDt;
      }
      _isCalibrated = true;
      
      AppLogger.i('AdaptiveSensor', 'Calibration complete. Actual Hz: ${_actualHz.toStringAsFixed(1)}');
      
      if (_actualHz < 20.0) {
        AppLogger.w('AdaptiveSensor', 'Hardware rate too low (${_actualHz.toStringAsFixed(1)}Hz). Switching to Fallback.');
        onHardwareFallback();
      }
    }
  }

  double get actualHz => _actualHz;
  bool get isCalibrated => _isCalibrated;

  void pause() {
    _accSub?.pause();
    _gyroSub?.pause();
    AppLogger.i('AdaptiveSensor', 'Sensors PAUSED (Battery Optimization).');
  }

  void resume() {
    _accSub?.resume();
    _gyroSub?.resume();
    AppLogger.i('AdaptiveSensor', 'Sensors RESUMED.');
  }

  void stop() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    AppLogger.i('AdaptiveSensor', 'Sensors stopped.');
  }
}

