/// v7.0 Biomechanical Signal Snapshot.
class StepCandidate {
  final DateTime timestamp;
  final double magnitude;
  final double jerk;
  final double verticalAcc;
  
  // v7.0: 9-Axis Window for ML [1, 75, 9]
  final List<List<double>> featureWindow;

  StepCandidate({
    required this.timestamp,
    required this.magnitude,
    required this.jerk,
    required this.verticalAcc,
    required this.featureWindow,
  });
}

/// Result from the Stage 6 Confirmation Engine.
class ValidationResult {
  final bool approved;
  final String? reason;
  final int tier;
  final double mlConfidence;
  final double fftFreq;

  ValidationResult({
    required this.approved,
    this.reason,
    required this.tier,
    required this.mlConfidence,
    required this.fftFreq,
  });
}
