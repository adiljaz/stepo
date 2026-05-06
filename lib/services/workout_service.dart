import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class WorkoutSession {
  final DateTime startTime;
  final List<LatLng> route;
  final double distanceKm;
  final int steps;
  final double avgPaceMinPerKm;

  const WorkoutSession({
    required this.startTime,
    required this.route,
    required this.distanceKm,
    required this.steps,
    required this.avgPaceMinPerKm,
  });

  Duration get duration => DateTime.now().difference(startTime);
}

class WorkoutService extends ChangeNotifier {
  StreamSubscription<Position>? _gpsSub;
  final List<LatLng> _route = [];
  DateTime? _startTime;
  int _startSteps = 0;
  int _currentSteps = 0;
  bool _isActive = false;

  bool get isActive => _isActive;
  List<LatLng> get route => List.unmodifiable(_route);
  double get distanceKm => _calculateDistance(_route);

  Future<void> startWorkout({required int currentSteps}) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _route.clear();
    _startTime = DateTime.now();
    _startSteps = currentSteps;
    _currentSteps = currentSteps;
    _isActive = true;

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Record a new point every 5m
      ),
    ).listen(
      (pos) {
        _route.add(LatLng(pos.latitude, pos.longitude));
        notifyListeners();
      },
      onError: (Object error) {
        // Location service disabled or permission revoked mid-workout
        debugPrint('WorkoutService: GPS stream error — $error');
        // Stop the subscription to avoid repeated errors
        _gpsSub?.cancel();
        _gpsSub = null;
        notifyListeners();
      },
      cancelOnError: false,
    );

    notifyListeners();
  }

  void updateSteps(int steps) {
    _currentSteps = steps;
  }

  WorkoutSession stopWorkout() {
    _gpsSub?.cancel();
    _isActive = false;

    final steps = _currentSteps - _startSteps;
    final distKm = _calculateDistance(_route);
    final durationHours =
        DateTime.now().difference(_startTime!).inSeconds / 3600.0;
    final paceMinPerKm = distKm > 0 ? (durationHours * 60) / distKm : 0.0;

    notifyListeners();
    return WorkoutSession(
      startTime: _startTime!,
      route: List.from(_route),
      distanceKm: distKm,
      steps: steps,
      avgPaceMinPerKm: paceMinPerKm,
    );
  }

  /// Haversine formula — calculates geodesic distance in km.
  static double _calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _haversine(points[i], points[i + 1]);
    }
    return total;
  }

  static double _haversine(LatLng a, LatLng b) {
    const R = 6371.0; // Earth radius km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final hav = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(a.latitude)) *
            math.cos(_deg2rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
  }

  static double _deg2rad(double deg) => deg * math.pi / 180.0;
}
