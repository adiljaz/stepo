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
  final String profileImage;
  final int streakCount;

  const UserProfile({
    this.name = '',
    this.ageYears = 30,
    this.weightKg = 70,
    this.heightCm = 170,
    this.sex = 'male',
    this.dailyGoalSteps = 8000,
    this.strideLengthMeters = 0.762, // Default human average
    this.aiSensitivity = AISensitivity.normal,
    this.profileImage = '',
    this.streakCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ageYears': ageYears,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'sex': sex,
      'dailyGoalSteps': dailyGoalSteps,
      'strideLengthMeters': strideLengthMeters,
      'aiSensitivity': aiSensitivity.index,
      'profileImage': profileImage,
      'streakCount': streakCount,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      ageYears: map['ageYears'] ?? 30,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170.0,
      sex: map['sex'] ?? 'male',
      dailyGoalSteps: map['dailyGoalSteps'] ?? 8000,
      strideLengthMeters: (map['strideLengthMeters'] as num?)?.toDouble() ?? 0.762,
      aiSensitivity: AISensitivity.values[map['aiSensitivity'] ?? 1],
      profileImage: map['profileImage'] ?? '',
      streakCount: map['streakCount'] ?? 0,
    );
  }

  UserProfile copyWith({
    String? name,
    int? ageYears,
    double? weightKg,
    double? heightCm,
    String? sex,
    int? dailyGoalSteps,
    double? strideLengthMeters,
    AISensitivity? aiSensitivity,
    String? profileImage,
    int? streakCount,
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
        profileImage: profileImage ?? this.profileImage,
        streakCount: streakCount ?? this.streakCount,
      );
}
