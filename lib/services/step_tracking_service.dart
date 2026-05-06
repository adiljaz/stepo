import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/step_constants.dart';
import '../models/step_candidate.dart';
import '../db/step_database.dart';
import 'signal_processor.dart';
import 'step_detector.dart';
import 'gait_classifier.dart';
import 'reconciliation_engine.dart';
import 'health_sync_service.dart';
import 'anti_cheat_engine.dart';
import 'barometer_service.dart';
import 'calorie_calculator.dart';
import 'badge_service.dart';
import 'reminder_service.dart';
import 'widget_service.dart';
import 'package:permission_handler/permission_handler.dart';

class StepTrackingState {
  final int steps;
  final double distanceKm;
  final double calories;
  final GaitLabel gaitLabel;
  final int calibrationProgress;
  final int? lastCorrection;
  final bool isGpsActive;
  final bool isBackgroundActive;
  final double lastFraudScore;
  final String? lastRejectionReason;
  final int hardwareSteps;
  final int softwareSteps;
  final int floors;
  final int dailyGoal;

  const StepTrackingState({
    this.steps = 0,
    this.distanceKm = 0.0,
    this.calories = 0.0,
    this.gaitLabel = GaitLabel.still,
    this.calibrationProgress = 0,
    this.lastCorrection,
    this.isGpsActive = false,
    this.isBackgroundActive = false,
    this.lastFraudScore = 0.0,
    this.lastRejectionReason,
    this.hardwareSteps = 0,
    this.softwareSteps = 0,
    this.floors = 0,
    this.dailyGoal = 8000,
  });

  StepTrackingState copyWith({
    int? steps,
    double? distanceKm,
    double? calories,
    GaitLabel? gaitLabel,
    int? calibrationProgress,
    int? lastCorrection,
    bool? isGpsActive,
    bool? isBackgroundActive,
    double? lastFraudScore,
    String? lastRejectionReason,
    int? hardwareSteps,
    int? softwareSteps,
    int? floors,
    int? dailyGoal,
  }) => StepTrackingState(
    steps: steps ?? this.steps,
    distanceKm: distanceKm ?? this.distanceKm,
    calories: calories ?? this.calories,
    gaitLabel: gaitLabel ?? this.gaitLabel,
    calibrationProgress: calibrationProgress ?? this.calibrationProgress,
    lastCorrection: lastCorrection,
    isGpsActive: isGpsActive ?? this.isGpsActive,
    isBackgroundActive: isBackgroundActive ?? this.isBackgroundActive,
    lastFraudScore: lastFraudScore ?? this.lastFraudScore,
    lastRejectionReason: lastRejectionReason ?? this.lastRejectionReason,
    hardwareSteps: hardwareSteps ?? this.hardwareSteps,
    softwareSteps: softwareSteps ?? this.softwareSteps,
    floors: floors ?? this.floors,
    dailyGoal: dailyGoal ?? this.dailyGoal,
  );

  double get goalProgress => dailyGoal > 0 ? (steps / dailyGoal).clamp(0.0, 1.0) : 0;
}

class StepTrackingService extends StateNotifier<StepTrackingState> {
  StepTrackingService() : super(const StepTrackingState());

  // ── Engine components ──────────────────────────────────────────────────────
  final SignalProcessor _signalProcessor = SignalProcessor();
  final StepDetector _stepDetector = StepDetector();
  final ReconciliationEngine _reconcileEngine = ReconciliationEngine();
  final HealthSyncService _healthSync = HealthSyncService();
  final BarometerService _barometer = BarometerService();

  // ── Anti-cheat isolate ─────────────────────────────────────────────────────
  Isolate? _antiCheatIsolate;
  SendPort? _antiCheatSendPort;
  final ReceivePort _antiCheatReceivePort = ReceivePort();

  // ── Streams & timers ──────────────────────────────────────────────────────
  final List<StreamSubscription> _subs = [];
  Timer? _reconcileTimer;
  Timer? _syncTimer;
  Timer? _dbSaveTimer;

  // ── Sensor state ───────────────────────────────────────────────────────────
  double _currentGpsSpeed = 0.0;
  GyroscopeEvent _lastGyro = GyroscopeEvent(0, 0, 0, DateTime.now());
  MagnetometerEvent _lastMag = MagnetometerEvent(0, 0, 0, DateTime.now());
  DateTime _lastScreenTouch = DateTime.now();

  // ── Counters ──────────────────────────────────────────────────────────────
  int _softwareSteps = 0;
  int _hardwareBaseline = 0;
  int _lastTotalHardware = 0;
  int _cleanStepCount = 0;
  double _totalStepIntervalMs = 600;
  GaitLabel _currentGaitLabel = GaitLabel.still;

