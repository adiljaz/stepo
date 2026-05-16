import 'package:dio/dio.dart';
import '../constants/api_config.dart';
import '../core/storage/secure_storage.dart';

class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure we always use the latest baseUrl from config
        options.baseUrl = ApiConfig.baseUrl;
        
        final token = await SecureStorage.read('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired logic could go here
        }
        return handler.next(e);
      },
    ));
  }

  // Auth
  Future<Response> loginWithGoogle(String idToken) async {
    return await _dio.post('/auth/google', data: {'id_token': idToken});
  }

  // Steps
  Future<Response> syncSteps(int totalSteps) async {
    return await _dio.post('/steps/sync', data: {
      'totalSteps': totalSteps,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Leaderboard
  Future<Response> getLeaderboard({String type = 'global', String? country, String? state, String? district}) async {
    return await _dio.get('/leaderboard', queryParameters: {
      'type': type,
      'country': country,
      'state': state,
      'district': district,
    });
  }

  // User
  Future<Response> getProfile() async {
    return await _dio.get('/users/me');
  }
}
