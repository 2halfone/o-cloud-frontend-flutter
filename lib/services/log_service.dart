import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_log.dart';
import '../utils/token_manager.dart';

class LogService {
  static const String _baseUrl = 'http://34.140.122.146:3000'; // ✅ IP AGGIORNATO
    /// Retrieve authentication logs
  Future<AuthLogsResponse?> getAuthLogs({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await TokenManager.getToken();
      
      if (token == null) {
        throw Exception('No access token available');
      }

      final url = 'http://34.140.122.146:3000/admin/auth-logs?page=$page&limit=$limit'; // ✅ IP AGGIORNATO
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',      };

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode == 200) {
          try {
            final jsonData = json.decode(response.body);
            return AuthLogsResponse.fromJson(jsonData);
          } catch (e) {
            throw Exception('Failed to parse response: $e');
          }
        } else {
          throw Exception('Failed to load auth logs: ${response.statusCode}');
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Refresh logs (direct call for update)
  Future<AuthLogsResponse?> refreshLogs({
    int page = 1,
    int limit = 50,
  }) async {
    return await getAuthLogs(page: page, limit: limit);
  }

  /// Check if user can access logs (is admin)
  Future<bool> canAccessLogs() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) return false;

      // Try making a quick request to verify permissions
      final url = Uri.parse('$_baseUrl/admin/auth-logs')
          .replace(queryParameters: {'page': '1', 'limit': '1'});

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
