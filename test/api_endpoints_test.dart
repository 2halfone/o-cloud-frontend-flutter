import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('API Endpoints Connectivity Tests', () {
    const String baseUrl = 'http://34.140.122.146:3000';
    
    test('should connect to backend server', () async {
      try {
        final response = await http.get(Uri.parse(baseUrl)).timeout(
          const Duration(seconds: 10),
        );
        
        print('✅ Backend server status: ${response.statusCode}');
        print('📡 Response body: ${response.body}');
        
        expect(response.statusCode, equals(200));
        
        // Parse the endpoints from response
        final data = jsonDecode(response.body);
        expect(data['status'], equals('running'));
        expect(data['endpoints'], isNotNull);
        
        print('🔍 Available endpoints:');
        final endpoints = data['endpoints'] as Map<String, dynamic>;
        endpoints.forEach((key, value) {
          print('  $key: $value');
        });
        
      } catch (e) {
        fail('Failed to connect to backend: $e');
      }
    });
    
    test('should have correct QR user endpoints', () async {
      try {
        final response = await http.get(Uri.parse(baseUrl)).timeout(
          const Duration(seconds: 10),
        );
        
        final data = jsonDecode(response.body);
        final endpoints = data['endpoints'] as Map<String, dynamic>;
        
        // Check QR user endpoints
        expect(endpoints['qr_user'], isNotNull);
        final qrUserEndpoints = endpoints['qr_user'] as String;
        
        print('🎯 QR User endpoints: $qrUserEndpoints');
        
        // Verify it contains the expected endpoints
        expect(qrUserEndpoints, contains('/user/qr/scan'));
        expect(qrUserEndpoints, contains('/user/qr/attendance/history'));
        expect(qrUserEndpoints, contains('/user/qr/attendance/today'));
        
        print('✅ All QR user endpoints are available');
        
      } catch (e) {
        fail('Failed to verify QR endpoints: $e');
      }
    });
    
    test('should have correct QR admin endpoints', () async {
      try {
        final response = await http.get(Uri.parse(baseUrl)).timeout(
          const Duration(seconds: 10),
        );
        
        final data = jsonDecode(response.body);
        final endpoints = data['endpoints'] as Map<String, dynamic>;
        
        // Check QR admin endpoints
        expect(endpoints['qr_admin'], isNotNull);
        final qrAdminEndpoints = endpoints['qr_admin'] as String;
        
        print('🎯 QR Admin endpoints: $qrAdminEndpoints');
        
        // Verify it contains the expected endpoints
        expect(qrAdminEndpoints, contains('/user/qr/admin/generate'));
        
        print('✅ QR admin endpoints are available');
        
      } catch (e) {
        fail('Failed to verify QR admin endpoints: $e');
      }
    });
    
    test('should verify authentication endpoints', () async {
      try {
        final response = await http.get(Uri.parse(baseUrl)).timeout(
          const Duration(seconds: 10),
        );
        
        final data = jsonDecode(response.body);
        final endpoints = data['endpoints'] as Map<String, dynamic>;
        
        // Check auth endpoints
        expect(endpoints['auth'], isNotNull);
        final authEndpoints = endpoints['auth'] as String;
        
        print('🔐 Auth endpoints: $authEndpoints');
        
        // Verify it contains the expected endpoints
        expect(authEndpoints, contains('/auth/register'));
        expect(authEndpoints, contains('/auth/login'));
        
        print('✅ Authentication endpoints are available');
        
      } catch (e) {
        fail('Failed to verify auth endpoints: $e');
      }
    });
  });
}
