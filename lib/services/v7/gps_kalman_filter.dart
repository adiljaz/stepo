class GPSKalmanFilter {
  // State: current smoothed velocity in km/h
  double _v = 0.0;
  
  // Estimation error covariance
  double _p = 1.0; 

  // Process noise (expected natural variation in human walking/running speed)
  final double _q = 0.1;

  // Measurement noise (GPS inaccuracy)
  // Higher = trust the prediction more, trust the GPS less
  final double _r = 3.0;

  /// Returns the current smoothed speed in km/h
  double get currentSpeedKmh => _v;

  /// Updates the filter with a new raw GPS speed measurement
  void update(double measuredSpeedKmh) {
    // Prediction Update: error covariance grows over time
    _p = _p + _q;

    // Measurement Update: calculate Kalman Gain
    double k = _p / (_p + _r);
    
    // Update State estimate based on measurement and gain
    _v = _v + k * (measuredSpeedKmh - _v);
    
    // Update Covariance estimate
    _p = (1 - k) * _p;
  }
  
  /// Resets the filter (e.g., when GPS signal is lost)
  void reset() {
    _v = 0.0;
    _p = 1.0;
  }
}
