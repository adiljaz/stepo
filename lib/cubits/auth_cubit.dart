import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import '../core/storage/secure_storage.dart';
import 'user_settings_cubit.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, profileSetupRequired, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({required this.status, this.errorMessage});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated() => AuthState(status: AuthStatus.authenticated);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.profileSetupRequired() => AuthState(status: AuthStatus.profileSetupRequired);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService = AuthService();
  final UserSettingsCubit _settingsCubit;

  AuthCubit(this._settingsCubit) : super(AuthState.initial());

  Future<void> checkAuth() async {
    emit(AuthState.loading());
    try {
      final token = await SecureStorage.read('access_token');
      if (token != null) {
        final profileSetupDone = await UserSettingsCubit.isOnboarded();
        if (!profileSetupDone) {
          emit(AuthState.profileSetupRequired());
        } else {
          emit(AuthState.authenticated());
        }
      } else {
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthState.loading());
    try {
      final userData = await _authService.loginWithEmail(email, password);
      await _handleAuthSuccess(userData);
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic>? userData) async {
    if (userData == null) {
      emit(AuthState.unauthenticated());
      return;
    }

    final name = userData['username'] ?? userData['name'] ?? '';
    final profileImage = userData['profileImage'] ?? '';
    final hasCompleteProfile = name.isNotEmpty && name != 'User';

    if (hasCompleteProfile) {
      // Mark as onboarded locally
      await UserSettingsCubit.setLocalOnboarded(true);
      
      // Sync the settings cubit with server data
      await _settingsCubit.syncFromServer();
      
      emit(AuthState.authenticated());
    } else {
      emit(AuthState.profileSetupRequired());
    }
  }

  Future<void> loginWithGoogle() async {
    emit(AuthState.loading());
    try {
      final userData = await _authService.signIn();
      await _handleAuthSuccess(userData);
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthState.loading());
    try {
      final userData = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      await _handleAuthSuccess(userData);
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emit(AuthState.unauthenticated());
  }

  void completeProfileSetup() {
    emit(AuthState.authenticated());
  }
}
