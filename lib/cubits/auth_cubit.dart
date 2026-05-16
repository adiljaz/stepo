import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import '../core/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, onboardingRequired, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({required this.status, this.errorMessage});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated() => AuthState(status: AuthStatus.authenticated);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.onboardingRequired() => AuthState(status: AuthStatus.onboardingRequired);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService = AuthService();

  AuthCubit() : super(AuthState.initial());

  Future<void> checkAuth() async {
    emit(AuthState.loading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!onboardingCompleted) {
        emit(AuthState.onboardingRequired());
        return;
      }

      final token = await SecureStorage.read('access_token');
      if (token != null) {
        emit(AuthState.authenticated());
      } else {
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthState.loading());
    final success = await _authService.loginWithEmail(email, password);
    if (success) {
      emit(AuthState.authenticated());
    } else {
      emit(AuthState.error("Invalid credentials"));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthState.loading());
    final success = await _authService.signUpWithEmail(
      name: name,
      email: email,
      password: password,
    );
    if (success) {
      emit(AuthState.authenticated());
    } else {
      emit(AuthState.error("Signup failed. Email might be in use."));
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emit(AuthState.unauthenticated());
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    emit(AuthState.unauthenticated()); // After onboarding, go to Login
  }
}
