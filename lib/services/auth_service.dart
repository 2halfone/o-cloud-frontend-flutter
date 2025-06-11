import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';
import '../utils/token_manager.dart';

class AuthService {
  static const String _baseUrl = 'http://34.140.122.146:3000'; // Gateway
  static const FlutterSecureStorage _storage = FlutterSecureStorage();Future<void> register(String email, String password, String name, String surname) async {
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
          'name': name,
          'surname': surname,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  Future<Map<String, dynamic>> login(String email, String password) async {
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        final accessToken = responseData['access_token'] as String?;
        final refreshToken = responseData['refresh_token'] as String?;
          if (accessToken == null) {
          throw Exception('Access token not found in response');
        }
          // Use TokenManager to save the token
        await TokenManager.saveToken(accessToken);
        if (refreshToken != null) {
          await _storage.write(key: 'refresh_token', value: refreshToken);
        }
        
        // Save user email for future use
        await _storage.write(key: 'user_email', value: email);
        
        return responseData;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  // Method for authorized requests with auto-refresh
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
      // Automatic token refresh handling on 401
    if (response.statusCode == 401 && accessToken != null) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the request only once with the new token
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
        // Fallback to logout on persistent errors
        await logout();
        throw Exception('Session expired. Please login again.');
      }
    }
    
    return response;
  }

  // Automatic token refresh on 401
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
    // Remove all tokens and user data
    await TokenManager.deleteToken();
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
  }
  Future<bool> isLoggedIn() async {
    final accessToken = await TokenManager.getToken();
    if (accessToken == null) return false;
    
    // Check if the token is still valid
    try {
      return !JwtDecoder.isExpired(accessToken);
    } catch (e) {
      return false;
    }
  }
  
  // Helper methods to access user data
  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }
  
  Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }    Future<String?> getAccessToken() async {
    return await TokenManager.getToken();
  }
    // Method to check if user is admin by decoding the JWT token
  Future<bool> isUserAdmin() async {
    try {
      final accessToken = await TokenManager.getToken();
      if (accessToken == null) return false;
      
      // Decode the JWT token to access claims
      final decodedToken = JwtDecoder.decode(accessToken);
        // 🔍 DEBUG: Print the entire token for investigation
      debugPrint('🔍 JWT Token Debug:');
      debugPrint('Token: ${decodedToken.toString()}');
        // Check if the user has admin role - STRICT VALIDATION
      // Only these specific fields should be checked for admin status
      final role = decodedToken['role']; 
      final userType = decodedToken['user_type'];
      final isAdmin = decodedToken['is_admin'];      final roles = decodedToken['roles'] as List<dynamic>?;
      
      debugPrint('🔍 Role field: $role');
      debugPrint('🔍 User type field: $userType');
      debugPrint('🔍 Is admin field: $isAdmin');
      debugPrint('🔍 Roles array: $roles');
        // Check role field for string values
      if (role is String && (role.toLowerCase() == 'admin' || role.toLowerCase() == 'administrator')) {
        debugPrint('🔍 ✅ Admin detected via role string: $role');
        return true;
      }
      
      // Check user_type field for string values  
      if (userType is String && (userType.toLowerCase() == 'admin' || userType.toLowerCase() == 'administrator')) {
        debugPrint('🔍 ✅ Admin detected via user_type string: $userType');
        return true;
      }
      
      // Check is_admin field for boolean values
      if (isAdmin is bool && isAdmin == true) {
        debugPrint('🔍 ✅ Admin detected via is_admin boolean: $isAdmin');
        return true;
      }
      
      // Check roles array
      if (roles != null && roles.any((r) => r.toString().toLowerCase() == 'admin')) {
        debugPrint('🔍 ✅ Admin detected via roles array: $roles');
        return true;
      }
        // 🚫 RIMUOVIAMO questo controllo email - causa falsi positivi
      // Gli utenti con email che contengono 'admin' non dovrebbero automaticamente diventare admin      // Only el campo 'role' nel JWT dovrebbe determinare i permessi
      final email = decodedToken['email'] ?? decodedToken['sub'];
      debugPrint('🔍 Email field: $email (but not using for admin detection)');
      
      // 🚫 COMMENTED OUT: if (email is String && email.toLowerCase().contains('admin')) {
      //   debugPrint('🔍 Admin detected via email contains admin: $email');
      //   return true;
      // }
      
      debugPrint('🔍 No admin role detected - returning false');
      return false;
    } catch (e) {
      debugPrint('🔍 Error in isUserAdmin: $e');
      return false;
    }
  }
}
