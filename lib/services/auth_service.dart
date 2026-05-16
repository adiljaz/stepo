import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../core/storage/secure_storage.dart';
import '../constants/api_config.dart';
import '../core/network/api_client.dart';
import 'package:dio/dio.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '486188532652-s6t9t85a3f1m29m782vukhf2adqdlm1v.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> signIn() async {
    try {
      debugPrint("AuthService: Starting Google Sign-In...");
      // await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint("AuthService: Google Sign-In cancelled by user or failed (googleUser is null)");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw AuthException("Failed to get Google ID Token");

      final response = await _apiClient.post(
        '/auth/google',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = response.data['access_token'] ?? response.data['accessToken'] ?? response.data['token'];
        if (accessToken != null) {
          await SecureStorage.write('access_token', accessToken.toString());
          return response.data['user'] as Map<String, dynamic>?;
        }
      }
      throw AuthException("Backend authentication failed");
    } catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>?> loginWithEmail(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['accessToken'] ?? response.data['token'];
        if (accessToken != null) {
          await SecureStorage.write('access_token', accessToken.toString());
          return response.data['user'] as Map<String, dynamic>?;
        }
      }
      throw AuthException("Invalid email or password");
    } catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = response.data['accessToken'] ?? response.data['token'];
        if (accessToken != null) {
          await SecureStorage.write('access_token', accessToken.toString());
          return response.data['user'] as Map<String, dynamic>?;
        }
      }
      throw AuthException("Signup failed");
    } catch (e) {
      throw _parseError(e);
    }
  }

  AuthException _parseError(Object e) {
    debugPrint("AuthService: Parsing error: $e");
    
    // Check for the specific Android MediaProvider/PhotoPicker crash
    final errorStr = e.toString();
    if (errorStr.contains("MediaProvider") || errorStr.contains("NullPointerException") || errorStr.contains("sign_in_failed")) {
      return AuthException("SYSTEM CRASH: Your phone's Media Provider crashed. Please restart your phone and try again, or use Email Login.");
    }

    if (e is AuthException) return e;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return AuthException("Backend server unreachable at ${ApiConfig.baseUrl}. Is the server running?");
      }
      final errorMsg = e.response?.data?['message'] ?? e.message ?? "Unknown network error";
      return AuthException("Network error: $errorMsg");
    }
    return AuthException("Authentication failed: $e");
  }

  static Future<bool> isLoggedIn() async {
    final token = await SecureStorage.read('access_token');
    return token != null;
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await SecureStorage.clearAll();
  }
}
