import 'dart:io';

class ApiConfig {
  // Using 10.0.2.2 for Android emulators, 127.0.0.1 for iOS/Desktop
  // For physical Android devices, you must use your computer's local IP (e.g. 192.168.1.X)
  static String get baseUrl {
    if (_manualBaseUrl != null) return _manualBaseUrl!;
    
    if (Platform.isAndroid) {
      return 'http://127.0.0.1:5000/api/v1';
    } else {
      return 'http://127.0.0.1:5000/api/v1';
    }
  }
  
  static String? _manualBaseUrl;
  
  static void updateBaseUrl(String newUrl) {
    _manualBaseUrl = newUrl;
  }
  
  // Headers
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}
