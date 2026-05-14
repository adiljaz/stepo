import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/step_constants.dart';
import '../../providers/user_settings_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/daily_record.dart';
import '../../models/user_profile.dart';
import '../../db/step_database.dart';
import 'barometer_tracker.dart';
import 'gps_kalman_filter.dart';
import '../../utils/logger.dart';

// Import v7 Deliverables
import 'adaptive_sensor_controller.dart';
import 'signal_filters.dart';
import 'peak_detector.dart';
import 'hardware_fusion.dart';
import 'ml_validator.dart';
import 'fft_anti_cheat.dart';
import 'confirmation_engine.dart';
import 'reconciliation_engine.dart';

/// The v7.0 World-Class Step Tracking State.
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
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}

/// v7.0 Biomechanical Tracking Engine Orchestrator.
class StepTrackingServiceV7 extends StateNotifier<StepTrackerState> {
  
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
  StreamSubscription<Position>? _gpsSub;

  // Buffers for ML/FFT (Isolate-friendly)
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

  StepTrackingServiceV7() : super(StepTrackerState(
    steps: 0,
    pendingSteps: 0,
    mlConfidence: 0,
    fftFreq: 0,
    currentTier: ConfirmationTier.tier1Instant,
    rejectedToday: 0,
    distanceKm: 0,
    calories: 0,
    flightsOfStairs: 0,
  )) {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Database & Reconciliation Recovery
    _totalDailySteps = await StepDatabase.getStepsForDate(DailyRecord.today());
    await _reconcileEngine.initialize(_totalDailySteps);

    // Initial state update
    _updateUI(ConfirmationTier.tier1Instant, 0.0, 0.0);

    // 2. Initialize ML
    await _mlValidator.initialize();

    // 3. Start Hardware Fusion
    _hwFusion = HardwareFusion(onHardwareStep: _onHardwareStep);
    _hwFusion.start();

    // 4. Start Sensor Stream
    _sensorController = AdaptiveSensorController(
      onSample: _onSensorSample,
      onHardwareFallback: () => state = state.copyWith(lastStatus: "LOW_HZ_FALLBACK"),
    );
    _sensorController.start();

    // 5. Start Barometer Tracker
    _barometerTracker = BarometerTracker(
      onFlightsUpdated: (flights) {
        state = state.copyWith(flightsOfStairs: flights);
      },
    );
    _barometerTracker.start();

    // 6. Start GPS Fusion
    _kalmanFilter = GPSKalmanFilter();
    _startGpsStream();
  }

