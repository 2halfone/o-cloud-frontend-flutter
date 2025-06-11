import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_cloud_backend/models/attendance.dart';

void main() {
  group('AttendanceStatus JSON Values Tests', () {
    test('should serialize AttendanceStatus.present as "present"', () {
      final request = AttendanceRequest(
        qrContent: QRContent(
          jwt: 'test-jwt',
          type: 'attendance_qr',
          version: '1.0',
        ),
        status: AttendanceStatus.present,
        reason: null,
      );      final json = request.toJson();
      expect(json['status'], equals('present'));
      
      debugPrint('✅ AttendanceStatus.present serializes to: ${json['status']}');
    });    test('should have correct JSON values for all status types', () {
      final expectedValues = {
        AttendanceStatus.present: 'present',
        AttendanceStatus.hospital: 'hospital',
        AttendanceStatus.family: 'family',
        AttendanceStatus.emergency: 'emergency',        AttendanceStatus.vacancy: 'vacancy',
        AttendanceStatus.personal: 'personal',
        AttendanceStatus.notRegistered: 'not_registered',
      };

      for (final entry in expectedValues.entries) {
        final request = AttendanceRequest(
          qrContent: QRContent(
            jwt: 'test-jwt',
            type: 'attendance_qr',
            version: '1.0',
          ),
          status: entry.key,
          reason: null,
        );        final json = request.toJson();
        expect(json['status'], equals(entry.value));
        debugPrint('✅ ${entry.key} → ${json['status']}');
      }
    });

    test('should match backend expected values', () {
      // These are the valid statuses from your backend
      final backendExpectedValues = [
        "present", "hospital", "family", "emergency", 
        "vacancy", "personal", "not_registered"
      ];

      final appStatusValues = [
        AttendanceStatus.present,
        AttendanceStatus.hospital,
        AttendanceStatus.family,
        AttendanceStatus.emergency,
        AttendanceStatus.vacancy,
        AttendanceStatus.personal,
        AttendanceStatus.notRegistered,
      ];

      for (int i = 0; i < appStatusValues.length; i++) {
        final request = AttendanceRequest(
          qrContent: QRContent(
            jwt: 'test-jwt',
            type: 'attendance_qr',
            version: '1.0',
          ),
          status: appStatusValues[i],
          reason: null,
        );

        final json = request.toJson();
        final serializedValue = json['status'];
          expect(backendExpectedValues.contains(serializedValue), true,
            reason: 'Status ${appStatusValues[i]} serialized to "$serializedValue" should be in backend expected values');
      }
      
      debugPrint('✅ All status values match backend expectations');
    });
  });
}
