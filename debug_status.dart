import 'lib/models/attendance.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

void main() {
  debugPrint('=== DEBUG STATUS VALUES ===');
  
  // Testa tutti i valori status
  for (AttendanceStatus status in AttendanceStatus.values) {
    final request = AttendanceRequest(
      qrContent: QRContent(jwt: 'test', type: 'test', version: '1.0'),
      status: status,
      reason: null,
    );
    
    final json = request.toJson();
    debugPrint('${status.toString()} → JSON: ${json['status']}');
  }
  
  debugPrint('\n=== JSON COMPLETO ===');
  final testRequest = AttendanceRequest(
    qrContent: QRContent(jwt: 'test_jwt', type: 'attendance', version: '1.0'),
    status: AttendanceStatus.present,
    reason: null,
  );
  
  debugPrint(jsonEncode(testRequest.toJson()));
}
