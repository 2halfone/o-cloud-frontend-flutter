import 'package:flutter_test/flutter_test.dart';
import 'package:go_cloud_backend/models/attendance.dart';

void main() {
  group('AttendanceStatus JSON Values Tests', () {
    test('should serialize AttendanceStatus.present as "presente"', () {
      final request = AttendanceRequest(
        qrContent: QRContent(
          jwt: 'test-jwt',
          type: 'attendance_qr',
          version: '1.0',
        ),
        status: AttendanceStatus.present,
        reason: null,
      );

      final json = request.toJson();
      expect(json['status'], equals('presente'));
      
      print('✅ AttendanceStatus.present serializes to: ${json['status']}');
    });

    test('should have correct JSON values for all status types', () {
      final expectedValues = {
        AttendanceStatus.present: 'presente',
        AttendanceStatus.vacation: 'vacation',
        AttendanceStatus.hospital: 'hospital',
        AttendanceStatus.family: 'family',
        AttendanceStatus.sick: 'sick',
        AttendanceStatus.personal: 'personal',
        AttendanceStatus.business: 'business',
        AttendanceStatus.other: 'other',
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
        );

        final json = request.toJson();
        expect(json['status'], equals(entry.value));
        print('✅ ${entry.key} → ${json['status']}');
      }
    });

    test('should match backend expected values', () {
      // These are the valid statuses from the backend error message
      final backendExpectedValues = [
        "presente", "vacation", "hospital", "family", 
        "sick", "personal", "business", "other"
      ];

      final appStatusValues = [
        AttendanceStatus.present,
        AttendanceStatus.vacation,
        AttendanceStatus.hospital,
        AttendanceStatus.family,
        AttendanceStatus.sick,
        AttendanceStatus.personal,
        AttendanceStatus.business,
        AttendanceStatus.other,
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
      
      print('✅ All status values match backend expectations');
    });
  });
}
