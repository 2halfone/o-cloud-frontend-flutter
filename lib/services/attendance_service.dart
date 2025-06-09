import 'dart:convert';
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
        print('🔄 AttendanceService: Attempt $attempts/$maxRetries');
        return await _performAttendanceSubmission(request);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        final errorMessage = e.toString().toLowerCase();
        
        // Check if this is a synchronization/concurrency error that might benefit from retry
        if (_isRetryableError(errorMessage) && attempts < maxRetries) {
          final delay = retryDelayMs * attempts; // Exponential backoff
          print('⏳ AttendanceService: Retryable error detected, waiting ${delay}ms before retry $attempts/$maxRetries');
          print('🔍 AttendanceService: Error: $errorMessage');
          
          await Future.delayed(Duration(milliseconds: delay));
          continue;
        } else {
          // Non-retryable error or max retries reached
          print('❌ AttendanceService: Final error after $attempts attempts: $e');
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
    }
    
    // Define which errors are worth retrying for synchronization issues
    final retryableErrors = [
      // Italian error messages
      'sincronizzazione',
      'errore di sincronizzazione',
      'conflitto',
      'presenza esistente',
      'presenza duplicata',
      'già registrato',
      'operazione in corso',
      
      // English error messages
      'synchronization',
      'sync error',
      'concurrent',
      'conflict',
      'duplicate',
      'already exists',
      'already registered',
      'operation in progress',
      'resource locked',
      'lock',
      
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
    ];
    
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
        
        print('👤 AttendanceService: Current user ID: $userId');
        print('🎭 AttendanceService: Current user role: $userRole');
        print('📧 AttendanceService: Current user email: $userEmail');
        
        // Also decode the QR JWT to see event details
        final qrJwt = request.qrContent.jwt;
        final decodedQrToken = JwtDecoder.decode(qrJwt);
        final eventCreatedBy = decodedQrToken['created_by'];
        final eventId = decodedQrToken['event_id'];
        
        print('🎯 AttendanceService: Event ID: $eventId');
        print('👨‍💼 AttendanceService: Event created by user ID: $eventCreatedBy');
        
        // Check if current user is trying to mark attendance on their own event
        if (userId.toString() == eventCreatedBy.toString()) {
          print('⚠️ AttendanceService: WARNING - User is trying to mark attendance on their own event!');
        }
      } catch (jwtError) {
        print('🔍 AttendanceService: Could not decode tokens for debugging: $jwtError');
      }

      final url = '$_baseUrl/user/qr/scan';
      print('🌐 AttendanceService: Making request to: $url');
      print('📝 AttendanceService: Request data: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );      print('📡 AttendanceService: Response status: ${response.statusCode}');
      print('📄 AttendanceService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        print('✅ AttendanceService: Attendance submitted successfully');
        return AttendanceResponse.fromJson(jsonData);      } else if (response.statusCode == 500) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Internal server error';
        final details = errorData['details'] ?? '';
        print('🔴 AttendanceService: Server error (500): $errorMsg');
        print('🔍 AttendanceService: Error details: $details');
        
        // Provide user-friendly error messages for specific server errors
        if (errorMsg.contains('presenza esistente') || errorMsg.contains('already exists') || errorMsg.contains('duplicate')) {
          throw Exception('Presenza già registrata per oggi. Non è possibile registrare una presenza duplicata.');
        } else if (details.contains('column') && details.contains('does not exist')) {
          // Database schema issue - this should not be retried
          throw Exception('Errore di configurazione del sistema. Contatta l\'amministratore per risolvere il problema del database.');
        } else if (errorMsg.contains('failed to insert user') || errorMsg.contains('user-service')) {
          // User service synchronization issue
          throw Exception('Errore nella sincronizzazione dell\'account utente. Il sistema potrebbe richiedere aggiornamenti di configurazione.');
        } else if (errorMsg.contains('sincronizzazione') || errorMsg.contains('synchronization') || errorMsg.contains('concurrent')) {
          throw Exception('Errore di sincronizzazione. Sto riprovando automaticamente...');
        } else if (errorMsg.contains('timeout') || errorMsg.contains('busy')) {
          throw Exception('Il server è temporaneamente occupato. Riprovo automaticamente...');
        } else {
          throw Exception('Errore interno del server: $errorMsg');
        }
      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Conflict error';
        print('🟡 AttendanceService: Conflict error (409): $errorMsg');
        
        // 409 usually indicates a conflict, which is often retryable
        throw Exception('Conflitto rilevato: $errorMsg');
      } else if (response.statusCode == 503 || response.statusCode == 504) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Service unavailable';
        print('🟡 AttendanceService: Service unavailable (${response.statusCode}): $errorMsg');
        
        // 503/504 are temporary and should be retried
        throw Exception('Servizio temporaneamente non disponibile. Riprovo...');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Failed to submit attendance';
        print('⚠️ AttendanceService: HTTP ${response.statusCode} error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ AttendanceService: Error occurred: $e');
      throw Exception('Network error: $e');
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

      final url = '$_baseUrl/user/qr/attendance/today';
      print('🌐 AttendanceService: Checking today\'s attendance: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 AttendanceService: Today attendance response status: ${response.statusCode}');
      print('📄 AttendanceService: Today attendance response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return TodayAttendanceResponse.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch today\'s attendance');
      }
    } catch (e) {
      print('❌ AttendanceService: Error fetching today\'s attendance: $e');
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
      print('Error parsing QR content: $e');
      return null;
    }
  }
  // Helper method to get status labels for UI
  String getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.vacation:
        return 'Vacation';
      case AttendanceStatus.hospital:
        return 'Hospital';
      case AttendanceStatus.family:
        return 'Family Reasons';
      case AttendanceStatus.sick:
        return 'Sick Leave';
      case AttendanceStatus.personal:
        return 'Personal Reasons';
      case AttendanceStatus.business:
        return 'Business Trip';
      case AttendanceStatus.other:
        return 'Other';
    }
  }

  // Get list of available status options
  List<AttendanceStatus> getAvailableStatuses() {
    return AttendanceStatus.values;
  }  // Check if status requires family reason
  bool requiresMotivation(AttendanceStatus status) {
    return status == AttendanceStatus.family;
  }
}