  Future<void> _startGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return; // Wait for user to enable in workout screen
      }

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        final speedKmh = position.speed * 3.6; // m/s to km/h
        _kalmanFilter.update(speedKmh);
      }, onError: (error) {
        AppLogger.w('Tracker', 'GPS stream error: $error');
      });
      AppLogger.i('Tracker', 'GPS Fusion stream started.');
    } catch (e) {
      AppLogger.w('Tracker', 'GPS Fusion error: $e');
    }
  }

  void updateProfile(UserProfile p) {
    _currentSensitivity = p.aiSensitivity;
    _currentStrideLength = p.strideLengthMeters;
  }

  void _onSensorSample(double ax, double ay, double az, double gx, double gy, double gz, double dt) {
    // STAGE 2: Filter
    final norm = _normalizer.normalize(ax, ay, az);
    final filteredVertical = _filter.process(norm['vertical']!, 0);
    final filteredMag = _filter.process(norm['magnitude']!, 1);
    
    // Jerk calculation
    final jerk = (norm['magnitude']! - 1.0).abs() * 9.81 / dt;

    // Buffer for ML/FFT
    _mlWindowBuffer.add([ax, ay, az, gx, gy, gz, norm['vertical']!, norm['magnitude']!, jerk]);
    if (_mlWindowBuffer.length > 256) _mlWindowBuffer.removeAt(0);
    
    _fftMagnitudeBuffer.add(norm['magnitude']!);
    if (_fftMagnitudeBuffer.length > 256) _fftMagnitudeBuffer.removeAt(0);

    // STAGE 3: Peak Detection
    if (_peakDetector.process(filteredMag, filteredVertical, dt)) {
      _processCandidatePeak();
    }
  }

  void _onHardwareStep(int delta) {
    AppLogger.i('Tracker', 'Hardware co-processor detected $delta steps');
    
    // Wake up AI sensors if they were paused
    if (_isSensorPaused) {
      _sensorController.resume();
      _isSensorPaused = false;
    }
    
    _resetInactivityTimer();
    
    // Trigger reconciliation immediately to catch undercounting if the peak detector missed it
    _totalDailySteps = _reconcileEngine.reconcile(_softwareSessionSteps, _hwFusion.currentSteps, _rejections);
    _updateUI(ConfirmationTier.tier1Instant, state.mlConfidence, state.fftFreq);
  }

  Future<void> _processCandidatePeak() async {
    if (_mlWindowBuffer.length < 75) return;

    final window = _mlWindowBuffer.sublist(_mlWindowBuffer.length - 75);
    final fftSamples = _fftMagnitudeBuffer.length >= 256 ? _fftMagnitudeBuffer.sublist(_fftMagnitudeBuffer.length - 256) : <double>[];

    // STAGE 4 & 5: Parallel Sources
    final mlResult = await _mlValidator.predict(window);
    final fftResult = fftSamples.isNotEmpty ? _fftEngine.analyze(fftSamples, _sensorController.actualHz) : FFTResult(dominantFreq: 1.5, entropy: 0.1);

    // STAGE 6: Smart Confirmation
    final evaluation = _confirmationEngine.evaluate(
      mlConfidence: mlResult.confidence,
      mlClass: mlResult.prediction,
      hardwareDelta: _hwFusion.currentSteps, 
      isiConsistent: true, // Simplified
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
    _softwareSessionSteps++;
    
    // STAGE 7: Reconciliation
    _totalDailySteps = _reconcileEngine.reconcile(_softwareSessionSteps, _hwFusion.currentSteps, _rejections);

    _updateUI(tier, ml.confidence, fft.dominantFreq);

    // Persist
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

  void _updateUI(ConfirmationTier tier, double mlConfidence, double fftFreq) {
    // STAGE 8: UI Update
    final dist = _totalDailySteps * _currentStrideLength / 1000.0;
    final cals = _totalDailySteps * AppConfig.kCaloriesPerStepWalk;
    
    state = state.copyWith(
      steps: _totalDailySteps,
      mlConfidence: mlConfidence,
      fftFreq: fftFreq,
      currentTier: tier,
      distanceKm: dist,
      calories: cals,
    );
  }

  void _handleReject(String reason, GaitNetResult ml, FFTResult fft) {

    _rejections++;
    state = state.copyWith(rejectedToday: _rejections);
    
    StepDatabase.logRejectedStep(
      id: 'reject_${DateTime.now().millisecondsSinceEpoch}',
      ts: DateTime.now(),
      reason: reason,
      conf: ml.confidence,
      fft: fft.dominantFreq,
    );
    AppLogger.w('Tracker', 'Step REJECTED: $reason');
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 3), () {
      AppLogger.i('Tracker', 'No steps for 3 minutes. Pausing AI sensors to save battery.');
      _sensorController.pause();
      _barometerTracker.pause();
      _isSensorPaused = true;
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _gpsSub?.cancel();
    _sensorController.stop();
    _barometerTracker.stop();
    _hwFusion.stop();
    _mlValidator.dispose();
    super.dispose();
  }
}

final stepTrackerProvider = StateNotifierProvider<StepTrackingServiceV7, StepTrackerState>((ref) {
  final service = StepTrackingServiceV7();
  
  // Set initial
  service.updateProfile(ref.read(userSettingsProvider));
  
  // Listen for dynamic changes
  ref.listen<UserProfile>(userSettingsProvider, (previous, next) {
    service.updateProfile(next);
  });
  
  return service;
});
