enum AISensitivity { strict, normal, forgiving }

class UserProfile {
  final String name;
  final int ageYears;
  final double weightKg;
  final double heightCm;
  final String sex; // 'male' | 'female'
  final int dailyGoalSteps;
  final double strideLengthMeters;
  final AISensitivity aiSensitivity;

  const UserProfile({
    this.name = '',
    this.ageYears = 30,
    this.weightKg = 70,
    this.heightCm = 170,
    this.sex = 'male',
    this.dailyGoalSteps = 8000,
    this.strideLengthMeters = 0.762, // Default human average
    this.aiSensitivity = AISensitivity.normal,
  });

  UserProfile copyWith({
    String? name,
    int? ageYears,
    double? weightKg,
    double? heightCm,
    String? sex,
    int? dailyGoalSteps,
    double? strideLengthMeters,
    AISensitivity? aiSensitivity,
  }) =>
      UserProfile(
        name: name ?? this.name,
        ageYears: ageYears ?? this.ageYears,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        sex: sex ?? this.sex,
        dailyGoalSteps: dailyGoalSteps ?? this.dailyGoalSteps,
        strideLengthMeters: strideLengthMeters ?? this.strideLengthMeters,
        aiSensitivity: aiSensitivity ?? this.aiSensitivity,
      );
}