  // ── User profile ──────────────────────────────────────────────────────────
  double _weightKg = 70;
  int _dailyGoal = 8000;

  Stream<String> get debugStream => _signalProcessor.debugStream;

  bool _isInitialised = false;

  Future<void> initialise() async {
    if (_isInitialised) return;

    await _loadUserProfile();
    final granted = await requestAllPermissions();
    if (!granted) return;

    await _setupAntiCheatIsolate();
    _startSensors();
    _startPedometer();
    _startGps();
    await _barometer.initialise();

    if (_barometer.isAvailable) {
      _subs.add(_barometer.floorsStream.listen((floors) {
        state = state.copyWith(floors: floors);
      }));
    }

    _reconcileTimer = Timer.periodic(
        const Duration(seconds: kReconcileIntervalSec), (_) => _runReconciliation());
    _syncTimer = Timer.periodic(
        const Duration(seconds: kHealthSyncIntervalSec), (_) => _runHealthSync());
    _dbSaveTimer = Timer.periodic(
        const Duration(minutes: 5), (_) => _saveToDatabase());

    await _healthSync.requestPermissions();
    await ReminderService.initialise();
    ReminderService.start(() => _softwareSteps);
    await WidgetService.initialise();

    _isInitialised = true;
  }

  Future<void> _loadUserProfile() async {
    final p = await SharedPreferences.getInstance();
    _weightKg = p.getDouble('profile_weight') ?? 70;
    _dailyGoal = p.getInt('profile_goal') ?? 8000;
    state = state.copyWith(dailyGoal: _dailyGoal);
  }

  Future<bool> requestAllPermissions() async {
    final statuses = await [
      Permission.activityRecognition,
      Permission.sensors,
      Permission.location,
      Permission.notification,
    ].request();
    final granted = statuses.values.every((s) => s == PermissionStatus.granted);
    state = state.copyWith(isBackgroundActive: granted);
    return granted;
  }

  Future<void> _setupAntiCheatIsolate() async {
    _antiCheatIsolate = await Isolate.spawn(
        AntiCheatEngine.spawn, _antiCheatReceivePort.sendPort);
    _antiCheatReceivePort.listen((message) {
      if (message is SendPort) {
        _antiCheatSendPort = message;
      } else if (message is Map<String, dynamic>) {
        _handleAntiCheatResult(AntiCheatResult.fromJson(message));
      }
    });
  }

