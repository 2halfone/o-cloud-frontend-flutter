import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class QRImagePickerWidget extends StatelessWidget {
  final Function(String) onQRScanned;
  final Function(String) onError;

  const QRImagePickerWidget({
    super.key,
    required this.onQRScanned,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPickerButton(
            context: context,
            icon: Icons.photo_camera,
            title: 'Take Photo',
            subtitle: 'Capture QR code with camera',
            onTap: () => _pickImage(ImageSource.camera),
            gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          const SizedBox(height: 16),
          _buildPickerButton(
            context: context,
            icon: Icons.photo_library,
            title: 'Choose from Gallery',
            subtitle: 'Select QR code from photos',
            onTap: () => _pickImage(ImageSource.gallery),
            gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[300],
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // TODO: Implement QR code detection from image
        // For now, we'll simulate a successful scan
        _simulateQRDetection(image.path);
      }
    } catch (e) {
      onError('Failed to pick image: $e');
    }
  }

  void _simulateQRDetection(String imagePath) {
    // This is a placeholder - in a real implementation you would use
    // a library like google_ml_kit to detect QR codes in images
    
    // For demonstration, we'll simulate finding a QR code
    Future.delayed(const Duration(milliseconds: 500), () {
      onQRScanned('Simulated QR data from image: ${DateTime.now().millisecondsSinceEpoch}');
    });
  }
}
