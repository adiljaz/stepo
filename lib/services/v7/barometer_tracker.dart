import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../../utils/logger.dart';

class BarometerTracker {
  StreamSubscription? _baroSub;
  double? _basePressure;
  double _currentPressureSmoothed = 0.0;
  final double _alpha = 0.1; // Low-pass filter for noise
  
  double _altitudeGainedMeters = 0.0;
  int _flightsClimbed = 0;
  
  // ~8.3 meters per hPa at sea level. 1 flight = 3.0 meters (approx 0.36 hPa drop)
  static const double _metersPerHpa = 8.3;
  static const double _metersPerFlight = 3.0;

  final Function(int flights) onFlightsUpdated;

  BarometerTracker({required this.onFlightsUpdated});

  void start() {
    try {
      _baroSub = barometerEventStream(samplingPeriod: SensorInterval.normalInterval).listen((event) {
        final pressure = event.pressure; // hPa
        
        if (_basePressure == null) {
          _basePressure = pressure;
          _currentPressureSmoothed = pressure;
          return;
        }

        // Apply Low-pass filter
        _currentPressureSmoothed = _alpha * pressure + (1 - _alpha) * _currentPressureSmoothed;

        // Calculate altitude change from base (pressure drops as you go up)
        final pressureDrop = _basePressure! - _currentPressureSmoothed;
        final altitudeChange = pressureDrop * _metersPerHpa;

        if (altitudeChange > _altitudeGainedMeters) {
          _altitudeGainedMeters = altitudeChange;
          
          final newFlights = (_altitudeGainedMeters / _metersPerFlight).floor();
          if (newFlights > _flightsClimbed) {
            _flightsClimbed = newFlights;
            AppLogger.i('Barometer', 'Flight of stairs climbed! Total: $_flightsClimbed');
            onFlightsUpdated(_flightsClimbed);
          }
        } else if (altitudeChange < _altitudeGainedMeters - 1.5) {
          // If we go down by 1.5 meters, reset base to track the next independent climb
          _basePressure = _currentPressureSmoothed;
          _altitudeGainedMeters = 0.0;
        }
      }, onError: (error) {
        AppLogger.w('Barometer', 'Stream error: $error');
      });
      AppLogger.i('Barometer', 'Barometer tracking started.');
    } catch (e) {
      AppLogger.w('Barometer', 'Barometer sensor not available: $e');
    }
  }

  void pause() {
    _baroSub?.pause();
  }

  void resume() {
    _baroSub?.resume();
  }

  void stop() {
    _baroSub?.cancel();
  }
}
