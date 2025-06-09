import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_cloud_backend/screens/qr_scanner_screen.dart';
import 'package:go_cloud_backend/widgets/qr_scanner/attendance_form.dart';
import 'package:go_cloud_backend/models/attendance.dart';

void main() {
  group('QR Scanner Tests', () {
    testWidgets('QR Scanner Screen should build correctly', (WidgetTester tester) async {      await tester.pumpWidget(
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
    });    testWidgets('Attendance Form should build correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AttendanceForm(
              qrData: '{"jwt":"test.jwt.token","type":"attendance","version":"1.0"}',
              onSubmitSuccess: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify the form builds
      expect(find.byType(AttendanceForm), findsOneWidget);
      
      // Verify header
      expect(find.text('Register Attendance'), findsOneWidget);
      expect(find.text('Confirm your attendance today'), findsOneWidget);
      
      // Verify QR data display
      expect(find.text('QR Code Scanned:'), findsOneWidget);
      
      // Verify status selection
      expect(find.text('Attendance Status'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      
      // Verify action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('Attendance Form cancel button should work', (WidgetTester tester) async {
      bool wasCancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AttendanceForm(
              qrData: '{"jwt":"test.jwt.token","type":"attendance","version":"1.0"}',
              onSubmitSuccess: () {},
              onCancel: () => wasCancelled = true,
            ),
          ),
        ),
      );

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Verify cancel was called
      expect(wasCancelled, isTrue);
    });

    test('AttendanceStatus enum should have correct values', () {
      expect(AttendanceStatus.present.toString(), 'AttendanceStatus.present');
      expect(AttendanceStatus.vacation.toString(), 'AttendanceStatus.vacation');
      expect(AttendanceStatus.hospital.toString(), 'AttendanceStatus.hospital');
      expect(AttendanceStatus.family.toString(), 'AttendanceStatus.family');
      expect(AttendanceStatus.sick.toString(), 'AttendanceStatus.sick');
      expect(AttendanceStatus.personal.toString(), 'AttendanceStatus.personal');
      expect(AttendanceStatus.business.toString(), 'AttendanceStatus.business');
      expect(AttendanceStatus.other.toString(), 'AttendanceStatus.other');
    });    test('QRContent should serialize correctly', () {
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

    test('AttendanceRequest should serialize correctly', () {
      final qrContent = QRContent(
        jwt: 'test.jwt.token',
        type: 'attendance',
        version: '1.0',
      );

      final request = AttendanceRequest(
        qrContent: qrContent,
        status: AttendanceStatus.present,
      );

      final json = request.toJson();
      expect(json['qr_content'], isA<Map<String, dynamic>>());
      expect(json['status'], 'present');
      expect(json['reason'], isNull);

      final fromJson = AttendanceRequest.fromJson(json);
      expect(fromJson.qrContent.jwt, request.qrContent.jwt);
      expect(fromJson.status, request.status);
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
        status: AttendanceStatus.sick,
        reason: 'Sick leave',
      );

      final json = request.toJson();
      expect(json['qr_content'], isA<Map<String, dynamic>>());
      expect(json['status'], 'sick');
      expect(json['reason'], 'Sick leave');

      final fromJson = AttendanceRequest.fromJson(json);
      expect(fromJson.qrContent.jwt, request.qrContent.jwt);
      expect(fromJson.status, request.status);
      expect(fromJson.reason, request.reason);
    });
  });
}
