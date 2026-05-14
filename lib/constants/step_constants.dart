import 'package:flutter/material.dart';
import '../models/user_profile.dart';

/// Stepooo v7.0 — World-Class Biomechanical Engine Constants.
///
/// This configuration centralizes all thresholds for the 8-stage AI pipeline.
/// All physical units are in SI (m/s², rad/s, seconds) unless specified.
class AppConfig {
  // ── Project Identity ───────────────────────────────────────────────────────
  static const String kAppName = "Stepooo";
  static const String kAppVersion = "7.0.0-AI";

  // ── STAGE 1 & 2: SENSE & FILTER ───────────────────────────────────────────
  static const int kMinCalibrationTicks = 150; // ~3s at 50Hz
  static const double kGemaAlpha = 0.2;        // Gravity EMA alpha
  static const double kHpfAlpha = 0.85;        // Gravity removal alpha
  
  // Butterworth 2nd Order Band-pass (0.5Hz - 5.0Hz) @ 50Hz
  // b = [0.0976, 0, -0.0976], a = [1.0, -1.7869, 0.8048]
  static const List<double> kButterB = [0.0976, 0.0, -0.0976];
  static const List<double> kButterA = [1.0, -1.7869, 0.8048];

  // ── STAGE 3: DETECT (Pan-Tompkins Adaptive) ───────────────────────────────
  static const int kMinStepIntervalMs = 250;
  static const int kMaxStepIntervalMs = 2500;
  static const double kPeakThresholdStdWeight = 0.6;
  static const double kMaxIsiCv = 0.35;        // Symmetry check threshold
  
  // Jerk (m/s³) range
  static const double kMinJerk = 5.0;
  static const double kMaxJerk = 80.0;

  // Peak shape (ms)
  static const int kMinRiseTimeMs = 80;
  static const int kMaxRiseTimeMs = 200;
  static const int kMinFallTimeMs = 80;
  static const int kMaxFallTimeMs = 250;

  // ── STAGE 4: PARALLEL SOURCES ─────────────────────────────────────────────
  static const double kHardwareGroundTruthTolerance = 0.15; // 15% limit
  static const int kMlInputWindowSize = 75; // 1.5s at 50Hz
  static const int kMlFeatureCount = 9;     // Acc(3) + Gyro(3) + Vert + Mag + Jerk

  // ── STAGE 5: AI & ML VALIDATION ───────────────────────────────────────────
  static const double kMlMinConfidence = 0.85;
  static const double kFftDominantFreqMin = 0.8;
  static const double kFftDominantFreqMax = 2.5;
  static const double kFftRunFreqMax = 4.0;
  static const double kFftMechanicalFloor = 8.0;
  static const double kMaxSpectralEntropy = 0.78;

  // ── STAGE 6: SMART CONFIRMATION ───────────────────────────────────────────
  static const Duration kTier1Delay = Duration.zero;
  static const Duration kTier2Delay = Duration(seconds: 2);
  static const Duration kTier3Delay = Duration(seconds: 10);
  
  static double getTier1MlThreshold(AISensitivity s) => s == AISensitivity.strict ? 0.95 : (s == AISensitivity.normal ? 0.90 : 0.70);
  static double getTier2MlThreshold(AISensitivity s) => s == AISensitivity.strict ? 0.85 : (s == AISensitivity.normal ? 0.75 : 0.50);
  static double getTier3MlThreshold(AISensitivity s) => s == AISensitivity.strict ? 0.70 : (s == AISensitivity.normal ? 0.60 : 0.40);

  static const double kTier4FftThreshold = 0.85;
  static const double kTier3FraudLimit = 0.60;

  // ── STAGE 7: RECONCILIATION ───────────────────────────────────────────────
  static const Duration kReconcileInterval = Duration(seconds: 10);
  static const double kRecoverMissedPct = 0.08; // 8%

  // ── UI DESIGN TOKENS (Premium Palette) ────────────────────────────────────
  static const Color kPrimaryColor = Color(0xFF3B82F6); // Professional Blue
  static const Color kSecondaryColor = Color(0xFF2E2E2E); // Dark Grey
  static const Color kAccentColor = Color(0xFF06B6D4); // Electric Cyan
  static const Color kSuccessColor = Color(0xFF10B981); // Emerald Green
  static const Color kWarningColor = Color(0xFFF59E0B); // Amber
  static const Color kErrorColor = Color(0xFFEF4444); // Rose Red
  static const Color kBackgroundColor = Color(0xFF0F172A); // Deep Slate
  static const Color kSurfaceColor = Color(0xFF1E293B); // Elevated Slate
  static const Color kTextColor = Color(0xFFF8FAFC); // Off-White
  static const Color kSecondaryTextColor = Color(0xFF94A3B8); // Muted Slate

  // --- Constants ---
  static const double kStrideMeter = 0.762;
  static const double kCaloriesPerStepWalk = 0.04;
  static const double kCaloriesPerStepRun = 0.07;
}
