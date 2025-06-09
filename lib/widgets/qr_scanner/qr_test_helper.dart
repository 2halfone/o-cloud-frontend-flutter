import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRTestHelper extends StatelessWidget {
  final Function(String) onQRGenerated;

  const QRTestHelper({
    super.key,
    required this.onQRGenerated,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Fixed width to prevent layout issues
      constraints: const BoxConstraints(
        maxWidth: 280,
        maxHeight: 300, // Prevent excessive height
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Test Helper',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Generate test QR codes for development:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          _buildTestButton(
            'Valid JWT Token',
            _generateValidJWT(),
            Icons.verified,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildTestButton(
            'Expired JWT Token',
            _generateExpiredJWT(),
            Icons.schedule,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildTestButton(
            'Invalid JWT Format',
            _generateInvalidJWT(),
            Icons.error,
            Colors.red,
          ),
        ],
      ),
    );
  }
  Widget _buildTestButton(String title, String qrData, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 280), // Add max width constraint
      child: OutlinedButton(
        onPressed: () {
          onQRGenerated(qrData);
          HapticFeedback.lightImpact();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Prevent row from expanding beyond content
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  String _generateValidJWT() {
    // Simulated valid JWT structure for testing
    final header = '{"alg":"HS256","typ":"JWT"}';
    final payload = '{"user_id":"12345","exp":${DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000},"iat":${DateTime.now().millisecondsSinceEpoch ~/ 1000}}';
    final signature = 'fake_signature_for_testing';
    
    return '{"token":"$header.$payload.$signature","user_id":"12345","timestamp":"${DateTime.now().toIso8601String()}"}';
  }

  String _generateExpiredJWT() {
    // Simulated expired JWT structure for testing
    final header = '{"alg":"HS256","typ":"JWT"}';
    final payload = '{"user_id":"12345","exp":${DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000},"iat":${DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000}}';
    final signature = 'fake_signature_for_testing';
    
    return '{"token":"$header.$payload.$signature","user_id":"12345","timestamp":"${DateTime.now().toIso8601String()}"}';
  }

  String _generateInvalidJWT() {
    // Invalid JSON structure for testing error handling
    return '{"invalid_json": missing_quote_and_bracket';
  }
}
