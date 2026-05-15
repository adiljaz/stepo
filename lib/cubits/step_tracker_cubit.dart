import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/step_constants.dart';
import '../models/daily_record.dart';
import '../models/user_profile.dart';
import '../db/step_database.dart';
import '../services/v7/barometer_tracker.dart';
import '../services/v7/gps_kalman_filter.dart';
import '../utils/logger.dart';
import '../models/locomotion_state.dart';
import '../services/v7/locomotion_classifier.dart';

// Import v7 Deliverables
import '../services/v7/adaptive_sensor_controller.dart';
import '../services/v7/signal_filters.dart';
import '../services/v7/peak_detector.dart';
import '../services/v7/hardware_fusion.dart';
import '../services/v7/ml_validator.dart';
import '../services/v7/fft_anti_cheat.dart';
import '../services/v7/confirmation_engine.dart';
import '../services/v7/reconciliation_engine.dart';

class StepTrackerState {
  final int steps;
  final int pendingSteps;
  final double mlConfidence;
  final double fftFreq;
  final ConfirmationTier currentTier;
  final int rejectedToday;
  final double distanceKm;
  final double calories;
  final int flightsOfStairs;
  final LocomotionState locomotionState;
  final String? lastStatus;

  StepTrackerState({
    required this.steps,
    required this.pendingSteps,
    required this.mlConfidence,
    required this.fftFreq,
    required this.currentTier,
    required this.rejectedToday,
    required this.distanceKm,
    required this.calories,
    required this.flightsOfStairs,
    required this.locomotionState,
    this.lastStatus,
  });

