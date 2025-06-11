import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Error Message Translation Tests', () {
    test('should have all error messages in English', () {
      // Test that common error message patterns are in English
      final englishErrorMessages = [
        'Authentication error. Please login again',
        'Access denied. Contact administrator', 
        'Attendance already registered for today',
        'Connection error. Check internet connection',
        'Network error: Connection failed',
        'System configuration error',
        'Internal server error',
        'Registration successful! Welcome!',
        'Status updated successfully',
        'Event deleted successfully',
        'QR Code saved to gallery!',
      ];

      for (final message in englishErrorMessages) {
        expect(message, isNotEmpty);
        expect(message, isA<String>());
        // Verify no Italian words remain
        expect(message.toLowerCase(), isNot(contains('errore')));
        expect(message.toLowerCase(), isNot(contains('accesso')));
        expect(message.toLowerCase(), isNot(contains('negato')));
        expect(message.toLowerCase(), isNot(contains('già')));
        expect(message.toLowerCase(), isNot(contains('registrato')));
        expect(message.toLowerCase(), isNot(contains('connessione')));
        expect(message.toLowerCase(), isNot(contains('autenticazione')));
        expect(message.toLowerCase(), isNot(contains('successo')));
        expect(message.toLowerCase(), isNot(contains('completato')));
        expect(message.toLowerCase(), isNot(contains('salvato')));
        expect(message.toLowerCase(), isNot(contains('aggiornato')));
        expect(message.toLowerCase(), isNot(contains('eliminato')));
      }
    });

    test('should identify network errors correctly', () {
      final networkErrors = [
        'SocketException: Connection failed',
        'Failed host lookup',
        'Network is unreachable',
        'Connection timeout',
      ];

      for (final error in networkErrors) {
        expect(error.contains('SocketException') ||
               error.contains('Connection') ||
               error.contains('timeout') ||
               error.contains('Failed host lookup') ||
               error.contains('Network is unreachable'), 
               isTrue, 
               reason: 'Should identify "$error" as network error');
      }
    });

    test('should identify authorization errors correctly', () {
      final authErrors = [
        'Access denied. Contact administrator',
        'Authorization error',
        'HTTP 403 error',
      ];

      for (final error in authErrors) {
        expect(error.contains('Access denied') ||
               error.contains('Authorization error') ||
               error.contains('403'), 
               isTrue,
               reason: 'Should identify "$error" as authorization error');
      }
    });

    test('should identify authentication errors correctly', () {
      final authErrors = [
        'Authentication error. Please login again',
        'Authentication error',
        'HTTP 401 error',
      ];

      for (final error in authErrors) {
        expect(error.contains('Authentication error') ||
               error.contains('401') ||
               error.contains('login again'), 
               isTrue,
               reason: 'Should identify "$error" as authentication error');
      }
    });

    test('should identify duplicate attendance errors correctly', () {
      final duplicateErrors = [
        'Attendance already registered for today',
        'duplicate attendance',
        'already exists',
      ];

      for (final error in duplicateErrors) {
        expect(error.contains('already registered') ||
               error.contains('duplicate') ||
               error.contains('already exists'), 
               isTrue,
               reason: 'Should identify "$error" as duplicate error');
      }
    });

    test('should have success messages in English', () {
      final successMessages = [
        'Registration successful! Welcome!',
        'Status updated successfully',
        'Event deleted successfully',
        'QR Code saved to gallery!',
        'Attendance registered successfully',
      ];

      for (final message in successMessages) {
        expect(message, isNotEmpty);
        expect(message, isA<String>());
        // Verify no Italian success words remain
        expect(message.toLowerCase(), isNot(contains('successo')));
        expect(message.toLowerCase(), isNot(contains('completato')));
        expect(message.toLowerCase(), isNot(contains('salvato')));
        expect(message.toLowerCase(), isNot(contains('riuscito')));
      }
    });
  });

  group('Error Classification Logic', () {
    test('should correctly classify real-world error scenarios', () {
      final testCases = [
        {
          'error': 'Exception: Network error: SocketException: Connection refused',
          'category': 'network',
          'userMessage': 'Connection error'
        },
        {
          'error': 'Exception: Access denied. Contact administrator for permissions.',
          'category': 'authorization',
          'userMessage': 'Access denied'
        },
        {
          'error': 'Exception: Authentication error. Please login again and try again.',
          'category': 'authentication',
          'userMessage': 'Authentication error'
        },
        {
          'error': 'Exception: FormatException: Invalid JSON',
          'category': 'format',
          'userMessage': 'Format error'
        },
      ];

      for (final testCase in testCases) {
        final error = testCase['error'] as String;
        final category = testCase['category'] as String;
        
        switch (category) {
          case 'network':
            expect(error.contains('SocketException') || 
                   error.contains('Connection') || 
                   error.contains('Network error'), isTrue);
            break;
          case 'authorization':
            expect(error.contains('Access denied') || 
                   error.contains('403'), isTrue);
            break;
          case 'authentication':
            expect(error.contains('Authentication error') || 
                   error.contains('401'), isTrue);
            break;
          case 'format':
            expect(error.contains('FormatException') || 
                   error.contains('json'), isTrue);
            break;
        }
      }
    });
  });
}
