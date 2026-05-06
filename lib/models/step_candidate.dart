import 'dart:math' as math;

class StepCandidate {
  final DateTime timestamp;
  final double magnitude;
  final double xRms;
  final double yRms;
  final double zRms;
  final double gyroMagnitude;
  final double magMagnitude; // Magnetometer magnitude
  final double jerk;
  final double impactDuration;
  final double interStepInterval;
  final List<double> signalWindow; // Last 128 samples (Magnitude)
  final List<double> xWindow; // Raw X for asymmetry/tremors
  final List<double> yWindow; 
  final List<double> zWindow;
  final List<double> gyroWindow;

  StepCandidate({
    required this.timestamp,
    required this.magnitude,
    required this.xRms,
    required this.yRms,
    required this.zRms,
    required this.gyroMagnitude,
    required this.magMagnitude,
    required this.jerk,
    required this.impactDuration,
    required this.interStepInterval,
    required this.signalWindow,
    required this.xWindow,
    required this.yWindow,
    required this.zWindow,
    required this.gyroWindow,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'magnitude': magnitude,
      'xRms': xRms,
      'yRms': yRms,
      'zRms': zRms,
      'gyroMagnitude': gyroMagnitude,
      'magMagnitude': magMagnitude,
      'jerk': jerk,
      'impactDuration': impactDuration,
      'interStepInterval': interStepInterval,
      'signalWindow': signalWindow,
      'xWindow': xWindow,
      'yWindow': yWindow,
      'zWindow': zWindow,
      'gyroWindow': gyroWindow,
    };
  }

  factory StepCandidate.fromJson(Map<String, dynamic> json) {
    return StepCandidate(
      timestamp: DateTime.parse(json['timestamp']),
      magnitude: json['magnitude'],
      xRms: json['xRms'],
      yRms: json['yRms'],
      zRms: json['zRms'],
      gyroMagnitude: (json['gyroMagnitude'] as num).toDouble(),
      magMagnitude: (json['magMagnitude'] as num).toDouble(),
      jerk: (json['jerk'] as num).toDouble(),
      impactDuration: (json['impactDuration'] as num).toDouble(),
      interStepInterval: (json['interStepInterval'] as num).toDouble(),
      signalWindow: (json['signalWindow'] as List).map((e) => (e as num).toDouble()).toList(),
      xWindow: (json['xWindow'] as List).map((e) => (e as num).toDouble()).toList(),
      yWindow: (json['yWindow'] as List).map((e) => (e as num).toDouble()).toList(),
      zWindow: (json['zWindow'] as List).map((e) => (e as num).toDouble()).toList(),
      gyroWindow: (json['gyroWindow'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class AntiCheatResult {
  final bool approved;
  final String? rejectionReason;
  final double fraudScore;
  final String gaitLabel;

  AntiCheatResult({
    required this.approved,
    this.rejectionReason,
    required this.fraudScore,
    required this.gaitLabel,
  });

  Map<String, dynamic> toJson() {
    return {
      'approved': approved,
      'rejectionReason': rejectionReason,
      'fraudScore': fraudScore,
      'gaitLabel': gaitLabel,
    };
  }

  factory AntiCheatResult.fromJson(Map<String, dynamic> json) {
    return AntiCheatResult(
      approved: json['approved'],
      rejectionReason: json['rejectionReason'],
      fraudScore: (json['fraudScore'] as num).toDouble(),
      gaitLabel: json['gaitLabel'],
    );
  }
}
