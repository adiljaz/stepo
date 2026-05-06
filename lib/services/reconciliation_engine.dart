import '../constants/step_constants.dart';

class ReconciliationResult {
  final int correctionAmount;
  final bool triggerAnomalyReview;

  ReconciliationResult({
    required this.correctionAmount,
    required this.triggerAnomalyReview,
  });
}

class ReconciliationEngine {
  int _lastKnownHardwareCount = 0;
  int _lastKnownSoftwareCount = 0;

  ReconciliationResult reconcile({
    required int currentHardwareCount,
    required int currentSoftwareCount,
  }) {
    final hardwareDelta = currentHardwareCount - _lastKnownHardwareCount;
    final softwareDelta = currentSoftwareCount - _lastKnownSoftwareCount;

    int correction = 0;
    bool triggerReview = false;

    // Rule 1: Hardware > Software by significant margin (true miss)
    if (hardwareDelta > softwareDelta * kHardwareMissThreshold && hardwareDelta > 5) {
      correction = hardwareDelta - softwareDelta;
    }

    // Rule 2: Software > Hardware by significant margin (possible anomaly)
    if (softwareDelta > hardwareDelta * kSoftwareOvercountThreshold && softwareDelta > 10) {
      triggerReview = true;
    }

    // Rule 3: Perfect agreement or small diff - no action

    _lastKnownHardwareCount = currentHardwareCount;
    _lastKnownSoftwareCount = currentSoftwareCount + correction;

    return ReconciliationResult(
      correctionAmount: correction,
      triggerAnomalyReview: triggerReview,
    );
  }

  void setInitialBaseline(int hardware, int software) {
    _lastKnownHardwareCount = hardware;
    _lastKnownSoftwareCount = software;
  }
}
