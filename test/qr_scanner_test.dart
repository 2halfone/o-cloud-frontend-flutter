import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_cloud_backend/screens/qr_scanner_screen.dart';
import 'package:go_cloud_backend/models/attendance.dart';

void main() {
  group('QR Scanner Tests', () {
    testWidgets('QR Scanner Screen should build correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QRScannerScreen(),
        ),
      );

      // Verify the screen builds without errors
      expect(find.byType(QRScannerScreen), findsOneWidget);
      
      // Verify header elements
      expect(find.text('QR Scanner'), findsOneWidget);
      expect(find.text('Scan the code to register attendance'), findsOneWidget);
      
      // Verify control buttons
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Flash'), findsOneWidget);
    });

    test('QRContent should serialize correctly', () {
      final qrContent = QRContent(
        jwt: 'test.jwt.token',
        type: 'attendance',
        version: '1.0',
      );

      final json = qrContent.toJson();
      expect(json['jwt'], 'test.jwt.token');
      expect(json['type'], 'attendance');
      expect(json['version'], '1.0');

      final fromJson = QRContent.fromJson(json);
      expect(fromJson.jwt, qrContent.jwt);
      expect(fromJson.type, qrContent.type);
      expect(fromJson.version, qrContent.version);
    });

    test('AttendanceRequest should serialize correctly without status', () {
      final qrContent = QRContent(
        jwt: 'test.jwt.token',
        type: 'attendance',
        version: '1.0',
      );

      final request = AttendanceRequest(
        qrContent: qrContent,
      );

      final json = request.toJson();
      expect(json['qr_content'], isA<QRContent>());
      expect(json['reason'], isNull);

      final fromJson = AttendanceRequest.fromJson(json);
      expect(fromJson.qrContent.jwt, request.qrContent.jwt);
      expect(fromJson.reason, request.reason);
    });

    test('AttendanceRequest with reason should serialize correctly', () {
      final qrContent = QRContent(
        jwt: 'test.jwt.token',
        type: 'attendance',
        version: '1.0',
      );

      final request = AttendanceRequest(
        qrContent: qrContent,
        reason: 'Emergency leave',
      );

      final json = request.toJson();
      expect(json['qr_content'], isA<QRContent>());
      expect(json['reason'], 'Emergency leave');

      final fromJson = AttendanceRequest.fromJson(json);
      expect(fromJson.qrContent.jwt, request.qrContent.jwt);
      expect(fromJson.reason, request.reason);
    });    test('AttendanceResponse should handle new API fields', () {
      final response = AttendanceResponse(
        message: 'Attendance registered successfully',
        eventId: 'event123',
        eventName: 'Daily Attendance',
        status: AttendanceStatus.present,
        timestamp: DateTime(2024, 1, 15, 9, 0, 0),
        success: true,
        validation: 'valid',
        tableName: 'user_attendance',
      );

      final json = response.toJson();
      expect(json['message'], 'Attendance registered successfully');
      expect(json['event_id'], 'event123');
      expect(json['event_name'], 'Daily Attendance');
      expect(json['status'], 'present');
      expect(json['success'], true);
      expect(json['validation'], 'valid');
      expect(json['table_name'], 'user_attendance');

      final fromJson = AttendanceResponse.fromJson(json);
      expect(fromJson.message, response.message);
      expect(fromJson.eventId, response.eventId);
      expect(fromJson.eventName, response.eventName);
      expect(fromJson.status, response.status);
      expect(fromJson.success, response.success);
      expect(fromJson.validation, response.validation);
      expect(fromJson.tableName, response.tableName);
    });
  });
}
