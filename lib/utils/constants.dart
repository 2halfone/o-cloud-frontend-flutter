class ApiConstants {
  // ✅ AGGIORNATO con l'IP corretto
  static const String baseUrl = 'http://34.140.122.146:3000';
  static const String authBaseUrl = 'http://34.140.122.146:3001';
  static const String userBaseUrl = 'http://34.140.122.146:3002';
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshEndpoint = '/auth/refresh';  static const String adminLogsEndpoint = '/admin/auth-logs';
}

// Add these constants for compatibility with UserService
const String userBaseUrl = ApiConstants.userBaseUrl;
const String authBaseUrl = ApiConstants.authBaseUrl;
const String baseUrl = ApiConstants.baseUrl;
