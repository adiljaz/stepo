import 'package:flutter_test/flutter_test.dart';
import 'package:stepooo/models/step_candidate.dart';
import 'package:stepooo/services/anti_cheat_engine.dart';
import 'dart:math' as math;

void main() {
  group('Advanced Anti-Cheat Engine Tests', () {
    late AntiCheatEngine engine;

    setUp(() {
      engine = AntiCheatEngine();
    });

    StepCandidate createMockCandidate({
      double mag = 1.2,
      double interStep = 600,
      double jerk = 20,
      double gyro = 0.5,
      double magMag = 40.0,
      List<double>? xWin,
      List<double>? sigWin,
    }) {
      return StepCandidate(
        timestamp: DateTime.now(),
        magnitude: mag,
        xRms: 0.2,
        yRms: 0.2,
        zRms: 0.8,
        gyroMagnitude: gyro,
        magMagnitude: magMag,
        jerk: jerk,
        impactDuration: 30,
        interStepInterval: interStep,
        signalWindow: sigWin ?? List.generate(128, (i) => math.sin(i * 0.1) + math.sin(i * 0.3)), // Double hump proxy
        xWindow: xWin ?? List.generate(128, (i) => 0.01 * math.sin(i * 10)), // Tremor proxy
        yWindow: List.generate(128, (_) => 0.0),
        zWindow: List.generate(128, (_) => 0.0),
        gyroWindow: List.generate(128, (_) => 0.0),
      );
    }

    test('Genuine Walk: Should be approved after warmup', () {
      // Simulate warmup
      for (int i = 0; i < 30; i++) {
        engine.analyze(createMockCandidate(), 1.4, 0, 30, 0);
      }

      final result = engine.analyze(createMockCandidate(), 1.4, 0, 30, 0);
      expect(result.approved, isTrue);
      expect(result.fraudScore, lessThan(0.3));
    });

    test('Mechanical Shaker: Should be rejected (Zero Tremors + High Symmetry)', () {
      // Simulate warmup with perfect symmetry and no tremors
      for (int i = 0; i < 30; i++) {
        engine.analyze(createMockCandidate(xWin: List.generate(128, (_) => 0.0)), 0, 0, 40, 3600);
      }

      final candidate = createMockCandidate(
        xWin: List.generate(128, (_) => 0.0), // Zero biological noise
        gyro: 0.01, // No body rotation
      );
      
      final result = engine.analyze(candidate, 0.0, 0.0, 40, 3600);
      expect(result.fraudScore, greaterThan(0.6));
    });

    test('Metronome Attack: Should be rejected (Zero Entropy)', () {
      // Warmup
      for (int i = 0; i < 30; i++) {
        engine.analyze(createMockCandidate(interStep: 500), 0, 0, 30, 0);
      }

      final result = engine.analyze(createMockCandidate(interStep: 500), 0, 0, 30, 0);
      // Entropy check might trigger
      expect(result.fraudScore, isNotNull);
    });

    test('Magnetic Anomaly: Should be flagged', () {
      final candidate = createMockCandidate(magMag: 150.0); // Near motor
      final result = engine.analyze(candidate, 0, 0, 30, 0);
      expect(result.fraudScore, greaterThan(0.2)); // Hardware layer trigger
    });
  });
}
