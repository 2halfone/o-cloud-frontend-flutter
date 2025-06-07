class ApiConstants {
  // ✅ AGGIORNATO con l'IP corretto
  static const String BASE_URL = 'http://34.140.122.146:3000';
  static const String AUTH_BASE_URL = 'http://34.140.122.146:3001';
  static const String USER_BASE_URL = 'http://34.140.122.146:3002';
  
  // Endpoints
  static const String LOGIN_ENDPOINT = '/auth/login';
  static const String REGISTER_ENDPOINT = '/auth/register';
  static const String REFRESH_ENDPOINT = '/auth/refresh';
  static const String ADMIN_LOGS_ENDPOINT = '/admin/auth-logs';
}

// ✅ Aggiungi queste costanti per compatibilità con UserService
const String USER_BASE_URL = ApiConstants.USER_BASE_URL;
const String AUTH_BASE_URL = ApiConstants.AUTH_BASE_URL;
const String BASE_URL = ApiConstants.BASE_URL;
