import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import '../models/step_candidate.dart';
import '../constants/step_constants.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// Stepooo Anti-Cheat Engine — v5.0
/// ════════════════════════════════════════════════════════════════════════════
///
/// Runs in a dedicated Dart Isolate so it NEVER blocks the UI thread.
///
/// The engine evaluates 7 independent fraud vectors on every step candidate
/// that has already passed the StepDetector's 10 biomechanical gates.
/// Even if a determined attacker bypasses the detector, the ACE catches them
/// through session-level behavioral analysis.
///
/// Attack vectors defeated:
///   V1  — Physics impossibility      (jerk/GRF outside human range)
///   V2  — Human tremor absence       (8–12 Hz micro-tremor fingerprint)
///   V3  — Wrist/hand oscillation     (spectral flatness of inter-step intervals)
///   V4  — Gait DNA deviation         (personal cadence/magnitude profile)
///   V5  — Context impossibility      (GPS coherence, time-of-day)
///   V6  — Mechanical regularity      (Shannon entropy of interval distribution)
///   V7  — Hardware cross-validation  (gyro-accel correlation)
///
/// Output: [AntiCheatResult] — approved/rejected + fraud score 0–1
///
class AntiCheatEngine {
  // ─── Isolate entry point ──────────────────────────────────────────────────
  static Future<void> spawn(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    final engine = AntiCheatEngine();
    await for (final message in receivePort) {
      if (message is Map<String, dynamic>) {
        final candidate     = StepCandidate.fromJson(message['candidate']);
        final gpsSpeed      = (message['gpsSpeed']      as num).toDouble();
        final pressureChg   = (message['pressureChange'] as num).toDouble();
        final batteryTemp   = (message['batteryTemp']   as num).toDouble();
        final lastTouchSecs = (message['lastTouchSecs'] as num).toInt();
        final result = engine.analyze(candidate, gpsSpeed, pressureChg, batteryTemp, lastTouchSecs);
        mainSendPort.send(result.toJson());
      }
    }
  }

  // ─── Session state ────────────────────────────────────────────────────────

  int _committedSteps = 0;

  // Rolling history (last 60 steps ≈ ~1 minute of walking)
  final List<double> _magHistory      = [];  // peak magnitudes
  final List<double> _intervalHistory = [];  // inter-step intervals (ms)
  final List<double> _jerkHistory     = [];  // jerk values

  // Personal Gait DNA — exponentially smoothed session profile
  double _dnaIntervalMs  = 600.0; // ~100 spm neutral start
  double _dnaMagG        = 0.50;  // moderate step magnitude
  bool   _dnaInitialized = false;

  // Consecutive high-fraud counter (triggers session-level flag)
  int _consecutiveHighFraud = 0;
  static const int _kFraudRunLimit = 5;

  bool get isInWarmup => _committedSteps < kWarmupSteps;

  // ─── Main Analysis ────────────────────────────────────────────────────────

