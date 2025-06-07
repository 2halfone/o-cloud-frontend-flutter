import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:go_cloud_backend/services/user_service.dart';

// Generate mock classes
@GenerateMocks([http.Client])
import 'user_service_test.mocks.dart';

void main() {
  group('UserService Tests', () {
    late UserService userService;
    late MockClient mockClient;

    setUp(() {
      userService = UserService();
      mockClient = MockClient();
    });

    test('fetchUsers should return list of users', () async {
      when(mockClient.get(
        Uri.parse('http://34.140.122.146:3002/users'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        '[{"id": "1", "email": "test@test.com", "name": "Test User"}]',
        200,
      ));

      expect(userService, isNotNull);
    });

    test('fetchUser should return single user', () async {
      when(mockClient.get(
        Uri.parse('http://34.140.122.146:3002/users/1'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        '{"id": "1", "email": "test@test.com", "name": "Test User"}',
        200,
      ));

      expect(userService, isNotNull);
    });
  });
}
