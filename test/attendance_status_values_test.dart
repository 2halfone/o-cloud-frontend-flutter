import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_cloud_backend/models/attendance.dart';

void main() {
  group('New Automatic Attendance API Tests', () {
    test('should create AttendanceRequest without status field', () {
      final request = AttendanceRequest(
        qrContent: QRContent(
          jwt: 'test-jwt',
          type: 'attendance_qr',
          version: '1.0',
        ),
        reason: null,
      );

      final json = request.toJson();
      
      // Status field should NOT be present in the request
      expect(json.containsKey('status'), false);
      expect(json['qr_content'], isA<QRContent>());
      expect(json['reason'], isNull);
      
      debugPrint('✅ AttendanceRequest created without status field (automatic presence)');
    });

    test('should handle AttendanceResponse with new automatic fields', () {
      // Test the new response structure from backend
      final responseJson = {
        'success': true,
        'message': 'Presenza registrata automaticamente',
        'event_id': 'test-event-123',
        'event_name': 'Test Event',
        'status': 'present',  // Always present in response
        'timestamp': '2024-12-12T10:15:30Z',
        'validation': 'automatic',
        'table_name': 'attendance_test_event_2024_12_12',
      };

      final response = AttendanceResponse.fromJson(responseJson);
      
      expect(response.success, true);
      expect(response.message, 'Presenza registrata automaticamente');
      expect(response.eventId, 'test-event-123');
      expect(response.eventName, 'Test Event');
      expect(response.status, AttendanceStatus.present);
      expect(response.validation, 'automatic');
      expect(response.tableName, 'attendance_test_event_2024_12_12');
      
      debugPrint('✅ New automatic attendance response handled correctly');
    });

    test('should verify QRContent structure for automatic attendance', () {
      final qrContent = QRContent(
        jwt: 'eyJhbGciOiJIUzI1NiIs...',
        type: 'attendance_qr',
        version: '1.0',
      );

      final json = qrContent.toJson();
      expect(json['jwt'], 'eyJhbGciOiJIUzI1NiIs...');
      expect(json['type'], 'attendance_qr');
      expect(json['version'], '1.0');

      debugPrint('✅ QRContent structure valid for automatic attendance');
    });

    test('should create request with optional reason for automatic attendance', () {
      final request = AttendanceRequest(
        qrContent: QRContent(
          jwt: 'test-jwt',
          type: 'attendance_qr',
          version: '1.0',
        ),
        reason: 'Late arrival but present',
      );

      final json = request.toJson();
      
      expect(json.containsKey('status'), false); // Status not in request
      expect(json['reason'], 'Late arrival but present');
      
      debugPrint('✅ AttendanceRequest with reason (no status) created correctly');
    });

    test('should verify automatic attendance flow compatibility', () {
      // Simulate the new automatic flow:
      // 1. User scans QR
      // 2. Frontend creates request WITHOUT status
      // 3. Backend automatically assigns "present" status
      // 4. Response contains success confirmation
      
      final qrContent = QRContent(
        jwt: 'valid-jwt-token',
        type: 'attendance_qr',
        version: '1.0',
      );

      final request = AttendanceRequest(
        qrContent: qrContent,
      );

      // Verify request doesn't contain status
      final requestJson = request.toJson();
      expect(requestJson.containsKey('status'), false);
      
      // Simulate backend response with automatic presence
      final mockResponseJson = {
        'success': true,
        'message': 'Presenza registrata automaticamente',
        'event_id': 'daily-meeting-2024-12-12',
        'event_name': 'Daily Meeting',
        'status': 'present',  // Backend sets this automatically
        'timestamp': DateTime.now().toIso8601String(),
        'validation': 'automatic',
        'table_name': 'attendance_daily_meeting_2024_12_12',
      };

      final response = AttendanceResponse.fromJson(mockResponseJson);
      
      expect(response.success, true);
      expect(response.status, AttendanceStatus.present);
      expect(response.validation, 'automatic');
      
      debugPrint('✅ Automatic attendance flow verified: QR scan → automatic presence');
      debugPrint('   Request has no status field');
      debugPrint('   Response confirms automatic "present" status');
      debugPrint('   Backend validation: ${response.validation}');
    });
  });
}
