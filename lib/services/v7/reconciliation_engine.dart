import 'dart:async';
import '../../constants/step_constants.dart';
import '../../utils/logger.dart';

/// STAGE 7 — RECONCILIATION.
/// 
/// Ensures software step counting never deviates significantly from 
/// the hardware motion co-processor (Ground Truth).
class ReconciliationEngine {
  int _baseDailySteps = 0;
  int _sessionSoftwareDelta = 0;

  Future<void> initialize(int savedSteps) async {
    _baseDailySteps = savedSteps;
    _sessionSoftwareDelta = 0;
    AppLogger.i('Reconcile', 'Initial base daily count: $_baseDailySteps');
  }

  /// Syncs software session delta against hardware ground truth.
  /// 
  /// Returns the corrected total daily step count.
  int reconcile(int sessionSoftwareDelta, int sessionHardwareDelta, int totalRejected) {
    _sessionSoftwareDelta = sessionSoftwareDelta;

    // 1. Snap down if overcounting by >15%
    final maxAllowed = (sessionHardwareDelta * (1.0 + AppConfig.kHardwareGroundTruthTolerance)).toInt();
    if (sessionHardwareDelta > 0 && _sessionSoftwareDelta > maxAllowed) {
      AppLogger.w('Reconcile', 'Overcount detected! Sw=$_sessionSoftwareDelta, Hw=$sessionHardwareDelta. Snapping down.');
      _sessionSoftwareDelta = sessionHardwareDelta;
    }

    // 2. Recovery if undercounting by >8%
    // CRITICAL ANTI-CHEAT OVERRIDE: 
    // Do NOT recover steps if the AI explicitly detected and rejected them as fraud (shaking)!
    final minExpected = (sessionHardwareDelta * (1.0 - AppConfig.kRecoverMissedPct)).toInt();
    final totalProcessedByAi = _sessionSoftwareDelta + totalRejected;
    
    if (sessionHardwareDelta > 0 && _sessionSoftwareDelta < minExpected) {
      if (totalProcessedByAi >= sessionHardwareDelta) {
         AppLogger.i('Reconcile', 'Hardware delta is higher, but AI rejected $totalRejected fraud steps. Blocking hardware recovery.');
      } else {
         AppLogger.i('Reconcile', 'Undercount detected. Recovering steps: ${sessionHardwareDelta - _sessionSoftwareDelta}');
         _sessionSoftwareDelta = sessionHardwareDelta;
      }
    }

    return _baseDailySteps + _sessionSoftwareDelta;
  }

  /// Recovers steps after a crash or restart by comparing hardware delta.
  Future<int> recoverAfterRestart(int lastHardwareTotal, int currentHardwareTotal) async {
    final delta = currentHardwareTotal - lastHardwareTotal;
    if (delta > 0) {
      AppLogger.i('Reconcile', 'Recovered $delta steps from hardware co-processor.');
      return delta;
    }
    return 0;
  }
}
