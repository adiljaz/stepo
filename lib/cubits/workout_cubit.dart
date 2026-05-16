import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
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
}

class WorkoutState {
  final bool isActive;
  final List<LatLng> route;
  final double distanceKm;
  final int startSteps;
   final int currentSteps;
  final String? errorMessage;

  WorkoutState({
    required this.isActive,
    required this.route,
    required this.distanceKm,
    required this.startSteps,
    required this.currentSteps,
    this.errorMessage,
  });

  WorkoutState copyWith({
    bool? isActive,
    List<LatLng>? route,
    double? distanceKm,
    int? startSteps,
    int? currentSteps,
    String? errorMessage,
  }) {
    return WorkoutState(
      isActive: isActive ?? this.isActive,
      route: route ?? this.route,
      distanceKm: distanceKm ?? this.distanceKm,
      startSteps: startSteps ?? this.startSteps,
      currentSteps: currentSteps ?? this.currentSteps,
      errorMessage: errorMessage,
    );
  }
}

class WorkoutCubit extends Cubit<WorkoutState> {
  StreamSubscription<Position>? _gpsSub;
  DateTime? _startTime;

  WorkoutCubit() : super(WorkoutState(
    isActive: false,
    route: [],
    distanceKm: 0,
    startSteps: 0,
    currentSteps: 0,
  ));

  Future<void> startWorkout({required int currentSteps}) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _startTime = DateTime.now();
    emit(state.copyWith(
      isActive: true,
      route: [],
      startSteps: currentSteps,
      currentSteps: currentSteps,
      distanceKm: 0,
    ));

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final newRoute = List<LatLng>.from(state.route)..add(LatLng(pos.latitude, pos.longitude));
      emit(state.copyWith(
        route: newRoute,
        distanceKm: _calculateDistance(newRoute),
      ));
    }, onError: (Object error) {
      _gpsSub?.cancel();
      _gpsSub = null;
      emit(state.copyWith(isActive: false, errorMessage: 'GPS Connection Lost. Please check your location settings.'));
    });
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  void updateSteps(int steps) {
    emit(state.copyWith(currentSteps: steps));
  }

  WorkoutSession stopWorkout() {
    _gpsSub?.cancel();
    final session = WorkoutSession(
      startTime: _startTime ?? DateTime.now(),
      route: List.from(state.route),
      distanceKm: state.distanceKm,
      steps: state.currentSteps - state.startSteps,
      avgPaceMinPerKm: _calculatePace(),
    );
    emit(state.copyWith(isActive: false));
    return session;
  }

  double _calculatePace() {
    if (_startTime == null || state.distanceKm <= 0) return 0;
    final durationHours = DateTime.now().difference(_startTime!).inSeconds / 3600.0;
    return (durationHours * 60) / state.distanceKm;
  }

  static double _calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _haversine(points[i], points[i + 1]);
    }
    return total;
  }

  static double _haversine(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final hav = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180.0) *
            math.cos(b.latitude * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
  }

  @override
  Future<void> close() {
    _gpsSub?.cancel();
    return super.close();
  }
}