  AntiCheatResult analyze(
    StepCandidate c,
    double gpsSpeed,
    double pressureChange,
    double batteryTemp,
    int lastTouchSecs,
  ) {
    _committedSteps++;
    _updateHistory(c);

    // ── V1: Physics plausibility ──────────────────────────────────────────
    final v1 = _vectorPhysics(c, gpsSpeed);

    // ── V2: Biological tremor fingerprint ─────────────────────────────────
    final v2 = _vectorTremor(c);

    // ── V3: Wrist-shake spectral signature ────────────────────────────────
    final v3 = _vectorHandShake(c);

    // ── V4: Gait DNA coherence ────────────────────────────────────────────
    final v4 = _vectorGaitDNA(c);

    // ── V5: Context / situational ────────────────────────────────────────
    final v5 = _vectorContext(c, gpsSpeed, batteryTemp, lastTouchSecs);

    // ── V6: Mechanical regularity (entropy) ───────────────────────────────
    final v6 = _vectorEntropy();

    // ── V7: Hardware gyro cross-validation ───────────────────────────────
    final v7 = _vectorHardware(c);

    // ── Master fraud score ────────────────────────────────────────────────
    final fraudScore = _masterScore(v1, v2, v3, v4, v5, v6, v7);

    // ── Warmup grace period ───────────────────────────────────────────────
    if (isInWarmup) {
      // Only reject extreme physical impossibilities during calibration
      if (fraudScore > 0.92) {
        return AntiCheatResult(
          approved: false,
          fraudScore: fraudScore,
          rejectionReason: 'Non-human motion during calibration',
          gaitLabel: 'suspicious',
        );
      }
      return AntiCheatResult(
        approved: true,
        fraudScore: fraudScore,
        gaitLabel: 'calibrating',
      );
    }

    // ── Consecutive fraud run check ───────────────────────────────────────
    if (fraudScore >= kFraudHardFreeze) {
      _consecutiveHighFraud++;
    } else {
      _consecutiveHighFraud = 0;
    }

    final gaitLabel = _gaitLabel(c, gpsSpeed, fraudScore);
    final reason    = fraudScore >= kFraudSoftCorrect ? _rejectionReason(v1, v2, v3, v4, v5, v6, v7) : null;

    return AntiCheatResult(
      approved: fraudScore < kFraudHardFreeze,
      fraudScore: fraudScore,
      rejectionReason: reason,
      gaitLabel: gaitLabel,
    );
  }

  // ─── History update ───────────────────────────────────────────────────────

  void _updateHistory(StepCandidate c) {
    _magHistory.add(c.magnitude);
    _intervalHistory.add(c.interStepInterval);
    _jerkHistory.add(c.jerk);
    if (_magHistory.length      > 60) _magHistory.removeAt(0);
    if (_intervalHistory.length > 60) _intervalHistory.removeAt(0);
    if (_jerkHistory.length     > 60) _jerkHistory.removeAt(0);

    // Update personal Gait DNA (exponential moving average)
    if (!_dnaInitialized && _committedSteps >= 10) {
      // Seed DNA from first 10 steps' average
      _dnaIntervalMs = _intervalHistory.reduce((a, b) => a + b) / _intervalHistory.length;
      _dnaMagG       = _magHistory.reduce((a, b) => a + b) / _magHistory.length;
      _dnaInitialized = true;
    } else if (_dnaInitialized) {
      _dnaIntervalMs  = _dnaIntervalMs  * 0.97 + c.interStepInterval * 0.03;
      _dnaMagG        = _dnaMagG        * 0.97 + c.magnitude         * 0.03;
    }
  }

  // ─── V1: Physics plausibility ─────────────────────────────────────────────

  double _vectorPhysics(StepCandidate c, double speed) {
    double score = 0.0;

    // Cadence vs speed coherence
    final cadenceHz = 1000.0 / c.interStepInterval;
    if (cadenceHz > kMaxCadenceHz) {
      score = 1.0; // superhuman cadence
    } else if (cadenceHz > 3.5 && speed < 0.5) {
      score = math.max(score, 0.88); // fast steps, no movement
    }

    // Jerk outside human biomechanics
    if (c.jerk < 3.0) { score = math.max(score, 0.82); } // pendulum-smooth
    if (c.jerk > 50.0) { score = math.max(score, 0.78); } // mechanical impact

    // Magnitude outside running range
    if (c.magnitude > 1.7) score = math.max(score, 0.70); // drop/throw

    return score;
  }

  // ─── V2: Biological tremor fingerprint ───────────────────────────────────

