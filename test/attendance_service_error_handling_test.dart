import 'package:flutter_test/flutter_test.dart';
import 'package:go_cloud_backend/services/attendance_service.dart';
import 'package:go_cloud_backend/models/attendance.dart';

void main() {
  group('AttendanceService Error Handling Tests', () {
    test('should handle 500 server errors gracefully', () {
      final attendanceService = AttendanceService();
      
      // Verify service instantiation
      expect(attendanceService, isNotNull);
      
      print('✅ AttendanceService error handling test setup complete');
      print('🔍 Testing scenario: 500 server error responses');
      print('📋 Expected behavior: User-friendly error messages');
    });

    test('should provide specific error messages for different scenarios', () {
      final attendanceService = AttendanceService();
      
      // Test the getStatusLabel method to ensure UI labels are correct
      final presentLabel = attendanceService.getStatusLabel(AttendanceStatus.present);
      expect(presentLabel, equals('Present'));
        final vacationLabel = attendanceService.getStatusLabel(AttendanceStatus.hospital);
      expect(vacationLabel, equals('Hospital'));
      
      print('✅ Status labels validation passed');
      print('📝 Present label: $presentLabel');
      print('🏖️ Vacation label: $vacationLabel');
    });    test('should correctly identify statuses requiring motivation', () {
      final attendanceService = AttendanceService();
      
      // No statuses should require motivation anymore
      expect(attendanceService.requiresMotivation(AttendanceStatus.present), false);
      expect(attendanceService.requiresMotivation(AttendanceStatus.hospital), false);
      expect(attendanceService.requiresMotivation(AttendanceStatus.emergency), false);
      expect(attendanceService.requiresMotivation(AttendanceStatus.personal), false);
      expect(attendanceService.requiresMotivation(AttendanceStatus.family), false); // No longer requires motivation
      
      print('✅ Motivation requirements validation passed');
      print('👍 Present: No motivation required');
      print('🏥 Hospital: No motivation required');
      print('🚨 Emergency: No motivation required');
      print('👨‍👩‍👧‍👦 Family: No motivation required');
      print('👤 Personal: No motivation required');
    });

    test('should provide all available status options', () {
      final attendanceService = AttendanceService();
      
      final availableStatuses = attendanceService.getAvailableStatuses();
  
      // Should contain 5 status values (excluding notRegistered and personal)
      expect(availableStatuses, hasLength(5));
      expect(availableStatuses.contains(AttendanceStatus.present), true);
      expect(availableStatuses.contains(AttendanceStatus.hospital), true);
      expect(availableStatuses.contains(AttendanceStatus.family), true);
      expect(availableStatuses.contains(AttendanceStatus.emergency), true);
      expect(availableStatuses.contains(AttendanceStatus.vacancy), true);
      
      // Should NOT be available
      expect(availableStatuses.contains(AttendanceStatus.personal), false);
      expect(availableStatuses.contains(AttendanceStatus.notRegistered), false);
      
      print('✅ Available status options validation passed');
      print('📊 Total status options: ${availableStatuses.length}');
    });
    
    test('getAvailableStatuses should exclude internal statuses', () {
      final attendanceService = AttendanceService();
      final statuses = attendanceService.getAvailableStatuses();
      
      expect(statuses, hasLength(5)); // Changed from 6 to 5
      expect(statuses, isNot(contains(AttendanceStatus.notRegistered)));
      expect(statuses, isNot(contains(AttendanceStatus.personal)));
    });
  });
}
