import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/admin_events.dart';
import '../utils/token_manager.dart';

class AdminEventsService {
  static const String _baseUrl = 'http://34.140.122.146:3000'; // Gateway URL

  /// Get all events with statistics (not limited to 5)
  Future<List<EventWithStatistics>> getAllEvents() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }      const url = '$_baseUrl/user/qr/admin/events';
      debugPrint('🌐 AdminEventsService: Getting all events from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );      debugPrint('📡 AdminEventsService: Response status: ${response.statusCode}');
      debugPrint('📄 AdminEventsService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final events = (jsonData['events'] as List)
            .map((event) => EventWithStatistics.fromJson(event))
            .toList();
        
        debugPrint('✅ AdminEventsService: Retrieved ${events.length} events');
        return events;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch events');
      }    } catch (e) {
      debugPrint('❌ AdminEventsService: Error fetching events: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get users for a specific event with their attendance status
  Future<EventUsersResponse> getEventUsers(
    String eventId, {
    String? statusFilter,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (statusFilter != null && statusFilter.isNotEmpty) {
        queryParams['status'] = statusFilter;
      }      final uri = Uri.parse('$_baseUrl/user/qr/admin/events/$eventId/users')
          .replace(queryParameters: queryParams);
      
      debugPrint('🌐 AdminEventsService: Getting event users from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 AdminEventsService: Response status: ${response.statusCode}');
      debugPrint('📄 AdminEventsService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return EventUsersResponse.fromJson(jsonData);      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch event users');
      }
    } catch (e) {
      debugPrint('❌ AdminEventsService: Error fetching event users: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Update user status for a specific event
  Future<UserStatusUpdateResponse> updateUserStatus(
    String eventId,
    int userId,
    String status, {
    String? motivation,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }      final url = '$_baseUrl/user/qr/admin/events/$eventId/users/$userId/status';
      debugPrint('🌐 AdminEventsService: Updating user status: $url');

      final requestBody = {
        'status': status,
        if (motivation != null) 'motivazione': motivation,
      };

      debugPrint('📝 AdminEventsService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📡 AdminEventsService: Response status: ${response.statusCode}');
      debugPrint('📄 AdminEventsService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return UserStatusUpdateResponse.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);        throw Exception(errorData['error'] ?? 'Failed to update user status');
      }
    } catch (e) {      debugPrint('❌ AdminEventsService: Error updating user status: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Delete an event
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }      final url = '$_baseUrl/user/qr/admin/events/$eventId';
      debugPrint('🌐 AdminEventsService: Deleting event: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 AdminEventsService: Delete response status: ${response.statusCode}');
      debugPrint('📄 AdminEventsService: Delete response body: ${response.body}');if (response.statusCode == 200 || response.statusCode == 204) {        final jsonData = response.statusCode == 200 
            ? jsonDecode(response.body)
            : {'message': 'Event deleted successfully'};
        debugPrint('✅ AdminEventsService: Event deleted successfully');
        return jsonData;
      } else {
        // Handle both JSON and plain text error responses
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? 'Failed to delete event';
        } catch (e) {
          // If response is not JSON, use the plain text response
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : 'Failed to delete event (HTTP ${response.statusCode})';
        }        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ AdminEventsService: Error deleting event: $e');
      throw Exception('Network error: $e');
    }
  }

  // Helper methods for UI
  String getStatusLabel(String status) {
    switch (status) {
      case 'present':
        return '✅ Present';
      case 'hospital':
        return '🏥 Hospital';
      case 'family':
        return '👨‍👩‍👧‍👦 Family Reasons';
      case 'emergency':
        return '🚨 Emergency';
      case 'vacancy':
        return '🏖️ Vacation';
      case 'personal':
        return '👤 Personal Reasons';
      case 'not_registered':
        return '⏳ Not Registered';
      default:
        return status.toUpperCase();
    }
  }

  String getStatusLabelWithoutEmoji(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'hospital':
        return 'Hospital';
      case 'family':
        return 'Family Reasons';
      case 'emergency':
        return 'Emergency';
      case 'vacancy':
        return 'Vacation';
      case 'personal':
        return 'Personal Reasons';
      case 'not_registered':
        return 'Not Registered';
      default:
        return status.toUpperCase();
    }
  }

  String getStatusEmoji(String status) {
    switch (status) {
      case 'present':
        return '✅';
      case 'hospital':
        return '🏥';
      case 'family':
        return '👨‍👩‍👧‍👦';
      case 'emergency':
        return '🚨';
      case 'vacancy':
        return '🏖️';
      case 'personal':
        return '👤';
      case 'not_registered':
        return '⏳';
      default:
        return '❓';
    }
  }

  String getStatusDescription(String status) {
    switch (status) {
      case 'present':
        return 'User is present and has scanned QR code';
      case 'hospital':
        return 'Medical appointment or hospital visit';
      case 'family':
        return 'Family emergency or family-related absence';
      case 'emergency':
        return 'General emergency situation';
      case 'vacancy':
        return 'Planned vacation or leave of absence';
      case 'personal':
        return 'Personal reasons for absence';
      case 'not_registered':
        return 'User has not yet scanned QR code';
      default:
        return 'Unknown status';
    }
  }

  List<String> getAvailableStatuses() {
    return [
      'present',
      'hospital',
      'family',
      'emergency',
      'vacancy',
      'personal',
      'not_registered',
    ];
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF4CAF50); // Green
      case 'hospital':
        return const Color(0xFFF44336); // Red
      case 'family':
        return const Color(0xFF9C27B0); // Purple
      case 'emergency':
        return const Color(0xFFFF5722); // Deep Orange
      case 'vacancy':
        return const Color(0xFF2196F3); // Blue
      case 'personal':
        return const Color(0xFF00BCD4); // Cyan
      case 'not_registered':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'hospital':
        return Icons.local_hospital;
      case 'family':
        return Icons.family_restroom;
      case 'emergency':
        return Icons.emergency;
      case 'vacancy':
        return Icons.beach_access;
      case 'personal':
        return Icons.person;
      case 'not_registered':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }
}