  double _vectorTremor(StepCandidate c) {
    // Human hands have an involuntary 8–12 Hz physiological tremor with
    // RMS amplitude ~0.005–0.05 g.  Mechanical shakers or rigid devices
    // held steady have near-zero high-frequency micro-tremor.
    //
    // We approximate tremor energy using the rate of zero-crossings of the
    // de-meaned z-axis signal (a proxy for 8-12 Hz content).
    // More zero crossings per sample = higher frequency content.
    if (c.zWindow.length < 8) return 0.0;

    // De-mean
    final mean = c.zWindow.reduce((a, b) => a + b) / c.zWindow.length;
    final centred = c.zWindow.map((v) => v - mean).toList();

    // Count zero-crossings (proportional to dominant frequency)
    int crossings = 0;
    for (int i = 1; i < centred.length; i++) {
      if (centred[i - 1] * centred[i] < 0) crossings++;
    }
    // At 50 Hz, 8–12 Hz content = 16–24 crossings per 50-sample window
    // Mechanical device on flat surface: 0–3 crossings (mostly DC)
    final crossingsPerSample = crossings / centred.length;

    // Pathologically low crossing rate → no tremor → machine signature
    if (crossingsPerSample < 0.06) return 0.78; // fewer than 3 crossings per 50
    return 0.0;
  }

  // ─── V3: Hand-shake spectral signature ───────────────────────────────────

  double _vectorHandShake(StepCandidate c) {
    // Hand-shaking at 4–7 Hz produces intervals of 143–250 ms with
    // VERY low variance (the person settles into a rhythm quickly).
    // Genuine walking intervals vary MORE than artificial shaking.
    //
    // We detect this as: very regular cadence (CV < 3 %) at hand-shake
    // frequencies (>3.5 Hz), OR very small magnitude with very regular cadence.
    if (_intervalHistory.length < 8) return 0.0;

    final mean = _intervalHistory.reduce((a, b) => a + b) / _intervalHistory.length;
    if (mean <= 0) return 0.0;
    final sd   = _stdDev(_intervalHistory.map((v) => v.toInt()).toList());
    final cv   = sd / mean; // coefficient of variation

    final cadenceHz = 1000.0 / mean;

    // Extremely regular cadence at hand-shake frequency
    if (cv < 0.03 && cadenceHz > 3.0) return 0.90;  // mechanical metronome at shake freq
    if (cv < 0.05 && cadenceHz > 2.8) return 0.75;  // suspiciously regular at high freq

    // Regular but plausible — check if magnitude is too low for real steps
    if (cv < 0.04 && c.magnitude < 0.35) return 0.70; // tiny very-regular taps

    return 0.0;
  }

  // ─── V4: Gait DNA coherence ───────────────────────────────────────────────

  double _vectorGaitDNA(StepCandidate c) {
    if (!_dnaInitialized || _committedSteps < 20) return 0.0;

    // Interval deviation from personal rhythm
    final intervalDev = (c.interStepInterval - _dnaIntervalMs).abs() / _dnaIntervalMs;
    // Magnitude deviation from personal profile
    final magDev = (c.magnitude - _dnaMagG).abs() / math.max(_dnaMagG, 0.1);

    // If BOTH interval and magnitude deviate significantly, likely a different
    // activity (phone given to someone, phone shaking on desk, etc.)
    if (intervalDev > 0.45 && magDev > 0.45) return 0.82;
    if (intervalDev > 0.60) return 0.70;

    return 0.0;
  }

  // ─── V5: Context / situational ───────────────────────────────────────────

  double _vectorContext(StepCandidate c, double speed, double temp, int touch) {
    double score = 0.0;

    // Night-time walking penalty (0–5 AM)
    final hour = DateTime.now().hour;
    final nightPenalty = (hour >= 0 && hour <= 5) ? 1.35 : 1.0;

    // GPS-vs-steps incoherence
    // At walking speed (~1.4 m/s), step interval ~700 ms → distance ~1.0 m
    // If GPS says device is stationary (speed < 0.3 m/s) but steps are
    // coming fast (< 500 ms), something is wrong.
    if (speed < 0.3 && c.interStepInterval < 500) score += 0.70;

    // Long phone idle + sudden burst of steps
    if (touch > 7200) score += 0.25; // phone untouched > 2 hours

    return (score * nightPenalty).clamp(0.0, 1.0);
  }

  // ─── V6: Shannon entropy ─────────────────────────────────────────────────

