import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../utils/token_manager.dart';

class AuthService {
  static const String _baseUrl = 'https://34.140.122.146';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Estrazione di access_token, refresh_token e claim aggiuntivi
      final accessToken = responseData['access_token'] as String?;
      final refreshToken = responseData['refresh_token'] as String?;
      
      if (accessToken == null) {
        throw Exception('Access token not found in response');
      }
      
      // Salvataggio sicuro dei token
      await _storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }
      
      // Decodifica della payload JWT per estrarre claim aggiuntivi
      try {
        final decodedToken = JwtDecoder.decode(accessToken);
        final userId = decodedToken['user_id']?.toString();
        final email = decodedToken['email']?.toString();
        
        // Salvataggio claim aggiuntivi
        if (userId != null) {
          await _storage.write(key: 'user_id', value: userId);
        }
        if (email != null) {
          await _storage.write(key: 'user_email', value: email);
        }
        
        // Ritorna tutti i dati utili per la UI
        return {
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'user_id': userId,
          'email': email,
          'decoded_payload': decodedToken,
        };
      } catch (e) {
        // Se la decodifica fallisce, ritorna almeno i token
        return {
          'access_token': accessToken,
          'refresh_token': refreshToken,
        };
      }
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Metodo per richieste autorizzate con auto-refresh
  Future<http.Response> makeAuthorizedRequest(
    String method,
    String endpoint,
    {Map<String, dynamic>? body}
  ) async {
    final accessToken = await _storage.read(key: 'access_token');
    
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
        final newAccessToken = await _storage.read(key: 'access_token');
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
          await _storage.write(key: 'access_token', value: newAccessToken);
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

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<void> logout() async {
    // Rimuovi tutti i token e dati utente
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await TokenManager.deleteToken(); // Compatibilità con il vecchio sistema
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await _storage.read(key: 'access_token');
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
  }
  
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }
}
