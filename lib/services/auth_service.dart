import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../core/storage/secure_storage.dart';
import '../constants/api_config.dart';
import '../core/network/api_client.dart';
import 'package:dio/dio.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final ApiClient _apiClient = ApiClient();

  Future<bool> signIn() async {
    try {
      debugPrint("AuthService: Starting Google Sign-In...");
      // Force account picker by signing out first
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint("AuthService: User cancelled sign-in.");
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint("AuthService: FAILED to get ID Token.");
        return false;
      }

      debugPrint("AuthService: Google ID Token RECEIVED. Calling backend...");
      debugPrint("AuthService: Target URL: ${ApiConfig.baseUrl}/auth/google");
      
      final response = await _apiClient.post(
        '/auth/google',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try both snake_case and camelCase
        final accessToken = response.data['access_token'] ?? response.data['accessToken'] ?? response.data['token'];
        final refreshToken = response.data['refresh_token'] ?? response.data['refreshToken'];

        if (accessToken != null) {
          await SecureStorage.write('access_token', accessToken.toString());
          if (refreshToken != null) {
            await SecureStorage.write('refresh_token', refreshToken.toString());
          }
          
          debugPrint("AuthService: Login SUCCESS. Tokens stored securely.");
          return true;
        } else {
          debugPrint("AuthService: ERROR - No access token found in response body: ${response.data}");
          return false;
        }
      }

      debugPrint("AuthService: Backend returned error: ${response.data}");
      return false;
    } catch (e) {
      debugPrint("AuthService: ERROR during Google Login: $e");
      _handleAuthError(e);
      return false;
    }
  }

  void _handleAuthError(Object e) {
    if (e is DioException) {
      debugPrint("AuthService: Dio Error Type: ${e.type}");
      debugPrint("AuthService: Dio Error Message: ${e.message}");
      if (e.response != null) {
        debugPrint("AuthService: Response Data: ${e.response?.data}");
        debugPrint("AuthService: Status Code: ${e.response?.statusCode}");
      }
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        debugPrint("AuthService: CONNECTION ERROR - Is the backend server running at ${ApiConfig.baseUrl}?");
        if (Platform.isAndroid && ApiConfig.baseUrl.contains('127.0.0.1')) {
          debugPrint("AuthService: TIP - On Android Emulator, use 10.0.2.2 instead of 127.0.0.1");
        }
      }
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      debugPrint("AuthService: Logging in with email...");
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['accessToken'] ?? response.data['token'];
        if (accessToken != null) {
          await SecureStorage.write('access_token', accessToken.toString());
          debugPrint("AuthService: Email login SUCCESS.");
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("AuthService: ERROR during email login.");
      _handleAuthError(e);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("AuthService: Signing up with email...");
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = response.data['accessToken'] ?? response.data['token'];
        if (accessToken != null) {
          await SecureStorage.write('access_token', accessToken.toString());
          debugPrint("AuthService: Email signup SUCCESS.");
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("AuthService: ERROR during email signup.");
      _handleAuthError(e);
      return false;
    }
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
