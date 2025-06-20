class MonitoringConfig {
  // API Endpoints
  static const String baseApiUrl = 'http://34.140.122.146:3000';
  static const String securityUrl = '$baseApiUrl/api/dashboard/security';
  static const String vmHealthUrl = '$baseApiUrl/api/dashboard/vm-health';
  static const String insightsUrl = '$baseApiUrl/api/dashboard/insights';
  
  // Timeouts and retry settings
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(seconds: 2);
  static const Duration refreshInterval = Duration(seconds: 30);
  static const Duration requestTimeout = Duration(seconds: 15);
  
  // Alert thresholds
  static const double cpuCriticalThreshold = 90.0;
  static const double memoryCriticalThreshold = 90.0;
  static const double diskCriticalThreshold = 95.0;
  
  // Dashboard settings
  static const bool defaultAutoRefresh = true;
  static const bool defaultAlertNotifications = true;
  static const bool defaultHapticFeedback = true;
}
