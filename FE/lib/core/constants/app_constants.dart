class AppConstants {
  static const String appName = 'ToyFlix Market';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );

  static const String tokenKey = 'auth_token';
  static const String isLoggedInKey = 'is_logged_in';
  static const String userKey = 'user_info';
}
