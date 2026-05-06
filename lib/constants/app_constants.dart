// App-wide constants — no magic numbers anywhere else in the codebase.

/// Default daily step goal.
const int kDefaultDailyGoal = 8000;

/// Average stride length in kilometres (avg adult: ~76.2 cm).
const double kStrideKm = 0.000762;

/// Kilocalories burned per step (generic estimate).
const double kCaloriesPerStep = 0.04;

/// UI Design tokens.
const kPrimaryColor = 0xFF4F46E5;         // Indigo
const kBackgroundColor = 0xFFF8FAFF;
const kSurfaceColor = 0xFFFFFFFF;
const kCardRadius = 16.0;
const kCardShadowBlur = 12.0;
const kCardShadowOpacity = 0.07;

/// Activity status labels.
const String kStatusWalking   = 'WALKING';
const String kStatusRunning   = 'RUNNING';
const String kStatusStill     = 'STILL';
const String kStatusVehicle   = 'IN_VEHICLE';
const String kStatusUnknown   = 'UNKNOWN';

/// Minimum splash display time (milliseconds).
const int kSplashMinDurationMs = 1800;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 7-LAYER PIPELINE & ANTI-CHEAT CONSTANTS (ELITE CURATED MODE)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const double kMinWalkHz            = 0.85; // ELITE: Re-tightened to block all arm waving
const double kMaxWalkHz            = 3.0;  
const double kShakeRejectHz        = 3.8;  // ELITE: Rejects erratic shaking much earlier
const int    kCadenceScoreThreshold = 3;   // ELITE: Requires 1.5s of perfect rhythm
const double kMinStdDev            = 0.25; // ELITE: Requires heavy foot-strike energy
const double kMaxStdDev            = 10.0; 
const int    kCommitThreshold      = 6;    // ELITE: 6-step verification buffer
const int    kMaxStepsPerEvent     = 30;   
const double kMaxStepsPerSecond    = 4.0;  
const double kVehicleSpeedMs       = 7.0;  // ~25km/h
const double kVehicleClearMs       = 4.0;  
const int    kVehicleConfirmSec    = 4;    
const int    kVehicleClearSec      = 5;
const int    kGpsStopSec           = 30;
const double kMachineAutocorr      = 0.82; // ELITE: Blocks "Too Perfect" rhythmic shaking
const int    kSuspiciousFreezeSec  = 120;  // ELITE: Longer penalty for cheaters
const double kGravity              = 9.81;
const int    kBufferSize           = 128;
const int    kVarianceWindow       = 64;
const int    kCadenceCheckMs       = 500;
const int    kAccelSampleMs        = 20;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ACCURACY FIX CONSTANTS (v3)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const int    kMaxHoldBuffer        = 20;
const int    kHoldTimeoutMs        = 2000; 
const int    kMaxReconcileDrift    = 20;   
const int    kReconcileIntervalSec = 10;    
