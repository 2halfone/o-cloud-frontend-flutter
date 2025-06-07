import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../utils/token_manager.dart';

class AuthService {
  static const String _baseUrl = 'http://34.140.122.146';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> register(String email, String password) async {
    print('🔄 Starting registration request...');
    print('📧 Email: $email');
    print('🌐 URL: $_baseUrl/auth/register');
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          // ❌ NON inviamo il campo 'name' - il backend lo genererà automaticamente
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Registration successful!');
      } else {
        print('❌ Registration failed: ${response.statusCode}');
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      print('💥 Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔄 Starting login request...');
    print('📧 Email: $email');
    print('🌐 URL: $_baseUrl/auth/login');
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Login response status: ${response.statusCode}');
      print('📄 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        final accessToken = responseData['access_token'] as String?;
        final refreshToken = responseData['refresh_token'] as String?;
          if (accessToken == null) {
          throw Exception('Access token not found in response');
        }
        
        // Usa TokenManager per salvare il token
        await TokenManager.saveToken(accessToken);
        if (refreshToken != null) {
          await _storage.write(key: 'refresh_token', value: refreshToken);
        }
        
        print('✅ Login successful!');
        return responseData;
      } else {
        print('❌ Login failed: ${response.statusCode}');
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('💥 Login error: $e');
      throw Exception('Login failed: $e');
    }
  }
  // Metodo per richieste autorizzate con auto-refresh
  Future<http.Response> makeAuthorizedRequest(
    String method,
    String endpoint,
    {Map<String, dynamic>? body}
  ) async {
    final accessToken = await TokenManager.getToken();
    
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
    
    final uri = Uri.parse('$_baseUrl$endpoint');
    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
      // Gestione automatica del rinnovo token su 401
    if (response.statusCode == 401 && accessToken != null) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Ripeti la richiesta una sola volta con il nuovo token
        final newAccessToken = await TokenManager.getToken();
        headers['Authorization'] = 'Bearer $newAccessToken';
        
        switch (method.toUpperCase()) {
          case 'POST':
            response = await http.post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'GET':
            response = await http.get(uri, headers: headers);
            break;
        }
      } else {
        // Fallback a logout su errori persistenti
        await logout();
        throw Exception('Session expired. Please login again.');
      }
    }
    
    return response;
  }

  // Rinnovo automatico token su 401
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
        if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = responseData['access_token'] as String?;
        final newRefreshToken = responseData['refresh_token'] as String?;
        
        if (newAccessToken != null) {
          await TokenManager.saveToken(newAccessToken);
          if (newRefreshToken != null) {
            await _storage.write(key: 'refresh_token', value: newRefreshToken);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  Future<void> logout() async {
    // Rimuovi tutti i token e dati utente
    await TokenManager.deleteToken();
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
  }
  Future<bool> isLoggedIn() async {
    final accessToken = await TokenManager.getToken();
    if (accessToken == null) return false;
    
    // Verifica se il token è ancora valido
    try {
      return !JwtDecoder.isExpired(accessToken);
    } catch (e) {
      return false;
    }
  }
  
  // Metodi helper per accedere ai dati utente
  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }
  
  Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }    Future<String?> getAccessToken() async {
    return await TokenManager.getToken();
  }
    // Metodo per verificare se l'utente è admin decodificando il JWT token
  Future<bool> isUserAdmin() async {
    try {
      final accessToken = await TokenManager.getToken();
      if (accessToken == null) return false;
      
      // Decodifica il JWT token per accedere ai claims
      final decodedToken = JwtDecoder.decode(accessToken);
      
      // Controlla se l'utente ha il ruolo admin
      // Il campo può essere 'role', 'roles', 'user_type', o 'is_admin' a seconda del backend
      final role = decodedToken['role'] ?? decodedToken['user_type'] ?? decodedToken['is_admin'];
      final roles = decodedToken['roles'] as List<dynamic>?;
      
      // Verifica diversi formati possibili per il ruolo admin
      if (role is String && (role.toLowerCase() == 'admin' || role.toLowerCase() == 'administrator')) {
        return true;
      }
      
      if (role is bool && role == true) {
        return true;
      }
      
      if (roles != null && roles.any((r) => r.toString().toLowerCase() == 'admin')) {
        return true;
      }
      
      // Controlla anche nell'email se contiene 'admin'
      final email = decodedToken['email'] ?? decodedToken['sub'];
      if (email is String && email.toLowerCase().contains('admin')) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('🔍 Error checking admin status: $e');
      return false;
    }
  }
}
