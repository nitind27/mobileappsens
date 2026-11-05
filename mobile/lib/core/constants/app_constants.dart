class AppConstants {
  static const String appName = 'FieldPilot';
  static const String appTagline = 'Smart Field Collection & Workforce Management';
  static const String appVersion = '1.0.0';

  // Base API URL
  // For Android emulator use http://10.0.2.2:8000
  // For physical device over Wi-Fi, use your local machine IP e.g. http://192.168.1.X:8000
  // For web / local desktop use http://localhost:8000
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';
  static const String webBaseUrl = 'http://localhost:8000';

  // Storage Keys
  static const String tokenKey = 'fp_auth_token';
  static const String userKey = 'fp_user_data';
  static const String roleKey = 'fp_user_role';
  static const String baseUrlKey = 'fp_api_base_url';
  static const String isDarkModeKey = 'fp_dark_mode';
  static const String trackingConsentKey = 'fp_tracking_consent';

  // Location tracking settings
  static const int locationIntervalSeconds = 30;
  static const double geofenceRadiusMeters = 200.0;
}