  StepTrackerState copyWith({
    int? steps,
    int? pendingSteps,
    double? mlConfidence,
    double? fftFreq,
    ConfirmationTier? currentTier,
    int? rejectedToday,
    double? distanceKm,
    double? calories,
    int? flightsOfStairs,
    LocomotionState? locomotionState,
    String? lastStatus,
  }) {
    return StepTrackerState(
      steps: steps ?? this.steps,
      pendingSteps: pendingSteps ?? this.pendingSteps,
      mlConfidence: mlConfidence ?? this.mlConfidence,
      fftFreq: fftFreq ?? this.fftFreq,
      currentTier: currentTier ?? this.currentTier,
      rejectedToday: rejectedToday ?? this.rejectedToday,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      flightsOfStairs: flightsOfStairs ?? this.flightsOfStairs,
      locomotionState: locomotionState ?? this.locomotionState,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}

class StepTrackerCubit extends Cubit<StepTrackerState> {
  // Deliverables
  late AdaptiveSensorController _sensorController;
  final OrientationNormalizer _normalizer = OrientationNormalizer();
  final ButterworthFilter _filter = ButterworthFilter();
  final BiomechanicalPeakDetector _peakDetector = BiomechanicalPeakDetector();
  late HardwareFusion _hwFusion;
  final GaitNetMLValidator _mlValidator = GaitNetMLValidator();
  final FFTAntiCheat _fftEngine = FFTAntiCheat();
  final SmartConfirmationEngine _confirmationEngine = SmartConfirmationEngine();
  final ReconciliationEngine _reconcileEngine = ReconciliationEngine();
  late final BarometerTracker _barometerTracker;
  late final GPSKalmanFilter _kalmanFilter;
  final LocomotionClassifier _classifier = LocomotionClassifier();
  StreamSubscription<Position>? _gpsSub;

  String? _activeVehicleSessionId;
  DateTime? _vehicleSessionStartTime;

  final List<List<double>> _mlWindowBuffer = [];
  final List<double> _fftMagnitudeBuffer = [];

  int _totalDailySteps = 0;
  int _softwareSessionSteps = 0;
  int _rejections = 0;

  Timer? _inactivityTimer;
  bool _isSensorPaused = false;
  bool _isInitialized = false;
  AISensitivity _currentSensitivity = AISensitivity.normal;
  double _currentStrideLength = 0.762;

  StepTrackerCubit() : super(StepTrackerState(
    steps: 0,
    pendingSteps: 0,
    mlConfidence: 0,
    fftFreq: 0,
    currentTier: ConfirmationTier.tier1Instant,
    rejectedToday: 0,
    distanceKm: 0,
    calories: 0,
    flightsOfStairs: 0,
    locomotionState: const StationaryState(),
  )) {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _totalDailySteps = await StepDatabase.getStepsForDate(DailyRecord.today());
    await _reconcileEngine.initialize(_totalDailySteps);

    _updateUI(ConfirmationTier.tier1Instant, 0.0, 0.0);

    await _mlValidator.initialize();

    _hwFusion = HardwareFusion(onHardwareStep: _onHardwareStep);
    _hwFusion.start();

    _sensorController = AdaptiveSensorController(
      onSample: _onSensorSample,
      onHardwareFallback: () => emit(state.copyWith(lastStatus: "LOW_HZ_FALLBACK")),
    );
    _sensorController.start();

    _barometerTracker = BarometerTracker(
      onFlightsUpdated: (flights) {
        emit(state.copyWith(flightsOfStairs: flights));
      },
    );
    _barometerTracker.start();

    _kalmanFilter = GPSKalmanFilter();
    _startGpsStream();
  }

  Future<void> _startGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        final speedKmh = position.speed * 3.6;
        _kalmanFilter.update(speedKmh);
      }, onError: (error) {
        AppLogger.w('Tracker', 'GPS stream error: $error');
      });
    } catch (e) {
      AppLogger.w('Tracker', 'GPS Fusion error: $e');
    }
  }

  void updateProfile(UserProfile p) {
    _currentSensitivity = p.aiSensitivity;
    _currentStrideLength = p.strideLengthMeters;
  }

  void _onSensorSample(double ax, double ay, double az, double gx, double gy, double gz, double dt) {
    final norm = _normalizer.normalize(ax, ay, az);
    final filteredVertical = _filter.process(norm['vertical']!, 0);
    final filteredMag = _filter.process(norm['magnitude']!, 1);
    final jerk = (norm['magnitude']! - 1.0).abs() * 9.81 / dt;

    _mlWindowBuffer.add([ax, ay, az, gx, gy, gz, norm['vertical']!, norm['magnitude']!, jerk]);
    if (_mlWindowBuffer.length > 256) _mlWindowBuffer.removeAt(0);

    // Update Locomotion State
    _updateLocomotion(gx, gy, gz, jerk, norm['magnitude']!);
    
    _fftMagnitudeBuffer.add(norm['magnitude']!);
    if (_fftMagnitudeBuffer.length > 256) _fftMagnitudeBuffer.removeAt(0);

    if (_peakDetector.process(filteredMag, filteredVertical, dt)) {
      _processCandidatePeak();
    }
  }

  void _onHardwareStep(int delta) {
    if (_isSensorPaused) {
      _sensorController.resume();
      _isSensorPaused = false;
    }
    _resetInactivityTimer();
    _totalDailySteps = _reconcileEngine.reconcile(_softwareSessionSteps, _hwFusion.currentSteps, _rejections);
    _updateUI(ConfirmationTier.tier1Instant, state.mlConfidence, state.fftFreq);
  }

  Future<void> _processCandidatePeak() async {
    if (_mlWindowBuffer.length < 75) return;
    final window = _mlWindowBuffer.sublist(_mlWindowBuffer.length - 75);
    final fftSamples = _fftMagnitudeBuffer.length >= 256 ? _fftMagnitudeBuffer.sublist(_fftMagnitudeBuffer.length - 256) : <double>[];

    final mlResult = await _mlValidator.predict(window);
    final fftResult = fftSamples.isNotEmpty ? _fftEngine.analyze(fftSamples, _sensorController.actualHz) : FFTResult(dominantFreq: 1.5, entropy: 0.1);

    final evaluation = _confirmationEngine.evaluate(
      mlConfidence: mlResult.confidence,
      mlClass: mlResult.prediction,
      hardwareDelta: _hwFusion.currentSteps, 
      isiConsistent: true,
      fftFreq: fftResult.dominantFreq,
      spectralEntropy: fftResult.entropy,
      gpsSpeedKmh: _kalmanFilter.currentSpeedKmh,
      sensitivity: _currentSensitivity,
    );

    _applyTieredConfirmation(evaluation, mlResult, fftResult);
  }

  void _applyTieredConfirmation(ConfirmationResult result, GaitNetResult ml, FFTResult fft) {
    if (!result.approved && result.tier == ConfirmationTier.tier4Reject) {
      _handleReject(result.reason ?? "UNKNOWN_REJECT", ml, fft);
      return;
    }

    if (result.tier == ConfirmationTier.tier1Instant) {
      _confirmStep(ml, fft, ConfirmationTier.tier1Instant);
    } else if (result.tier == ConfirmationTier.tier2Fast) {
      Timer(AppConfig.kTier2Delay, () => _confirmStep(ml, fft, ConfirmationTier.tier2Fast));
    } else if (result.tier == ConfirmationTier.tier3Deep) {
      Timer(AppConfig.kTier3Delay, () => _confirmStep(ml, fft, ConfirmationTier.tier3Deep));
    }
  }

  void _confirmStep(GaitNetResult ml, FFTResult fft, ConfirmationTier tier) {
    // ── STEP GATE: Only count steps if biological locomotion is confirmed ──
    if (state.locomotionState is! WalkingState && state.locomotionState is! RunningState) {
      AppLogger.w('Tracker', 'STEP_GATED: Current state is ${state.locomotionState.runtimeType}');
      return;
    }

    // ── ANTI-CHEAT: High GPS speed but biological cadence ──
    if (_kalmanFilter.currentSpeedKmh > 15.0 && state.locomotionState is! RunningState) {
       emit(state.copyWith(locomotionState: const SuspiciousMovementState('HIGH_SPEED_HUMAN_CADENCE')));
       AppLogger.e('Tracker', 'ANTI-CHEAT: Suspicious Movement Flagged!');
       return;
    }

    _softwareSessionSteps++;
    _totalDailySteps = _reconcileEngine.reconcile(_softwareSessionSteps, _hwFusion.currentSteps, _rejections);
    _updateUI(tier, ml.confidence, fft.dominantFreq);

    StepDatabase.logStepEvent(
      id: 'step_${DateTime.now().millisecondsSinceEpoch}',
      ts: DateTime.now(),
      tier: tier.index,
      mlClass: ml.prediction,
      mlConf: ml.confidence,
      fftFreq: fft.dominantFreq,
      hwDelta: _hwFusion.currentSteps,
      isi: 600.0,
    );
    
    StepDatabase.upsertToday(steps: _totalDailySteps, distanceKm: _totalDailySteps * _currentStrideLength / 1000.0, calories: _totalDailySteps * AppConfig.kCaloriesPerStepWalk);
  }

  void _updateLocomotion(double gx, double gy, double gz, double jerk, double mag) {
    final gyroVar = sqrt(gx*gx + gy*gy + gz*gz); // Simplified variance for real-time
    
    final newState = _classifier.classify(
      gpsSpeedKmh: _kalmanFilter.currentSpeedKmh,
      gpsAccuracy: 10.0, // Should be from GPS stream
      maxJerk: jerk,
      avgMag: mag,
      spectralPowerGaitBand: state.mlConfidence, // Proxy for spectral power
      gyroVariance: gyroVar,
      altitudeDelta: 0.0, // From barometer
    );

    if (newState.runtimeType != state.locomotionState.runtimeType) {
      _handleStateTransition(state.locomotionState, newState);
      emit(state.copyWith(locomotionState: newState));
    }
  }

  void _handleStateTransition(LocomotionState oldState, LocomotionState newState) {
    // Power Management
    if (newState is StationaryState) {
      _sensorController.setPowerMode(PowerMode.low);
    } else if (oldState is StationaryState) {
      _sensorController.setPowerMode(PowerMode.normal);
    }

    // Session Logging
    if (newState is InVehicleState) {
      _activeVehicleSessionId = 'v_${DateTime.now().millisecondsSinceEpoch}';
      _vehicleSessionStartTime = DateTime.now();
    } else if (oldState is InVehicleState && _activeVehicleSessionId != null) {
      StepDatabase.logVehicleSession(
        id: _activeVehicleSessionId!,
        type: oldState.vehicleType.name,
        startTime: _vehicleSessionStartTime!,
        endTime: DateTime.now(),
        avgSpeed: _kalmanFilter.currentSpeedKmh,
      );
      _activeVehicleSessionId = null;
    }
  }

  void _updateUI(ConfirmationTier tier, double mlConfidence, double fftFreq) {
    final dist = _totalDailySteps * _currentStrideLength / 1000.0;
    final cals = _totalDailySteps * AppConfig.kCaloriesPerStepWalk;
    
    emit(state.copyWith(
      steps: _totalDailySteps,
      mlConfidence: mlConfidence,
      fftFreq: fftFreq,
      currentTier: tier,
      distanceKm: dist,
      calories: cals,
    ));
  }

  void _handleReject(String reason, GaitNetResult ml, FFTResult fft) {
    _rejections++;
    emit(state.copyWith(rejectedToday: _rejections));
    StepDatabase.logRejectedStep(
      id: 'reject_${DateTime.now().millisecondsSinceEpoch}',
      ts: DateTime.now(),
      reason: reason,
      conf: ml.confidence,
      fft: fft.dominantFreq,
    );
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 3), () {
      _sensorController.pause();
      _barometerTracker.pause();
      _isSensorPaused = true;
    });
  }

  @override
  Future<void> close() {
    _inactivityTimer?.cancel();
    _gpsSub?.cancel();
    _sensorController.stop();
    _barometerTracker.stop();
    _hwFusion.stop();
    _mlValidator.dispose();
    return super.close();
  }
}
