class ApiConfig {
  // Using 10.0.2.2 for Android emulators, 127.0.0.1 for other platforms
  static String baseUrl = 'http://127.0.0.1:5000/api/v1';
  
  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }
  
  // Headers
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}

