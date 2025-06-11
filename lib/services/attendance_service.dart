import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/attendance.dart';
import '../utils/token_manager.dart';

class AttendanceService {
  static const String _baseUrl = 'http://34.140.122.146:3000'; // Gateway URL
  Future<AttendanceResponse> submitAttendance(AttendanceRequest request) async {
    // Retry logic for handling synchronization errors
    return await _submitAttendanceWithRetry(request, maxRetries: 3);
  }

  Future<AttendanceResponse> _submitAttendanceWithRetry(
    AttendanceRequest request, {
    int maxRetries = 3,
    int retryDelayMs = 1000,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      attempts++;
      
      try {
        debugPrint('🔄 AttendanceService: Attempt $attempts/$maxRetries');
        return await _performAttendanceSubmission(request);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        final errorMessage = e.toString().toLowerCase();
        
        // Check if this is a synchronization/concurrency error that might benefit from retry
        if (_isRetryableError(errorMessage) && attempts < maxRetries) {
          final delay = retryDelayMs * attempts; // Exponential backoff
          debugPrint('⏳ AttendanceService: Retryable error detected, waiting ${delay}ms before retry $attempts/$maxRetries');
          debugPrint('🔍 AttendanceService: Error: $errorMessage');
          
          await Future.delayed(Duration(milliseconds: delay));
          continue;
        } else {
          // Non-retryable error or max retries reached
          debugPrint('❌ AttendanceService: Final error after $attempts attempts: $e');
          throw lastException;
        }
      }
    }
    
    throw lastException ?? Exception('Max retries reached');
  }  bool _isRetryableError(String errorMessage) {
    // First check for non-retryable errors (configuration/schema issues)
    final nonRetryableErrors = [
      'column',
      'does not exist',
      'schema',
      'table does not exist',
      'syntax error',
      'authentication failed',
      'invalid token',
      'expired token',
      'permission denied',
      'unauthorized',
      'forbidden',
      'failed to insert user into user-service', // Specific backend configuration issue
      'user-service.*column.*does not exist',    // User service schema issue
    ];
    
    // If it's a non-retryable error, don't retry
    if (nonRetryableErrors.any((error) => errorMessage.contains(error))) {
      return false;
    }    // Define which errors are worth retrying for synchronization issues
    final retryableErrors = [
      // English error messages (translated from Italian)
      'synchronization',
      'synchronization error',
      'conflict',
      'operation in progress',
      
      // English error messages
      'synchronization',
      'sync error',
      'concurrent',
      'conflict',
      'operation in progress',
      'resource locked',
      'lock',
      
      // Italian server messages that might still come from backend
      'sincronizzazione',
      'errore di sincronizzazione',
      'conflitto',
      'operazione in corso',
      
      // Network and server errors
      'timeout',
      'connection timeout',
      'server error',
      'internal server error',
      'temporary',
      'temporarily unavailable',
      'busy',
      'service unavailable',
      '503',
      '504',
      
      // Database errors that might indicate concurrency issues
      'deadlock',
      'transaction',
      'rollback',
      'constraint violation',
    ];    // These errors should NOT be retried as they indicate permanent conflicts
    final nonRetryableAttendanceErrors = [
      'attendance already exists',
      'duplicate attendance',
      'already registered',
      'duplicate',
      'already exists',
      'already registered',
      'attendance already recorded',
      // Italian server messages
      'hai già registrato',
      'presenza già registrata',
      'presenza esistente',
      'utente registrato',
      'duplicato',
    ];
    
    // Check for non-retryable attendance errors first
    if (nonRetryableAttendanceErrors.any((error) => errorMessage.contains(error))) {
      debugPrint('🚫 AttendanceService: Non-retryable attendance error detected: $errorMessage');
      return false;
    }
    
    return retryableErrors.any((error) => errorMessage.contains(error));
  }
  Future<AttendanceResponse> _performAttendanceSubmission(AttendanceRequest request) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }      // Decode the user token to log user info for debugging
      try {
        final decodedUserToken = JwtDecoder.decode(token);
        final userId = decodedUserToken['user_id'] ?? decodedUserToken['sub'] ?? decodedUserToken['id'];
        final userRole = decodedUserToken['role'] ?? decodedUserToken['user_type'];
        final userEmail = decodedUserToken['email'];
        
        debugPrint('👤 AttendanceService: Current user ID: $userId');
        debugPrint('🎭 AttendanceService: Current user role: $userRole');
        debugPrint('📧 AttendanceService: Current user email: $userEmail');
        
        // Also decode the QR JWT to see event details
        final qrJwt = request.qrContent.jwt;
        final decodedQrToken = JwtDecoder.decode(qrJwt);
        final eventCreatedBy = decodedQrToken['created_by'];
        final eventId = decodedQrToken['event_id'];
        
        debugPrint('🎯 AttendanceService: Event ID: $eventId');
        debugPrint('👨‍💼 AttendanceService: Event created by user ID: $eventCreatedBy');
        
        // Check if current user is trying to mark attendance on their own event
        if (userId.toString() == eventCreatedBy.toString()) {
          debugPrint('⚠️ AttendanceService: WARNING - User is trying to mark attendance on their own event!');
        }
      } catch (jwtError) {
        debugPrint('🔍 AttendanceService: Could not decode tokens for debugging: $jwtError');
      }      const url = '$_baseUrl/user/qr/scan';
      debugPrint('🌐 AttendanceService: Making request to: $url');
      debugPrint('📝 AttendanceService: Request data: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      debugPrint('📡 AttendanceService: Response status: ${response.statusCode}');
      debugPrint('📄 AttendanceService: Response headers: ${response.headers}');
      debugPrint('📜 AttendanceService: Response body: ${response.body}');
      debugPrint('📄 AttendanceService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        debugPrint('✅ AttendanceService: Attendance submitted successfully');
        return AttendanceResponse.fromJson(jsonData);      } else if (response.statusCode == 500) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Internal server error';
        final details = errorData['details'] ?? '';
        debugPrint('🔴 AttendanceService: Server error (500): $errorMsg');
        debugPrint('🔍 AttendanceService: Error details: $details');        // Provide user-friendly error messages for specific server errors
        if (errorMsg.contains('attendance already exists') || errorMsg.contains('already exists') || errorMsg.contains('duplicate')) {
          throw Exception('Attendance already registered for today. Cannot register duplicate attendance.');
        } else if (errorMsg.contains('hai già registrato') || errorMsg.contains('presenza già registrata') || errorMsg.contains('presenza esistente')) {
          throw Exception('Attendance already registered for today. Cannot register duplicate attendance.');
        } else if (details.contains('column') && details.contains('does not exist')) {
          // Database schema issue - this should not be retried
          throw Exception('System configuration error. Please contact administrator to resolve database issue.');
        } else if (errorMsg.contains('failed to insert user') || errorMsg.contains('user-service')) {
          // User service synchronization issue
          throw Exception('User account synchronization error. System may require configuration updates.');
        } else if (errorMsg.contains('synchronization') || errorMsg.contains('synchronization error') || errorMsg.contains('concurrent')) {
          throw Exception('Synchronization error. Retrying automatically...');
        } else if (errorMsg.contains('sincronizzazione') || errorMsg.contains('errore di sincronizzazione')) {
          throw Exception('Synchronization error. Retrying automatically...');
        } else if (errorMsg.contains('timeout') || errorMsg.contains('busy')) {
          throw Exception('Server is temporarily busy. Retrying automatically...');
        } else {
          throw Exception('Internal server error: $errorMsg');
        }} else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Unauthorized';
        debugPrint('🔴 AttendanceService: Authentication error (401): $errorMsg');
        debugPrint('🔍 AttendanceService: User may not be properly authenticated or token expired');
          throw Exception('Authentication error. Please login again and try again.');
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Forbidden';
        debugPrint('🔴 AttendanceService: Authorization error (403): $errorMsg');
        debugPrint('🔍 AttendanceService: User role may not have permission for attendance registration');
        
        throw Exception('Access denied. Your user role does not have permissions to register attendance. Contact administrator.');      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Conflict error';
        debugPrint('🟡 AttendanceService: Conflict error (409): $errorMsg');
        
        // Translate Italian server messages to English
        String translatedMsg = errorMsg;
        if (errorMsg.contains('hai già registrato') || errorMsg.contains('presenza già registrata') || errorMsg.contains('duplicato')) {
          translatedMsg = 'Attendance already registered for today. You cannot register duplicate attendance.';
        } else if (errorMsg.contains('presenza esistente')) {
          translatedMsg = 'Attendance already exists for this event.';
        } else if (errorMsg.contains('utente registrato')) {
          translatedMsg = 'User already registered for this event.';
        }
        
        throw Exception(translatedMsg);
      } else if (response.statusCode == 503 || response.statusCode == 504) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Service unavailable';
        debugPrint('🟡 AttendanceService: Service unavailable (${response.statusCode}): $errorMsg');
          // 503/504 are temporary and should be retried
        throw Exception('Service temporarily unavailable. Retrying...');      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Failed to submit attendance';
        debugPrint('⚠️ AttendanceService: HTTP ${response.statusCode} error: $errorMsg');
        
        // Translate any remaining Italian server messages to English
        String translatedMsg = errorMsg;
        if (errorMsg.contains('hai già registrato') || errorMsg.contains('presenza già registrata')) {
          translatedMsg = 'Attendance already registered for today.';
        } else if (errorMsg.contains('presenza esistente')) {
          translatedMsg = 'Attendance already exists for this event.';
        } else if (errorMsg.contains('utente registrato')) {
          translatedMsg = 'User already registered for this event.';
        } else if (errorMsg.contains('sincronizzazione')) {
          translatedMsg = 'Synchronization error. Please try again.';
        } else if (errorMsg.contains('errore di autenticazione')) {
          translatedMsg = 'Authentication error. Please login again.';
        } else if (errorMsg.contains('accesso negato')) {
          translatedMsg = 'Access denied. Contact administrator.';
        }
        
        throw Exception(translatedMsg);
      }    } catch (e) {
      debugPrint('❌ AttendanceService: Exception caught: $e');
      debugPrint('🔍 AttendanceService: Exception type: ${e.runtimeType}');
      
      // Check if it's actually a network/connection error
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') || 
          e.toString().contains('timeout') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        debugPrint('🌐 AttendanceService: Confirmed network error');
        throw Exception('Network error: $e');
      } else if (e.toString().contains('FormatException') || 
                 e.toString().contains('json')) {
        debugPrint('📄 AttendanceService: JSON parsing error');        throw Exception('Server response format error. Please try again later.');
      } else if (e.toString().contains('TimeoutException')) {
        debugPrint('⏱️ AttendanceService: Request timeout');
        throw Exception('Request timeout. Check your connection and try again.');
      } else {
        // For other exceptions, preserve the original error message
        debugPrint('⚠️ AttendanceService: Generic error, preserving original message');
        throw Exception(e.toString());
      }
    }
  }

  Future<AttendanceHistoryResponse> getAttendanceHistory({int page = 1, int limit = 10}) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }      final response = await http.get(
        Uri.parse('$_baseUrl/user/qr/attendance/history?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AttendanceHistoryResponse.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch attendance history');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  Future<TodayAttendanceResponse> getTodayAttendance() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      const url = '$_baseUrl/user/qr/attendance/today';
      debugPrint('🌐 AttendanceService: Checking today\'s attendance: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 AttendanceService: Today attendance response status: ${response.statusCode}');
      debugPrint('📄 AttendanceService: Today attendance response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return TodayAttendanceResponse.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch today\'s attendance');
      }
    } catch (e) {
      debugPrint('❌ AttendanceService: Error fetching today\'s attendance: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<bool> checkHealthStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

    // Helper method to parse QR content from scanned string
  QRContent? parseQRContent(String qrString) {
    try {
      final jsonData = jsonDecode(qrString);
      return QRContent.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing QR content: $e');
      return null;
    }
  }  // Helper method to get status labels for UI
  String getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.hospital:
        return 'Hospital';
      case AttendanceStatus.family:
        return 'Family Reasons';
      case AttendanceStatus.emergency:
        return 'Emergency';
      case AttendanceStatus.vacancy:
        return 'Vacancy';
      case AttendanceStatus.personal:
        return 'Personal Reasons';
      case AttendanceStatus.notRegistered:
        return 'Not Registered';
    }
  }
  // Get list of available status options
  List<AttendanceStatus> getAvailableStatuses() {
    return [
      AttendanceStatus.present,
      AttendanceStatus.hospital,
      AttendanceStatus.family,
      AttendanceStatus.emergency,
      AttendanceStatus.vacancy,
      // Removed: AttendanceStatus.personal (not shown to users)
      // Removed: AttendanceStatus.notRegistered (internal use only)
    ];
  }  // Check if status requires family reason
  bool requiresMotivation(AttendanceStatus status) {
    return false; // No statuses require motivation text input
  }
}
