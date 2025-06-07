import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_log.dart';
import '../utils/token_manager.dart';

class LogService {
  static const String _baseUrl = 'http://34.140.122.146:3000'; // ✅ IP AGGIORNATO
  
  /// Recupera i log di autenticazione
  Future<AuthLogsResponse?> getAuthLogs({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print('🔍 [LogService] Fetching auth logs - Page: $page, Limit: $limit');
      
      final token = await TokenManager.getToken();
      print('🔑 [LogService] Token found: ${token != null}');
      print('🔑 [LogService] Token length: ${token?.length ?? 0}');
      
      if (token == null) {
        print('❌ [LogService] No token available');
        throw Exception('No access token available');
      }

      final url = 'http://34.140.122.146:3000/admin/auth-logs?page=$page&limit=$limit'; // ✅ IP AGGIORNATO
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 [LogService] Calling: $url');
      print('📋 [LogService] Headers: $headers');

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ [LogService] TIMEOUT after 10 seconds');
            throw Exception('Request timeout');
          },
        );

        print('✅ [LogService] Response received: ${response.statusCode}');
        print('📄 [LogService] Response body length: ${response.body.length}');
        print('📄 [LogService] Response body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final jsonData = json.decode(response.body);
            print('🎯 [LogService] JSON parsed successfully');
            return AuthLogsResponse.fromJson(jsonData);
          } catch (e) {
            print('❌ [LogService] JSON parsing error: $e');
            throw Exception('Failed to parse response: $e');
          }
        } else {
          print('❌ [LogService] HTTP Error: ${response.statusCode}');
          print('📄 [LogService] Error body: ${response.body}');
          throw Exception('Failed to load auth logs: ${response.statusCode}');
        }
      } catch (e) {
        print('💥 [LogService] Exception: $e');
        rethrow;
      }
    } catch (e) {
      print('💥 [LogService] Exception: $e');
      rethrow;
    }
  }

  /// Refresh dei log (chiamata diretta per aggiornamento)
  Future<AuthLogsResponse?> refreshLogs({
    int page = 1,
    int limit = 50,
  }) async {
    print('🔄 [LogService] Refreshing logs...');
    return await getAuthLogs(page: page, limit: limit);
  }

  /// Verifica se l'utente può accedere ai log (è admin)
  Future<bool> canAccessLogs() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) return false;

      // Prova a fare una richiesta rapida per verificare i permessi
      final url = Uri.parse('$_baseUrl/admin/auth-logs')
          .replace(queryParameters: {'page': '1', 'limit': '1'});

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ [LogService] Error checking admin access: $e');
      return false;
    }
  }
}
