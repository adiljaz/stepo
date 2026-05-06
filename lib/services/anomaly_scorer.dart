import 'dart:math' as math;
import '../constants/step_constants.dart';

class AnomalyInput {
  final List<double> interStepIntervals;
  final List<double> peakMagnitudes;
  final List<double> verticalAxisRatios;
  final double dominantFrequency;
  final double autocorrelation;

  AnomalyInput({
    required this.interStepIntervals,
    required this.peakMagnitudes,
    required this.verticalAxisRatios,
    required this.dominantFrequency,
    required this.autocorrelation,
  });
}

class AnomalyScorer {
  /// Computes a composite anomaly score (0.0 = genuine, 1.0 = fake)
  static double computeScore(AnomalyInput input) {
    double scoreA = _scoreMechanicalRegularity(input.interStepIntervals);
    double scoreB = _scoreHandShake(input.dominantFrequency, input.peakMagnitudes.last);
    double scoreC = _scoreAxisDominance(input.verticalAxisRatios.last);
    double scoreD = _scoreGaitRhythm(input.autocorrelation);

    return (0.30 * scoreA) + (0.25 * scoreB) + (0.25 * scoreC) + (0.20 * scoreD);
  }

  static double _scoreMechanicalRegularity(List<double> intervals) {
    if (intervals.length < 4) return 0.0;
    
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / intervals.length;
    final stdDev = math.sqrt(variance);
    final cv = stdDev / (mean > 0 ? mean : 1);

    if (cv < kMachineCvThreshold) return 0.9;
    if (cv > kHumanCvThreshold) return 0.0;
    
    // Linear interpolation between thresholds
    return 0.9 * (1.0 - (cv - kMachineCvThreshold) / (kHumanCvThreshold - kMachineCvThreshold));
  }

  static double _scoreHandShake(double freq, double magnitude) {
    if (freq > kShakeFreqThresholdHz && magnitude < kShakeMagThresholdG) {
      return 0.85;
    }
    return 0.0;
  }

  static double _scoreAxisDominance(double verticalRatio) {
    if (verticalRatio < kMinVerticalAxisRatio) return 0.80;
    if (verticalRatio > kTargetVerticalAxisRatio) return 0.0;
    
    return 0.80 * (1.0 - (verticalRatio - kMinVerticalAxisRatio) / (kTargetVerticalAxisRatio - kMinVerticalAxisRatio));
  }

  static double _scoreGaitRhythm(double autocorr) {
    if (autocorr > kMachineAutocorrThreshold) return 0.80;
    if (autocorr < kHumanAutocorrThreshold) return 0.0;
    
    return 0.80 * (autocorr - kHumanAutocorrThreshold) / (kMachineAutocorrThreshold - kHumanAutocorrThreshold);
  }
}