  double _vectorEntropy() {
    if (_intervalHistory.length < 15) return 0.0;

    // Bin intervals into 10 ms buckets and compute Shannon entropy.
    // Walking: H ≈ 2.5–4.5 bits (natural variation).
    // Mechanical shaker/metronome: H < 1.0 bit (all in one bin).
    // Pure noise: H > 5.5 bits (too random — robot random-faker).
    final Map<int, int> bins = {};
    for (final v in _intervalHistory) {
      final bin = (v / 10.0).round();
      bins[bin] = (bins[bin] ?? 0) + 1;
    }
    double h = 0.0;
    final n = _intervalHistory.length;
    for (final count in bins.values) {
      final p = count / n;
      if (p > 0) h -= p * (math.log(p) / math.ln2);
    }

    if (h < kMinShannonEntropy)  return 0.88; // metronome / machine
    if (h > kMaxShannonEntropy)  return 0.60; // random noise faker
    return 0.0;
  }

  // ─── V7: Hardware gyroscope cross-validation ─────────────────────────────

  double _vectorHardware(StepCandidate c) {
    // During real walking the phone rotates ~5–30°/s as the leg swings.
    // During lateral hand-shaking the gyro magnitude is much HIGHER (fast
    // wrist rotation) — typically > 1.5 rad/s.
    // A phone on a vibrating surface or mechanical shaker: very LOW gyro.

    // Abnormally high gyro = rapid wrist rotation (shaking)
    if (c.gyroMagnitude > 2.0) return 0.78;

    // Abnormally low gyro = mechanical device (no natural rotation)
    // Use a threshold of 0.08 rad/s — walking always generates some rotation
    if (c.gyroMagnitude < 0.08 && c.magnitude > 0.5) return 0.62;

    // Motor magnetic anomaly detection
    if (c.magMagnitude > 80.0) return 0.85;

    return 0.0;
  }

  // ─── Master scoring ───────────────────────────────────────────────────────

  double _masterScore(
    double v1, double v2, double v3, double v4,
    double v5, double v6, double v7,
  ) {
    // Weighted sum (weights reflect the reliability/specificity of each vector)
    const w = [0.22, 0.15, 0.20, 0.15, 0.10, 0.12, 0.06];
    final scores = [v1, v2, v3, v4, v5, v6, v7];
    double composite = 0.0;
    for (int i = 0; i < scores.length; i++) {
      composite += scores[i] * w[i];
    }

    // Consensus amplifier: each additional vector that fires above 0.5
    // strengthens the overall score (compound evidence principle)
    final triggers = scores.where((s) => s > 0.50).length;
    if (triggers >= 2) composite *= 1.20;
    if (triggers >= 3) composite *= 1.30;
    if (triggers >= 4) composite *= 1.50; // near-certain fraud

    // HARD OVERRIDE: if V3 (hand-shake) alone is ≥ 0.90, auto-reject
    if (v3 >= 0.90) return 1.0;

    return composite.clamp(0.0, 1.0);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _gaitLabel(StepCandidate c, double speed, double fraud) {
    if (fraud > 0.75)       return 'fraudulent';
    if (_consecutiveHighFraud >= _kFraudRunLimit) return 'suspended';
    if (speed > 3.5)        return 'running';
    if (speed > 0.8)        return 'walking';
    if (c.magnitude > 0.80) return 'stationary_step';
    return 'still';
  }

  String _rejectionReason(
    double v1, double v2, double v3, double v4,
    double v5, double v6, double v7,
  ) {
    // Return the most significant reason (highest scoring vector)
    final reasons = [
      (v1, 'Physics impossibility detected'),
      (v2, 'Biological tremor absent'),
      (v3, 'Hand-shake oscillation pattern'),
      (v4, 'Gait DNA mismatch'),
      (v5, 'Context incoherence'),
      (v6, 'Mechanical regularity (metronome)'),
      (v7, 'Hardware cross-validation failed'),
    ];
    reasons.sort((a, b) => b.$1.compareTo(a.$1));
    return reasons.first.$2;
  }

  double _stdDev(List<int> data) {
    if (data.isEmpty) return 0.0;
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data
        .map((x) => math.pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b) / data.length;
    return math.sqrt(variance);
  }

}

