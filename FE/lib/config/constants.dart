/// Constants for the application

/// API Configuration
class ApiConstants {
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';

  // Timeouts (milliseconds)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}

/// UI Constants
class UIConstants {
  // Spacing
  static const double spacingXs = 8.0;
  static const double spacingSmall = 16.0;
  static const double spacingMedium = 24.0;
  static const double spacingLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;

  // Shadow
  static const double shadowBlur = 12.0;
  static const double shadowBlurLarge = 20.0;
  static const double shadowOffsetY = 4.0;
  static const double shadowOffsetYLarge = 8.0;
}

/// Colors
class AppColors {
  // Primary
  static const int primaryOrange = 0xFFFF6600;
  static const int primaryOrangeLight = 0xFFFF8A00;

  // Neutrals
  static const int white = 0xFFFFFFFF;
  static const int surface = 0xFFF8F9FB;
  static const int surfaceLight = 0xFFFAFAFA;

  // Text
  static const int textPrimary = 0xFF1A1A1A;
  static const int textSecondary = 0xFF666666;
  static const int textHint = 0xFFBDBDBD;

  // Borders
  static const int borderDefault = 0xFFE0E0E0;
  static const int borderFocus = 0xFFFF6600;

  // Feedback
  static const int errorRed = 0xFFEF5350;
  static const int errorBg = 0xFFFFEBEE;
  static const int successGreen = 0xFF4CAF50;
}

/// Storage Keys
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String isLoggedIn = 'is_logged_in';
  static const String userData = 'user_data';
}

/// Validation Rules
class ValidationRules {
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minEmailLength = 6;
  static const int maxEmailLength = 254;
}
