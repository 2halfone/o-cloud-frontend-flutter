import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/token_manager.dart';

class AnalyticsApiService {
  static const String baseUrl = 'http://34.140.122.146:3000'; // Updated to new gateway URL
  static const Duration _requestTimeout = Duration(seconds: 10); // Reduced timeout

  // Helper method to get authenticated headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenManager.getToken();
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('📊 Using authenticated headers with token: ${token.substring(0, 20)}...');
    } else {
      print('⚠️ No JWT token available for authentication');
    }
    
    return headers;
  }

  // Auth logs with pagination
  static Future<Map<String, dynamic>> getAuthLogs({
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/auth-logs').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });    print('📊 Fetching auth logs from: $uri');
    
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_requestTimeout);

      print('📊 Auth logs response status: ${response.statusCode}');
      print('📊 Auth logs response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Auth logs data parsed: $data');
        return data;
      } else {
        print('❌ Auth logs error response: ${response.body}');
        throw Exception('Failed to fetch auth logs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Auth logs exception: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout while fetching auth logs');
      }
      rethrow;
    }
  }

  // Users list with statistics
  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 100,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });    print('📊 Fetching users from: $uri');
    
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_requestTimeout);

      print('📊 Users response status: ${response.statusCode}');
      print('📊 Users response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Users data parsed: $data');
        return data;
      } else {
        print('❌ Users error response: ${response.body}');
        throw Exception('Failed to fetch users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Users exception: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout while fetching users');
      }
      rethrow;
    }
  }

  // QR events list with statistics
  static Future<Map<String, dynamic>> getQrEvents({
    int page = 1,
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/user/qr/admin/events').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });    print('📊 Fetching QR events from: $uri');
    
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_requestTimeout);

      print('📊 QR events response status: ${response.statusCode}');
      print('📊 QR events response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 QR events data parsed: $data');
        return data;
      } else if (response.statusCode == 404) {
        // If endpoint returns 404, return empty data structure
        print('📊 QR events endpoint not found, returning empty data');
        return {
          'data': [],
          'total': 0,
          'page': page,
          'limit': limit,
        };
      } else {
        print('❌ QR events error response: ${response.body}');
        throw Exception('Failed to fetch QR events: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ QR events exception: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout while fetching QR events');
      }
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        // If there's a connection issue, return empty data instead of failing
        print('📊 QR events connection issue, returning empty data');
        return {
          'data': [],
          'total': 0,
          'page': page,
          'limit': limit,
          'error': 'Connection failed',
        };
      }
      rethrow;
    }
  }

  // Event attendance for specific event
  static Future<Map<String, dynamic>> getEventAttendance(int eventId) async {
    final uri = Uri.parse('$baseUrl/user/qr/admin/events/$eventId/attendance');    print('📊 Fetching attendance for event $eventId from: $uri');
    
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_requestTimeout);

      print('📊 Event attendance response status: ${response.statusCode}');
      print('📊 Event attendance response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Event attendance data parsed: $data');
        return data;
      } else {
        print('❌ Event attendance error response: ${response.body}');
        throw Exception('Failed to fetch event attendance: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Event attendance exception: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout while fetching event attendance');
      }
      rethrow;
    }
  }

  // Users who scanned for specific event
  static Future<Map<String, dynamic>> getEventUsers(int eventId) async {
    final uri = Uri.parse('$baseUrl/user/qr/admin/events/$eventId/users');    print('📊 Fetching users for event $eventId from: $uri');
    
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_requestTimeout);

      print('📊 Event users response status: ${response.statusCode}');
      print('📊 Event users response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Event users data parsed: $data');
        return data;
      } else {
        print('❌ Event users error response: ${response.body}');
        throw Exception('Failed to fetch event users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Event users exception: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout while fetching event users');
      }
      rethrow;
    }
  }

  // Combined analytics data with better error handling
  static Future<Map<String, dynamic>> getAllAnalyticsData() async {
    print('📊 Fetching all analytics data...');
    
    try {
      // Execute API calls with individual error handling
      final List<Future<Map<String, dynamic>?>> futures = [
        _safeApiCall(() => getAuthLogs(limit: 10), 'auth_logs'),
        _safeApiCall(() => getUsers(limit: 50), 'users'),
        _safeApiCall(() => getQrEvents(limit: 20), 'qr_events'),
      ];

      final results = await Future.wait(futures);

      final authLogs = results[0] ?? {'data': [], 'total': 0};
      final users = results[1] ?? {'data': [], 'total': 0};
      final qrEvents = results[2] ?? {'data': [], 'total': 0};

      // Calculate summary statistics
      final analytics = {
        'auth_logs': authLogs,
        'users': users,
        'qr_events': qrEvents,
        'summary': {
          'total_auth_attempts': _extractTotalCount(authLogs),
          'total_users': _extractTotalCount(users),
          'total_qr_events': _extractTotalCount(qrEvents),
          'active_users_today': _calculateActiveUsersToday(authLogs),
          'successful_auth_rate': _calculateAuthSuccessRate(authLogs),
          'qr_scan_rate': _calculateQrScanRate(qrEvents),
        },
        'metadata': {
          'collection_time': DateTime.now().toIso8601String(),
          'data_source': 'real-time-api',
          'api_status': {
            'auth_logs': authLogs.containsKey('error') ? 'error' : 'ok',
            'users': users.containsKey('error') ? 'error' : 'ok',
            'qr_events': qrEvents.containsKey('error') ? 'error' : 'ok',
          }
        }
      };

      print('📊 Combined analytics data: $analytics');
      return analytics;
    } catch (e) {
      print('❌ Error fetching analytics data: $e');
      rethrow;
    }
  }

  // Safe API call wrapper
  static Future<Map<String, dynamic>?> _safeApiCall(
    Future<Map<String, dynamic>> Function() apiCall,
    String apiName,
  ) async {
    try {
      return await apiCall();
    } catch (e) {
      print('❌ Safe API call failed for $apiName: $e');
      return {
        'data': [],
        'total': 0,
        'error': e.toString(),
      };
    }
  }

  // Helper methods for calculations
  static int _extractTotalCount(Map<String, dynamic> data) {
    return data['total'] ?? data['count'] ?? (data['data'] as List?)?.length ?? 0;
  }

  static int _calculateActiveUsersToday(Map<String, dynamic> authLogs) {
    final logs = authLogs['data'] as List? ?? [];
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final Set<String> activeUsers = {};
    for (var log in logs) {
      if (log is Map && log['timestamp']?.toString().startsWith(todayStr) == true) {
        final userId = log['user_id']?.toString();
        if (userId != null) activeUsers.add(userId);
      }
    }
    
    return activeUsers.length;
  }

  static double _calculateAuthSuccessRate(Map<String, dynamic> authLogs) {
    final logs = authLogs['data'] as List? ?? [];
    if (logs.isEmpty) return 0.0;
    
    int successful = 0;
    for (var log in logs) {
      if (log is Map && log['success'] == true) {
        successful++;
      }
    }
    
    return (successful / logs.length) * 100;
  }

  static double _calculateQrScanRate(Map<String, dynamic> qrEvents) {
    final events = qrEvents['data'] as List? ?? [];
    if (events.isEmpty) return 0.0;
    
    int totalScans = 0;
    int totalCapacity = 0;
    
    for (var event in events) {
      if (event is Map) {
        totalScans += (event['scans_count'] as int? ?? 0);
        totalCapacity += (event['max_capacity'] as int? ?? 0);
      }
    }
    
    if (totalCapacity == 0) return 0.0;
    return (totalScans / totalCapacity) * 100;
  }
}
