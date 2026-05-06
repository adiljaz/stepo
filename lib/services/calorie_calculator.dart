/// MET (Metabolic Equivalent of Task) calorie calculator.
///
/// MET values sourced from the 2011 Compendium of Physical Activities
/// (Ainsworth et al., Med Sci Sports Exerc 43(8):1575-81).
///
/// Formula: Calories = MET × weight_kg × duration_hours
///
/// The gait classifier determines which MET value to apply:
///   Walking (3.2–4.8 km/h)  → MET 3.5
///   Brisk walk (>4.8 km/h)  → MET 5.0
///   Running (8 km/h+)        → MET 7.0
class CalorieCalculator {
  /// MET values indexed by gait intensity label.
  static const Map<String, double> _metValues = {
    'still':          0.9, // seated rest
    'shuffling':      2.0, // slow shuffle
    'walking':        3.5, // normal walk
    'brisk_walk':     5.0, // brisk walk
    'running':        7.0, // jogging / running
    'calibrating':    3.5, // assume walk during warmup
    'stationary_step':2.5, // on-the-spot stepping
    'fraudulent':     0.0, // rejected — no calories
  };

  /// Calculates calories burned for [steps] at [gaitLabel] gait.
  ///
  /// [weightKg] : user body weight in kg
  /// [stepIntervalMs] : average milliseconds per step (used to derive duration)
  static double calculate({
    required int steps,
    required double weightKg,
    required String gaitLabel,
    required double stepIntervalMs,
  }) {
    if (steps <= 0 || stepIntervalMs <= 0) return 0;

    final met = _metValues[gaitLabel] ?? 3.5;
    final durationHours = (steps * stepIntervalMs) / (1000.0 * 3600.0);
    return met * weightKg * durationHours;
  }
}