  void _startSensors() {
    // Gyroscope
    _subs.add(gyroscopeEventStream(
            samplingPeriod: const Duration(milliseconds: 20))
        .listen((e) => _lastGyro = e,
            onError: (_) {}, cancelOnError: false));

    // Magnetometer
    _subs.add(magnetometerEventStream(
            samplingPeriod: const Duration(milliseconds: 20))
        .listen((e) => _lastMag = e,
            onError: (_) {}, cancelOnError: false));

    // Accelerometer — primary step trigger
    _subs.add(accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 20))
        .listen((event) {
      // ── Gate 0: Biomechanical StepDetector ────────────────────────────
      // Refractory gate is the very first check inside StepDetector.process()
      // All 7 gates run here before _onStepDetectedOptimistic is ever called.
      final isStep = _stepDetector.process(event.x, event.y, event.z);

      // ── Signal metadata for anti-cheat isolate (runs regardless) ──────
      final candidate = _signalProcessor.processSample(
        event.x, event.y, event.z,
        _lastGyro.x, _lastGyro.y, _lastGyro.z,
        _lastMag.x, _lastMag.y, _lastMag.z,
      );

      if (isStep) {
        if (candidate != null && _antiCheatSendPort != null) {
          _antiCheatSendPort!.send({
            'candidate': candidate.toJson(),
            'gpsSpeed': _currentGpsSpeed,
            'pressureChange': 0.0,
            'batteryTemp': 0.0,
            'lastTouchSecs':
                DateTime.now().difference(_lastScreenTouch).inSeconds,
          });
        }
        _onStepDetectedOptimistic();
      }
    }, onError: (_) {}, cancelOnError: false));
  }

  void _startGps() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) return;

    _subs.add(Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      _currentGpsSpeed = pos.speed;
      state = state.copyWith(isGpsActive: true);
    }));
  }

  void onUserInteraction() => _lastScreenTouch = DateTime.now();

  void _onStepDetectedOptimistic() {
    _softwareSteps++;
    _cleanStepCount++;
    _emitState();
  }

  void _handleAntiCheatResult(AntiCheatResult result) {
    if (!result.approved) _softwareSteps = (_softwareSteps - 1).clamp(0, 99999999);

    GaitLabel label = GaitLabel.still;
    if (result.gaitLabel == 'walking') label = GaitLabel.walking;
    if (result.gaitLabel == 'running') label = GaitLabel.running;
    if (result.gaitLabel == 'calibrating') label = GaitLabel.calibrating;
    if (result.gaitLabel == 'fraudulent') label = GaitLabel.fraudulent;
    if (result.gaitLabel == 'stationary_step') label = GaitLabel.stationary_step;
    _currentGaitLabel = label;

    state = state.copyWith(
      lastFraudScore: result.fraudScore,
      lastRejectionReason: result.approved ? null : result.rejectionReason,
      gaitLabel: label,
      steps: _softwareSteps,
    );
    if (!result.approved) _emitState();
  }

  void _startPedometer() {
    _subs.add(Pedometer.stepCountStream.listen((event) async {
      if (_hardwareBaseline == 0) {
        _hardwareBaseline = event.steps;
        _reconcileEngine.setInitialBaseline(event.steps, _softwareSteps);

        final prefs = await SharedPreferences.getInstance();
        final lastSavedHw = prefs.getInt('last_hw_count') ?? 0;
        if (lastSavedHw > 0 && event.steps > lastSavedHw) {
          final missed = event.steps - lastSavedHw;
          if (missed < 50000) {
            _softwareSteps += missed;
            _emitState(correction: missed);
          }
        }
      }
      _lastTotalHardware = event.steps;
      _runPrecisionReconciliation();
    }, onError: (_) {}, cancelOnError: false));
  }

  void _runReconciliation() {
    final result = _reconcileEngine.reconcile(
      currentHardwareCount: _lastTotalHardware,
      currentSoftwareCount: _softwareSteps,
    );
    if (result.correctionAmount != 0) {
      _softwareSteps += result.correctionAmount;
      _emitState(correction: result.correctionAmount);
    }
  }

  void _runHealthSync() => _healthSync.syncSteps(_softwareSteps);

  Future<void> _saveToDatabase() async {
    await StepDatabase.upsertToday(
      steps: _softwareSteps,
      distanceKm: _softwareSteps * kDefaultStrideMeter / 1000.0,
      calories: state.calories,
      floors: state.floors,
    );

    // Badge check
    final streak = await StepDatabase.getStreak(_dailyGoal);
    final pb = await StepDatabase.getPersonalBest();
    await BadgeService.check(
      steps: _softwareSteps,
      streak: streak,
      dailyBest: pb?.steps ?? 0,
      monthTotal: _softwareSteps,
    );
  }

  void _emitState({int? correction}) {
    final dist = _softwareSteps * kDefaultStrideMeter / 1000.0;
    // MET-based calories
    final avgIntervalMs = _softwareSteps > 0
        ? (_totalStepIntervalMs / _softwareSteps)
        : 600.0;
    final cal = CalorieCalculator.calculate(
      steps: _softwareSteps,
      weightKg: _weightKg,
      gaitLabel: _currentGaitLabel.name,
      stepIntervalMs: avgIntervalMs,
    );

    state = state.copyWith(
      steps: _softwareSteps,
      distanceKm: dist,
      calories: cal,
      lastCorrection: correction,
      calibrationProgress:
          _cleanStepCount > kCalibrationDoneSteps ? kCalibrationDoneSteps : _cleanStepCount,
      hardwareSteps: _lastTotalHardware,
      softwareSteps: _softwareSteps,
      dailyGoal: _dailyGoal,
    );

    // Push to home-screen widget (Feature 8) — fire-and-forget, non-blocking
    WidgetService.update(
      steps: _softwareSteps,
      goal: _dailyGoal,
      calories: cal,
    );
  }

  void _runPrecisionReconciliation() {
    final hwDelta = _lastTotalHardware - _hardwareBaseline;
    if (hwDelta > _softwareSteps) {
      final diff = hwDelta - _softwareSteps;
      if (diff > 0 && diff < 50) {
        _softwareSteps += diff;
        _emitState(correction: diff);
      }
    }
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _reconcileTimer?.cancel();
    _syncTimer?.cancel();
    _dbSaveTimer?.cancel();
    _antiCheatIsolate?.kill();
    _barometer.dispose();
    ReminderService.stop();
    SharedPreferences.getInstance()
        .then((p) => p.setInt('last_hw_count', _lastTotalHardware));
    super.dispose();
  }
}
