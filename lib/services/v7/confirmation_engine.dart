import '../../constants/step_constants.dart';
import '../../models/user_profile.dart';

enum ConfirmationTier {
  tier1Instant,
  tier2Fast,
  tier3Deep,
  tier4Reject
}

class ConfirmationResult {
  final ConfirmationTier tier;
  final bool approved;
  final String? reason;

  ConfirmationResult({required this.tier, required this.approved, this.reason});
}

/// STAGE 6 — SMART CONFIRMATION ENGINE.
/// 
/// 4-tier validation logic based on AI confidence and contextual signals.
class SmartConfirmationEngine {
  ConfirmationResult evaluate({
    required double mlConfidence,
    required int mlClass, // 0=WALK, 1=FAKE, 2=RUN
    required int hardwareDelta,
    required bool isiConsistent,
    required double fftFreq,
    required double spectralEntropy,
    required double gpsSpeedKmh,
    required AISensitivity sensitivity,
  }) {
    // ── TIER 4: HARD REJECT ──────────────────────────────────────────────────
    if (gpsSpeedKmh > 15.0) {
      return ConfirmationResult(tier: ConfirmationTier.tier4Reject, approved: false, reason: 'VEHICLE_SPEED');
    }
    if (fftFreq > AppConfig.kFftMechanicalFloor) {
      return ConfirmationResult(tier: ConfirmationTier.tier4Reject, approved: false, reason: 'MECHANICAL_FFT');
    }
    if (mlClass == 1) { // FAKE_MECHANICAL
      return ConfirmationResult(tier: ConfirmationTier.tier4Reject, approved: false, reason: 'ML_FAKE_CLASS');
    }

    // ── TIER 1: INSTANT ──────────────────────────────────────────────────────
    if (mlConfidence > AppConfig.getTier1MlThreshold(sensitivity) && 
        hardwareDelta > 0 && 
        isiConsistent && 
        fftFreq >= AppConfig.kFftDominantFreqMin && 
        fftFreq <= AppConfig.kFftRunFreqMax) {
      return ConfirmationResult(tier: ConfirmationTier.tier1Instant, approved: true);
    }

    // ── TIER 2: FAST (2s delay) ─────────────────────────────────────────────
    if (mlConfidence >= AppConfig.getTier2MlThreshold(sensitivity) && 
        gpsSpeedKmh <= 15.0 && 
        fftFreq <= AppConfig.kFftRunFreqMax) {
      return ConfirmationResult(tier: ConfirmationTier.tier2Fast, approved: true);
    }

    // ── TIER 3: DEEP (10s delay) ─────────────────────────────────────────────
    return ConfirmationResult(tier: ConfirmationTier.tier3Deep, approved: false, reason: 'DEEP_ANALYSIS_REQUIRED');
  }

  /// Final validation for Tier 3 after 10s window
  bool validateDeepConsensus({
    required double mlConfidence,
    required double fraudScore,
    required bool contextValid,
    required AISensitivity sensitivity,
  }) {
    return mlConfidence > AppConfig.getTier3MlThreshold(sensitivity) && 
           fraudScore < AppConfig.kTier3FraudLimit && 
           contextValid;
  }
}
