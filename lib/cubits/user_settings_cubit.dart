import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

const _kName        = 'profile_name';
const _kAge         = 'profile_age';
const _kWeight      = 'profile_weight';
const _kHeight      = 'profile_height';
const _kSex         = 'profile_sex';
const _kGoal        = 'profile_goal';
const _kStride      = 'profile_stride';
const _kSensitivity = 'profile_sensitivity';
const _kOnboarded   = 'onboarding_complete';
const _kImage       = 'profile_image';
const _kStreak      = 'profile_streak';

class UserSettingsCubit extends Cubit<UserProfile> {
  final ApiService _apiService = ApiService();

  UserSettingsCubit() : super(const UserProfile()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    emit(UserProfile(
      name: p.getString(_kName) ?? '',
      ageYears: p.getInt(_kAge) ?? 30,
      weightKg: p.getDouble(_kWeight) ?? 70,
      heightCm: p.getDouble(_kHeight) ?? 170,
      sex: p.getString(_kSex) ?? 'male',
      dailyGoalSteps: p.getInt(_kGoal) ?? 8000,
      strideLengthMeters: p.getDouble(_kStride) ?? 0.762,
      aiSensitivity: AISensitivity.values[p.getInt(_kSensitivity) ?? 1],
      profileImage: p.getString(_kImage) ?? '',
      streakCount: p.getInt(_kStreak) ?? 0,
    ));
    
    // Also try to fetch from server if authenticated
    await syncFromServer();
  }

  Future<void> syncFromServer() async {
    try {
      final res = await _apiService.getProfile();
      if (res.statusCode == 200) {
        final profile = UserProfile.fromMap(res.data);
        await save(profile, sync: false);
      }
    } catch (_) {}
  }

  Future<void> save(UserProfile profile, {bool sync = true}) async {
    emit(profile);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, profile.name);
    await p.setInt(_kAge, profile.ageYears);
    await p.setDouble(_kWeight, profile.weightKg);
    await p.setDouble(_kHeight, profile.heightCm);
    await p.setString(_kSex, profile.sex);
    await p.setInt(_kGoal, profile.dailyGoalSteps);
    await p.setDouble(_kStride, profile.strideLengthMeters);
    await p.setInt(_kSensitivity, profile.aiSensitivity.index);
    await p.setString(_kImage, profile.profileImage);
    await p.setBool(_kOnboarded, true);

    if (sync) {
      try {
        await _apiService.updateProfile(profile.toMap());
      } catch (_) {}
    }
  }

  Future<void> setGoal(int goal) => save(state.copyWith(dailyGoalSteps: goal));

  Future<void> updateName(String newName) async {
    await save(state.copyWith(name: newName));
  }

  static Future<bool> isOnboarded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboarded) ?? false;
  }

  static Future<void> setLocalOnboarded(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, value);
  }
}
