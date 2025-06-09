import 'package:flutter/material.dart';

class QRTestWidget extends StatelessWidget {
  const QRTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'QR TEST CODE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            color: Colors.black,
            child: const Center(
              child: Text(
                '█████████\n█ █   █ █\n█ ███ █ █\n█ ███ █ █\n█ █   █ █\n█████████\n█       █\n█████████',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'EVENT_2025_ATTENDANCE_001',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),          const SizedBox(height: 8),
          const Text(
            'Scan with QR reader to register attendance',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
