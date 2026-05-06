import 'dart:async';
import 'dart:math' as math;
import '../constants/step_constants.dart';
import '../models/step_candidate.dart';

class PeakMetadata {
  final DateTime timestamp;
  final double magnitude;
  final double interStepInterval;
  
  PeakMetadata({
    required this.timestamp,
    required this.magnitude,
    required this.interStepInterval,
  });
}

class SignalProcessor {
  // Buffers for multi-axis RMS and Anti-Cheat
  final List<double> _xBuffer = List.generate(kCircularBufferSize, (_) => 0.0);
  final List<double> _yBuffer = List.generate(kCircularBufferSize, (_) => 0.0);
  final List<double> _zBuffer = List.generate(kCircularBufferSize, (_) => 0.0);
  final List<double> _magWindow = List.generate(128, (_) => 0.0);
  final List<double> _xWindow = List.generate(128, (_) => 0.0);
  final List<double> _yWindow = List.generate(128, (_) => 0.0);
  final List<double> _zWindow = List.generate(128, (_) => 0.0);
  final List<double> _gyroWindow = List.generate(128, (_) => 0.0);
  int _magWindowIndex = 0;

  // Circular buffers for raw and filtered data
  final List<double> _rawBuffer = List.generate(kCircularBufferSize, (_) => 0.0);
  final List<double> _filteredBuffer = List.generate(kCircularBufferSize, (_) => 0.0);
  int _bufferIndex = 0;

  // Adaptive threshold state
  double _currentThreshold = kBaseThresholdG;
  final List<double> _recentPeakMagnitudes = [];
  DateTime? _lastStepTime;
  
  // Debug stream for real-time signal analysis
  final _debugController = StreamController<String>.broadcast();
  Stream<String> get debugStream => _debugController.stream;

  // RMS State
  double _currentRms = 0.0;

  double _lastMag = 0.0;
  DateTime? _lastSampleTime;

  /// Process a new accelerometer and gyroscope sample
  /// Returns a StepCandidate if a step is detected, otherwise null
  StepCandidate? processSample(
    double ax, double ay, double az, 
    double gx, double gy, double gz,
    double mx, double my, double mz
  ) {
    final now = DateTime.now();
    final dt = _lastSampleTime == null ? 0.02 : now.difference(_lastSampleTime!).inMilliseconds / 1000.0;
    _lastSampleTime = now;

    // 1. Compute Resultant Magnitude
    final mag = math.sqrt(ax * ax + ay * ay + az * az) / 9.81 - 1.0;
    final jerk = (mag - _lastMag) / (dt > 0 ? dt : 0.02);
    _lastMag = mag;
    
    _bufferIndex = (_bufferIndex + 1) % kCircularBufferSize;
    _rawBuffer[_bufferIndex] = mag;
    _xBuffer[_bufferIndex] = ax / 9.81;
    _yBuffer[_bufferIndex] = ay / 9.81;
    _zBuffer[_bufferIndex] = az / 9.81;

    _magWindowIndex = (_magWindowIndex + 1) % 128;
    _magWindow[_magWindowIndex] = mag;
    _xWindow[_magWindowIndex] = ax / 9.81;
    _yWindow[_magWindowIndex] = ay / 9.81;
    _zWindow[_magWindowIndex] = az / 9.81;
    final gyroMag = math.sqrt(gx * gx + gy * gy + gz * gz);
    _gyroWindow[_magWindowIndex] = gyroMag;

    final filtered = _applyForwardFilter(mag);
    _filteredBuffer[_bufferIndex] = filtered;

    _updateRms();

    if (_checkPeak(filtered)) {
      final gyroMag = math.sqrt(gx * gx + gy * gy + gz * gz);
      final magMag = math.sqrt(mx * mx + my * my + mz * mz);
      final interval = _lastStepTime != null ? now.difference(_lastStepTime!).inMilliseconds.toDouble() : 500.0;
      
      return StepCandidate(
        timestamp: now,
        magnitude: filtered,
        xRms: _calculateAxisRms(_xBuffer),
        yRms: _calculateAxisRms(_yBuffer),
        zRms: _calculateAxisRms(_zBuffer),
        gyroMagnitude: gyroMag,
        magMagnitude: magMag,
        jerk: jerk.abs(),
        impactDuration: 30.0, 
        interStepInterval: interval,
        signalWindow: _getCircularWindow(_magWindow, _magWindowIndex),
        xWindow: _getCircularWindow(_xWindow, _magWindowIndex),
        yWindow: _getCircularWindow(_yWindow, _magWindowIndex),
        zWindow: _getCircularWindow(_zWindow, _magWindowIndex),
        gyroWindow: _getCircularWindow(_gyroWindow, _magWindowIndex),
      );
    }
    return null;
  }

  double _calculateAxisRms(List<double> buffer) {
    double sumSq = 0;
    const int window = 50;
    for (int i = 0; i < window; i++) {
      int idx = (_bufferIndex - i + kCircularBufferSize) % kCircularBufferSize;
      sumSq += buffer[idx] * buffer[idx];
    }
    return math.sqrt(sumSq / window);
  }

  double _filteredValue = 0.0;
  final double _alpha = 0.15; // LPF coefficient

  double _applyForwardFilter(double input) {
    _filteredValue = (_alpha * input) + ((1.0 - _alpha) * _filteredValue);
    return _filteredValue;
  }

  void _updateRms() {
    double sumSq = 0;
    const int window = 50; 
    for (int i = 0; i < window; i++) {
      int idx = (_bufferIndex - i + kCircularBufferSize) % kCircularBufferSize;
      sumSq += _rawBuffer[idx] * _rawBuffer[idx];
    }
    _currentRms = math.sqrt(sumSq / window);
  }

  bool _checkPeak(double value) {
    final now = DateTime.now();
    
    // Broadcast for debug panel
    _debugController.add(
      'mag=${value.toStringAsFixed(3)} threshold=${_currentThreshold.toStringAsFixed(3)}'
    );

    if (value <= _currentThreshold) return false;

    for (int i = 1; i <= kPeakLocalMaxWindow; i++) {
      int prevIdx = (_bufferIndex - i + kCircularBufferSize) % kCircularBufferSize;
      if (_filteredBuffer[prevIdx] > value) return false;
    }

    if (_lastStepTime != null) {
      final interval = now.difference(_lastStepTime!).inMilliseconds;
      if (interval < kMinStepIntervalMs) return false;
    }

    int prevIdx = (_bufferIndex - 1 + kCircularBufferSize) % kCircularBufferSize;
    if (_filteredBuffer[prevIdx] >= _currentThreshold) return false;

    _lastStepTime = now;
    _updateAdaptiveThreshold(value);
    return true;
  }

  void _updateAdaptiveThreshold(double peakMag) {
    // Faster adaptation based on recent peak magnitude
    _currentThreshold = kBaseThresholdG + (0.55 * peakMag);
  }

  List<double> _getCircularWindow(List<double> buffer, int index) {
    final result = List<double>.filled(128, 0.0);
    for (int i = 0; i < 128; i++) {
      result[i] = buffer[(index - 127 + i + 128) % 128];
    }
    return result;
  }

  double get currentRms => _currentRms;
  double get currentThreshold => _currentThreshold;
}

