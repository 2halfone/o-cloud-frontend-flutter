// Debug helper for testing error handling
// This file can be used to simulate different types of errors
// and verify that they are handled correctly

import 'package:flutter/material.dart';

class ErrorTestingHelper {
    /// Simulates different types of errors for testing
  static Map<String, String> getTestErrors() {
    return {
      'network_error': 'Network error: SocketException: Connection refused (errno = 111)',
      'auth_error': 'Authentication error. Please login again and retry.',
      'permission_error': 'Access denied. Your user role does not have permissions to register attendance. Contact the administrator.',
      'duplicate_error': 'Attendance already registered for today. Cannot register duplicate attendance.',
      'json_error': 'Error in server response format. Please try again later.',
      'timeout_error': 'Request timeout. Check your connection and retry.',
      'sync_error': 'Data synchronization error. The system is automatically retrying.',
      'config_error': 'System configuration error. Contact the administrator.',
      'generic_error': 'An unexpected error occurred during registration.',
    };
  }
  /// Verifies that an error is classified correctly
  static String classifyError(String errorMessage) {
    if (errorMessage.contains('SocketException') || 
        errorMessage.contains('Connection') || 
        errorMessage.contains('timeout') ||
        errorMessage.contains('Failed host lookup') ||
        errorMessage.contains('Network is unreachable')) {
      return 'network';
    } else if (errorMessage.contains('Access denied') || 
               errorMessage.contains('Authorization error') || 
               errorMessage.contains('403')) {
      return 'authorization';
    } else if (errorMessage.contains('Authentication error') || 
               errorMessage.contains('401') ||
               errorMessage.contains('authentication')) {
      return 'authentication';
    } else if (errorMessage.contains('already registered') || 
               errorMessage.contains('duplicate')) {
      return 'duplicate';
    } else if (errorMessage.contains('response format') || 
               errorMessage.contains('json')) {
      return 'format';
    } else if (errorMessage.contains('timeout') || 
               errorMessage.contains('expired')) {
      return 'timeout';
    } else if (errorMessage.contains('synchronization') || 
               errorMessage.contains('sync')) {
      return 'sync';
    } else if (errorMessage.contains('configuration') || 
               errorMessage.contains('database')) {
      return 'configuration';
    } else {
      return 'generic';
    }
  }
  /// Get user-friendly message for an error type
  static String getUserFriendlyMessage(String errorType) {
    switch (errorType) {
      case 'network':
        return 'Connection error: Check your internet connection and retry.';
      case 'authorization':
        return 'Access denied: Your account does not have permissions to register attendance. Contact the administrator.';
      case 'authentication':
        return 'Authentication error: Please login again and retry.';
      case 'duplicate':
        return 'Attendance already registered for today. You cannot register duplicate attendance.';
      case 'format':
        return 'Error in received data format. The server may be under maintenance.';
      case 'timeout':
        return 'Request timeout: The connection is too slow. Please retry.';
      case 'sync':
        return 'Data synchronization error. The system is automatically retrying.';
      case 'configuration':
        return 'System configuration error. Contact the administrator.';
      default:
        return 'An error occurred during registration. Please retry.';
    }
  }
  /// Get the appropriate icon for an error type
  static IconData getErrorIcon(String errorType) {
    switch (errorType) {
      case 'network':
        return Icons.wifi_off;
      case 'authorization':
        return Icons.block;
      case 'authentication':
        return Icons.login;
      case 'duplicate':
        return Icons.event_available;
      case 'format':
        return Icons.data_usage;
      case 'timeout':
        return Icons.timer_off;
      case 'sync':
        return Icons.sync_problem;
      case 'configuration':
        return Icons.settings;
      default:
        return Icons.error;
    }
  }
  /// Get the appropriate color for an error type
  static Color getErrorColor(String errorType) {
    switch (errorType) {
      case 'network':
        return Colors.grey;
      case 'authorization':
        return Colors.orange;
      case 'authentication':
        return Colors.red;
      case 'duplicate':
        return Colors.blue;
      case 'format':
        return Colors.purple;
      case 'timeout':
        return Colors.brown;
      case 'sync':
        return Colors.amber;
      case 'configuration':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }
  /// Test error classification
  static void runErrorClassificationTests() {
    final testErrors = getTestErrors();
    
    print('🧪 Testing Error Classification:');
    print('━' * 50);
    
    testErrors.forEach((errorType, errorMessage) {
      final classified = classifyError(errorMessage);
      final userMessage = getUserFriendlyMessage(classified);
      
      print('📝 Error Type: $errorType');
      print('   Original: $errorMessage');
      print('   Classified as: $classified');
      print('   User Message: $userMessage');
      print('   ✅ ${classified == errorType.replaceAll('_error', '') ? 'PASS' : 'FAIL'}');
      print('');
    });
  }
  /// Simulate a specific error for testing
  static void simulateError(String errorType, BuildContext context) {
    final testErrors = getTestErrors();
    final errorMessage = testErrors[errorType] ?? testErrors['generic_error']!;
    final classified = classifyError(errorMessage);
    final userMessage = getUserFriendlyMessage(classified);
    final icon = getErrorIcon(classified);
    final color = getErrorColor(classified);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Test Error - $errorType',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Debug widget for testing errors
class ErrorTestingWidget extends StatelessWidget {
  const ErrorTestingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final testErrors = ErrorTestingHelper.getTestErrors();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Testing'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testErrors.length,
        itemBuilder: (context, index) {
          final errorType = testErrors.keys.elementAt(index);
          final icon = ErrorTestingHelper.getErrorIcon(
            ErrorTestingHelper.classifyError(testErrors[errorType]!)
          );
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(icon, color: Colors.deepPurple),
              title: Text(errorType.replaceAll('_', ' ').toUpperCase()),
              subtitle: Text(ErrorTestingHelper.getUserFriendlyMessage(
                ErrorTestingHelper.classifyError(testErrors[errorType]!)
              )),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => ErrorTestingHelper.simulateError(errorType, context),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ErrorTestingHelper.runErrorClassificationTests(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.bug_report),
      ),
    );
  }
}
