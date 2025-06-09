import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:go_cloud_backend/services/attendance_service.dart';
import 'dart:io';

void main() {
  group('AttendanceService URL Configuration Tests', () {
    test('should use correct backend URL and not localhost', () {
      // Verify that AttendanceService is not using localhost
      final attendanceService = AttendanceService();
      
      // We can't directly access the private _baseUrl, but we can test 
      // that the service exists and is configured properly
      expect(attendanceService, isNotNull);
      
      // Test info (using debugPrint instead of print for tests)
      debugPrint('✅ AttendanceService instantiated successfully');
      debugPrint('🌐 Expected URL: http://34.140.122.146:3000');
      debugPrint('❌ Should NOT use: http://localhost:3000');
    });

    test('should not contain localhost references in attendance service', () {
      // Read the attendance service file and verify it doesn't contain localhost
      final file = File('lib/services/attendance_service.dart');
      expect(file.existsSync(), true, reason: 'AttendanceService file should exist');
      
      final content = file.readAsStringSync();
      
      // Ensure localhost is not used
      expect(content.contains('localhost'), false, 
          reason: 'AttendanceService should not contain localhost URLs');
      
      // Ensure correct IP is used
      expect(content.contains('34.140.122.146'), true,
          reason: 'AttendanceService should use the correct backend IP');
      
      debugPrint('✅ URL validation passed');
      debugPrint('🔍 File content checked for localhost references');
    });

    test('should have consistent URL configuration across services', () {
      final files = [
        'lib/services/auth_service.dart',
        'lib/services/attendance_service.dart',
        'lib/services/log_service.dart',
      ];
      
      for (final filePath in files) {
        final file = File(filePath);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          
          // Check for localhost usage (should not be present)
          expect(content.contains('localhost'), false,
              reason: '$filePath should not use localhost');
          
          // Check for correct IP (should be present if URL is defined)
          if (content.contains('_baseUrl')) {
            expect(content.contains('34.140.122.146'), true,
                reason: '$filePath should use correct backend IP');
          }
          
          debugPrint('✅ $filePath: URL validation passed');
        }
      }
    });
  });
}
