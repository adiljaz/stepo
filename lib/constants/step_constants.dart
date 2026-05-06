// Stepooo v4.0 — Zero-Delay Production Engine Constants
// All units are in SI (meters, seconds, g-force) unless specified.

/// Default daily step goal.
const int kDefaultDailyGoal = 8000;

/// Average stride length in kilometers.
const double kStrideKm = 0.000762;
const double kDefaultStrideMeter = 0.762;

/// Energy expenditure estimates.
const double kCaloriesPerStepWalk = 0.04;
const double kCaloriesPerStepRun = 0.07;

// ─────────────────────────────────────────────────────────────────────────
// LAYER 1: SIGNAL CONDITIONING
// ─────────────────────────────────────────────────────────────────────────

// --- Anti-Cheat Core Thresholds ---
const double kMaxCadenceHz = 4.5;         // Usain Bolt limit
const double kMinTremorRms = 0.003;       // Human biological floor (8-12Hz)
const double kMagneticAnomalyLimit = 20.0; // uT above baseline (motor detection)
const double kMinAsymmetryRatio = 0.04;   // 4% natural human variation
const double kMaxAsymmetryRatio = 0.20;   // 20% limit for normal gait
const double kMinShannonEntropy = 1.0;    // <1.0 is mechanical/metronome
const double kMaxShannonEntropy = 5.0;    // >5.0 is random noise
const double kMinGyroCorrelation = 0.40;  // Correlation between gyro/accel
const double kMaxGpsEnergyRatio = 1.8;    // Max distance/step ratio

// --- Anti-Cheat Actions ---
const double kFraudSoftCorrect = 0.50;    // Start silent corrections
const double kFraudHardFreeze = 0.75;     // Stop counting entirely
const double kFraudSessionFlag = 0.95;    // Mark entire session invalid

// --- Existing Constants ---
const double kSamplingRateHz = 50.0;
const int kCircularBufferSize = 256;
const int kFilterWindowSize = 256;
const int kRmsWindowSize = 64;
const double kLowCutoffHz = 0.5;
const double kHighCutoffHz = 5.0;

// ─────────────────────────────────────────────────────────────────────────
// LAYER 2: PEAK DETECTION (The Zero-Delay Trigger)
// ─────────────────────────────────────────────────────────────────────────

const double kBaseThresholdG = 0.30; // Lowered from 1.1 for higher sensitivity
const int kThresholdAdaptionWindow = 8;
const double kThresholdAdaptionWeight = 0.6;
const int kMinStepIntervalMs = 250; // Lowered from 350 to allow up to 240 bpm
const int kWarmupSteps = 30; // Steps needed for calibration
const int kRisingEdgeWindowMs = 100;
const int kPeakLocalMaxWindow = 3;

// ─────────────────────────────────────────────────────────────────────────
// LAYER 3: ANOMALY SCORING
// ─────────────────────────────────────────────────────────────────────────

const int kAnomalyWindowSize = 8;
const double kMachineCvThreshold = 0.02;
const double kHumanCvThreshold = 0.08;
const double kShakeFreqThresholdHz = 3.2;
const double kShakeMagThresholdG = 2.0;
const double kMinVerticalAxisRatio = 0.40;
const double kTargetVerticalAxisRatio = 0.55;
const double kMachineAutocorrThreshold = 0.92;
const double kHumanAutocorrThreshold = 0.70;

const double kAnomalyScoreReject = 0.65;
const int kMaxConsecutiveRejections = 20;

// ─────────────────────────────────────────────────────────────────────────
// LAYER 4: PERSONAL CALIBRATION
// ─────────────────────────────────────────────────────────────────────────

const int kCalibrationMinSteps = 10;
const int kCalibrationDoneSteps = 30;

// ─────────────────────────────────────────────────────────────────────────
// LAYER 6: FENCING
// ─────────────────────────────────────────────────────────────────────────

const double kVehicleSpeedThresholdMs = 7.5; // 27 km/h
const double kVehicleClearSpeedMs = 5.0;
const int kVehicleConfirmDurationSec = 5;
const double kStillRmsThresholdG = 0.03;
const double kMotionRmsThresholdG = 0.05;
const int kStillDetectionSec = 8;

// ─────────────────────────────────────────────────────────────────────────
// LAYER 8: HEALTH SYNC
// ─────────────────────────────────────────────────────────────────────────

const int kHealthSyncIntervalSec = 60;

// ─────────────────────────────────────────────────────────────────────────
// LAYER 9: RECONCILIATION
// ─────────────────────────────────────────────────────────────────────────

const int kReconcileIntervalSec = 10;
const double kHardwareMissThreshold = 1.15;
const double kSoftwareOvercountThreshold = 1.20;

// ─────────────────────────────────────────────────────────────────────────
// UI DESIGN TOKENS (Premium Palette)
// ─────────────────────────────────────────────────────────────────────────

const kPrimaryColor = 0xFF5D5FEF; // Modern Electric Indigo
const kSecondaryColor = 0xFFFF6B6B; // Soft Coral
const kAccentColor = 0xFF00D2FF;  // Cyan Accent
const kSuccessColor = 0xFF34C759; // Apple-style Green
const kWarningColor = 0xFFFF9500; // Apple-style Orange
const kErrorColor = 0xFFFF3B30;   // Apple-style Red
const kBackgroundColor = 0xFFF2F4F7; // Ultra-clean off-white
const kSurfaceColor = 0xFFFFFFFF;
const kTextColor = 0xFF1D1D1F; // Apple-style dark gray
const kSecondaryTextColor = 0xFF86868B; // Apple-style muted gray

const int kSplashMinDurationMs = 2200;
