import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

const _kName        = 'profile_name';
const _kAge         = 'profile_age';
const _kWeight      = 'profile_weight';
const _kHeight      = 'profile_height';
const _kSex         = 'profile_sex';
const _kGoal        = 'profile_goal';
const _kOnboarded   = 'onboarding_complete';

class UserSettingsNotifier extends StateNotifier<UserProfile> {
  UserSettingsNotifier() : super(const UserProfile()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = UserProfile(
      name: p.getString(_kName) ?? '',
      ageYears: p.getInt(_kAge) ?? 30,
      weightKg: p.getDouble(_kWeight) ?? 70,
      heightCm: p.getDouble(_kHeight) ?? 170,
      sex: p.getString(_kSex) ?? 'male',
      dailyGoalSteps: p.getInt(_kGoal) ?? 8000,
    );
  }

  Future<void> save(UserProfile profile) async {
    state = profile;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, profile.name);
    await p.setInt(_kAge, profile.ageYears);
    await p.setDouble(_kWeight, profile.weightKg);
    await p.setDouble(_kHeight, profile.heightCm);
    await p.setString(_kSex, profile.sex);
    await p.setInt(_kGoal, profile.dailyGoalSteps);
    await p.setBool(_kOnboarded, true);
  }

  Future<void> setGoal(int goal) => save(state.copyWith(dailyGoalSteps: goal));

  static Future<bool> isOnboarded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboarded) ?? false;
  }
}

final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserProfile>(
  (_) => UserSettingsNotifier(),
);
