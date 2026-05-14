import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects floor changes using the barometric pressure sensor.
///
/// Pressure drop of ~12 Pa corresponds to 1 floor (~3 m elevation gain).
/// Reference: International Standard Atmosphere model, ISO 2533.
class BarometerService {
  static const double kPaPerFloor = 12.0;
  static const double kFloorDebounceMs = 3000; // 3s dead-band between floor counts

  final _floorsController = StreamController<int>.broadcast();
  Stream<int> get floorsStream => _floorsController.stream;

  StreamSubscription? _baroSub;
  double? _baselinePressure;
  DateTime? _lastFloorTime;
  int _totalFloors = 0;
  bool _available = false;

  bool get isAvailable => _available;
  int get totalFloors => _totalFloors;

  Future<void> initialise() async {
    try {
      _baroSub = barometerEventStream().listen(
        _onPressure,
        onError: (_) {
          _available = false;
          debugPrint('BarometerService: sensor not available');
        },
        cancelOnError: true,
      );
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint('BarometerService: failed to initialise — $e');
    }
  }

  void _onPressure(BarometerEvent event) {
    final hPa = event.pressure;
    _baselinePressure ??= hPa;

    final deltaPa = (_baselinePressure! - hPa) * 100; // hPa → Pa
    final floors = (deltaPa / kPaPerFloor).round();

    if (floors > _totalFloors) {
      final now = DateTime.now();
      if (_lastFloorTime == null ||
          now.difference(_lastFloorTime!).inMilliseconds > kFloorDebounceMs) {
        _totalFloors = floors;
        _lastFloorTime = now;
        _floorsController.add(_totalFloors);
      }
    }
  }

  void dispose() {
    _baroSub?.cancel();
    _floorsController.close();
  }
}
